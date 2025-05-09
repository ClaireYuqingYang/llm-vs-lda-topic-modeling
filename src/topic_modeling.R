library(tidyverse)
library(tm)
library(topicmodels)
library(tidytext)

setwd("~/NYU_Study/DataPracticum/finalpro")

d <- read_csv("ietf_email.csv")

texts <- d$Body |> na.omit()

corpus <- VCorpus(VectorSource(texts))

corpus_clean <- corpus |>
  tm_map(content_transformer(tolower)) |>
  tm_map(removePunctuation) |>
  tm_map(removeNumbers) |>
  tm_map(removeWords, stopwords("english")) |>
  tm_map(stripWhitespace)

dtm <- DocumentTermMatrix(corpus_clean)

print(dim(dtm))

dtm_sparse <- removeSparseTerms(dtm, 0.99)

library(slam)
row_sums <- slam::row_sums(dtm_sparse)
dtm_sparse <- dtm_sparse[row_sums > 0, ]

library(topicmodels)
library(ggplot2)

topic_numbers <- 2:20

perplexities <- numeric(length(topic_numbers))

for (i in seq_along(topic_numbers)) {
  k <- topic_numbers[i]
  
  lda_temp <- LDA(dtm_sparse, k = k, control = list(seed = 1234))
  
  perplexities[i] <- perplexity(lda_temp, dtm_sparse)
  
  cat("Completed Topic Number:", k, "\n")
}

data.frame(k = topic_numbers, perplexity = perplexities) |>
  ggplot(aes(x = k, y = perplexity)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Elbow Plot for Choosing Number of Topics",
    x = "Number of Topics (k)",
    y = "Perplexity (Lower is Better)"
  ) +
  theme_minimal()

k_topics <- 10

lda_model <- LDA(dtm_sparse, k = k_topics, control = list(seed = 1234))

topics_terms <- tidy(lda_model, matrix = "beta")

topics_terms |>
  group_by(topic) |>
  slice_max(beta, n = 10) |>
  ungroup() |>
  mutate(term = reorder_within(term, beta, topic)) |>
  ggplot(aes(term, beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  coord_flip() +
  scale_x_reordered() +
  labs(title = paste("Top Words in", k_topics, "LDA Topics"))

doc_topics <- tidy(lda_model, matrix = "gamma")

doc_topic_assignment <- doc_topics |>
  group_by(document) |>
  slice_max(gamma, n = 1) |>
  ungroup()

d <- d |>
  mutate(document = as.character(row_number())) |>
  left_join(doc_topic_assignment, by = "document")

write_csv(d, "ietf_email_with_topics.csv")

cat("Traditional Topic Modeling (LDA) completed. Results saved to 'ietf_email_with_topics.csv'.\n")


topic_modeling_results <- read_csv('ietf_email_with_topics.csv')

library(tidytext)

topics_terms <- tidy(lda_model, matrix = "beta")

top_terms <- topics_terms |> 
  group_by(topic) |> 
  slice_max(beta, n = 10) |> 
  arrange(topic, -beta)

top_terms

library(tidytext)
library(stringr)

topic_labels <- topics_terms |>
  group_by(topic) |>
  slice_max(beta, n = 3) |>
  summarise(label = str_c(term, collapse = ", "))

print(topic_labels)

library(ggplot2)

d_labeled <- d |> 
  left_join(topic_modeling_results, by = "topic")

d_labeled |>
  count(label) |>
  ggplot(aes(x = reorder(label, n), y = n)) +
  geom_col(fill = "lightsteelblue") +
  coord_flip() +
  labs(title = "Number of Emails per Topic",
       x = "Topic (Top 3 words)",
       y = "Number of Emails") +
  theme_minimal(base_size = 14)

write_csv(topic_labels, "topic_labels.csv")
