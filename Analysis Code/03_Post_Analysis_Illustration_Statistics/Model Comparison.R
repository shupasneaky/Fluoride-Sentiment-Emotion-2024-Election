library(readr)
#import the data
fluoride_GPT <- read_csv("Data/Processed_Tweets/fluoride_posts.csv")
general_GPT <- read_csv("Data/Processed_Tweets/general_posts.csv")
fluoride_BERT <- read_csv("Backup/Flouride_Tweets_Sentiment_Emotion_roberta.csv")
general_BERT <- read_csv("Backup/User_Tweets_Sentiment_Emotion_roberta.csv")

library(dplyr)
#merge by text
fluoride_GPT <- fluoride_GPT %>% mutate(GPT_Sentiment = Sentiment) %>% select(Text, GPT_Sentiment) 
general_GPT <- general_GPT %>% mutate(GPT_Sentiment = Sentiment) %>% select(Text, GPT_Sentiment) 
fluoride_BERT <- fluoride_BERT %>% mutate(BERT_Sentiment = Sentiment) %>% select(Text, BERT_Sentiment) 
general_BERT <- general_BERT %>% mutate(BERT_Sentiment = Sentiment) %>% select(Text, BERT_Sentiment) 
fluoride_Comp <- merge(fluoride_GPT, fluoride_BERT, by = "Text")
general_Comp <- merge(general_GPT, general_BERT, by = "Text")
#remove NA before sampling
fluoride_Comp <- na.omit(fluoride_Comp)
general_Comp <- na.omit(general_Comp)

#randomly sample
set.seed(1)
fluor_samp <- fluoride_Comp[sample(nrow(fluoride_Comp), 100),] %>% mutate(Source = "Fluoride")
gen_samp <- general_Comp[sample(nrow(general_Comp), 100),] %>% mutate(Source = "General")
samp <- rbind(fluor_samp, gen_samp)

#write the files back
write.csv(samp, file = "Data/Processed_Tweets/posts_mc.csv")


#manually grade all 100 from each
# 1 = neg, 2 = neu, 3 = pos
library(readr)
comp <- read_csv("Data/Processed_Tweets/posts_mc_done.csv")
comp <- comp %>%
  select(-c(...1)) %>%
  mutate(T_Sentiment = case_when(
    T_Sentiment == 1 ~ "negative",
    T_Sentiment == 2 ~ "neutral", 
    TRUE ~ "positive"),
    GPT_Sentiment = tolower(GPT_Sentiment)) %>%
  select(Source, GPT_Sentiment, BERT_Sentiment, T_Sentiment)

fluor_comp <- comp %>% filter(Source=="Fluoride") %>% select(-Source)
gen_comp <- comp %>% filter(Source!="Fluoride") %>% select(-Source)

# ===============================
# Compare GPT vs BERT Predictions
# ===============================

library(dplyr)

# -------------------------------
# 1. Accuracy-Based Comparison
# -------------------------------

# Add logical columns indicating exact match with true sentiment
gen_comp <- gen_comp %>%
  mutate(
    GPT_Correct = GPT_Sentiment == T_Sentiment,
    BERT_Correct = BERT_Sentiment == T_Sentiment
  )

fluor_comp <- fluor_comp %>%
  mutate(
    GPT_Correct = GPT_Sentiment == T_Sentiment,
    BERT_Correct = BERT_Sentiment == T_Sentiment
  )

# Compute accuracy for GPT and BERT (proportion of correct predictions)
gen_acc <- gen_comp %>%
  summarise(
    GPT_Accuracy = mean(GPT_Correct),
    BERT_Accuracy = mean(BERT_Correct)
  )

fluor_acc <- fluor_comp %>%
  summarise(
    GPT_Accuracy = mean(GPT_Correct),
    BERT_Accuracy = mean(BERT_Correct)
  )

# Combine accuracy results into a single table
comparison_table <- bind_rows(
  gen_acc %>% mutate(Dataset = "General"),
  fluor_acc %>% mutate(Dataset = "Fluoride")
) %>%
  select(Dataset, GPT_Accuracy, BERT_Accuracy)

# -------------------------------
# 2. Ordinal Distance Comparison
# -------------------------------

# Define ordered factor levels for ordinal scoring
ordered_levels <- c("negative", "neutral", "positive")

# Function to convert sentiments to numeric scores: neg = 0, neutral = 1, pos = 2
convert_to_numeric <- function(x) {
  as.numeric(factor(x, levels = ordered_levels)) - 1
}

# Apply conversion and calculate absolute distance from true sentiment
gen_comp <- gen_comp %>%
  mutate(
    GPT_num = convert_to_numeric(GPT_Sentiment),
    BERT_num = convert_to_numeric(BERT_Sentiment),
    T_num = convert_to_numeric(T_Sentiment),
    GPT_Distance = abs(GPT_num - T_num),
    BERT_Distance = abs(BERT_num - T_num)
  )

fluor_comp <- fluor_comp %>%
  mutate(
    GPT_num = convert_to_numeric(GPT_Sentiment),
    BERT_num = convert_to_numeric(BERT_Sentiment),
    T_num = convert_to_numeric(T_Sentiment),
    GPT_Distance = abs(GPT_num - T_num),
    BERT_Distance = abs(BERT_num - T_num)
  )

# Compute Mean Absolute Distance from true sentiment
gen_dist <- gen_comp %>%
  summarise(
    GPT_Mean_Distance = mean(GPT_Distance),
    BERT_Mean_Distance = mean(BERT_Distance)
  )

fluor_dist <- fluor_comp %>%
  summarise(
    GPT_Mean_Distance = mean(GPT_Distance),
    BERT_Mean_Distance = mean(BERT_Distance)
  )

# Combine distance metrics into one comparison table
distance_table <- bind_rows(
  gen_dist %>% mutate(Dataset = "General"),
  fluor_dist %>% mutate(Dataset = "Fluoride")
) %>%
  select(Dataset, GPT_Mean_Distance, BERT_Mean_Distance)

# -------------------------------
# 3. Output Tables
# -------------------------------

# Accuracy comparison table
print(comparison_table)

# Ordinal distance comparison table
print(distance_table)


# We evaluated the performance of two sentiment classification models (GPT and BERT) across two datasets: general tweets and fluoride-specific tweets. As shown in Table X, the GPT-based model demonstrated consistently higher accuracy and lower mean absolute distance compared to the BERT-based model. For the general dataset, GPT achieved an accuracy of 87% versus 68% for BERT, with a mean ordinal distance of 0.15 compared to BERT's 0.36. Similar trends were observed in the fluoride dataset, where GPT outperformed BERT by 13 percentage points in accuracy and exhibited lower deviation from the true sentiment labels (0.38 vs. 0.54).

