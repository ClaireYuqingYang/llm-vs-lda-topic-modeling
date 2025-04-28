library(tidyverse)

llm_data <- read_csv("data/ietf_email_full_llm_bigthemes.csv")
lda_data <- read_csv("data/ietf_email_with_lda_topics.csv")

# llm_theme_counts <- llm_data |> 
#   count(LLM_Themes, name = "count") |> 
#   mutate(method = "LLM")
# 
# lda_theme_counts <- lda_data |> 
#   count(topic, name = "count") |> 
#   mutate(method = "LDA", topic = paste0("Topic ", topic))
# 
# theme_counts <- bind_rows(
#   llm_theme_counts |> rename(theme = LLM_Themes),
#   lda_theme_counts |> rename(theme = topic)

lda_primary <- lda_data %>%
  group_by(document) %>%
  slice_max(gamma, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(
    topic_char = as.character(topic),
    topic_char = if_else(is.na(topic_char), "Not Classified", topic_char)
  ) %>%
  count(topic_char) %>%
  mutate(
    prop   = n / sum(n),
    Source = "LDA"
  )

llm_primary <- llm_data %>%
  filter(!is.na(Big_Theme)) %>%
  mutate(raw = str_squish(Big_Theme)) %>%
  mutate(topic_char = case_when(
    str_detect(raw, regex("please|provide|i apologize|error|theme:", ignore_case=TRUE)) ~
      "Not Classified",
    str_detect(raw, regex("^IPv6\\s+Transition", ignore_case=TRUE)) ~
      "IPv6 Transition and Internet Infrastructure",
    str_detect(raw, regex("^Protocols?\\s+Evolution", ignore_case=TRUE)) ~
      "Protocols Evolution and Obsolescence",
    TRUE ~ raw
  )) %>%
  count(topic_char) %>%
  mutate(
    prop   = n / sum(n),
    Source = "LLM"
  )

lda_ord <- lda_primary %>%
  arrange(desc(prop)) %>%
  pull(topic_char)

llm_ord <- llm_primary %>%
  filter(topic_char != "Not Classified") %>%
  arrange(prop) %>%
  pull(topic_char)

lda_n <- length(lda_ord)-1
llm_n <- length(llm_ord)
mid    <- lda_n + 1

plot_df <- bind_rows(lda_primary, llm_primary) %>%
  mutate(
    x = case_when(
      topic_char == "Not Classified"~ mid,
      Source == "LDA"~ match(topic_char, lda_ord),
      Source == "LLM"~ mid + match(topic_char, llm_ord),
      TRUE  ~ NA_real_
    )
  )

breaks <- c(
  seq_len(lda_n), 
  mid,
  mid + seq_len(llm_n)
)

labels <- c(
  as.character(lda_ord[1:10]),
  "Not Classified",
  as.character(seq_along(llm_ord))
)

fig1 <- ggplot(plot_df, aes(x = x, y = prop, color = Source, linetype = Source)) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = breaks, labels = labels) +
  scale_y_continuous(labels = percent_format(1)) +
  scale_color_manual(values   = c("LDA" = "firebrick", "LLM" = "steelblue")) +
  scale_linetype_manual(values = c("LDA" = "solid",    "LLM" = "dashed")) +
  labs(
    x     = "Topic",
    y     = "Proportion of Documents",
    title = "LDA vs LLM Topic Distribution",
    color = NULL, linetype = NULL
  ) +
  theme_minimal(base_size = 14) +
  theme(
    axis.text.x      = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank()
  )


ggsave("figs/llm_vs_lda_theme_comparison.png", fig1, width = 10, height = 7)

cat("✅ Saved comparison figure to 'figs/llm_vs_lda_theme_comparison.png'\n")
