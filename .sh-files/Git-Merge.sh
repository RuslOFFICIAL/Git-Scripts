#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE="../.conf-files/Variables.conf"
COMMANDS_FILE="../.conf-files/Git-Login_Info.conf"

# .conf files.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		export "$key=$value"
	done < "$VARIABLES_FILE"
fi

echo "Git-Merge $Git_Merge_Version" && echo ""

# User insert directory path.
read -p "Enter the path of the Git repository folder: " dir_path
dir_path="${dir_path//\"/}"

# Convert Windows path to Unix.
if [[ "$dir_path" == [a-zA-Z]:\\* ]] || [[ "$dir_path" == [a-zA-Z]:/* ]]; then
	dir_path=$(cygpath -u "$dir_path")
fi

cd "$dir_path" || { echo "Directory not found!"; read -s -n 1 -p "Press any key to continue..."; exit 1; }

# Check if it is Git folder.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo "" && echo "Fatal: This directory is not a Git repository."
	read -s -n 1 -p "Press any key to continue..." && exit 1
fi

# Show current status and branches.
echo "" && echo "Current location: $(pwd)"
echo "" && echo "Available branches (Local and Remote):"
git branch -a && echo ""

# Switch branch.
read -p "Enter a branch to switch to (or press [ENTER] to stay on current): " switch_branch
if [ -n "$switch_branch" ]; then
	echo "" && echo "Switching branch..."
	if ! git checkout "$switch_branch"; then
		echo "" && echo "Error: Git checkout failed. Script stopped to prevent breaking things."
		read -s -n 1 -p "Press any key to continue..." && exit 1
	fi
fi

echo "======================================="

# Current branch info.
current_branch=$(git branch --show-current)
echo "You are currently on branch: [ $current_branch ]" && echo ""

# Merge branch selection.
read -p "Enter the branch you want to merge FROM: " source_branch
if [ -z "$source_branch" ]; then
	echo "Error: You must specify a source branch."
	read -s -n 1 -p "Press any key to continue..." && exit 1
fi

read -p "Allow unrelated histories? (Y/n) [Default: n]: " allow_unrelated

# Merge.
echo "" && echo "Running Git merge..."
echo "Fetching latest branches from GitHub..."
git fetch origin

if [[ "${allow_unrelated,,}" == "y" ]]; then
	git merge origin/"$source_branch" --allow-unrelated-histories -m "Force merge $source_branch history"
else
	git merge origin/"$source_branch"
fi

# Conflicts and Error handling.
if [ $? -ne 0 ]; then
	echo "" && echo "Merge stopped or failed."
	echo "Hint: If Git says 'unmerged files', run 'git merge --abort' in your terminal to reset." && echo "Hint: If it is an actual conflict, resolve the file markers and use Git-Push."
else
	echo "" && echo "Merge completed successfully!"
	
	read -p "Would you like to commit the merged changes? (Y/n) [Default: y]: " commit_now
	if [[ ! "${commit_now,,}" == "n" ]]; then
		read -p "Enter commit message: " commit_msg
		git add .
		git commit -m "${commit_msg:-Merge $source_branch into $current_branch}"
	fi
	
	read -p "Would you like to push the merged changes to GitHub right now? (Y/n) [Default: y]: " push_now
	if [[ ! "${push_now,,}" == "n" ]]; then
		echo "Pushing to GitHub..."
		git push
	else
		echo "Operation cancelled by user."
	fi
fi

# End.
echo "" && echo "Done!"
read -s -n 1 -p "Press any key to continue..." && exit 0