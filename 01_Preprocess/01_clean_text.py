import pandas as pd
import re
import emoji
import contractions
import spacy

"""
01_clean_text.py

This script cleans tweet text by:
1. Expanding contractions (e.g., "don't" → "do not")
2. Expanding abbreviations (e.g., "wym" → "what do you mean")
3. Removing unnecessary punctuation
4. Removing URLs and mentions → 'Text_nolink'
Processed columns are appended to the original CSV files.
"""

# Load spaCy model
nlp = spacy.load("en_core_web_sm")

# Load abbreviation dictionary from CSV
data_folder = "D:/pythonProject/Data/"
abbreviation_file = data_folder + "abbreviations.csv"
abbreviation_df = pd.read_csv(abbreviation_file)
abbreviation_dict = dict(zip(abbreviation_df['Abbreviation'].str.lower(), abbreviation_df['Meaning'].str.lower()))


# Function to expand contractions
def expand_contractions(text):
    return contractions.fix(text)


# Function to replace abbreviations
def expand_abbreviations(text):
    words = text.split()
    expanded_words = [abbreviation_dict[word.lower()] if word.lower() in abbreviation_dict else word for word in words]
    return " ".join(expanded_words)


# Function to remove pointless punctuation
def remove_punctuation(text):
    return re.sub(r"[^\w\s']", "", text)  # Keep words, spaces, and apostrophes (for contractions)


# Function to remove URLs and mentions
def remove_urls_mentions(text):
    text = re.sub(r"http\S+|www\S+", "", text)  # Remove URLs
    text = re.sub(r"@\w+", "", text)  # Remove mentions
    return text.strip()


# Define file paths
fluoride_file = data_folder + "fluoride_tweets.csv"
user_file = data_folder + "user_tweets.csv"
common_users_file = data_folder + "common_users_tweets.csv"


# Function to process the dataset
def process_file(file_path):
    df = pd.read_csv(file_path)

    if "Text" not in df.columns:
        print(f"Skipping {file_path} - 'Text' column missing.")
        return

    df["Text_nolink"] = df["Text"].astype(str).apply(remove_urls_mentions)

    df.to_csv(file_path, index=False, encoding="utf-8")
    print(f"Processed and saved: {file_path}")


# Process all files
process_file(fluoride_file)
process_file(user_file)
process_file(common_users_file)

print("Text cleaning completed.")
