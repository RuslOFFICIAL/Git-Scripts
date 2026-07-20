#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE="../.conf-files/Variables.conf"
COMMANDS_FILE="../.conf-files/Git-Aliases_Info.conf"
COMMANDS_FILENAME="Git-Aliases_Info.conf"
BASHRC="$HOME/.bashrc"

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

echo "Git-Aliases $Git_Aliases_Version" && echo

# Create .bashrc if it doesn't exist yet.
if [ ! -f "$BASHRC" ]; then
	echo ".bashrc not found. Creating a new one..."
	cat "$COMMANDS_FILE" > "$BASHRC"
	echo "All aliases successfully initialized in a new .bashrc file." && echo && echo "Done!"
	read -s -p "Press [Enter] to continue..." && exit 0
fi

echo "Checking and updating aliases in .bashrc..."

# Read the commands file line by line.
while IFS= read -r line || [[ -n "$line" ]]; do
	# Skip comments or empty lines
	[[ "$line" =~ ^#.* ]] || [[ -z "$line" ]] && continue

	# Extract the alias name.
	alias_name=$(echo "$line" | cut -d'=' -f1)
	alias_check="${alias_name}="
	
	# Check if the alias definition exists in the file.
	if grep -q "$alias_check" "$BASHRC"; then
        
		# Check if the exact line exists.
		if ! grep -Fxq "$line" "$BASHRC"; then
			echo "Updating \"$alias_check\"..."
			
			# Create temp file excluding the old alias, then append new one.
			grep -v "^$alias_check" "$BASHRC" > "$BASHRC.tmp"
			echo "$line" >> "$BASHRC.tmp"
			mv "$BASHRC.tmp" "$BASHRC"
		else
			echo "Alias \"$alias_check\" is already up to date."
		fi
	else
	
	# Append new alias
	echo "$line" >> "$BASHRC"
	echo "Added: \"$alias_check\""
	fi

done < "$COMMANDS_FILE"

# End.
echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0
