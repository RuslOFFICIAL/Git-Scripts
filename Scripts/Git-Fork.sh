#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"

# Functions.
prompt_and_create_tag() {
	echo
	read -r -e -p "Do you want to create a Git tag? (y/N): " create_tag
	if [[ "${create_tag,,}" == "y" ]]; then
		read -r -e -p "Enter tag name (e.g., v1.0.0): " tag_name
		if [ -n "$tag_name" ]; then
			tag_message=""
			read -r -e -p "Do you want to add a tag message? (y/N): " add_tag_msg
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
	echo "[WARNING]: File not found at '$VARIABLES_FILE'!" && echo "Check if there is that file or download it from GitHub repository!" && echo
fi

echo "Git-Fork $Git_Fork_Version" && echo

# User input.
read -r -e -p "Enter the local directory for the fork directory: " repo_dir
read -r -e -p "Enter original Git repository link: " repo_link
read -r -e -p "Enter the Git repository link: " fork_link
read -r -e -p "Enter the target branch [Default: repo-fork]: " target_branch
echo

# Choose mode.
echo "Choose repository type:"
echo "1) Separate repository (Fresh Git history, Unlinked from original)"
echo "2) Fork structure (Preserves history, Links original as upstream)"
read -r -e -p "Enter choice (1, 2) [Default: 2]: " repo_type
echo

# Ensure .git suffix is present for links if missing.
[ -n "$repo_link" ] && [[ "$repo_link" != *.git ]] && repo_link="${repo_link}.git"
[ -n "$fork_link" ] && [[ "$fork_link" != *.git ]] && fork_link="${fork_link}.git"

# Set default branch.
if [ -z "$target_branch" ]; then
	target_branch="main"
fi

# Set default repo type.
if [ -z "$repo_type" ]; then
	repo_type="2"
fi

# Sanitize input.
repo_dir="${repo_dir//\"/}"
repo_link="${repo_link//\"/}"
fork_link="${fork_link//\"/}"

# Convert Windows path to Unix path.
if [[ "$repo_dir" == [a-zA-Z]:\\* ]] || [[ "$repo_dir" == [a-zA-Z]:/* ]]; then
	repo_dir=$(cygpath -u "$repo_dir")
fi

# Check if path exists.
if [ ! -d "$repo_dir" ]; then
	echo "Directory '$repo_dir' does not exist. Creating it..."
	mkdir -p "$repo_dir" || { echo "Failed to create directory!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }
fi

# Find the cloned directory.
repo_folder="${repo_link##*/}"
repo_folder="${repo_folder%.git}"

# Navigate to the main directory.
cd "$repo_dir" || { echo "Directory not found!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

# Initialize and fork.
cd "$repo_dir"
echo "Cloning Git repository..."
git clone "$repo_link"
cd "$repo_folder" || { echo "Failed to enter directory '$repo_folder'!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

# Conditional logic based on choice.
if [ "$repo_type" = "1" ]; then
	# Separate repository workflow.
	echo "Initializing a fresh local Git folder..."
	rm -rf .git
	git init
	git checkout -b "$target_branch"
	echo "Adding and committing files..."
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
	git commit -m "Initial commit"
	echo "Linking the local files to the Git repository..."
	if git remote get-url origin >/dev/null 2>&1; then
		git remote set-url origin "$fork_link"
	else
		git remote add origin "$fork_link"
	fi
else
	# Fork workflow.
	echo "Configuring repository remotes for fork structure..."
	if git remote get-url origin >/dev/null 2>&1; then
		git remote set-url origin "$fork_link"
	else
		git remote add origin "$fork_link"
	fi
	echo "Creating target branch '$target_branch'..."
	git checkout -b "$target_branch"
fi

echo "Pushing it to Git..."
git push -u origin "$target_branch"

prompt_and_create_tag

# End.
echo -e "\nDone!"
read -s -p "Press [Enter] to continue..." && exit 0
