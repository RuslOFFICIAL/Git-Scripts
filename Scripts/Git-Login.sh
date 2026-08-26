#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"
COMMANDS_FILENAME="Git-Login_Info.conf"
COMMANDS_FILE="../Configs/$COMMANDS_FILENAME"

# Configs.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$clean_value"
	done < "$VARIABLES_FILE"
fi

if [ ! -f "$COMMANDS_FILE" ]; then
	echo "Error: '$COMMANDS_FILENAME' not found!" && echo "Check if you have that file or follow the instruction in '$COMMANDS_FILENAME.example'!" && echo
	read -s -p "Press [Enter] to continue..." && exit 1
fi

echo "Git-Login $Git_Login_Version" && echo

# Confirmation.
while true; do
	read -r -e -p "Are you sure you want to run this script? (Y/n) " confirmation
	case "$confirmation" in
		[Yy]* ) echo; break ;;
		[Nn]* ) echo; echo "Operation cancelled by user."; echo; read -s -p "Press [Enter] to continue..."; exit 0 ;;
		* ) echo "Please answer Y or n."; echo ;;
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
echo && echo "Press 'Ctrl+C' to skip CLI logins." && echo -n "Checking platform CLI logins... "
gh auth login
glab auth login
echo "Success!"

# End.
echo && echo "Git global configuration updated successfully!"
echo "Username:		$GitName" 
echo "Email:			$GitEmail"
echo "GPG signing key ID:	$gpg_status"

read -s -p "Press [Enter] to continue..." && exit 0