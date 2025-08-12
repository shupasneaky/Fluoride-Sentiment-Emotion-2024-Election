import pandas as pd

"""
03_find_common_users.py

This script identifies common users from 'fluoride_tweets.csv' and 'user_tweets.csv' 
and creates a new dataset 'common_users_tweets.csv' containing their tweets.
"""

# Define file paths
data_folder = "path/to/data"
fluoride_file = data_folder + "fluoride.csv"
user_file = data_folder + "user.csv"
common_users_file = data_folder + "common.csv"

# Load data
fluoride_df = pd.read_csv(fluoride_file, usecols=["Author ID", "Created At", "Tweet ID", "Text"])
user_df = pd.read_csv(user_file, usecols=["Author ID", "Created At", "Tweet ID", "Text"])

# Identify common users
common_users = set(fluoride_df["Author ID"]).intersection(set(user_df["Author ID"]))

# Filter tweets from common users
common_fluoride_tweets = fluoride_df[fluoride_df["Author ID"].isin(common_users)]
common_user_tweets = user_df[user_df["Author ID"].isin(common_users)]

# Combine tweets from common users into a single dataset
common_users_tweets = pd.concat([common_fluoride_tweets, common_user_tweets], ignore_index=True)

# Save to CSV
common_users_tweets.to_csv(common_users_file, index=False, encoding="utf-8")

print(f"Common users' tweets saved to {common_users_file}")
