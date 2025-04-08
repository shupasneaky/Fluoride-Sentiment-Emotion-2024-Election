import os
import pandas as pd
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification

"""
01_sentiment_emotion_analysis.py

This script applies sentiment and emotion classification to:
1. fluoride_tweets.csv
2. user_tweets.csv
3. common_users_tweets.csv

- Uses 'Text_nolink' as input.
- Outputs 'Sentiment' (Positive, Neutral, Negative).
- Outputs 'Dominant Emotion' (7-class emotion).
- If text is missing, sets both Sentiment & Emotion to "Missing".
- Saves results back to the same CSV files.
"""

# Define file paths
data_folder = "D:/pythonProject/Data/"
files = ["fluoride_tweets.csv", "user_tweets.csv", "common_users_tweets.csv"]

# Load the GoEmotions model
model_name = "j-hartmann/emotion-english-distilroberta-base"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(model_name)

# Define emotion labels (7-class output)
emotion_labels = ["anger", "disgust", "fear", "joy", "neutral", "sadness", "surprise"]

# Define sentiment labels (3-class mapping)
sentiment_map = {
    "joy": "Positive",
    "anger": "Negative",
    "disgust": "Negative",
    "fear": "Negative",
    "sadness": "Negative",
    "surprise": "Neutral",
    "neutral": "Neutral"
}

def classify_text(text):
    """Predicts Sentiment and Dominant Emotion for a given text."""
    if pd.isna(text) or not isinstance(text, str) or text.strip() == "":
        return "Missing", "Missing"  # Assign "Missing" if no text

    # Tokenize text
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=128)

    # Run model & get predictions
    with torch.no_grad():
        outputs = model(**inputs)
        probs = torch.nn.functional.softmax(outputs.logits, dim=-1)[0].tolist()

    # Get the dominant emotion (highest probability)
    dominant_emotion = emotion_labels[probs.index(max(probs))]

    # Map dominant emotion to sentiment
    sentiment = sentiment_map[dominant_emotion]

    return sentiment, dominant_emotion

# Process each file
for file in files:
    file_path = os.path.join(data_folder, file)

    if not os.path.exists(file_path):
        print(f"Skipping {file} - File not found.")
        continue

    print(f"Processing {file}...")

    # Load data
    df = pd.read_csv(file_path)

    if "Text_nolink" not in df.columns:
        print(f"Skipping {file} - 'Text_nolink' column not found.")
        continue

    # Apply classification
    df[["Sentiment", "Dominant Emotion"]] = df["Text_nolink"].apply(lambda x: pd.Series(classify_text(x)))

    # Save updated file
    df.to_csv(file_path, index=False)
    print(f"Updated file saved: {file_path}")

print("\nSentiment & Emotion classification completed for all files.")
