# Load required libraries
library(lessR)
library(dplyr)
library(tm)
library(tidyr)
library(tidytext)
library(wordcloud)
library(stringr)


### 1. Emotion Analysis
# Null Hypothesis: Posts that include the topic of fluoride have no emotional difference compared to those that are not about fluoride.

# Load Data
general_posts <- read.csv("general_posts.csv", header = TRUE)[,-1] %>% mutate(Source = "General")
fluoride_posts <- read.csv("fluoride_posts.csv", header = TRUE)[,-1] %>% mutate(Source = "Fluoride")
combined_posts <- bind_rows(general_posts, fluoride_posts) 

# Create a marker for fluoride topics
combined_posts <- combined_posts %>%  mutate(Fluoride_Topic = ifelse(grepl("\\bFluoride\\b", Topic), "Fluoride", "NonFluoride"))

# Given Fluoride, what topics, make a pie-chart

# Get all emotions in data
emotion_vec <- combined_posts %>%
  separate_longer_delim(Emotion, ",") %>%
  mutate(Emotion = trimws(Emotion)) %>%
  filter(Emotion != "N/A") %>%
  select(Emotion) %>%
  unique() %>%
  unlist()

# Creating Table for python code:

fluor <- combined_posts$Fluoride_Topic == "Fluoride"

pyvec = sapply(emotion_vec, function(x) {
  Has_Emotion <- grepl(paste0("\\b", x, "\\b"), combined_posts$Emotion)
  c(sum(Has_Emotion & fluor)/sum(fluor), sum(Has_Emotion & !fluor)/sum(!fluor)) 
}) %>% t()
colnames(pyvec) = c("Fluoride", "Non-Fluoride")
rownames(pyvec) = emotion_vec
round(pyvec, 3)


# Sampling procedure for significance of emotions across Fluoride v NonFluoride Topics.

# Begin with 1000 samples of the posts
iter = 1000
emotion_results_df <- vector("list", iter)
unique_ids <- unique(combined_posts$Author.ID)

for (i in 1:iter) {
  if (i %% 5 == 0) message("Working on iteration ", i)
  
  # Sample one post per unique Author.ID 
  # This will give us no more user correlation between emotions and posts. 
  # (users who post about sad stuff will post sadly regardless of topic, me thinks)
  # This eliminates that bias
  split_indices <- split(seq_len(nrow(combined_posts)), combined_posts$Author.ID)
  sampled_indices <- vapply(split_indices, function(x) x[sample.int(length(x), 1)], integer(1))
  sampled_df <- combined_posts[sampled_indices, ]
  
  # Preallocate result list for this iteration
  emotion_results <- vector("list", length(emotion_vec))
  
  fluor <- sampled_df$Fluoride_Topic == "Fluoride"
  
  for (j in seq_along(emotion_vec)) {
    emotion <- emotion_vec[j]
    Has_Emotion <- grepl(paste0("\\b", emotion, "\\b"), sampled_df$Emotion)
    
    # Build 2x2 matrix
    sample_table <- matrix(c(
      sum(!fluor & !Has_Emotion),
      sum(fluor & !Has_Emotion),
      sum(!fluor & Has_Emotion),
      sum(fluor & Has_Emotion)
    ), nrow = 2, byrow = FALSE,
    dimnames = list(c("NonFluoride", "Fluoride"), c("FALSE", "TRUE")))
    
    test <- fisher.test(sample_table)
    
    emotion_results[[j]] <- data.frame(
      Emotion = emotion,
      P_Value = test$p.value,
      Odds_Ratio = unname(test$estimate),
      stringsAsFactors = FALSE
    )
  }
  
  # Combine into one data.frame and adjust p-values
  result_df <- do.call(rbind, emotion_results)
  result_df$Adjusted_P <- p.adjust(result_df$P_Value, method = "bonferroni")
  emotion_results_df[[i]] <- result_df
}

# Combine all iterations into one data frame
all_results <- do.call(rbind, lapply(seq_along(emotion_results_df), function(i) {
  cbind(iter = i, emotion_results_df[[i]])
}))

# Get the summary matrix
summary_list <- lapply(split(all_results, all_results$Emotion), function(df) {
  odds <- df$Odds_Ratio
  padj <- df$Adjusted_P
  
  data.frame(
    Emotion = unique(df$Emotion),
    Avg_Odds_Ratio = mean(odds),
    Lower_OR_95CI = quantile(odds, 0.025),
    Upper_OR_95CI = quantile(odds, 0.975),
    Prop_Sig = mean(padj < 0.05),
    Avg_Adjusted_P = mean(padj)
  )
})

# Combine into one data.frame
summary_clean <- do.call(rbind, summary_list)

# Sort
summary_clean <- summary_clean[order(summary_clean$Avg_Adjusted_P), ]
rownames(summary_clean) <- NULL
# Show result
summary_clean

write.csv(summary_clean, file = "emotion_summary.csv")

