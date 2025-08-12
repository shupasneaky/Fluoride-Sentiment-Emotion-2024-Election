import pandas as pd
from getKeys import getKeys
import tweepy
import datetime
import time

# Import keys
folder_path = r"path/to/keys"
getKeys(folder_path, globals())
bearer_token = globals()['bearer_token']
consumer_key = globals()['APIkey']
consumer_secret = globals()['APIkey_secret']
access_token = globals()['access_token']
access_token_secret = globals()['access_token_secret']

client = tweepy.Client(bearer_token=bearer_token, consumer_key=consumer_key, consumer_secret=consumer_secret,
                       access_token=access_token, access_token_secret=access_token_secret, wait_on_rate_limit=True)


# Function to save tweets with variable file path and filename reflecting time range
def fetch_and_save_tweets(start_date, end_date, save_location, no_of_tweets=10, query=""):
    try:
        # Fetching tweets using search_recent_tweets to get more comprehensive results
        tweets = client.search_recent_tweets(
            query=query,
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

        # Extracting tweet data and all available information
        attributes_container = []
        if tweets.data:
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

        # Creation of the DataFrame
        tweets_df = pd.DataFrame(attributes_container)
        # Create filename reflecting start and end dates
        filename = f"tweets_{start_date.replace(':', '').replace('T', '_')}_to_{end_date.replace(':', '').replace('T', '_')}.csv"
        save_path = f"{save_location}/{filename}"
        tweets_df.to_csv(save_path, index=False)
        print(f"Tweets saved to {save_path}")
    except tweepy.TooManyRequests:
        print("Rate limit exceeded. Waiting for 30 minutes before retrying...")
        time.sleep(1800)  # Wait for 30 minutes before retrying
    except BaseException as e:
        print('Status Failed On,', str(e))


# Run this periodically with specified interval
def periodic_tweet_fetcher(save_location, no_of_tweets=10, start_time=None, time_window_minutes=15, query=""):
    end_time = start_time + datetime.timedelta(minutes=time_window_minutes)

    while start_time < datetime.datetime.now(datetime.timezone.utc):
        # Format timestamps to ISO 8601 strings with UTC 'Z' suffix
        start_date = start_time.strftime("%Y-%m-%dT%H:%M:%SZ")
        end_date = end_time.strftime("%Y-%m-%dT%H:%M:%SZ")

        fetch_and_save_tweets(start_date, end_date, save_location, no_of_tweets, query)

        # Move the window forward by the specified time window interval
        start_time = end_time
        end_time = start_time + datetime.timedelta(minutes=time_window_minutes)

        # Sleep for 30 minutes before the next fetch
        time.sleep(10)


# Example usage
save_location = r"path/to/mainfolder"  # Set your desired save location
no_of_tweets = 50  # Set desired number of tweets to fetch (minimum 10, maximum 180)
start_time = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=7)  # Start 6 days ago
time_window_minutes = 60  # Width of the time frame in minutes
keywords = ["fluoridation", "fluoridated", "fluoride"]
query = f"({' OR '.join(keywords)}) lang:en -is:retweet -is:quote -has:links -has:media -has:images -has:video_link"  # Query string with language filter and excluding retweets

# Run the periodic fetcher with manually set start time and specified window
periodic_tweet_fetcher(save_location, no_of_tweets, start_time, time_window_minutes, query)

