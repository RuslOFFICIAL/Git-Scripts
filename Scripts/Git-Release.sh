#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"
INCLUDE_FILE_1_NAME="Git-Launcher_Info.conf"
INCLUDE_FILE_1="../Configs/$INCLUDE_FILE_1_NAME"

# Configs.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$clean_value"
	done < "$VARIABLES_FILE"
fi

echo "Git-Release $Git_Release_Version" && echo

# Confirmation.
while true; do
	read -r -e -p "Are you sure you want to run this script? (Y/n) " confirmation
	case "$confirmation" in
		[Yy]* ) echo; break ;;
		[Nn]* ) echo; echo "Operation cancelled by user."; echo; read -s -p "Press [Enter] to continue..."; exit 0 ;;
		* ) echo "Please answer Y or n."; echo ;;
	esac
done

# Paths
SOURCE_DIR=".."
STAGING_DIR="../TempRelease"
CONFIGS_DIR="$STAGING_DIR/Configs"
ARCHIVE_FOLDER="../Releases"
ARCHIVE_FILE="$ARCHIVE_FOLDER/Git-Scripts_$Git_Scripts_Version.tar.gz"

echo -n "Cleaning release folder... "
rm -f "$ARCHIVE_FOLDER"/Git-Scripts_*.tar.gz

echo "Done!" && echo -n "Preparing release folder... "
mkdir -p "$STAGING_DIR"
mkdir -p "$CONFIGS_DIR"

echo "Done!" && echo -n "Copying files... "
shopt -s dotglob
for item in ../*; do
	name=$(basename "$item")
	
	if [[ "$name" == "TempRelease" || "$name" == "Releases" || "$name" == ".git" || "$name" == "Configs" ]]; then
		continue
	fi

	cp -a "$item" "$STAGING_DIR/"
done
shopt -u dotglob

echo "Done!" && echo -n "Including all '.example' files in release... "
cp ../Configs/*.example "$CONFIGS_DIR/"

echo "Done!" && echo -n "Including '$VARIABLES_FILE_NAME' and '$INCLUDE_FILE_1_NAME' in release... "
cp "$VARIABLES_FILE" "$CONFIGS_DIR"
cp "$INCLUDE_FILE_1" "$CONFIGS_DIR"

# Make files be executable.
if [ -n "$Executable" ]; then
	echo "Done!" && echo -n "Applying executable permissions... "
	
	(cd "$STAGING_DIR" && chmod +x $Executable 2>/dev/null)
fi

echo "Done!" && echo -n "Compressing into .tar.gz file... "
mkdir -p "$ARCHIVE_FOLDER"
tar --owner=0 --group=0 --no-same-owner -czf "$ARCHIVE_FILE" -C "$STAGING_DIR" .

echo "Done!" && echo -n "Cleaning up temporary folders... "
rm -rf "$STAGING_DIR"

echo "Done!" && echo && echo "Done!" && echo "Your release is ready inside the 'Releases' folder."
echo && echo "Done!"
read -s -p "Press [Enter] to continue..." && exit 0