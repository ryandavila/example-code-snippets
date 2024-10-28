#!/bin/bash

###
# This script is used for transfering large files between local servers I have. It is run regularly
# with cron jobs.
###

# Define the path to the directory containing files
directory="/media/ryan/media"

# Define the path to the text file containing the list of files
file_list="/home/ryan/Documents/transfer_list.txt"

# Define the SSH username and hostname of the remote host
remote_user="root"
remote_host="192.168.1.6"

# Define the path to the directory on the remote host where you want to copy the files
remote_directory="/mnt/user/internal/inbox/"

# Define the path to the log file
log_file="/home/ryan/logs/scripts/transfer_media_to_server.log"

# Create the log directory if it doesn't exist
log_dir=$(dirname "$log_file")
if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir"
fi

# Function to print the usage
print_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --dry-run    : Perform a dry run, print files that would be transferred."
    echo "  -c, --console     : Print output to console instead of logging to a file."
    exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    -d | --dry-run)
        dry_run=true
        ;;
    -c | --console)
        console_output=true
        ;;
    *)
        print_usage
        ;;
    esac
    shift
done

# Redirect output to console if specified
if [ "$console_output" = true ]; then
    log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $@"
    }
else
    # Create the log file if it doesn't exist
    touch "$log_file"
    log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $@" >>"$log_file"
    }
fi

# Check if the directory exists
if [ ! -d "$directory" ]; then
    log "Directory does not exist."
    exit 1
fi

# Check if the file list exists, if not create it
touch "$file_list"

# Loop through each file in the directory
for file in "$directory"/*; do
    # Extract file name from the path
    filename=$(basename "$file")

    # Check if the file is already in the list
    found=false
    while IFS= read -r line; do
        if [ "$filename" == "$line" ]; then
            found=true
            break
        fi
    done <"$file_list"

    if [ "$found" = false ]; then
        if [ "$dry_run" = true ]; then
            log "Would transfer $filename to remote host."
        else
            log "Copying $filename to remote host..."

            # Use scp to securely copy the file/directory to the remote host recursively
            scp -r "$file" "$remote_user@$remote_host:$remote_directory"
            if [ $? -eq 0 ]; then
                log "File $filename copied successfully to remote host."

                # Add the file name to the list
                echo "$filename" >>"$file_list"
            else
                log "Error copying file $filename to remote host."
            fi
        fi
    fi
done
