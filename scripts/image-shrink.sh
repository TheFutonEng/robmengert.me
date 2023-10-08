#!/bin/bash

# Check if the image folder path is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <image_folder>"
    exit 1
fi

# Set the image folder path from the command-line argument
image_folder="$1"

# Check if the specified folder exists
if [ ! -d "$image_folder" ]; then
    echo "Error: The specified folder '$image_folder' does not exist."
    exit 1
fi

# Array of supported image extensions
supported_extensions=("png" "jpg" "jpeg" "gif")

# Loop through the supported image extensions
for extension in "${supported_extensions[@]}"; do
    # Loop through the image files in the folder with the current extension
    for image_file in "$image_folder"/*."$extension"; do
        # Check if there are any files with the current extension
        if [ -e "$image_file" ]; then
            # Get the base name of the image file (without the path)
            base_name=$(basename "$image_file")
            
            # Construct the new image name with "50" in it
            new_image_name="${base_name%.$extension}-50%.$extension"
            
            # Execute the convert command to resize and overwrite the original image
            convert "$image_file" -resize 50% "$image_folder/$new_image_name"
            
            # Move the resized image to overwrite the original
            mv "$image_folder/$new_image_name" "$image_file"

            # Print a message indicating the conversion
            echo "Converted $base_name to $new_image_name and overwritten the original"
        fi
    done
done
