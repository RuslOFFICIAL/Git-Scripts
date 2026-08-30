#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"
COMMANDS_FILE_NAME="Git-Bashrc_Info.conf"
COMMANDS_FILE="../Configs/$COMMANDS_FILE_NAME"
BASHRC="$HOME/.bashrc"

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

echo "Git-Bashrc $Git_Bashrc_Version" && echo

# Confirmation.
while true; do
	read -r -e -p "Are you sure you want to run this script? (Y/n) " confirmation
	case "$confirmation" in
		[Yy]* ) echo; break ;;
		[Nn]* ) echo; echo "Operation cancelled by user."; echo; read -s -p "Press [Enter] to continue..."; exit 0 ;;
		* ) echo "Please answer Y or n."; echo ;;
	esac
done

# Create .bashrc if it doesn't exist yet.
if [ ! -f "$BASHRC" ]; then
	echo ".bashrc not found. Creating a new one..."
	cat "$COMMANDS_FILE" > "$BASHRC"
	echo "All aliases successfully initialized in a new .bashrc file." && echo && echo "Done!"
	read -s -p "Press [Enter] to continue..." && exit 0
fi

echo "Checking and updating aliases in .bashrc..."

# Read the commands file line by line.
current_block=""
in_function=0
declare -A processed_funcs 2>/dev/null || typeset -A processed_funcs

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
	line="${raw_line%$'\r'}"
	
	if [[ "$in_function" -eq 0 ]]; then
		# Skip comments or empty lines outside of functions.
		[[ "$line" =~ ^#.* ]] || [[ -z "$line" ]] && continue

		# Check if this line starts a function.
		if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*\([[:space:]]*\)[[:space:]]*\{ ]]; then
			in_function=1
			current_block="$line"
			
			if [[ "$line" =~ \} ]]; then
				in_function=0
			fi
		fi
	else
		current_block+=$'\n'$line

		if [[ "$line" =~ ^[[:space:]]*\} ]]; then
			in_function=0
		fi
	fi

	# Function block.
	if [[ "$in_function" -eq 0 && -n "$current_block" ]]; then
		func_name=$(echo "$current_block" | head -n 1 | sed -E 's/^[[:space:]]*([a-zA-Z0-9_-]+)[[:space:]]*\(\).*/\1/')
		
		# Ignore if duplicate function name exists in the commands file.
		if [[ -n "${processed_funcs[$func_name]}" ]]; then
			echo "Skipping duplicate function definition: \"$func_name\""
			current_block=""
			continue
		fi
		processed_funcs["$func_name"]=1
		
		normalized_block=$(echo "$current_block" | tr -d '\r')
		normalized_bashrc=$(tr -d '\r' < "$BASHRC")

		# Ignore if function already exists in .bashrc (duplicate) instead of updating or removing.
		match_count=$(echo "$normalized_bashrc" | grep -Ec "^[[:space:]]*${func_name}[[:space:]]*\(\)[[:space:]]*\{")
		if [[ "$match_count" -gt 1 ]]; then
			echo "Ignoring function \"$func_name\" (multiple definitions found in .bashrc)."
			current_block=""
			continue
		elif [[ "$match_count" -eq 1 ]]; then
			# Extract existing function block from .bashrc for comparison.
			existing_block=$(awk -v fn="$func_name" '
				($0 ~ "^[[:space:]]*" fn "[[:space:]]*\\(\\)[[:space:]]*\\{") {p=1; print; next}
				p {print}
				p && /^[[:space:]]*\}/ {p=0}
			' "$BASHRC")

			# Normalize line endings for accurate comparison.
			normalized_existing=$(echo "$existing_block" | tr -d '\r')

			if [[ "$normalized_existing" != "$normalized_block" ]]; then
				echo -n "Updating function \"$func_name\"..."
				
				# Remove old function block and append the updated one.
				awk -v fn="$func_name" '
					$0 ~ "^[[:space:]]*" fn "[[:space:]]*\\(\\)[[:space:]]*\\{" {skip=1; next}
					skip && /^[[:space:]]*\}/ {skip=0; next}
					!skip
				' "$BASHRC" > "$BASHRC.tmp"
				echo "$current_block" >> "$BASHRC.tmp"
				mv "$BASHRC.tmp" "$BASHRC"
				echo " Success!"
			else
				echo "Function \"$func_name\" is already up to date."
			fi
		else
			echo "$current_block" >> "$BASHRC"
			echo "Added function: \"$func_name\""
		fi
		current_block=""
		continue
	fi

	[[ "$in_function" -eq 1 ]] && continue

	# Handle regular single-line aliases/variables.
	alias_name=$(echo "$line" | cut -d'=' -f1)
	alias_check="${alias_name}="
	
	if grep -q "$alias_check" "$BASHRC"; then
		if ! grep -Fxq "$line" "$BASHRC"; then
			echo -n "Updating \"$alias_check\"..."
			grep -v "^$alias_check" "$BASHRC" > "$BASHRC.tmp"
			echo "$line" >> "$BASHRC.tmp"
			mv "$BASHRC.tmp" "$BASHRC"
			echo " Success!"
		else
			echo "Alias \"$alias_check\" is already up to date."
		fi
	else
		echo "$line" >> "$BASHRC"
		echo "Added: \"$alias_check\""
	fi

done < "$COMMANDS_FILE"

# End.
echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0
