import pandas as pd

"""
02_time_splitting.py

This script adds a 'Time_Label' column to 'common_users_tweets.csv' 
and 'fluoride_tweets.csv', marking tweets as 'before' or 'after' 
the election date (November 6, 12:00 PM UTC).
"""

# Define file paths
data_folder = "D:/pythonProject/Data/"
fluoride_file = data_folder + "fluoride_tweets.csv"
common_users_file = data_folder + "common_users_tweets.csv"

# Election date threshold (Ensure it is timezone-aware in UTC)
election_date = pd.Timestamp("2024-11-06 12:00:00", tz="UTC")

# Function to label tweets as "before" or "after"
def label_time(df):
    df["Created At"] = pd.to_datetime(df["Created At"], errors="coerce", utc=True)  # Keep timezone

    # Apply labeling
    df["Time_Label"] = df["Created At"].apply(
        lambda x: "before" if pd.notna(x) and x < election_date else "after"
    )
    return df

# Process datasets
for file in [fluoride_file, common_users_file]:
    df = pd.read_csv(file)
    if "Created At" in df.columns:
        df = label_time(df)
        df.to_csv(file, index=False, encoding="utf-8")
        print(f"Updated {file} with 'Time_Label' column.")

print("Time-based labeling completed.")
