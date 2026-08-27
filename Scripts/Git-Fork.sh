#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"

# Configs.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$clean_value"
	done < "$VARIABLES_FILE"
else
	echo "Warning: File not found at '$VARIABLES_FILE'!" && echo "Check if you have that file or download it from GitHub repository!" && echo
fi

echo "Git-Fork $Git_Fork_Version" && echo

# User input.
read -r -e -p "Enter your local directory for the fork directory: " repo_dir
read -r -e -p "Enter original GitHub repository link: " repo_link
read -r -e -p "Enter your GitHub repository link: " fork_link
read -r -e -p "Enter your target branch [Default: repo-fork]: " target_branch
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
echo "Cloning GitHub repository..."
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
		chmod +x $Executable 2>/dev/null
		git update-index --chmod=+x $Executable 2>/dev/null
	fi
	git commit -m "Initial commit"
	echo "Linking your local files to your GitHub repository..."
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

echo "Pushing it to GitHub..."
git push -u origin "$target_branch"

# End.
echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0