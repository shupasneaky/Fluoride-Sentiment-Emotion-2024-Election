####################################### Packages ########################################
library(dplyr)
library(ggplot2)
library(tidyr)
library(tidytext)
library(wordcloud)
library(RColorBrewer)
library(gt)
library(webshot2)

####################################### Load Data ########################################
general_posts <- read.csv("general_posts.csv", header = TRUE)[,-1] %>% mutate(Source = "General")
fluoride_posts <- read.csv("fluoride_posts.csv", header = TRUE)[,-1] %>% mutate(Source = "Fluoride")
combined_posts <- bind_rows(general_posts, fluoride_posts) 

str(combined_posts)

####################################### Sentiment summary of fluoride tweets ########################################
# Table: Sentiment counts
fluoride_sentiment_table <- fluoride_posts %>%
  count(Sentiment) %>%
  mutate(Percent = n / sum(n) * 100)

print(fluoride_sentiment_table)

save_table_as_png <- function(df, title, filename) {
  df %>% gt() %>% tab_header(title = title) %>%
    fmt_number( columns = where(is.numeric), decimals = 1 ) %>%
    gtsave(filename)
}
save_table_as_png(fluoride_sentiment_table, "Sentiment Distribution of Fluoride Tweets", "fluoride_sentiment_table.png")

# Plot: Bar plot of sentiment
ggplot(fluoride_sentiment_table, aes(x = Sentiment, y = n, fill = Sentiment)) +
  geom_bar(stat = "identity", color = "black") +
  labs(title = "Sentiment of Fluoride-Related Tweets", x = "Sentiment", y = "Count") +
  theme_minimal()


####################################### Segment users by fluoride sentiment ########################################
# Get each user's dominant sentiment about fluoride
fluoride_user_sentiment <- fluoride_posts %>%
  group_by(Author.ID) %>%
  count(Sentiment) %>%
  slice_max(order_by = n, n = 1) %>% 
  ungroup()

print(fluoride_user_sentiment)


####################################### Topic distribution by user group ########################################
# Join user sentiment info to all tweets
all_posts_with_sentiment <- combined_posts %>%
  left_join(fluoride_user_sentiment, by = "Author.ID", suffix = c("", "_fluoride"))


# Split topics (because some tweets have multiple topics)
topics_by_sentiment <- all_posts_with_sentiment %>%
  separate_rows(Topic, sep = ",") %>%
  filter(!is.na(Sentiment_fluoride)) %>% # Keep only users classified by fluoride sentiment
  count(Sentiment_fluoride, Topic) %>%
  group_by(Sentiment_fluoride) %>%
  mutate(Percent = n / sum(n) * 100) %>%
  ungroup()

print(topics_by_sentiment)

save_table_as_png(topics_by_sentiment, "Topic representation from posts by user sentiment", "fluoride_topic_table.png")


# Plot: Faceted bar plot by sentiment group
ggplot(topics_by_sentiment, aes(x = reorder(Topic, -n), y = n, fill = Topic)) +
  geom_bar(stat = "identity") +
  facet_wrap(~ Sentiment_fluoride, scales = "free_y") +
  labs(title = "Topic Distribution by Fluoride Sentiment Group", x = "Topic", y = "Count") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

####################################### Statistical test — Are topic distributions different? ########################################
# Create contingency table
topic_sentiment_table <- topics_by_sentiment %>%
  select(Sentiment_fluoride, Topic, n) %>%
  pivot_wider(names_from = Sentiment_fluoride, values_from = n, values_fill = 0)

save_table_as_png(topic_sentiment_table, "Topic representation from posts by user sentiment", "fluoride_topic_sentiment_table.png")

# Run Chi-square test
chisq_test <- chisq.test(topic_sentiment_table[,-1])
print(chisq_test)


####################################### Wordclouds function ########################################

# Download Google 10k common words
url <- "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english.txt"
local_path <- "google-10000-english.txt"
download.file(url, local_path, method = "auto")
google_words <- readLines(local_path)
all_stopwords <- c(google_words[1:1000], stopwords(source = "snowball"), "fluoride", "water", "fluoridated", "fluorid", "fluoridation")


