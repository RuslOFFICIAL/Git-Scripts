#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE="../.conf-files/Variables.conf"
COMMANDS_FILE="../.conf-files/Git-Launcher_Info.conf"
COMMANDS_FILENAME="Git-Launcher_Info.conf"

# .conf files.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$value"
	done < "$VARIABLES_FILE"
fi

if [ ! -f "$COMMANDS_FILE" ]; then
	echo "Error: $COMMANDS_FILENAME not found!" && echo "Check if you have that file or follow the instruction in $COMMANDS_FILENAME.example!" && echo
	read -s -p "Press [Enter] to continue..." && exit 1
fi

echo "Git-Launcher $Git_Launcher_Version" && echo

# Display options and build selection array.
declare -A script_map
options=()

while IFS='|' read -r key label script || [[ -n "$key" ]]; do
	script="${script%$'\r'}"
	
	# Skip comments or empty lines
	[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
	
	echo "[$key] $label"
	options+=("$key")
	script_map["$key"]="$script"
done < "$COMMANDS_FILE"

# Prompt for selection.
if [ ${#options[@]} -eq 0 ]; then
	echo "Error: No options found in $COMMANDS_FILENAME." && echo
	read -s -p "Press [Enter] to continue..." && exit 1
fi

echo
while true; do
	read -p "Enter your choice ($(printf "%s, " "${options[@]}" | sed 's/, $//')): " user_choice
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
