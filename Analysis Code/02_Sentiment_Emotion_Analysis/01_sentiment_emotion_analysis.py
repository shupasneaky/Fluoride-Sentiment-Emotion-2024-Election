import openai
import pandas as pd
import time
import os
import re  # Import regex for better parsing

# Load API Key
with open("D:/openai_key.txt", "r") as file:
    api_key = file.read().strip()

client = openai.OpenAI(api_key=api_key)

# System message definition
system_message = {
    "role": "system",
    "content": """I am going to provide you with short text posts from conversations on x.com. 
These tweets are surrounding the 2024 election. 
Your job is to classify the Topic, Sentiment towards the Topic, and all Emotions represented in the text. 

The Sentiment responses can only be within the list:
 "Neutral", "Negative", "Positive". 
There can be only one Sentiment.

The Topic responses can only be within the list:
"Dental", "Cancer", "Thyroid", "Neurological Effects", "Fluoride", "Vaccines", "Autism", "IQ", "Pineal", "Endocrine" "Mass medication",  "Conspiracy", "Political",
 "Science", "Technology", "Health", "Societal Issues", "Economic", "Education", "Arts", "Sports". 
There can be multiple topics. 

The Emotion responses can only be within the list:
"Serenity", "Joy", "Ecstasy", "Acceptance", "Trust", "Admiration", "Apprehension", "Fear", "Terror", "Distraction", "Surprise",
 "Amazement", "Pensiveness", "Sadness", "Grief", "Boredom", "Disgust", "Loathing", "Annoyance", "Anger", "Rage",
  "Interest", "Anticipation", "Vigilance", "Love", "Submission", "Alarm", "Disappointment", "Remorse", "Contempt",
   "Aggression", "Optimism", "Guilt", "Curiosity", "Despair", "Unbelief", "Envy", "Cynicism", "Pride", "Hope",
    "Delight", "Sentimentality", "Shame", "Outrage", "Pessimism", "Morbidness", "Dominance", "Anxiety", "Bittersweet", "Ambivalence",
     "Frozenness", "Confusion".
There can be more than one emotion.

Respond ONLY in the following format and in a single line:
'Topic: [Topic1, Topic2, ...], Sentiment: [Sentiment], Emotion: [Level Emotion1, Level Emotion2, ...]'.

An example of an appropriate response:
'Topic: [Space, Technology], Sentiment: [Positive], Emotion: [Joy, Trust, Anticipation, Anger, Anxiety]'
"""
}

# File paths
input_files = [
    "path/to/user.csv",
    "path/to/fluoride.csv"
]
output_dir = "path/to/data/processed_data"

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)


def analyze_tweet(tweet):
    """
    Sends a single tweet to OpenAI for topic, sentiment, and emotion analysis.
    Returns the topic, sentiment, and emotion as text.
    """
    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[system_message, {"role": "user",
                                       "content": f"Classify the sentiment, topic, and emotion of this tweet: '{tweet}'"}],
            temperature=0.5
        )

        raw_response = response.choices[0].message.content.strip()

        # PRINT: Show AI's full response
        print(f"🔍 AI Response: {raw_response}")

        if not raw_response:
            return "Unknown", "Neutral", "None"

        # Extract Topic, Sentiment, and Emotion using regex
        topic_match = re.search(r"Topic:\s*\[(.*?)\]", raw_response)
        sentiment_match = re.search(r"Sentiment:\s*\[(.*?)\]", raw_response)
        emotion_match = re.search(r"Emotion:\s*\[(.*?)\]", raw_response)

        topic = topic_match.group(1) if topic_match else "Unknown"
        sentiment = sentiment_match.group(1) if sentiment_match else "Neutral"
        emotion = emotion_match.group(1) if emotion_match else "None"

        # PRINT: Show extracted details
        print(f"✅ Extracted -> Topic: {topic} | Sentiment: {sentiment} | Emotion: {emotion}\n")

        return topic, sentiment, emotion

    except Exception as e:
        print(f"❌ Error processing tweet: {e}")
        return "Unknown", "Neutral", "None"


def process_file(file_path):
    """Processes tweets one by one, saves after each response, and compiles into a final CSV."""
    df = pd.read_csv(file_path)

    if "Text_nolink" not in df.columns:
        raise ValueError(f"Column 'Text_nolink' not found in {file_path}")

    # Initialize missing columns
    for col in ["Topic", "Sentiment", "Emotion"]:
        if col not in df.columns:
            df[col] = None

    output_file = os.path.join(output_dir, os.path.basename(file_path).replace(".csv", "_processed.csv"))

    # Process each tweet one by one
    for index, row in df.iterrows():
        if pd.isna(row["Text_nolink"]) or pd.notna(row["Sentiment"]):  # FIX: Only process unprocessed tweets
            continue  # Skip empty rows and already processed tweets

        tweet_text = str(row["Text_nolink"])
        print(f"📤 Processing tweet {index + 1}/{len(df)}...")

        topic, sentiment, emotion = analyze_tweet(tweet_text)

        # Save result immediately
        df.at[index, "Topic"] = topic
        df.at[index, "Sentiment"] = sentiment
        df.at[index, "Emotion"] = emotion
        df.to_csv(output_file, index=False)  # FIX: Now only saves processed tweets

    print(f"✅ Finished processing {file_path}. Final results saved to {output_file}.")


# Process each file
for file in input_files:
    try:
        process_file(file)
    except Exception as e:
        print(f"❌ Error processing file {file}: {e}")

# Combine all processed files into one final CSV
combined_output = "path/to/data/final_dataset.csv"
all_files = [os.path.join(output_dir, f) for f in os.listdir(output_dir) if f.endswith("_processed.csv")]

if all_files:
    combined_df = pd.concat([pd.read_csv(f) for f in all_files], ignore_index=True)
    combined_df.to_csv(combined_output, index=False)
    print(f"✅ All processed tweets compiled into: {combined_output}")
