library(tidyverse)
library(ollamar)

d <- read_csv("ietf_email.csv")

d <- d |> mutate(Body_short = str_sub(Body, 1, 800))

batch_size <- 400
n_batches <- ceiling(nrow(d) / batch_size)

summarize_theme_freely <- function(text) {
  tryCatch({
    chat <- chat_ollama(
      system_prompt = "You are an assistant for summarizing email discussions.
Please carefully read the email body provided.
Extract 1-2 **concise** theme phrases that summarize the main topic(s) of the email.
-Only output the themes in English, like: 'Theme: ...'.
-No numbering (no '1.', '2.'), no explanations, no repetition of the email body.
-If only one theme is found, output just one.
-Keep the output **strictly clean** and **short**.",
      model = "llama3",
      echo = FALSE
    )
    chat$chat(text)
  }, error = function(e) {
    NA
  })
}

for (i in 1:n_batches) {
  cat("Processing batch", i, "...\n")
  
  d_batch <- d |> 
    slice(((i-1)*batch_size + 1):(min(i*batch_size, nrow(d)))) |> 
    mutate(
      LLM_Themes = map_chr(Body_short, summarize_theme_freely, .progress = TRUE)
    )
  
  write_csv(d_batch, paste0("ietf_email_llm_batch_", i, ".csv"))
  
  cat("Batch", i, "completed.\n")
}

cat("All batches processed. Ready for merging.\n")

file_list <- list.files(pattern = "ietf_email_llm_batch_.*\\.csv$")
d_all <- file_list |> map_dfr(read_csv)
write_csv(d_all, "ietf_email_full_llm_themes.csv")
