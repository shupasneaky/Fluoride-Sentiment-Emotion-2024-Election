#===================================================================================================
# Libraries
#===================================================================================================
library(dplyr)
library(tidyverse)
library(stats)
library(readr)

#===================================================================================================
# Functions
#===================================================================================================
# count the occurrences of each topic and arrange in descending order
get_topics <- function(x,n){
  x <- x %>% group_by(`Tweet ID`) %>%
    summarise(
      Topic = first(Topic),
      Emotion = paste(Emotion, collapse = ", ")
      ) %>% 
    ungroup() %>%
    count(Topic, sort = TRUE) 
  print(x, n=n)
}
get_sentiment <- function(x,n){
  x <- x %>% group_by(`Tweet ID`) %>%
    summarise(
      Sentiment = first(Sentiment),
      Emotion = paste(Emotion, collapse = ", ")
    ) %>% 
    ungroup() %>%
    count(Sentiment, sort = TRUE) 
  print(x, n=n)
}
get_emotions <- function(x,n){
  x <- x %>% count(Emotion, sort = TRUE)
  print(x, n=n)
}
# cleans brackets and other
clean_it <- function(x){
  x <- x %>%
    mutate(Sentiment = gsub("\\[|\\]", "", Sentiment)) %>%
    mutate(Emotion = gsub("\\[|\\]", "", Emotion)) %>%
    separate_rows(Emotion, sep = ",\\s*") %>%  # splits on comma and optional spaces
    mutate(Emotion = trimws(Emotion)) %>%
    mutate(Sentiment = case_when(
      Sentiment == "Sarcastic/Negative" ~ "Negative",
      Sentiment == "Mixed" ~ "Neutral",
      TRUE ~ Sentiment
    ))
  return(x)
}
#===================================================================================================
# Manual Scripts
#===================================================================================================

fluoride <- read_csv("fluoride_tweets_processed.csv") 
user <- read_csv("user_tweets_processed.csv")

fluoride <- fluoride %>% select(-Time_Label) %>% clean_it()
user <- user %>% clean_it()
all <- rbind(fluoride, user)

user %>% get_topics(.,n=400)
fluoride %>% get_emotions(.,n=50)
fluoride %>% get_sentiment(.,n=50) %>% mutate(n = n/sum(n))



