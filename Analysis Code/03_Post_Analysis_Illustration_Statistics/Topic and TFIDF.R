# Simple RankAggreg function to get best topic number
library(tibble)
library(dplyr)
library(readr)
library(RankAggreg)
setwd("Results/Topic Models")
files = list.files()
best_topic_nums <- list()
for (f in files) {
  metrics <- read_csv(paste0(f,'/metrics.csv'))
  metrics <- metrics %>% column_to_rownames("K") %>%
    abs() %>%
    apply(., 2, function(x){ metrics$K[order(x, decreasing = TRUE)] }) %>%
    t()
  ranks <- RankAggreg(metrics, k = ncol(metrics), verbose = FALSE)
  best_topic_nums[[f]] <- ranks$top.list
}

best_topic_nums <- do.call(rbind,best_topic_nums)
colnames(best_topic_nums) <- paste("Rank",1:8)
as.data.frame(best_topic_nums)

## type options:
# all_negative
# all_neutral
# all_positive
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(tidytext)
library(SnowballC)

# Rank aggreg was w/e in choosing the topics. Let's use our own brain and TF-IDF Import the data
fluoride_GPT <- read_csv("Data/Processed_Tweets/fluoride_posts.csv")
general_GPT <- read_csv("Data/Processed_Tweets/general_posts.csv")
test <- fluoride_GPT %>% distinct()


# Load custom stopwords
goog_words <- read.delim("C:/Users/owvis/OneDrive - University of Florida/Fluoride_Xdata/Data/Processed_Tweets/google-10000-english.txt", header = FALSE)
custom_stopwords <- c(goog_words$V1[1:1000], "amp")

# Combine & Stem stopwords
combined_stopwords <- stop_words %>%
  select(word) %>%
  bind_rows(tibble(word = custom_stopwords)) %>%
  distinct() %>%
  mutate(word = tolower(word),
         word = gsub("[^a-z]", "", word),
         word = wordStem(word, language = "en")) %>%
  filter(word != "")


# Select topic group
x <- c("all_positive", 4)  # Change as needed
# x <- c("all_neutral", 5)  # Change as needed
# x <- c("all_negative", 6)  # Change as needed

# Load topic assignments
csvpath <- paste0("Results/Topic Models/", x[1], "/", x[2], "_topics/assignments_", x[2], "_topics.csv")
topics <- read_csv(csvpath)

# Tokenize and clean
tokens <- topics %>%
  mutate(Text_nolink = tolower(Text_nolink)) %>%
  separate_rows(Text_nolink, sep = " ") %>%
  mutate(Text_nolink = gsub("[^a-z]", "", Text_nolink)) %>%
  filter(Text_nolink != "") %>%
  rename(word = Text_nolink)

# Apply stemming
tokens <- tokens %>%
  mutate(word = wordStem(word, language = "en"))

# Remove stopwords
tokens <- tokens %>%
  anti_join(combined_stopwords, by = "word")

# Total word frequency
word_total_counts <- tokens %>%
  count(word, name = "total_count") %>%
  filter(total_count > 10)

# Re-filter tokens to keep only frequent words
tokens <- tokens %>%
  semi_join(word_total_counts, by = "word")

# Count per-topic frequency
word_topic_counts <- tokens %>%
  group_by(Assigned_Topic, word) %>%
  summarise(count = n(), .groups = "drop")

# Total words per topic
topic_totals <- tokens %>%
  count(Assigned_Topic, name = "topic_total")

# TF-IDF Calculation
tfidf_df <- word_topic_counts %>%
  left_join(topic_totals, by = "Assigned_Topic") %>%
  mutate(tf = count / topic_total) %>%  # term frequency
  group_by(word) %>%
  mutate(df = n()) %>%  # number of topics each word appears in
  ungroup() %>%
  mutate(idf = log(n_distinct(word_topic_counts$Assigned_Topic) / df),
         tfidf = tf * idf) %>%
  arrange(Assigned_Topic, desc(tfidf)) %>%
  group_by(Assigned_Topic) %>%
  slice_head(n = 6)

print(tfidf_df, n = 100)

table(topics$Assigned_Topic)

