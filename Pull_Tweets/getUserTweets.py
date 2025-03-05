import os
import pandas as pd
import tweepy
import datetime
import time
from getKeys import getKeys  # Import the function to retrieve API keys

def pull_tweets_for_author_subset(client, author_ids, save_location, start_time, end_time, time_window_minutes=60, no_of_tweets=10, query="", index=0):
    total_tweets_pulled = 0
    author_ids_copy = author_ids[:]  # Use a copy so we can modify it without affecting the original list

    while total_tweets_pulled < no_of_tweets and author_ids_copy:
        # Ensure end_time does not exceed the specified window (6 days 23 hours ago to 1 hour ago)
        if start_time >= end_time:
            break

        # Format timestamps to ISO 8601 strings with UTC 'Z' suffix
        start_date = start_time.strftime("%Y-%m-%dT%H:%M:%SZ")
        current_end_time = min(end_time, start_time + datetime.timedelta(minutes=time_window_minutes))
        end_date = current_end_time.strftime("%Y-%m-%dT%H:%M:%SZ")

        # Build author-specific query
        author_query = f"({' OR '.join([f'from:{author_id}' for author_id in author_ids_copy])}) lang:en -is:retweet -is:quote -has:links -has:media -has:images -has:video_link"

        try:
            # Fetch tweets for the specific authors
            tweets = client.search_recent_tweets(
                query=author_query,
                start_time=start_date,
                end_time=end_date,
                max_results=no_of_tweets,
                tweet_fields=[
                    "id", "text", "author_id", "created_at", "public_metrics", "source",
                    "lang", "geo", "possibly_sensitive", "referenced_tweets", "reply_settings"
                ],
                user_fields=["id", "name", "username", "created_at", "location", "verified", "description",
                             "public_metrics"]
            )

            # Collect tweet data
            attributes_container = []
            if tweets.data:
                seen_authors = set()  # Track authors from whom tweets have been pulled
                for tweet in tweets.data:
                    tweet_data = {
                        "Tweet ID": tweet.id,
                        "Text": tweet.text,
                        "Author ID": tweet.author_id,
                        "Created At": tweet.created_at,
                        "Source": tweet.source,
                        "Language": tweet.lang,
                        "Possibly Sensitive": tweet.possibly_sensitive,
                        "Referenced Tweets": tweet.referenced_tweets,
                        "Reply Settings": tweet.reply_settings,
                        "Public Metrics": tweet.public_metrics
                    }
                    attributes_container.append(tweet_data)
                    total_tweets_pulled += 1
                    seen_authors.add(tweet.author_id)

                    # Stop if we reach the desired number of tweets
                    if total_tweets_pulled >= no_of_tweets:
                        break

                # Remove authors who had tweets pulled in this iteration
                author_ids_copy = [author_id for author_id in author_ids_copy if author_id not in seen_authors]

            # Save collected tweets to a CSV file
            if attributes_container:
                tweets_df = pd.DataFrame(attributes_container)
                filename = f"{index}_tweets_{start_date.replace(':', '').replace('T', '_')}_to_{end_date.replace(':', '').replace('T', '_')}.csv"
                save_path = os.path.join(save_location, filename)
                tweets_df.to_csv(save_path, index=False)
                print(f"Tweets saved to {save_path}")

        except tweepy.TooManyRequests:
            print("Rate limit exceeded. Waiting for 30 minutes before retrying...")
            time.sleep(1800)  # Wait for 30 minutes before retrying
        except BaseException as e:
            print('Status Failed On,', str(e))

        # Move time window forward
        start_time = current_end_time

def main():
    # Load unique author IDs
    unique_ids_path = r"C:/Users/owvis/OneDrive - University of Florida/Fluoride_Xdata/uniqueIDs_flouride_term_tweets.csv"
    save_location = r"C:/Users/owvis/OneDrive - University of Florida/Fluoride_Xdata/Flouride_users"
    df = pd.read_csv(unique_ids_path)
    unique_author_ids = df['Unique Author ID'].tolist()

    # Import keys
    folder_path = r"C:\Users\owvis\Desktop\ra\Twitter Fluoride\TweetScrape\Keys"
    getKeys(folder_path, globals())
    bearer_token = globals()['bearer_token']
    consumer_key = globals()['APIkey']
    consumer_secret = globals()['APIkey_secret']
    access_token = globals()['access_token']
    access_token_secret = globals()['access_token_secret']

    # Initialize Twitter API client
    client = tweepy.Client(bearer_token=bearer_token, consumer_key=consumer_key, consumer_secret=consumer_secret,
                           access_token=access_token, access_token_secret=access_token_secret, wait_on_rate_limit=True)

    # Set time parameters for the overall window
    end_time = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=1)
    base_start_time = end_time - datetime.timedelta(days=6, hours=20)

    # Ensure start_time is within the API's allowed window (e.g., 7 days ago maximum)
    api_minimum_time = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=6, hours=20)
    if base_start_time < api_minimum_time:
        base_start_time = api_minimum_time

    # Loop through unique author IDs in subsets of 10 with indexing for unique filenames
    batch_size = 10
    index = 1  # Start index for filenames
    for i in range(0, len(unique_author_ids), batch_size):
        subset = unique_author_ids[i:i + batch_size]
        start_time = base_start_time  # Reset start_time to base_start_time for each new batch
        pull_tweets_for_author_subset(client, subset, save_location, start_time, end_time, time_window_minutes=360, index=index)
        index += 1  # Increment index for the next file

if __name__ == "__main__":
    main()
