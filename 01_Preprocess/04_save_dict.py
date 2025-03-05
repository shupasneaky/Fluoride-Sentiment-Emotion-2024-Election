import os
import pandas as pd
from gensim import corpora

"""
save_dictionary.py

This script creates and saves a dictionary from 'common_users_tweets_filtered.csv' 
so that all topic modeling and visualization scripts can reference it.
"""

# Define paths
data_folder = "D:/pythonProject/Data/"
results_folder = "D:/pythonProject/Results/"
os.makedirs(results_folder, exist_ok=True)

input_file = os.path.join(data_folder, "common_users_tweets_filtered.csv")
dictionary_path = os.path.join(results_folder, "dictionary.dict")

# Load data
df = pd.read_csv(input_file)
tokens = df["tokens"].apply(eval).tolist()  # Convert string lists back to lists

# Create and save dictionary
dictionary = corpora.Dictionary(tokens)
dictionary.save(dictionary_path)

print(f"Dictionary saved at: {dictionary_path}")
