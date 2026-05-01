library(tidyverse)
library(ollamar)

# ==== Step 1: Read small themes ====

llm_themes <- read_csv("ietf_email_full_llm_themes.csv")  # change to bare filename

# ==== Step 2: Define single-item classification function ====

assign_big_theme <- function(single_theme) {
  chat <- chat_ollama(
    system_prompt = "You have previously summarized 10 big themes based on email topics:
- IPv6 Transition and Internet Infrastructure
- Meeting Logistics, Safety, and Location Planning
- Mailing List Operations and Moderation
- Identity, Privacy, and Authentication
- Standards Development Process and Governance
- Security, Encryption, and Trust Models
- Protocol Evolution and Obsolescence
- Volunteerism, Leadership, and NomCom Issues
- Process Experiments and Organizational Change
- Email Systems, Infrastructure, and Statistics

Now, given a short email theme, assign it to the most appropriate big theme.

Instructions:
- Only output the big theme title.
- No extra explanation, no numbering.
- Output must be exactly one big theme title.",
    model = "llama3",
    echo = FALSE
  )
  chat$chat(single_theme)
}

# ==== Step 3: Batch classification ====

batch_size <- 400
n_batches <- ceiling(nrow(llm_themes) / batch_size)

for (i in 1:n_batches) {
  cat("Processing batch", i, "...\n")
  
  d_batch <- llm_themes |> 
    slice(((i-1)*batch_size + 1):(min(i*batch_size, nrow(llm_themes)))) |> 
    mutate(
      Big_Theme = map_chr(LLM_Themes, assign_big_theme, .progress = TRUE)
    )
  
  write_csv(d_batch, paste0("ietf_email_bigtheme_batch_", i, ".csv"))  # save without data/ path
  
  cat("Batch", i, "completed.\n")
}

# ==== Step 4: Merge ====

file_list <- list.files(pattern = "ietf_email_bigtheme_batch_.*\\.csv$")  # remove data/ prefix
bigthemes_final <- file_list |> map_dfr(read_csv)

write_csv(bigthemes_final, "ietf_email_full_llm_bigthemes.csv")  # save to root directory

cat("✅ Big theme classification for each email is complete, saved to 'ietf_email_full_llm_bigthemes.csv'\n")
