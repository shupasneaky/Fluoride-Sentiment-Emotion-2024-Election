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
      Emotion %in% c("Annoyance", "Offense") ~ "Annoyance",
      Emotion %in% c("Anger", "Frustration") ~ "Anger",
      Emotion %in% c("Rage", "Fury") ~ "Rage",
      
      #Anticipation
      Emotion %in% c("Interest") ~ "Interest",
      Emotion %in% c("Anticipation") ~ "Anticipation",
      Emotion %in% c("Vigilance") ~ "Vigilance",
      
      #Joy
      Emotion %in% c("Serenity", "Happiness") ~ "Serenity",
      Emotion %in% c("Joy", "Enthusiasm", "Satisfaction") ~ "Joy",
      Emotion %in% c("Ecstasy", "Excitement") ~ "Ecstasy",
      
      #Trust
      Emotion %in% c("Acceptance", "Understanding", "Calmness", "Contentment") ~ "Acceptance",
      Emotion %in% c("Trust", "Agreement", "Belief", "Certainty") ~ "Trust",
      Emotion %in% c("Admiration", "Reverence", "Gratitude", "Respect", "Responsibility") ~ "Admiration",
      
      #Fear
      Emotion %in% c("Apprehension", "Caution", "Distress", "Uncertainty") ~ "Apprehension",
      Emotion %in% c("Fear", "Shock", "Worry") ~ "Fear",
      Emotion %in% c("Terror", "Dread", "Horror") ~ "Terror",
      
      #Surprise
      Emotion %in% c("Distraction") ~ "Distraction",
      Emotion %in% c("Surprise") ~ "Surprise",
      Emotion %in% c("Amazement", "Awe") ~ "Amazement",
      
      #Sadness
      Emotion %in% c("Pensiveness", "Discomfort", "Pain", "Nervousness") ~ "Pensiveness",
      Emotion %in% c("Sadness", "Bitterness") ~ "Sadness",
      Emotion %in% c("Grief") ~ "Grief",
      
      #Disgust
      Emotion %in% c("Boredom", "Discontent", "Doubt") ~ "Boredom",
      Emotion %in% c("Disgust", "Distrust", "Mistrust") ~ "Disgust",
      Emotion %in% c("Loathing", "Blame") ~ "Loathing",
      
      #Primary Dyads
      Emotion %in% c("Love", "Appreciation", "Fondness", "Care", "Compassion", "Encouragement", "Support", "Affection") ~ "Love",
      Emotion %in% c("Submission", "Resignation") ~ "Submission",
      Emotion %in% c("Alarm", "Awareness", "Concern", "Urgency") ~ "Alarm",
      Emotion %in% c("Disappointment") ~ "Disappointment",
      Emotion %in% c("Remorse", "Disdain", "Regret", "Dispassion", "Rejection", "Reluctance", "Self-Deprecation") ~ "Remorse",
      Emotion %in% c("Contempt", "Apathy", "Detest", "Defiance", "Vindication", "Defensiveness", "Disagreement", "Disapproval", "Resentment") ~ "Contempt",
      Emotion %in% c("Aggression", "Greed", "Persistence", "Seriousness") ~ "Aggression",
      Emotion %in% c("Optimism", "Inspiration", "Patriotism", "Playfulness") ~ "Optimism",
      
      #Secondary Dyads
      Emotion %in% c("Guilt", "Apology") ~ "Guilt",
      Emotion %in% c("Curiosity") ~ "Curiosity",
      Emotion %in% c("Despair", "Embarrassment", "Overwhelm") ~ "Despair",
      Emotion %in% c("Unbelief", "Disbelief", "Suspicion", "Skepticism", "Challenge") ~ "Unbelief",
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
      Emotion %in% c("", "None", "Wisdom", "Patience", "Loyalty", "Reminder", "Expectation", "Dismissal", "Reflection", "Reassurance", "Rationality", "Pragmatism", "Neutrality", "Numbness", "Observation", "Unclear", "Neutral", "Indifference", "Contemplation", "Independence", "Informative", "Instruction") ~ "N/A",
      TRUE ~ Emotion
    )) %>%
    distinct() %>%
    group_by(Created.At, Tweet.ID, Author.ID, Text, Text_nolink, Topic, Sentiment) %>%
    summarise(Emotion = paste(Emotion, collapse = ","))
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



