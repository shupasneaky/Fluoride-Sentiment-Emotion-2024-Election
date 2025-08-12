# Load required libraries
library(lessR)
library(dplyr)
library(tm)
library(tidyr)
library(tidytext)
library(wordcloud)
library(stringr)


# Read the CSV file
fluoride_posts <- read.csv("D:/pythonProject/Data/Processed_Tweets/fluoride_tweets_processed.csv", stringsAsFactors = FALSE)
general_posts <- read.csv("D:/pythonProject/Data/Processed_Tweets/user_tweets_processed.csv", stringsAsFactors = FALSE)


fix_emos <- function(x){
  x <- x %>%
    tidyr::separate_rows(Emotion, sep = ',') %>%
    dplyr::mutate(Emotion = stringr::str_trim(Emotion)) %>% 
    dplyr::mutate(Emotion = case_when(
      #Basic Emotions Low/Med/High
      #Anger 
      Emotion %in% c("Annoyance", "Offense") ~ "Anger", #  "Annoyance",
      Emotion %in% c("Anger", "Frustration") ~ "Anger",
      Emotion %in% c("Rage", "Fury") ~ "Anger", #"Rage",
      
      #Anticipation
      Emotion %in% c("Interest") ~ "Anticipation",#"Interest",
      Emotion %in% c("Anticipation") ~ "Anticipation",
      Emotion %in% c("Vigilance") ~ "Anticipation",#"Vigilance",
      
      #Joy
      Emotion %in% c("Serenity", "Happiness") ~ "Joy", #"Serenity",
      Emotion %in% c("Joy", "Enthusiasm", "Satisfaction") ~ "Joy",
      Emotion %in% c("Ecstasy", "Excitement") ~ "Joy",# "Ecstasy",
      
      #Trust
      Emotion %in% c("Acceptance", "Understanding", "Calmness", "Contentment", "Patience") ~ "Trust",# "Acceptance",
      Emotion %in% c("Trust", "Agreement", "Belief", "Certainty", "Loyalty") ~ "Trust",
      Emotion %in% c("Admiration", "Reverence", "Gratitude", "Respect", "Responsibility") ~ "Trust", #"Admiration",
      
      #Fear
      Emotion %in% c("Apprehension", "Caution", "Distress", "Uncertainty") ~ "Fear",# "Apprehension",
      Emotion %in% c("Fear", "Shock", "Worry") ~ "Fear",
      Emotion %in% c("Terror", "Dread", "Horror") ~ "Fear",# "Terror",
      
      #Surprise
      Emotion %in% c("Distraction") ~ "Surprise", #"Distraction",
      Emotion %in% c("Surprise") ~ "Surprise",
      Emotion %in% c("Amazement", "Awe") ~ "Surprise", # "Amazement",
      
      #Sadness
      Emotion %in% c("Pensiveness", "Discomfort", "Pain", "Nervousness") ~ "Sadness", #"Pensiveness",
      Emotion %in% c("Sadness", "Bitterness") ~ "Sadness",
      Emotion %in% c("Grief") ~ "Sadness",# "Grief",
      
      #Disgust
      Emotion %in% c("Boredom", "Discontent", "Doubt") ~ "Disgust", #"Boredom",
      Emotion %in% c("Disgust", "Distrust", "Mistrust") ~ "Disgust",
      Emotion %in% c("Loathing", "Blame") ~ "Disgust",# "Loathing",
      
      #Primary Dyads
      Emotion %in% c("Love", "Appreciation", "Fondness", "Care", "Compassion", "Encouragement", "Support", "Affection") ~ "Love",
      Emotion %in% c("Submission", "Resignation", "Vulnerability") ~ "Submission",
      Emotion %in% c("Alarm", "Awareness", "Concern", "Urgency") ~ "Alarm",
      Emotion %in% c("Disappointment") ~ "Disappointment",
      Emotion %in% c("Remorse", "Disdain", "Regret", "Dispassion", "Rejection", "Reluctance", "Self-Deprecation") ~ "Remorse",
      Emotion %in% c("Contempt", "Dismissal", "Apathy", "Numbness", "Detest", "Defiance", "Vindication", "Defensiveness", "Disagreement", "Disapproval", "Resentment") ~ "Contempt",
      Emotion %in% c("Aggression", "Greed", "Persistence", "Seriousness") ~ "Aggression",
      Emotion %in% c("Optimism", "Inspiration", "Patriotism", "Playfulness") ~ "Optimism",
      
      #Secondary Dyads
      Emotion %in% c("Guilt", "Apology") ~ "Guilt",
      Emotion %in% c("Curiosity") ~ "Curiosity",
      Emotion %in% c("Despair", "Embarrassment", "Overwhelm") ~ "Despair",
      Emotion %in% c("Unbelief", "Disbelief", "Suspicion", "Contemplation", "Skepticism", "Challenge") ~ "Unbelief",
      Emotion %in% c("Envy", "Desire") ~ "Envy",
      Emotion %in% c("Cynicism", "Disinterest", "Mischief") ~ "Cynicism",
      Emotion %in% c("Pride") ~ "Pride",
      Emotion %in% c("Hope", "Determination", "Relief", "Liberation", "Resilience", "Reverence") ~ "Hope",
      
      #Tertiary Dyads
      Emotion %in% c("Delight", "Amusement", "Humor") ~ "Delight",
      Emotion %in% c("Sentimentality", "Pity", "Nostalgia", "Sympathy", "Empathy") ~ "Sentimentality",
      Emotion %in% c("Shame") ~ "Shame",
      Emotion %in% c("Outrage", "Clarification") ~ "Outrage",
      Emotion %in% c("Pessimism") ~ "Pessimism",
      Emotion %in% c("Morbidness", "Sarcasm") ~ "Morbidness",
      Emotion %in% c("Dominance", "Confidence", "Conviction", "Protectiveness", "Motivation", "Courage", "Empowerment", "Control") ~ "Dominance",
      Emotion %in% c("Anxiety", "Desperation") ~ "Anxiety",
      
      #Opposite Dyads
      Emotion %in% c("Bittersweet") ~ "Bittersweet",
      Emotion %in% c("Ambivalence", "Criticism", "Disillusionment") ~ "Ambivalence",
      Emotion %in% c("Frozenness") ~ "Frozenness",
      Emotion %in% c("Confusion") ~ "Confusion",
      
      #Catch_all
      Emotion %in% c("", "None", "Wisdom", "Reminder", "Expectation", "Reflection", "Reassurance", "Rationality", "Pragmatism", "Neutrality", "Observation", "Unclear", "Neutral", "Indifference", "Independence", "Informative", "Instruction") ~ "N/A",
      TRUE ~ Emotion
    )) %>%
    distinct() %>%
    group_by(Created.At, Tweet.ID, Author.ID, Text, Text_nolink, Topic, Sentiment) %>%
    summarise(Emotion = list(unique(Emotion)), .groups = "drop") %>%
    rowwise() %>%
    mutate(Emotion = list({
      emos <- Emotion
      
      # Primary Dyads
      if(all(c("Joy", "Trust") %in% emos)) emos <- c(emos, "Love")
      if(all(c("Trust", "Fear") %in% emos)) emos <- c(emos, "Submission")
      if(all(c("Fear", "Surprise") %in% emos)) emos <- c(emos, "Alarm")
      if(all(c("Surprise", "Sadness") %in% emos)) emos <- c(emos, "Disappointment")
      if(all(c("Sadness", "Disgust") %in% emos)) emos <- c(emos, "Remorse")
      if(all(c("Disgust", "Anger") %in% emos)) emos <- c(emos, "Contempt")
      if(all(c("Anger", "Anticipation") %in% emos)) emos <- c(emos, "Aggression")
      if(all(c("Anticipation", "Joy") %in% emos)) emos <- c(emos, "Optimism")
      
      # Secondary Dyads
      if(all(c("Joy", "Fear") %in% emos)) emos <- c(emos, "Guilt")
      if(all(c("Trust", "Surprise") %in% emos)) emos <- c(emos, "Curiosity")
      if(all(c("Fear", "Sadness") %in% emos)) emos <- c(emos, "Despair")
      if(all(c("Surprise", "Disgust") %in% emos)) emos <- c(emos, "Unbelief")
      if(all(c("Sadness", "Anger") %in% emos)) emos <- c(emos, "Envy")
      if(all(c("Disgust", "Anticipation") %in% emos)) emos <- c(emos, "Cynicism")
      if(all(c("Anger", "Joy") %in% emos)) emos <- c(emos, "Pride")
      if(all(c("Anticipation", "Trust") %in% emos)) emos <- c(emos, "Hope")
      
      # Tertiary Dyads
      if(all(c("Joy", "Surprise") %in% emos)) emos <- c(emos, "Delight")
      if(all(c("Trust", "Sadness") %in% emos)) emos <- c(emos, "Sentimentality")
      if(all(c("Fear", "Disgust") %in% emos)) emos <- c(emos, "Shame")
      if(all(c("Surprise", "Anger") %in% emos)) emos <- c(emos, "Outrage")
      if(all(c("Sadness", "Anticipation") %in% emos)) emos <- c(emos, "Pessimism")
      if(all(c("Disgust", "Joy") %in% emos)) emos <- c(emos, "Morbidness")
      if(all(c("Anger", "Trust") %in% emos)) emos <- c(emos, "Dominance")
      if(all(c("Anticipation", "Fear") %in% emos)) emos <- c(emos, "Anxiety")
      
      # Opposite Dyads
      if(all(c("Joy", "Sadness") %in% emos)) emos <- c(emos, "Bittersweet")
      if(all(c("Trust", "Disgust") %in% emos)) emos <- c(emos, "Ambivalence")
      if(all(c("Fear", "Anger") %in% emos)) emos <- c(emos, "Frozenness")
      if(all(c("Surprise", "Anticipation") %in% emos)) emos <- c(emos, "Confusion")
      
      unique(emos)
    })) %>%
    unnest(Emotion) %>%
    distinct() %>%
    group_by(Created.At, Tweet.ID, Author.ID, Text, Text_nolink, Topic, Sentiment) %>%
    summarise(Emotion = paste(unique(Emotion), collapse = ","), .groups = "drop")
  return(x)
}

