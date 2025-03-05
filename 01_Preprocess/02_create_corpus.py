import pandas as pd
import collections

"""
02_create_corpus.py

This script generates four word frequency tables from the 'Text_Lemm' column:
1. 'all_corpus.csv' - From both CSVs combined.
2. 'fluoride_corpus.csv' - From fluoride_tweets.csv only.
3. 'user_corpus.csv' - From user_tweets.csv only.
4. 'common_corpus.csv' - From common_users_tweets.csv.
Each table is sorted by word frequency in descending order and now includes:
- The count of tweets containing each word.
- The total number of tweets in the dataset.
"""

# Define file paths
data_folder = "D:/pythonProject/Data/"
fluoride_file = data_folder + "fluoride_tweets.csv"
user_file = data_folder + "user_tweets.csv"
common_users_file = data_folder + "common_users_tweets.csv"

# Define output files
all_corpus_file = data_folder + "all_corpus.csv"
fluoride_corpus_file = data_folder + "fluoride_corpus.csv"
user_corpus_file = data_folder + "user_corpus.csv"
common_corpus_file = data_folder + "common_corpus.csv"

# Load data
fluoride_df = pd.read_csv(fluoride_file, usecols=["Text_Lemm"])
user_df = pd.read_csv(user_file, usecols=["Text_Lemm"])
common_users_df = pd.read_csv(common_users_file, usecols=["Text_Lemm"])

# Function to generate a word frequency table
def generate_word_frequency(text_series, output_file):
    word_counts = collections.Counter()
    tweet_counts = collections.defaultdict(int)  # Tracks the number of tweets containing each word
    total_tweets = len(text_series.dropna())  # Total number of tweets in the dataset
    total_words = 0

    for text in text_series.dropna():
        words = text.split()  # Tokenize by whitespace
        unique_words = set(words)  # Count each word only once per tweet
        word_counts.update(words)
        total_words += len(words)

        for word in unique_words:
            tweet_counts[word] += 1  # Increment count of tweets containing the word

    # Convert to DataFrame
    word_freq_df = pd.DataFrame(word_counts.items(), columns=["word", "count"])
    word_freq_df["tweet_count"] = word_freq_df["word"].map(tweet_counts)# Number of tweets containing the word
    word_freq_df["tweet_frequency"] = word_freq_df["word"].map(tweet_counts) / total_tweets  # Number of tweets containing the word
    word_freq_df["frequency"] = word_freq_df["count"] / total_words  # Word occurrence frequency
    word_freq_df["total"] = total_words  # Total number of words
    word_freq_df["total_tweets"] = total_tweets  # Total number of tweets

    # Order by highest frequency
    word_freq_df = word_freq_df.sort_values(by="count", ascending=False)

    # Save to CSV
    word_freq_df.to_csv(output_file, index=False, encoding="utf-8")
    print(f"Word frequency table saved to {output_file}")

# Generate word frequency tables
generate_word_frequency(pd.concat([fluoride_df["Text_Lemm"], user_df["Text_Lemm"]]), all_corpus_file)
generate_word_frequency(fluoride_df["Text_Lemm"], fluoride_corpus_file)
generate_word_frequency(user_df["Text_Lemm"], user_corpus_file)
generate_word_frequency(common_users_df["Text_Lemm"], common_corpus_file)

print("All corpus files generated successfully.")
