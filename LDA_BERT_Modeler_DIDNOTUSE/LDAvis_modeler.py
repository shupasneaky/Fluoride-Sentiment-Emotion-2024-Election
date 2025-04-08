import os
import pandas as pd
import gensim
from gensim import corpora
import pyLDAvis
import pyLDAvis.gensim

"""
interactive_topic_modeling.py

This script performs LDA topic modeling on 'common_users_tweets_filtered.csv'
and generates:
1. pyLDAvis interactive visualizations for topics ranging from 3 to 10.
2. Saves trained LDA models as '.model' files for reuse.
3. Saves tweet-level topic assignments in CSV format.
"""

# Define file paths
data_folder = "D:/pythonProject/Data/"
results_folder = "D:/pythonProject/Results/"
input_file = data_folder + "common_users_tweets_filtered.csv"

# Load data
df = pd.read_csv(input_file)
tokens = df["tokens"].apply(eval).tolist()  # Convert string lists back to lists

# Create dictionary and BoW representation
dictionary = corpora.Dictionary(tokens)
corpus = [dictionary.doc2bow(text) for text in tokens]

# Ensure results folder exists
os.makedirs(results_folder, exist_ok=True)

# Generate LDA models and save them
for num_topics in range(3, 11):
    print(f"Processing LDA model for {num_topics} topics...")

    # Train LDA Model
    lda_model = gensim.models.LdaModel(
        corpus=corpus,
        id2word=dictionary,
        num_topics=num_topics,
        random_state=42,
        passes=10,
        alpha='auto',
        per_word_topics=True
    )

    # Create folder for this topic number
    topic_folder = f"{results_folder}Topic{num_topics}/"
    os.makedirs(topic_folder, exist_ok=True)

    # Save trained model
    model_path = f"{topic_folder}lda_model_{num_topics}.model"
    lda_model.save(model_path)
    print(f"Saved LDA model: {model_path}")

    # Save interactive visualization
    vis = pyLDAvis.gensim.prepare(lda_model, corpus, dictionary)
    pyLDAvis.save_html(vis, f"{topic_folder}lda_viz.html")
    print(f"Saved visualization: {topic_folder}lda_viz.html")

    # Assign topics to tweets
    df["Topic"] = [max(lda_model.get_document_topics(bow), key=lambda x: x[1])[0] for bow in corpus]

    # Save topic assignments CSV
    output_csv = f"{topic_folder}topic_assignments_{num_topics}_topics.csv"
    df[["Time_Label", "Tweet ID", "Author ID", "tokens", "Topic"]].to_csv(output_csv, index=False)
    print(f"Saved topic assignments: {output_csv}")

print("\nAll topic models processed and saved.")
