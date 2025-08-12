####################################### Packages ########################################
library(dplyr)
library(ggplot2)
library(tidyr)
library(tidytext)
library(wordcloud)
library(RColorBrewer)
library(gt)
library(tm)
library(stringr)
library(webshot2)

####################################### Load Data ########################################
general_posts <- read.csv("general_posts.csv", header = TRUE)[,-1] %>% mutate(Source = "General")
fluoride_posts <- read.csv("fluoride_posts.csv", header = TRUE)[,-1] %>% mutate(Source = "Fluoride")
combined_posts <- bind_rows(general_posts, fluoride_posts) 

str(combined_posts)

####################################### Sentiment summary of tweets ########################################
# Table: Sentiment percents
# 
pull1_tweet_sentiment <- fluoride_posts %>%
  count(Sentiment) %>%
  mutate(Percent = n / sum(n) * 100,
         Group = "Fluoride")

pull2_tweet_sentiment <- general_posts %>%
  count(Sentiment) %>%
  mutate(Percent = n / sum(n) * 100,
         Group = "General")

combined_sentiment <- bind_rows(pull1_tweet_sentiment, pull2_tweet_sentiment)

ggplot(combined_sentiment, aes(x = Sentiment, y = Percent, fill = Group)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  geom_text(aes(label = paste(round(Percent, 0), "%",sep="")), position = position_dodge(width = 0.9), vjust = -0.25) +
  labs(title = "Sentiment Comparison (Percent)", x = "Sentiment", y = "Percent") +
  theme_minimal()


# Table: Sentiment counts
# 
pull1_tweet_sentiment <- fluoride_posts %>%
  count(Sentiment) %>%
  mutate(Group = "Fluoride")

pull2_tweet_sentiment <- general_posts %>%
  count(Sentiment) %>%
  mutate(Group = "General")

combined_sentiment <- bind_rows(pull1_tweet_sentiment, pull2_tweet_sentiment)

ggplot(combined_sentiment, aes(x = Sentiment, y = n, fill = Group)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9), color = "black") +
  geom_text(aes(label = n), position = position_dodge(width = 0.9), vjust = -0.25) +
  labs(title = "Sentiment Comparison by Count", x = "Sentiment", y = "Count") +
  theme_minimal()


####################################### Segment users by fluoride sentiment ########################################
# Get each user's dominant sentiment about fluoride
fus <- fluoride_posts %>%
  mutate(Sentiment = case_when(
    Sentiment == "Positive" ~ 1,
    Sentiment == "Neutral" ~ 0,
    Sentiment == "Negative" ~ -1
  )) %>%
  group_by(Author.ID) %>%
  summarise(sentiment_avg = mean(Sentiment, na.rm = TRUE))


pos_users <- fus$Author.ID[fus$sentiment_avg > 0.5]
neg_users <- fus$Author.ID[fus$sentiment_avg < -0.5]
neu_users <- fus$Author.ID[!(fus$Author.ID %in% c(pos_users, neg_users))]

####################################### Tables of Users by Sentiment ########################################

user_sent_table <- data.frame(
  positive = c(length(pos_users), sum(unique(general_posts$Author.ID) %in% pos_users)),
  neutral = c(length(neu_users), sum(unique(general_posts$Author.ID) %in% neu_users)),
  negative = c(length(neg_users), sum(unique(general_posts$Author.ID) %in% neg_users)),
  row.names = c("1", "2")
)

user_sent_table$total = rowSums(user_sent_table)
user_sent_table <- tibble::rownames_to_column(user_sent_table, var = "Pull")
user_sent_table


post_sent_table <- data.frame(
  positive = c(sum(fluoride_posts$Sentiment=="Positive") , sum(general_posts$Sentiment=="Positive")),
  neutral = c(sum(fluoride_posts$Sentiment=="Neutral") , sum(general_posts$Sentiment=="Neutral")),
  negative = c(sum(fluoride_posts$Sentiment=="Negative") , sum(general_posts$Sentiment=="Negative")),
  row.names = c("1", "2")
)

post_sent_table$total = rowSums(post_sent_table)
post_sent_table <- tibble::rownames_to_column(post_sent_table, var = "Pull")
post_sent_table

