library(tidyverse)
library(text2vec)
library(data.table)
library(reshape2)
library(ggplot2)

lda_data <- read_csv("data/ietf_email_with_lda_topics.csv")

lda_labels <- read_csv("data/lda_topic_labels.csv") %>%
  mutate(lda_topic = paste0("Topic ", topic)) %>%
  select(lda_topic, label)

lda_primary <- lda_data %>%
  group_by(document) %>%
  slice_max(gamma, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(lda_topic = paste0("Topic ", topic)) %>%
  left_join(lda_labels, by = "lda_topic") %>%
  mutate(lda_topic = coalesce(label, lda_topic)) %>%
  select(document, lda_topic)

llm_data <- read_csv("data/ietf_email_full_llm_bigthemes.csv")
llm_theme_data <- llm_data %>%
  mutate(document = row_number()) %>%
  select(document, Big_Theme) %>%
  mutate(
    llm_theme = case_when(
      is.na(Big_Theme) ~ "Not Classified",
      str_detect(Big_Theme, regex("please|provide|i apologize|error|theme:", ignore_case = TRUE)) ~ "Not Classified",
      str_detect(Big_Theme, regex("ipv6", ignore_case = TRUE)) ~ "IPv6 Transition and Internet Infrastructure",
      str_detect(Big_Theme, regex("protocol", ignore_case = TRUE)) ~ "Protocol Evolution and Obsolescence",
      TRUE ~ Big_Theme
    )
  ) %>%
  select(document, llm_theme)

doc_texts <- lda_data %>%
  mutate(document = row_number()) %>%
  select(document, Body) %>%
  left_join(lda_primary, by = "document") %>%
  left_join(llm_theme_data, by = "document") %>%
  filter(!is.na(lda_topic), !is.na(llm_theme))

prep_fun <- tolower
tok_fun <- word_tokenizer

it <- itoken(doc_texts$Body, preprocessor = prep_fun, tokenizer = tok_fun, progressbar = FALSE)

vocab <- create_vocabulary(it) %>% prune_vocabulary(term_count_min = 5)
vectorizer <- vocab_vectorizer(vocab)
dtm <- create_dtm(it, vectorizer)

tfidf <- TfIdf$new()
dtm_tfidf <- tfidf$fit_transform(dtm)

doc_texts$lda_topic <- as.factor(doc_texts$lda_topic)
doc_texts$llm_theme <- as.factor(doc_texts$llm_theme)

lda_topic_vectors <- split(as.matrix(dtm_tfidf), doc_texts$lda_topic) %>%
  map(~ colMeans(matrix(.x, ncol = ncol(dtm_tfidf), byrow = TRUE)))

llm_theme_vectors <- split(as.matrix(dtm_tfidf), doc_texts$llm_theme) %>%
  map(~ colMeans(matrix(.x, ncol = ncol(dtm_tfidf), byrow = TRUE)))

cosine_sim <- function(a, b) {
  sum(a * b) / (sqrt(sum(a^2)) * sqrt(sum(b^2)))
}

lda_names <- names(lda_topic_vectors)
llm_names <- names(llm_theme_vectors)

sim_matrix <- matrix(NA, nrow = length(lda_names), ncol = length(llm_names),
                     dimnames = list(lda_names, llm_names))

for (i in seq_along(lda_names)) {
  for (j in seq_along(llm_names)) {
    sim_matrix[i, j] <- cosine_sim(lda_topic_vectors[[i]], llm_theme_vectors[[j]])
  }
}

sim_df <- melt(sim_matrix, varnames = c("LDA_Topic", "LLM_Theme"), value.name = "Similarity")

p <- ggplot(sim_df, aes(x = LLM_Theme, y = LDA_Topic, fill = Similarity)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "white", high = "darkred", mid = "orange", midpoint = 0.5, na.value = "grey90") +
  theme_minimal(base_size = 13) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Semantic Similarity Between LDA Topics and LLM Themes",
       fill = "Cosine Similarity")

ggsave("figs/llm_vs_lda_semantic_similarity.png", p,
       width  = 10,
       height = 7,
       dpi    = 300)

library(tibble)

lda_topics <- rownames(sim_matrix)
llm_themes <- colnames(sim_matrix)

greedy_mapping <- tibble(
  lda_topic = lda_topics,
  llm_theme = apply(sim_matrix, 1, function(x) llm_themes[which.max(x)]),
  similarity = apply(sim_matrix, 1, max)
)

print(greedy_mapping)
