#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE="../.conf-files/Variables.conf"

# .conf files.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		export "$key=$value"
	done < "$VARIABLES_FILE"
fi

echo "Git-Link-Repo $Git_LinkRepo_Version" && echo ""

# User input.
read -r -p "Enter your local repository directory: " repo_dir
read -p "Enter your commit message: " commit_message
read -p "Enter your GitHub repository link: " repo_link
read -p "Enter your target branch [Default: main]: " target_branch

# Set default branch.
if [ -z "$target_branch" ]; then
	target_branch="main"
fi

# Sanitize input.
repo_dir="${repo_dir//\"/}"
repo_link="${repo_link//\"/}"

# Convert Windows path to Unix path.
if [[ "$repo_dir" == [a-zA-Z]:\\* ]] || [[ "$repo_dir" == [a-zA-Z]:/* ]]; then
	repo_dir=$(cygpath -u "$repo_dir")
fi

# Navigate to directory.
cd "$repo_dir" || { echo "Directory not found!"; read -s -p "Press [Enter] to continue..."; exit 1; }

# Initialize and link.
echo "Initializing the local Git folder..."
git init
echo "Adding all your files..."
git add .
echo "Adding commit..."
git commit -m "$commit_message"
echo "Renaming the default branch to '$target_branch'..."
git branch -M "$target_branch"
echo "Linking your local files to your GitHub repository..."
git remote add origin "$repo_link"
echo "Pushing it to GitHub..."
git push -u origin "$target_branch"

echo "" && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0