#!/bin/bash
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE="../.conf-files/Variables.conf"
COMMANDS_FILE="../.conf-files/Git-Login_Info.conf"
COMMANDS_FILENAME="Git-Login_Info.conf"

# .conf files.
if [ -f "$VARIABLES_FILE" ]; then
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
		clean_value="${value%$'\r'}"
		export "$key=$value"
	done < "$VARIABLES_FILE"
fi

if [ ! -f "$COMMANDS_FILE" ]; then
	echo "Error: $COMMANDS_FILENAME not found!" && echo "Check if you have that file or follow the instruction in $COMMANDS_FILENAME.example!"
	read -s -n 1 -p "Press any key to continue..." && exit 1
fi

echo "Git-Login $Git_Login_Version" && echo ""

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

# End.
echo "" && echo "Git global configuration updated successfully!"
echo "Username:		$GitName" 
echo "Email:			$GitEmail"
echo "GPG signing key ID:	$gpg_status"

read -s -n 1 -p "Press any key to continue..." && exit 0