fluoride_posts <- fix_emos(fluoride_posts)
general_posts <- fix_emos(general_posts)

fix_topics <- function(x){
    x <- x %>%
      tidyr::separate_rows(Topic, sep = ',') %>%
      dplyr::mutate(Topic = stringr::str_trim(Topic)) %>% 
      dplyr::mutate(Topic = case_when(
        # Allowed Topics:"Dental", "Cancer", "Thyroid", "Neurological Effects", "Fluoride",
        # "Vaccines", "Autism", "IQ", "Pineal", "Endocrine" "Mass medication",  "Conspiracy", "Political",
        # "Science", "Technology", "Health", "Societal Issues", "Economic", "Education", "Arts", "Sports". 
        Topic %in% c("Dental") ~ "Dental",
        Topic %in% c("Cancer") ~ "Cancer",
        Topic %in% c("Thyroid") ~ "Thyroid",
        Topic %in% c("Neurological Effects") ~ "Neurological Effects",
        Topic %in% c("Fluoride") ~ "Fluoride",
        Topic %in% c("Vaccines") ~ "Vaccines",
        Topic %in% c("Autism") ~ "Autism",
        Topic %in% c("IQ") ~ "IQ",
        Topic %in% c("Pineal") ~ "Pineal",
        Topic %in% c("Endocrine") ~ "Endocrine",
        Topic %in% c("Mass medication") ~ "Mass medication",
        Topic %in% c("Conspiracy") ~ "Conspiracy",
        Topic %in% c("Political") ~ "Political",
        Topic %in% c("Science") ~ "Science",
        Topic %in% c("Technology") ~ "Technology",
        Topic %in% c("Health") ~ "Health",
        Topic %in% c("Societal Issues") ~ "Societal Issues",
        Topic %in% c("Economic") ~ "Economic",
        Topic %in% c("Education") ~ "Education",
        Topic %in% c("Arts", "Spiritual") ~ "Arts",
        Topic %in% c("Sports") ~ "Sports",
        TRUE ~ 'Other Topics'
      )) %>%
      distinct() %>%
      group_by(Created.At, Tweet.ID, Author.ID, Text, Text_nolink, Emotion, Sentiment) %>%
      summarise(Topic = paste(Topic, collapse = ","))
    return(x)
  }

