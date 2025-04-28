library(tidyverse)
library(ollamar)

#llama3 7b does not work on this step (it says cannot read or given no content), maybe because the input is too long. 
#Thus, We feed GPT 4o with the long themes_text. 
#10 topics are as stored in "llm_big_topics_summary.csv"

llm_themes <- read_csv("ietf_email_full_llm_themes.csv")

all_themes <- llm_themes$LLM_Themes |> na.omit() |> as.character()

themes_text <- paste(all_themes, collapse = "\n")
themes_text

summarize_big_themes <- function(text) {
  chat <- chat_ollama(
    system_prompt = "You are an expert at summarizing topics from a collection of themes.

Your task:
- Read the following 1587 short theme descriptions (each line is a theme).
- Group them into **10 bigger topics**.
- For each bigger topic, give:
  - A short title (3-5 words)
  - 1–2 sentences of description (summarizing what kind of themes are included)
- Only output clean titles and descriptions.
- No numbering like '1.', '2.', just structured clean output.
- Do NOT repeat the original small themes.
- Make it compact and readable.",
    model = "llama3",
    echo = FALSE
  )
  chat$chat(text)
}

big_themes_result <- summarize_big_themes(themes_text)

cat(big_themes_result)
