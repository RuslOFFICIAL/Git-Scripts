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

echo "Git-Statistic $Git_Statistic_Version" && echo

# Variables.
git_name=$(git config user.name)
total_added=0
total_removed=0
total_commits=0

# Path Input.
read -r -e -p "Enter the directory path: " target_dir

# Convert Windows path to Unix.
target_dir="${target_dir//\"/}"
target_dir=$(cygpath -u "$target_dir")

if [[ "$target_dir" == [a-zA-Z]:\\* ]] || [[ "$target_dir" == [a-zA-Z]:/* ]]; then
	target_dir=$(cygpath -u "$target_dir")
fi

echo "Checking path: $target_dir" && echo
if [ ! -d "$target_dir" ]; then
	echo "Directory not found!" && echo
	read -s -p "Press [Enter] to continue..." && exit 1
fi
cd "$target_dir" || exit

# Function to process repository.
process_repo() {
	pushd "$1" > /dev/null || return
	echo "Stats for $2"
	
	commits=$(git rev-list --count --author="$git_name" HEAD)
	
	# Calculate stats
	stats=$(git log --author="$git_name" --numstat --pretty=format: | awk '{add+=$1; del+=$2} END {print add+0, del+0}')
	add=$(echo "$stats" | cut -d' ' -f1)
	del=$(echo "$stats" | cut -d' ' -f2)
	
	echo "Commits: $commits | Added: $add | Removed: $del" && echo
	
	total_added=$((total_added + add))
	total_removed=$((total_removed + del))
	total_commits=$((total_commits + commits))
	
	popd > /dev/null
}

found_any=false

# Check target dir itself.
if [ -d ".git" ]; then
	found_any=true
	process_repo "." "$target_dir"
fi

# Check subdirectories.
for d in */; do
	d=${d%/}
	if [ -d "$d/.git" ]; then
		found_any=true
		process_repo "$d" "$d"
	fi
done

if [ "$found_any" = false ]; then
	echo "No git repositories found." && echo
	read -s -p "Press [Enter] to continue..." && exit 1
fi

# Summary.
# Separator.
printf "\033[1A\r"
cols=$(tput cols)
printf '%*s\n' "$cols" '' | tr ' ' '-'

# Total.
echo "Grand Total Commits: $total_commits"
echo "Grand Total Added: $total_added"
echo "Grand Total Removed: $total_removed"

echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0