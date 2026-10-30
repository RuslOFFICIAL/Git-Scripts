#!/bin/bash
set +H
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"
COMMANDS_FILE_NAME="Git-Login_Info.conf"
COMMANDS_FILE="../Configs/$COMMANDS_FILE_NAME"

# Configs.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$clean_value"
	done < "$VARIABLES_FILE"
else
	echo "[WARNING]: File not found at '$VARIABLES_FILE'!" && echo -e "Check if there is that file or download it from the repository!\n"
fi

if [ ! -f "$COMMANDS_FILE" ]; then
	echo "[ERROR]: File not found at '$COMMANDS_FILE'!" && echo -e "Check if there is that file or follow the instruction in '$COMMANDS_FILE_NAME.example'!\n"
	read -s -p "Press [Enter] to continue..." && exit 1
fi

echo -e "Git-Login $Git_Login_Version\n"

# Confirmation.
while true; do
	read -r -e -p "Run this script? (Y/N) " confirmation
	case "$confirmation" in
		[Yy]* ) echo; break ;;
		[Nn]* ) echo -e "\nOperation cancelled by user.\n"; read -s -p "Press [Enter] to continue..."; exit 0 ;;
		* ) echo -e "Please answer Y or n.\n" ;;
	esac
done

# Import Login details.
while IFS='=' read -r key value; do
	[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
	val="${value%$'\r'}"
	export "$key=$val"
done < "$COMMANDS_FILE"

# Login process.
# Username.
echo -n "Setting username... "
git config --global user.name "$GitName"
echo "Success!"

# Email.
echo -n "Setting user email... "
git config --global user.email "$GitEmail"
echo "Success!"

# GPG configuration.
if [ "$KeyIs" == "1" ]; then
	echo -n "Setting GPG signing key... "
	git config --global user.signingkey "$GitGPGKeyID" && git config --global commit.gpgsign true && gpg_status="$GitGPGKeyID"
	echo "Success!"
elif [ "$KeyIs" == "2" ]; then
	echo -n "Disabling GPG signing key... "
	git config --global --unset user.signingkey 2>/dev/null && git config --global commit.gpgsign false && gpg_status="Disabled"
	echo "Success!"
else
	gpg_status="Skipped" && echo "GPG signing skipped."
fi

# CLI.
echo -e "\nPress 'Ctrl+C' to skip CLI logins." && echo -n "Checking platform CLI logins... "
gh auth login
glab auth login
echo "Success!"

# End.
echo -e "\nGit global configuration updated successfully!"
echo "Username:		$GitName" 
echo "Email:			$GitEmail"
echo "GPG signing key ID:	$gpg_status"

read -s -p "Press [Enter] to continue..." && exit 0
