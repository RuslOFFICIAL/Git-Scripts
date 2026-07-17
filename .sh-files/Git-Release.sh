#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE="../.conf-files/Variables.conf"

# .conf files.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$value"
	done < "$VARIABLES_FILE"
fi

echo "Git-Release $Git_Release_Version" && echo ""

# Paths
SOURCE_DIR=".."
STAGING_DIR="../TempRelease"
ARCHIVE_FOLDER="../Releases"
ARCHIVE_FILE="$ARCHIVE_FOLDER/Git-Scripts_$Git_Scripts_Version.tar.gz"

echo -n "Cleaning release folder... "
rm -f "$ARCHIVE_FOLDER"/Git-Scripts_*.tar.gz

echo "Done!" && echo -n "Preparing release folder... "
mkdir -p "$STAGING_DIR"

echo "Done!" && echo -n "Copying files... "
shopt -s dotglob
for item in ../*; do
	name=$(basename "$item")
	
	if [[ "$name" == "TempRelease" || "$name" == "Releases" || "$name" == ".git" || "$name" == ".conf-files" ]]; then
		continue
	fi

	cp -a "$item" "$STAGING_DIR/"
done
shopt -u dotglob

echo "Done!" && echo -n "Including 'Variables.conf' and 'Git-Launcher_Info.conf' in release... "
mkdir -p "$STAGING_DIR/.conf-files"
cp "$VARIABLES_FILE" "$STAGING_DIR/.conf-files/"
cp "../.conf-files/Git-Launcher_Info.conf" "$STAGING_DIR/.conf-files/"

echo "Done!" && echo -n "Compressing into .tar.gz file... "
mkdir -p "$ARCHIVE_FOLDER"
tar -czf "$ARCHIVE_FILE" -C "$STAGING_DIR" .

echo "Done!" && echo -n "Cleaning up temporary folders... "
rm -rf "$STAGING_DIR"

echo "Done!" && echo "" && echo "Done!"
echo "Your release is ready inside the 'Releases' folder."
read -s -p "Press [Enter] to continue..." && exit 0