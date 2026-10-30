#!/bin/bash
set +H
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"

# Functions.
prompt_and_create_tag() {
	echo
	read -r -e -p "Create a Git tag? (y/N): " create_tag
	if [[ "${create_tag,,}" == "y" ]]; then
		read -r -e -p "Enter tag name (e.g., v1.0.0): " tag_name
		if [ -n "$tag_name" ]; then
			tag_message=""
			read -r -e -p "Add a tag message? (y/N): " add_tag_msg
			if [[ "${add_tag_msg,,}" == "y" ]]; then
				echo "Enter tag message (Press Enter then Ctrl+D on a new line when finished):"
				tag_message=$(cat | sed 's/"/\\"/g')
			fi
			
			[[ -z "$tag_message" ]] && tag_message="$tag_name"
			echo
			
			# Check if GPG signing key is configured in git.
			if [ -n "$(git config --get user.signingkey)" ]; then
				echo "It may ask now for the keyphrase of a GPG key if there is one."
				echo "[INFO] GPG key detected. Creating signed tag ('-s')..."
				git tag -s "$tag_name" -m "$tag_message"
			else
				echo "[INFO] No GPG key detected. Creating annotated tag ('-a')..."
				git tag -a "$tag_name" -m "$tag_message"
			fi
			
			git push origin "$tag_name" && echo "[INFO] Tag '$tag_name' pushed successfully." || echo "[ERROR]: Failed to push tag!"
		fi
	else
		echo -e "\nOperation cancelled by user."
	fi
}

# Configs.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$clean_value"
	done < "$VARIABLES_FILE"
else
	echo "[WARNING]: File not found at '$VARIABLES_FILE'!" && echo -e "Check if there is that file or download it from the repository!\n"
fi

echo -e "Git-Merge $Git_Merge_Version\n"

# User insert directory path.
read -r -e -p "Enter the path of the Git repository folder: " dir_path
dir_path="${dir_path//\"/}"

# Convert Windows path to Unix.
if [[ "$dir_path" == [a-zA-Z]:\\* ]] || [[ "$dir_path" == [a-zA-Z]:/* ]]; then
	dir_path=$(cygpath -u "$dir_path")
fi

cd "$dir_path" || { echo -e "\nDirectory not found!\n"; read -s -p "Press [Enter] to continue..."; exit 1; }

# Check if it is Git folder.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo -e "\n[FATAL]: This directory is not a Git repository.\n"
	read -s -p "Press [Enter] to continue..." && exit 1
fi

# Ensure .git suffix is present for links if missing.
repo_link=$(git remote get-url origin 2>/dev/null || git remote -v | awk '/^origin.*\(fetch\)$/{print $2}')

if [ -z "$repo_link" ]; then
	echo "[INFO] No 'origin' remote found for this repository."
	read -r -e -p "Enter the remote repository URL to set as origin: " repo_link
	if [ -n "$repo_link" ]; then
		[ -n "$repo_link" ] && [[ "$repo_link" != *.git ]] && repo_link="${repo_link}.git"
		git remote add origin "$repo_link" 2>/dev/null || git remote set-url origin "$repo_link"
		echo "Created and set remote origin: '$repo_link'"
	fi
else
	if [[ -n "$repo_link" && "$repo_link" != *.git ]]; then
		[ -n "$repo_link" ] && [[ "$repo_link" != *.git ]] && repo_link="${repo_link}.git"
		git remote set-url origin "$repo_link"
		echo "Updated remote origin: '$repo_link'"
	fi
fi

# Show current status and branches.
echo -e "\nCurrent location: $(pwd)"
echo -e "\nAvailable branches (Local and Remote):"
git branch -a

# Switch branch.
read -r -e -p $'\nEnter a branch to switch to (or press [ENTER] to stay on current): ' switch_branch
if [ -n "$switch_branch" ]; then
	echo -e "\nSwitching branch..."
	if ! git checkout "$switch_branch"; then
		echo -e "\n[ERROR]: Git checkout failed. Script stopped to prevent breaking things.\n"
		read -s -p "Press [Enter] to continue..." && exit 1
	fi
fi

echo "======================================="

# Current branch info.
current_branch=$(git branch --show-current)
echo "Current branch: [ $current_branch ]"

# Merge branch selection.
read -r -e -p $'\nEnter the branch to merge FROM: ' source_branch
if [ -z "$source_branch" ]; then
	echo -e "\n[ERROR]: A source branch must be specifed.\n"
	read -s -p "Press [Enter] to continue..." && exit 1
fi

read -r -e -p "Allow unrelated histories? (y/N) [Default: n]: " allow_unrelated

# Merge.
echo -e "\nFetching latest branches from Git..."
git fetch origin

if [[ "${allow_unrelated,,}" == "y" ]]; then
	git merge origin/"$source_branch" --allow-unrelated-histories -m "Force merge $source_branch history"
else
	git merge origin/"$source_branch"
fi

# Conflicts and Error handling.
if [ $? -ne 0 ]; then
	echo -e "\nMerge stopped or failed."
	echo "Hint: If Git says 'unmerged files', run 'git merge --abort' in a terminal to reset." && echo "Hint: If it is an actual conflict, resolve the file markers and use 'Git-Sync'."
else
	echo -e "\nMerge completed successfully!"
	
	read -r -e -p "Should the merged changes be commited? (Y/n) [Default: y]: " commit_now
	if [[ ! "${commit_now,,}" == "n" ]]; then
		read -r -e -p "Enter commit message: " commit_msg
		commit_msg="${commit_msg:-Merge $source_branch into $current_branch}"
		
		commit_description=""
		read -r -e -p "Add a commit description? (y/N): " add_commit_desc
		if [[ "${add_commit_desc,,}" == "y" ]]; then
			echo "Enter the commit description (Optional) (Press Enter then Ctrl+D on a new line when finished):"
			commit_description=$(cat | sed 's/"/\\"/g')
		fi
		
		git add .
		if [ -n "$Executable" ]; then
			echo "Applying executable permissions..."
			for pattern in $Executable; do
				find . -type f -name "$pattern" | while read -r file; do
					if git check-ignore -q "$file"; then
						continue
					fi
					
					chmod +x "$file" 2>/dev/null
					git update-index --chmod=+x "$file" 2>/dev/null
				done
			done
		fi
		
		echo "It may ask now for the keyphrase of a GPG key if there is one."
		git commit -m "$commit_msg" -m "$commit_description"
	fi
	
	read -r -e -p "Should the merged changes be pushed to Git right now? (Y/n) [Default: y]: " push_now
	if [[ ! "${push_now,,}" == "n" ]]; then
		echo "Pushing to Git..."
		git push
	else
		echo "Operation cancelled by user."
	fi
fi

# End.
echo -e "\nDone!"
read -s -p "Press [Enter] to continue..." && exit 0
