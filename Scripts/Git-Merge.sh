#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE="../Configs/Variables.conf"

# Configs.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		export "$key=$value"
	done < "$VARIABLES_FILE"
fi

echo "Git-Merge $Git_Merge_Version" && echo

# User insert directory path.
read -r -e -p "Enter the path of the Git repository folder: " dir_path
dir_path="${dir_path//\"/}"

# Convert Windows path to Unix.
if [[ "$dir_path" == [a-zA-Z]:\\* ]] || [[ "$dir_path" == [a-zA-Z]:/* ]]; then
	dir_path=$(cygpath -u "$dir_path")
fi

cd "$dir_path" || { echo "Directory not found!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

# Check if it is Git folder.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo && echo "Fatal: This directory is not a Git repository."
	read -s -p "Press [Enter] to continue..." && exit 1
fi

# Ensure .git suffix is present for links if missing.
repo_link=$(git remote get-url origin 2>/dev/null || git remote -v | awk '/^origin.*\(fetch\)$/{print $2}')

if [ -z "$repo_link" ]; then
	echo "[INFO] No 'origin' remote found for this repository."
	read -r -e -p "Enter the remote repository URL to set as origin: " repo_link
	if [ -n "$repo_link" ]; then
		# Ensure .git suffix before adding.
		[ -n "$repo_link" ] && [[ "$repo_link" != *.git ]] && repo_link="${repo_link}.git"
		git remote add origin "$repo_link"
		echo "Added remote origin: $repo_link"
	fi
else
	# Ensure .git suffix if it already existed.
	[ -n "$repo_link" ] && [[ "$repo_link" != *.git ]] && repo_link="${repo_link}.git"
fi

# Show current status and branches.
echo && echo "Current location: $(pwd)"
echo && echo "Available branches (Local and Remote):"
git branch -a && echo

# Switch branch.
read -r -e -p "Enter a branch to switch to (or press [ENTER] to stay on current): " switch_branch
if [ -n "$switch_branch" ]; then
	echo && echo "Switching branch..."
	if ! git checkout "$switch_branch"; then
		echo && echo "Error: Git checkout failed. Script stopped to prevent breaking things." && echo
		read -s -p "Press [Enter] to continue..." && exit 1
	fi
fi

echo "======================================="

# Current branch info.
current_branch=$(git branch --show-current)
echo "You are currently on branch: [ $current_branch ]" && echo

# Merge branch selection.
read -r -e -p "Enter the branch you want to merge FROM: " source_branch
if [ -z "$source_branch" ]; then
	echo "Error: You must specify a source branch." && echo
	read -s -p "Press [Enter] to continue..." && exit 1
fi

read -r -e -p "Allow unrelated histories? (Y/n) [Default: n]: " allow_unrelated

# Merge.
echo && echo "Fetching latest branches from GitHub..."
git fetch origin

if [[ "${allow_unrelated,,}" == "y" ]]; then
	git merge origin/"$source_branch" --allow-unrelated-histories -m "Force merge $source_branch history"
else
	git merge origin/"$source_branch"
fi

# Conflicts and Error handling.
if [ $? -ne 0 ]; then
	echo && echo "Merge stopped or failed."
	echo "Hint: If Git says 'unmerged files', run 'git merge --abort' in your terminal to reset." && echo "Hint: If it is an actual conflict, resolve the file markers and use Git-Push."
else
	echo && echo "Merge completed successfully!"
	
	read -r -e -p "Would you like to commit the merged changes? (Y/n) [Default: y]: " commit_now
	if [[ ! "${commit_now,,}" == "n" ]]; then
		read -r -e -p "Enter commit message: " commit_msg
		git add .
		git commit -m "${commit_msg:-Merge $source_branch into $current_branch}"
	fi
	
	read -r -e -p "Would you like to push the merged changes to GitHub right now? (Y/n) [Default: y]: " push_now
	if [[ ! "${push_now,,}" == "n" ]]; then
		echo "Pushing to GitHub..."
		git push
	else
		echo "Operation cancelled by user."
	fi
fi

# End.
echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0