word_cloud_fun <- function(d, save_path = NULL) {
  # Clean text: expand contractions, lowercase, remove punctuation, trim spaces
  clean_text <- d %>%
    select(Text_nolink) %>%
    filter(!is.na(Text_nolink)) %>%
    pull(Text_nolink) %>%
    replace_contraction() %>%
    tolower() %>%
    str_remove_all("[[:punct:]]") %>%
    str_squish()
  
  clean_text <- str_split(clean_text, "\\s+") %>%
    lapply(function(words) setdiff(words, all_stopwords)) %>%
    sapply(paste, collapse = " ")
  
  # Create corpus from cleaned text
  mooncloud <- VCorpus(VectorSource(clean_text)) %>%
    tm_map(stripWhitespace) %>%
    tm_map(PlainTextDocument)
  
  # Build term-document matrix and compute word frequencies
  tdm <- TermDocumentMatrix(mooncloud)
  tdm_matrix <- as.matrix(tdm)
  word_freq <- sort(rowSums(tdm_matrix), decreasing = TRUE)
  
  # Generate wordcloud
  if (!is.null(save_path)) {
    png(filename = save_path, width = 2000, height = 2000, res = 300)
  }
  
  wordcloud(names(word_freq), word_freq,
            scale = c(5, 1),
            max.words = 300,
            random.order = FALSE,
            rot.per = 0.3,
            use.r.layout = FALSE,
            fixed.asp = TRUE,
            colors = brewer.pal(8, "Dark2"))
  
  if (!is.null(save_path)) {
    dev.off()
  }
}

get_word_table <- function(d, save_path = paste0("word_count_sentiment_", sentiment, ".png")) {
  # Clean text: expand contractions, lowercase, remove punctuation, trim spaces
  clean_text <- d %>%
    select(Text_nolink) %>%
    filter(!is.na(Text_nolink)) %>%
    pull(Text_nolink) %>%
    replace_contraction() %>%
    tolower() %>%
    str_remove_all("[[:punct:]]") %>%
    str_squish()
  
  clean_text <- str_split(clean_text, "\\s+") %>%
    lapply(function(words) setdiff(words, all_stopwords)) %>%
    sapply(paste, collapse = " ")
  
  # Create corpus from cleaned text
  mooncloud <- VCorpus(VectorSource(clean_text)) %>%
    tm_map(stripWhitespace) %>%
    tm_map(PlainTextDocument)
  
  # Build term-document matrix and compute word frequencies
  tdm <- TermDocumentMatrix(mooncloud)
  tdm_matrix <- as.matrix(tdm)
  word_freq <- sort(rowSums(tdm_matrix), decreasing = TRUE)
  word_tab <- tibble(Freq = word_freq, Word = names(word_freq))
  
  # Generate table
  save_table_as_png(word_tab[1:20,], "Top 20 Word Counts from Posts", save_path )
  
}
  
####################################### Wordclouds by Sentiment Group ########################################
sentiment_groups <- unique(all_posts_with_sentiment$Sentiment_fluoride)

for (sentiment in sentiment_groups) {
  sentiment_data <- all_posts_with_sentiment %>% 
    filter(Sentiment_fluoride == sentiment)
  
  get_word_table(sentiment_data, save_path = paste0("word_count_table_sentiment_", sentiment, ".png"))
  
  #word_cloud_fun(sentiment_data, save_path = paste0("wordcloud_sentiment_", sentiment, ".png"))
}


####################################### Wordclouds by Topic ########################################
topic_groups <- all_posts_with_sentiment %>%
  separate_rows(Topic, sep = ",") %>%
  filter(!is.na(Topic)) %>%
  distinct(Topic) %>%
  pull(Topic)

for (topic in topic_groups) {
  topic_data <- all_posts_with_sentiment %>%
    separate_rows(Topic, sep = ",") %>%
    filter(Topic == topic)
  
  get_word_table(topic_data, save_path = paste0("word_count_table_topic_", topic, ".png"))
  
  #word_cloud_fun(topic_data, save_path = paste0("wordcloud_topic_", gsub(" ", "_", topic), ".png"))
}