fluoride_posts <- fix_topics(fluoride_posts)
general_posts <- fix_topics(general_posts)

fix_sent <- function(x){
  x <- x %>%
    dplyr::mutate(Sentiment = case_when(
      Sentiment %in% c("Positive", "Relief", "Optimism", "Optimistic", "Nostalgic", "Nostalgia", "Anticipation") ~ "Positive",
      Sentiment %in% c("Neutral", "Curiosity", "Ambivalence", "Surprise", "Mixed") ~ "Neutral",
      Sentiment %in% c("Negative", "Suspicious", "Regret", "Frustration", "Disbelief", "Skeptical", "Confusion", "Sarcastic", "Sarcastic/Negative", "Apprehension", "Concern", "Cynicism", "Sarcasm", "Annoyance", "Sadness") ~ "Negative",
      TRUE ~ Sentiment
    )) 
  return(x)
}

fluoride_posts <- fix_sent(fluoride_posts)
general_posts <- fix_sent(general_posts)

sort_sent <- function(x) as.data.frame(table(trimws(unlist(str_split(x$Sentiment,','))))) %>% arrange(desc(Freq))
sort_top <- function(x) as.data.frame(table(trimws(unlist(str_split(x$Topic,','))))) %>% arrange(desc(Freq))
sort_emo <- function(x) as.data.frame(table(trimws(unlist(str_split(x$Emotion,','))))) %>% arrange(desc(Freq))

sort_sent(fluoride_posts)
sort_sent(general_posts)
sort_emo(fluoride_posts)
sort_emo(general_posts)
sort_top(fluoride_posts)
sort_top(general_posts)

write.csv(general_posts, file = "general_posts.csv")
write.csv(fluoride_posts, file = "fluoride_posts.csv")


# Data has been fixed. 