pull2_post_by_fsent_table <- data.frame(
  positive = c( sum(general_posts$Sentiment[general_posts$Author.ID %in% pos_users]=="Positive"),
                sum(general_posts$Sentiment[general_posts$Author.ID %in% neu_users]=="Positive"),
                sum(general_posts$Sentiment[general_posts$Author.ID %in% neg_users]=="Positive") ),
  neutral = c( sum(general_posts$Sentiment[general_posts$Author.ID %in% pos_users]=="Neutral"),
               sum(general_posts$Sentiment[general_posts$Author.ID %in% neu_users]=="Neutral"),
               sum(general_posts$Sentiment[general_posts$Author.ID %in% neg_users]=="Neutral") ),
 negative = c( sum(general_posts$Sentiment[general_posts$Author.ID %in% pos_users]=="Negative"),
                sum(general_posts$Sentiment[general_posts$Author.ID %in% neu_users]=="Negative"),
                sum(general_posts$Sentiment[general_posts$Author.ID %in% neg_users]=="Negative") ),
  row.names = c("F_positive", "F_neutral", "F_negative")
)

pull2_post_by_fsent_table$Total_posts_by_F = rowSums(pull2_post_by_fsent_table)

pull2_post_by_fsent_table<-rbind(pull2_post_by_fsent_table, Total_posts = colSums(pull2_post_by_fsent_table)) %>%
  tibble::rownames_to_column(var = "Fluoride_Sentiment")

pull2_post_by_fsent_table

save_table_as_png <- function(df, title, filename) {
  df %>% gt() %>% tab_header(title = title) %>%
    fmt_number( columns = where(is.numeric), decimals = 1 ) %>%
    gtsave(filename)
}

save_table_as_png(user_sent_table, "Distribution of User Sentiment on Fluoride", "user_sent_table.png")
save_table_as_png(post_sent_table, "Distribution of Post Sentiment", "post_sent_table.png")
save_table_as_png(pull2_post_by_fsent_table, "Distribution of Pull 2 Posts Sentiments by Fluoride Sentiment", "pull2_post_by_fsent_table.png")


####################################### Wordclouds function ########################################

# Download Google 10k common words
url <- "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english.txt"
local_path <- "google-10000-english.txt"
download.file(url, local_path, method = "auto")
google_words <- readLines(local_path)
all_stopwords <- c(google_words[1:1000], stopwords(kind = "en"), "fluoride", "water", "fluoridated", "fluorid", "fluoridation")


word_cloud_fun <- function(d, save_path = NULL) {
  # Clean text: lowercase, remove punctuation, trim non-alphabetical
  clean_text <- d %>%
    pull(Text_nolink) %>%
    tolower() %>%
    str_replace_all("[^a-z\\s]", "") %>%
    str_split("\\s+")
  
  # Lemmatize, remove stop words, trim non-alphabetical
  clean_text <- lapply(clean_text, function(x){
    x %>% lemmatize_words() %>%  setdiff(all_stopwords) %>% str_replace_all("[^a-z\\s]", "")
  })
  
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
            max.words = 100,
            random.order = FALSE,
            rot.per = 0.3,
            use.r.layout = FALSE,
            fixed.asp = TRUE,
            colors = brewer.pal(8, "Dark2"))
  
  if (!is.null(save_path)) {
    dev.off()
  }
}

####################################### Wordclouds by Sentiment Group ########################################

#positive
word_cloud_fun(fluoride_posts %>% filter(Author.ID %in% pos_users), save_path = paste0("fluoride_posts_positive.png"))
word_cloud_fun(general_posts %>% filter(Author.ID %in% pos_users), save_path = paste0("general_posts_positive.png"))
#neutral
word_cloud_fun(fluoride_posts %>% filter(Author.ID %in% neu_users), save_path = paste0("fluoride_posts_neutral.png"))
word_cloud_fun(general_posts %>% filter(Author.ID %in% neu_users), save_path = paste0("general_posts_neutral.png"))
#negative
word_cloud_fun(fluoride_posts %>% filter(Author.ID %in% neg_users), save_path = paste0("fluoride_posts_negative.png"))
word_cloud_fun(general_posts %>% filter(Author.ID %in% neg_users), save_path = paste0("general_posts_negative.png"))


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


