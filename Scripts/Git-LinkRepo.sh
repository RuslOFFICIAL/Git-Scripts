#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"
COMMANDS_FILE_NAME="Git-Push_Info.conf"
COMMANDS_FILE="../Configs/Git-Push_Info.conf"

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

echo "Git-Link-Repo $Git_LinkRepo_Version" && echo

# User input.
read -r -e -p "Enter your local repository directory: " repo_dir
read -r -e -p "Enter your commit message [Default: Initial commit.]: " commit_message
read -r -e -p "Enter your commit description (Optional): " commit_description
read -r -e -p "Enter your GitHub repository link: " repo_link
read -r -e -p "Enter your target branch [Default: main]: " target_branch
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
	echo "Repository Directory: '$repo_dir'; Repository Link: '$repo_link'; Branch: '$target_branch'; Commit Message: '$commit_message;'; Commit Description: '$commit_description'"
	read -r -e -p "Are you sure you want to link the repository? (Y/n) " confirmation
	case "$confirmation" in
		[Yy]* ) echo; break ;;
		[Nn]* ) echo; echo "Operation cancelled by user."; echo; read -s -p "Press [Enter] to continue..."; exit 0 ;;
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
	chmod +x $Executable 2>/dev/null
	git update-index --chmod=+x $Executable 2>/dev/null
fi
echo "It may ask now for the keyphrase of your GPG key if you have one."
echo "Adding commit..."
git commit -m "$commit_message" -m "$commit_description"
echo "Renaming the default branch to '$target_branch'..."
git branch -M "$target_branch"
echo "Linking your local files to your GitHub repository..."
git remote add origin "$repo_link"
echo "Pushing it to GitHub..."
git push -u origin "$target_branch"

# Option to add to "Git-Push_Info.conf".
echo
read -r -e -p "Do you want to add this repository to '$COMMANDS_FILE_NAME'? (Y/N): " add_to_conf
if [[ "${add_to_conf,,}" == "y" ]]; then
	cd "$(dirname "$0")" || exit
	if [ ! -f "$COMMANDS_FILE" ]; then
		touch "$COMMANDS_FILE"
	fi
	read -r -e -p "Enter a short label/name for this project: " proj_label
	
	# Find next available number or let user pick with check.
	while true; do
		read -r -e -p "Enter a number ID for this project in the config: " proj_num
		
		# Check if number already exists in the file.
		if grep -qE "^[[:space:]]*$proj_num=" "$COMMANDS_FILE"; then
			echo "[WARNING] Number '$proj_num' is already taken in '$COMMANDS_FILE_NAME'. Please choose another one."
		else
			break
		fi
	done
	
	# Append config line.
	printf "\n%s=%s|%s|%s" "$proj_num" "$proj_label" "$repo_dir" "$target_branch" >> "$COMMANDS_FILE"
	echo && echo "Successfully added to '$COMMANDS_FILE_NAME'!"
else
	echo && echo "Operation cancelled by user."
fi

# End.
echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0