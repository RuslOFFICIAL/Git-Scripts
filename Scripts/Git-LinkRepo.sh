#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"
COMMANDS_FILE_NAME="Git-Sync_Info.conf"
COMMANDS_FILE="../Configs/$COMMANDS_FILE_NAME"

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
				tag_message=$(cat)
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

echo "Git-Link-Repo $Git_LinkRepo_Version" && echo

# User input.
read -r -e -p "Enter the local repository directory: " repo_dir
read -r -e -p "Enter the commit message [Default: Initial commit.]: " commit_message
echo "Enter the commit description (Optional):" commit_description
commit_description=$(cat)

while true; do
	read -r -e -p "Enter the Git repository link: " repo_link
	if [ -z "$repo_link" ]; then
		echo -e "[WARNING]: Git repositoy link cannot be empty. Please try again.\n"
		continue
	else
		break
	fi
done
read -r -e -p "Enter the target branch [Default: main]: " target_branch
echo

# Clean escape sequences.
commit_message=$(echo "$commit_message" | sed 's/\x1b\[[A-Z]//g')
commit_description=$(echo "$commit_description" | sed 's/\x1b\[[A-Z]//g')

# Ensure .git suffix is present for links if missing.
[ -n "$repo_link" ] && [[ "$repo_link" != *.git ]] && repo_link="${repo_link}.git"

# Set defaults.
if [ -z "$commit_message" ]; then
	commit_message="Initial commit."
fi
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
cd "$repo_dir" || { echo "Directory not found!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

# Confirmation.
while true; do
	echo -e "Repository Directory: '$repo_dir'\nRepository Link: '$repo_link'\nBranch: '$target_branch'\nCommit Message: '$commit_message;'\nCommit Description: '$commit_description'\n"
	read -r -e -p "Run this script? (Y/N) " confirmation
	case "$confirmation" in
		[Yy]* ) echo; break ;;
		[Nn]* ) echo -e "\nOperation cancelled by user."; echo; read -s -p "Press [Enter] to continue..."; exit 0 ;;
		* ) echo "Please answer Y or n."; echo ;;
	esac
done

# Initialize and link.
echo "Initializing the local Git folder..."
git init
echo "Adding all local files..."
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
echo "Adding commit..."
git commit -m "$commit_message" -m "$commit_description"
echo "Renaming the default branch to '$target_branch'..."
git branch -M "$target_branch"
echo "Linking the local files to the Git repository..."
git remote add origin "$repo_link"
echo "Pushing it to Git..."
git push -u origin "$target_branch"

prompt_and_create_tag

# Option to add to "$COMMANDS_FILE_NAME".
echo
read -r -e -p "Add this repository to '$COMMANDS_FILE_NAME'? (y/N): " add_to_conf
if [[ "${add_to_conf,,}" == "y" ]]; then
	cd "$(dirname "$0")" || exit
	if [ ! -f "$COMMANDS_FILE" ]; then
		touch "$COMMANDS_FILE"
	fi
	
	# Prompt for project label.
	while true; do
		read -r -e -p "Enter a short label/name for this project: " proj_label
		if [ -z "$proj_label" ]; then
			echo -e "[WARNING]: Project label cannot be empty. Please try again.\n"
		else
			break
		fi
	done
	
	# Prompt for project number.
	while true; do
		read -r -e -p "Enter a number ID for this project in the config: " proj_num
		if [ -z "$proj_num" ]; then
			echo -e "[WARNING]: Project number cannot be empty. Please try again.\n"
			continue
		fi
		
		# Check if number already exists in the file.
		if grep -qE "^[[:space:]]*$proj_num=" "$COMMANDS_FILE"; then
			echo -e "[WARNING]: Number '$proj_num' is already taken in '$COMMANDS_FILE_NAME'. Please choose another one.\n"
		else
			break
		fi
	done
	
	# Append config line.
	printf "\n%s=%s|%s|%s\n" "$proj_num" "$proj_label" "$repo_dir" "$target_branch" >> "$COMMANDS_FILE"
	sed -i '/^[[:space:]]*$/d' "$COMMANDS_FILE"
	sed -i 's/\r$//' "$COMMANDS_FILE"
	
	echo -e "\nSuccessfully added to '$COMMANDS_FILE_NAME'!"
else
	echo -e "\nOperation cancelled by user."
fi

# End.
echo -e "\nDone!"
read -s -p "Press [Enter] to continue..." && exit 0