# Statistics Time:
# Load Data
general_posts <- read.csv("general_posts.csv", header = TRUE)[,-1] %>% mutate(Source = "General")
fluoride_posts <- read.csv("fluoride_posts.csv", header = TRUE)[,-1] %>% mutate(Source = "Fluoride")

#Get common authors and create indicator column. 
common_authors <- intersect(general_posts$Author.ID, fluoride_posts$Author.ID)

combined_posts <- bind_rows(general_posts, fluoride_posts) %>%
  filter(Author.ID %in% common_authors)

### 1. Emotion Analysis - under the assumption that there is no 
###                       difference between emotions across
###                       the posts of the same users.

# Convert the dataset to long format
long_emotion_df <- combined_posts %>%
  separate_longer_delim(Emotion, delim = ",") %>%
  mutate(Emotion = trimws(Emotion)) %>%
  filter(Emotion != "N/A")

# Create the emotion contingency table
emotion_table <- table(long_emotion_df$Emotion, long_emotion_df$Source)

#Values to fill in tables on python
pytab_values <- round(t(emotion_table) / c(sum(combined_posts$Source == "Fluoride"), sum(combined_posts$Source == "General")), 2)


# Perform Chi-square test across all emotions
overall_emotion_test <- chisq.test(emotion_table)

# Perform tests for each emotion individually
emotion_levels <- rownames(emotion_table)

emotion_pvals <- sapply(emotion_levels, function(emotion) {
  emotion_binary_table <- matrix(c(
    sum(long_emotion_df$Emotion == emotion & long_emotion_df$Source == "General"),
    sum(long_emotion_df$Emotion != emotion & long_emotion_df$Source == "General"),
    sum(long_emotion_df$Emotion == emotion & long_emotion_df$Source == "Fluoride"),
    sum(long_emotion_df$Emotion != emotion & long_emotion_df$Source == "Fluoride")
  ), nrow = 2, byrow = TRUE)
  
  chisq.test(emotion_binary_table)$p.value
})

# Bonferroni correction for multiple tests
emotion_pvals_bonf <- p.adjust(emotion_pvals, method = "bonferroni")

# Results summary
emotion_results <- data.frame(
  Emotion = emotion_levels,
  P_Value_Bonferroni = round(emotion_pvals_bonf, 5),
  Significant = emotion_pvals_bonf < 0.05, row.names = NULL
)

emotion_results %>% filter(Significant == "TRUE")

### 2. Sentiment Analysis

# Combine data with labels
fluoride_sentiment <- fluoride_subset %>% mutate(Source = "Fluoride")
general_sentiment <- general_subset %>% mutate(Source = "General")

combined_sentiment <- bind_rows(fluoride_sentiment, general_sentiment)

# Create sentiment contingency table
sentiment_table <- table(combined_sentiment$Sentiment, combined_sentiment$Source)

# Perform Chi-square test across all sentiments
overall_sentiment_test <- chisq.test(sentiment_table)

# Perform tests for each sentiment individually
sentiment_levels <- rownames(sentiment_table)
sentiment_pvals <- sapply(sentiment_levels, function(sentiment) {
  sentiment_binary_table <- matrix(c(
    sum(fluoride_sentiment$Sentiment == sentiment),
    sum(fluoride_sentiment$Sentiment != sentiment),
    sum(general_sentiment$Sentiment == sentiment),
    sum(general_sentiment$Sentiment != sentiment)
  ), nrow = 2, byrow = TRUE)
  
  chisq.test(sentiment_binary_table)$p.value
})

# Bonferroni correction for sentiment tests
sentiment_pvals_bonf <- p.adjust(sentiment_pvals, method = "bonferroni")

# Results for sentiment
sentiment_results <- data.frame(
  Sentiment = sentiment_levels,
  P_Value = sentiment_pvals,
  P_Value_Bonferroni = sentiment_pvals_bonf,
  Significant = sentiment_pvals_bonf < 0.05
)

### Display Results
overall_emotion_test
emotion_results

overall_sentiment_test
sentiment_results
