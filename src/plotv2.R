library(tidyverse)
library(text2vec)
library(data.table)

lda_data <- read_csv("data/ietf_email_with_lda_topics.csv")
llm_data <- read_csv("data/ietf_email_full_llm_bigthemes.csv")

lda_primary <- lda_data %>%
  group_by(document) %>%
  slice_max(gamma, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(lda_topic = paste0("Topic ", topic)) %>%
  dplyr::select(document, lda_topic)

lda_labels <- read_csv("data/lda_topic_labels.csv") %>%
  mutate(lda_topic = paste0("Topic ", topic)) %>%
  dplyr::select(lda_topic, label)

lda_primary_labeled <- lda_primary %>%
  left_join(lda_labels, by = "lda_topic") %>%
  mutate(label = coalesce(label, lda_topic))

lda_primary <- lda_primary_labeled %>%
  dplyr::select(document, lda_topic = label)

llm_theme_data <- llm_data %>%
  mutate(document = row_number()) %>%
  dplyr::select(document, Big_Theme) %>%
  mutate(
    llm_theme = case_when(
      is.na(Big_Theme) ~ "Not Classified",
      str_detect(Big_Theme, regex("please|provide|i apologize|error|theme:", ignore_case = TRUE)) ~ "Not Classified",
      
      str_detect(Big_Theme, regex("ipv6", ignore_case = TRUE)) ~ "IPv6 Transition and Internet Infrastructure",
      str_detect(Big_Theme, regex("protocol", ignore_case = TRUE)) ~ "Protocol Evolution and Obsolescence",
      # str_detect(Big_Theme, regex("process", ignore_case = TRUE)) ~ "Process Topics",
      # str_detect(Big_Theme, regex("security|encryption|trust", ignore_case = TRUE)) ~ "Security Topics",
      # str_detect(Big_Theme, regex("meeting|mailing", ignore_case = TRUE)) ~ "Meeting & Logistics",
      
      # 其余不变
      TRUE ~ Big_Theme
    )
  )

joined <- inner_join(lda_primary, llm_theme_data, by = "document")

heatmap_df <- joined %>%
  count(lda_topic, llm_theme) %>%
  group_by(lda_topic) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()
theme_order <- heatmap_df %>%
  group_by(llm_theme) %>%
  summarise(total = sum(prop)) %>%
  arrange(desc(total)) %>%
  pull(llm_theme)

topic_order <- heatmap_df %>%
  group_by(lda_topic) %>%
  summarise(total = sum(prop)) %>%
  arrange(desc(total)) %>%
  pull(lda_topic)

heatmap_df <- heatmap_df %>%
  mutate(
    llm_theme = factor(llm_theme, levels = theme_order),
    lda_topic = factor(lda_topic, levels = topic_order)
  )

theme_order <- heatmap_df %>%
  group_by(llm_theme) %>%
  summarise(total = sum(prop)) %>%
  arrange(desc(total)) %>%
  pull(llm_theme)

heatmap_df <- heatmap_df %>%
  mutate(llm_theme = factor(llm_theme, levels = theme_order))

p <- ggplot(heatmap_df, aes(x = llm_theme, y = lda_topic, fill = prop)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(
    x = "LLM Big Theme",
    y = "LDA Topic",
    fill = "Proportion",
    title = "Heatmap of LDA vs LLM Topic Assignment"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

ggsave("figs/llm_vs_lda_theme_heatmap.png", p,
       width  = 10,
       height = 7,
       dpi    = 300)
