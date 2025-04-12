

# Read data: fluoride-related posts and general posts, then combine
fluoride_posts <- read.csv("D:/pythonProject/Data/Processed_Tweets/fluoride_tweets_processed.csv", stringsAsFactors = FALSE)
general_posts <- read.csv("D:/pythonProject/Data/Processed_Tweets/user_tweets_processed.csv", stringsAsFactors = FALSE)
combined_posts <- bind_rows(general_posts, fluoride_posts)

library(dplyr)
library(tm)
library(wordcloud)
library(stringr)
library(stopwords)
library(textclean)
library(RColorBrewer)

# Download Google 10k common words
url <- "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english.txt"
local_path <- "google-10000-english.txt"
download.file(url, local_path, method = "auto")
google_words <- readLines(local_path)
all_stopwords <- c(google_words[1:1000], stopwords(source = "snowball"), "fluoride", "water", "fluoridated", "fluorid", "fluoridation")


word_cloud_fun <- function(d){
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
  
  # Generate wordcloud and save as PNG
  if (!is.null(save_path)) {
    png(filename = save_path, width = 2000, height = 2000, res = 300)
  }
  
  wordcloud(names(word_freq), word_freq,
            scale = c(5, 1),
            max.words = 300,
            min.freq = 50, 
            random.order = FALSE,
            rot.per = 0.3,
            use.r.layout = FALSE,
            fixed.asp = TRUE,
            colors = brewer.pal(8, "Dark2"))
  dev.off()
  
  # If save_path is provided, close the PNG device
  if (!is.null(save_path)) {
    dev.off()
  }
}



