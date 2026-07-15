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
ZIP_FOLDER="../Releases"
ZIP_FILE="$ZIP_FOLDER/Git-Scripts_$Git_Scripts_Version.tar.gz"

echo "Cleaning release folder..."
rm -f "$ZIP_FOLDER"/Git-Scripts_*.zip

echo "" && echo "Preparing release folder..."
mkdir -p "$STAGING_DIR"

echo "Copying files..."
shopt -s dotglob
for item in ../*; do
	name=$(basename "$item")
	
	if [[ "$name" == "TempRelease" || "$name" == "Releases" || "$name" == ".git" || "$name" == ".conf-files" ]]; then
		continue
	fi

	cp -a "$item" "$STAGING_DIR/"
done
shopt -u dotglob

echo "Including 'Variables.conf' and 'Git-Launcher_Info.conf' in release..."
mkdir -p "$STAGING_DIR/.conf-files"
cp "$VARIABLES_FILE" "$STAGING_DIR/.conf-files/"
cp "../.conf-files/Git-Launcher_Info.conf" "$STAGING_DIR/.conf-files/"

echo "" && echo "Compressing into .zip file..."
mkdir -p "$ZIP_FOLDER"
tar -czf "$ZIP_FILE" -C "$STAGING_DIR" .

echo "" && echo "Cleaning up temporary folders..."
rm -rf "$STAGING_DIR"

echo "" && echo "Done!"
echo "Your release is ready inside the 'Releases' folder."
read -s -n 1 -p "Press any key to continue..." && exit 0