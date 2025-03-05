import os
import pandas as pd

def collect_unique_author_ids(folder_path, save_path):
    # List all CSV files in the folder
    file_list = [file for file in os.listdir(folder_path) if file.endswith('.csv')]

    # Initialize a set to collect unique Author IDs
    unique_author_ids = set()

    # Loop through each file and read the Author ID column
    for file_name in file_list:
        full_path = os.path.join(folder_path, file_name)
        try:
            df = pd.read_csv(full_path)
            if 'Author ID' in df.columns:
                unique_author_ids.update(df['Author ID'].unique())
        except Exception as e:
            print(f"Failed to process {file_name}: {e}")

    # Convert the unique Author IDs to a DataFrame and save as a CSV file
    unique_ids_df = pd.DataFrame({'Unique Author ID': list(unique_author_ids)})
    unique_ids_df.to_csv(save_path, index=False)
    print(f"Unique Author IDs saved to {save_path}")

# Example usage
folder_path = r"C:/Users/owvis/OneDrive - University of Florida/Fluoride_Xdata/Flouride_Term_Tweets"
save_path = r"C:/Users/owvis/OneDrive - University of Florida/Fluoride_Xdata/uniqueIDs_flouride_term_tweets.csv"
collect_unique_author_ids(folder_path, save_path)
