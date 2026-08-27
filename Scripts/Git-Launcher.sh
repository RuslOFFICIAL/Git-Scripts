#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"
COMMANDS_FILE_NAME="Git-Launcher_Info.conf"
COMMANDS_FILE="../Configs/$COMMANDS_FILE_NAME"

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

if [ ! -f "$COMMANDS_FILE" ]; then
	echo "Error: File not found at '$COMMANDS_FILE'!" && echo "Check if you have that file or follow the instruction in '$COMMANDS_FILE_NAME.example'!" && echo
	read -s -p "Press [Enter] to continue..." && exit 1
fi

echo "Git-Launcher $Git_Launcher_Version" && echo

# Display options and build selection array.
declare -A script_map
options=()

while IFS='|' read -r key label script || [[ -n "$key" ]]; do
	script="${script%$'\r'}"
	
	# Skip comments or empty lines.
	[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
	
	echo "[$key] $label"
	options+=("$key")
	script_map["$key"]="$script"
done < "$COMMANDS_FILE"

# Prompt for selection.
if [ ${#options[@]} -eq 0 ]; then
	echo "Error: No options found in '$COMMANDS_FILE_NAME'." && echo
	read -s -p "Press [Enter] to continue..." && exit 1
fi

echo
while true; do
	read -r -e -p "Enter your choice ($(printf "%s, " "${options[@]}" | sed 's/, $//')): " user_choice
	if [[ " ${options[*]} " =~ " ${user_choice} " ]]; then
		selected_script="${script_map[$user_choice]}"
		break
	else
		echo "Invalid choice, please try again."
	fi
done

# Execute the selected script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/$selected_script"
echo "Running \"$selected_script\"..." && echo

if [ -f "$TARGET_SCRIPT" ]; then
	bash "$TARGET_SCRIPT"
else
	echo "Error: Could not find script at $TARGET_SCRIPT"
fi

echo && echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0
