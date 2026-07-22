#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE="../.conf-files/Variables.conf"

# .conf files.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$value"
	done < "$VARIABLES_FILE"
fi

echo "Git-Fork $Git_Fork_Version" && echo

# User input.
read -r -p "Enter your local directory for the fork: " repo_dir
read -r -p "Enter original GitHub repository link (with .git at the end): " repo_link
read -r -p "Enter your GitHub repository link: " fork_link
read -r -p "Enter your target branch [Default: repo-fork]: " target_branch
echo

# Set default branch.
if [ -z "$target_branch" ]; then
	target_branch="main"
fi

# Sanitize input.
repo_dir="${repo_dir//\"/}"
repo_link="${repo_link//\"/}"
fork_link="${fork_link//\"/}"

# Convert Windows path to Unix path.
if [[ "$repo_dir" == [a-zA-Z]:\\* ]] || [[ "$repo_dir" == [a-zA-Z]:/* ]]; then
	repo_dir=$(cygpath -u "$repo_dir")
fi

# Find the cloned directory.
repo_folder="${repo_link##*/}"
repo_folder="${repo_folder%.git}"

# Navigate to the main directory.
cd "$repo_dir" || { echo "Directory not found!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

# Initialize and fork.
cd "$repo_dir"
echo "Cloning GitHub repository..."
git clone "$repo_link"
cd "$repo_folder" || { echo "Failed to enter directory '$repo_folder'!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }
echo "Initializing the local Git folder..."
git init
echo "Renaming the default branch to '$target_branch'..."
git checkout -b "$target_branch"

# End.
echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0