#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"
COMMANDS_FILE_NAME="Git-Sync_Info.conf"
COMMANDS_FILE="../Configs/$COMMANDS_FILE_NAME"

# Configs.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$clean_value"
	done < "$VARIABLES_FILE"
else
	echo "[WARNING]: File not found at '$VARIABLES_FILE'!" && echo "Check if you have that file or download it from GitHub repository!" && echo
fi

if [ ! -f "$COMMANDS_FILE" ]; then
	echo "[ERROR]: File not found at '$COMMANDS_FILE'!" && echo "Check if you have that file or follow the instruction in '$COMMANDS_FILE_NAME.example'!" && echo
	read -s -p "Press [Enter] to continue..." && exit 1
fi

# Automatically convert any Windows paths in the config file to Unix paths.
if grep -qE '[a-zA-Z]:[/\\]' "$COMMANDS_FILE"; then
	temp_conf=$(mktemp)
	while IFS= read -r line || [[ -n "$line" ]]; do
		if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
			echo "$line" >> "$temp_conf"
			continue
		fi
		
		key="${line%%=*}"
		rest="${line#*=}"
		label="${rest%%|*}"
		remainder="${rest#*|}"
		path="${remainder%%|*}"
		branch="${remainder#*|}"
		
		clean_path="${path//\"/}"
		clean_path="${clean_path%$'\r'}"
		
		if [[ "$clean_path" =~ ^[a-zA-Z]:[/\\] ]]; then
			unix_path=$(cygpath -u "$clean_path")
			echo "$key=$label|$unix_path|$branch" >> "$temp_conf"
		else
			echo "$line" >> "$temp_conf"
		fi
	done < "$COMMANDS_FILE"
	mv "$temp_conf" "$COMMANDS_FILE"
	echo -e "[INFO] Converted Windows paths to Unix paths in '$COMMANDS_FILE_NAME'.\n"
fi

echo "Git-Sync $Git_Sync_Version" && echo

# Build project map.
declare -A project_paths
declare -A project_branches
options=()

while IFS='=' read -r key rest || [[ -n "$key" ]]; do
	[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
	key=$(echo "$key" | tr -d '[:space:]')
	
	# Split by "|".
	IFS='|' read -r label path branch <<< "${rest%$'\r'}"
	
	# Clean quotes and carriage returns
	path="${path//\"/}"
	path="${path%$'\r'}"
	
	# Convert any Windows-style path to Unix path.
	if [[ "$path" =~ ^[a-zA-Z]:[/\\] ]]; then
		path=$(cygpath -u "$path")
	fi
	
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

# Switch to the target branch.
echo "Switching to the branch '$target_branch'..."
git switch "$target_branch" || { echo "[ERROR]:Failed to switch branch!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

# No changes logic.
if [ -z "$(git status --porcelain)" ]; then
	echo "No local changes detected."
	read -r -e -p "Do you still want to force a commit? (Y/N): " force_commit
	if [[ ! "${force_commit,,}" == "y" ]]; then
		echo "Checking for online updates..."
		git pull --rebase || {
			echo "[INFO] No tracking branch found. Setting upstream and retrying..."
			git branch --set-upstream-to="origin/$target_branch" "$target_branch" 2>/dev/null || git push -u origin "$target_branch"
			git pull --rebase || { echo "[ERROR]:Pull failed!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }
		}
		echo && echo "Done!"
		read -s -p "Press [Enter] to continue..." && exit 0
	fi
fi

# Commit logic.
while true; do
	read -r -e -p "Enter your commit message: " commit_message
	clean_message=$(echo "$commit_message" | sed 's/\x1b\[[A-Z]//g')
	
	if [ -n "$clean_message" ]; then
		commit_message="$clean_message"
		break
	else
		echo "[ERROR]: Commit message (title) cannot be empty!"
	fi
done
read -r -e -p "Enter your commit description (Optional): " commit_description

# Adding files and commit. Applying executable permissions.
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

# Pull logic.
echo "Pulling any changes..."
git pull --rebase || {
	echo "[INFO] No tracking branch found. Setting upstream and retrying..."
	git branch --set-upstream-to="origin/$target_branch" "$target_branch" 2>/dev/null || git push -u origin "$target_branch"
	git pull --rebase || { echo "[ERROR]: Pull failed!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }
}

# Push logic.
echo "Pushing your changes..."
git push origin "$target_branch" || { echo "[ERROR]: Push failed!"; echo; read -s -p "Press [Enter] to continue..."; exit 1; }

echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0
