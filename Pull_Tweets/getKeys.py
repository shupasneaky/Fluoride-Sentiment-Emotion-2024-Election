import os

def getKeys(folder_path, global_vars):

    # List all files in the folder
    file_names = os.listdir(folder_path)

    for file_name in file_names:
        # Build the full file path
        full_path = os.path.join(folder_path, file_name)

        # Check if it's a file (not a folder)
        if os.path.isfile(full_path):
            # Remove the file extension for variable name (assuming files are .txt)
            variable_name = os.path.splitext(file_name)[0]

            # Open the file and read its content
            with open(full_path, 'r') as file:
                content = file.read().strip()  # Read and remove extra whitespace

            # Use the passed globals() dictionary to create variables
            global_vars[variable_name] = content

            # Print to check if the variable is created
            print(f"Variable {variable_name} contains: {global_vars[variable_name]}")


