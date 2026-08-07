#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE="../Configs/Variables.conf"
COMMANDS_FILENAME="Git-Push_Info.conf"
COMMANDS_FILE="../Configs/$COMMANDS_FILENAME"

# Configs.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$value"
	done < "$VARIABLES_FILE"
fi

if [ ! -f "$COMMANDS_FILE" ]; then
	echo "Error: '$COMMANDS_FILENAME' not found!" && echo "Check if you have that file or follow the instruction in '$COMMANDS_FILENAME.example'!" && echo
	read -s -p "Press [Enter] to continue..." && exit 1
fi

echo "Git-Push $Git_Push_Version" && echo

# Build project map.
declare -A project_paths
declare -A project_branches
options=()

while IFS='=' read -r key rest || [[ -n "$key" ]]; do
	[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
	key=$(echo "$key" | tr -d '[:space:]')
	
	# Split by "|".
	IFS='|' read -r label path branch <<< "${rest%$'\r'}"
	
	echo "[$key] $label"
	options+=("$key")
	project_paths["$key"]="$path"
	project_branches["$key"]="${branch:-main}"
done < "$COMMANDS_FILE"

echo
while true; do
	read -r -e -p "Enter your choice ($(printf "%s, " "${options[@]}" | sed 's/, $//')): " user_choice
	if [[ " ${options[*]} " =~ " ${user_choice} " ]]; then
		target_dir="${project_paths[$user_choice]}"
		target_branch="${project_branches[$user_choice]}"
		break
	else
		echo "Invalid choice, please try again."
	fi
done

# Convert Windows path to Unix.
target_dir="${target_dir//\"/}"
if [[ "$target_dir" == [a-zA-Z]:\\* ]] || [[ "$target_dir" == [a-zA-Z]:/* ]]; then
	target_dir=$(cygpath -u "$target_dir")
fi

cd "$target_dir" || { echo "Directory not found!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

# Push Logic.
echo "Switching to the branch '$target_branch'..."
git switch "$target_branch" || { echo "[ERROR] Failed to switch branch!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

if [ -z "$(git status --porcelain)" ]; then
	echo "No local changes detected."
	read -r -e -p "Do you still want to force a commit? (Y/N): " force_commit
	if [[ ! "${force_commit,,}" == "y" ]]; then
		echo "Checking for online updates..."
		git pull --rebase || { echo "[ERROR] Pull failed!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }
		echo && echo "Done!"
		read -s -p "Press [Enter] to continue..." && exit 0
	fi
fi

while true; do
	read -r -e -p "Enter your commit message: " commit_message
	clean_message=$(echo "$commit_message" | sed 's/\x1b\[[A-Z]//g')
	
	if [ -n "$clean_message" ]; then
		commit_message="$clean_message"
		break
	else
		echo "Error: Commit message (title) cannot be empty!"
	fi
done

read -r -e -p "Enter your commit description (Optional): " commit_description
echo "Adding all local files..."
git add .
echo "It may ask now for the keyphrase of your GPG key if you have one."
echo "Adding commit..."
git commit -m "$commit_message" -m "$commit_description"

echo "Pulling any changes..."
git pull --rebase || { echo "[ERROR] Pull failed!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

echo "Pushing your changes..."
git push origin "$target_branch" || { echo "[ERROR] Push failed!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0