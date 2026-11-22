#!/bin/bash
[ -n "$BASH_VERSION" ] && set +H
cd "$(dirname "$0")" || exit

# Variables.
VARIABLES_FILE_NAME="Variables.conf"
VARIABLES_FILE="../Configs/$VARIABLES_FILE_NAME"
COMMANDS_FILE_NAME="Git-Login_Info.conf"
COMMANDS_FILE="../Configs/$COMMANDS_FILE_NAME"

# Functions.
is_enabled() {
	case "${1,,}" in
		1|true|yes|y|on) return 0 ;;
		*) return 1 ;;
	esac
}

expand_path() {
	local p="$1"
	if [[ "$p" == "~" ]]; then
		printf '%s\n' "$HOME"
	elif [[ "$p" == "~/"* ]]; then
		printf '%s\n' "$HOME/${p:2}"
	else
		printf '%s\n' "$p"
	fi
}

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
	read -r -s -p "Press [Enter] to continue..." && exit 1
fi

echo -e "Git-Login $Git_Login_Version\n"

# Confirmation.
while true; do
	read -r -e -p "Run this script? (Y/N) " confirmation
	case "$confirmation" in
		[Yy]* ) echo; break ;;
		[Nn]* ) echo -e "\nOperation cancelled by user.\n"; read -r -s -p "Press [Enter] to continue..."; exit 0 ;;
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

# SSH configuration.
ssh_status="Skipped"
raw_ssh_paths="${SSHKeysPaths:-$HOME/.ssh/id_ed25519}"
read -r -a ssh_key_list <<< "$raw_ssh_paths"
ssh_key_type="${SSHKeyType:-ed25519}"
ssh_key_comment="${SSHKeyComment:-$GitEmail}"
ready_ssh_keys=()
found_count=0
created_count=0
kept_count=0
missing_count=0

case "${SSHMode,,}" in
	1|existing)
		echo -e "\nChecking existing SSH keys..."
		for raw_key in "${ssh_key_list[@]}"; do
			resolved_key="$(expand_path "$raw_key")"
			echo "Checking '$resolved_key'..."
			if [ -f "$resolved_key" ]; then
				echo "Found existing SSH key: '$resolved_key'."
				ready_ssh_keys+=("$resolved_key")
				((found_count++))
			else
				echo "[WARNING]: SSH key not found at '$resolved_key'."
				((missing_count++))
			fi
		done

		if [ "$found_count" -gt 0 ] && [ "$missing_count" -eq 0 ]; then
			ssh_status="Using existing ($found_count key(s))"
		elif [ "$found_count" -gt 0 ]; then
			ssh_status="Partial ($found_count found, $missing_count missing)"
		else
			ssh_status="Missing ($missing_count key(s))"
		fi
		;;
	2|new)
		echo -e "\nCreating SSH keys ($ssh_key_type)..."
		for raw_key in "${ssh_key_list[@]}"; do
			resolved_key="$(expand_path "$raw_key")"
			mkdir -p "$(dirname "$resolved_key")"
			create_key=true

			if [ -e "$resolved_key" ]; then
				read -r -e -p "Key '$resolved_key' already exists. Overwrite? (y/N) " overwrite
				case "$overwrite" in
					[Yy]* ) create_key=true ;;
					* ) create_key=false; echo "Keeping existing key '$resolved_key'." ;;
				esac
			fi

			if [ "$create_key" = true ]; then
				if [ -n "$ssh_key_comment" ]; then
					ssh-keygen -t "$ssh_key_type" -f "$resolved_key" -C "$ssh_key_comment"
				else
					ssh-keygen -t "$ssh_key_type" -f "$resolved_key"
				fi
				if [ -f "$resolved_key" ]; then
					ready_ssh_keys+=("$resolved_key")
					((created_count++))
					if [ -f "${resolved_key}.pub" ]; then
						echo -e "\nPublic key (${resolved_key}.pub) - add this to GitHub / GitLab / Bitbucket:"
						cat "${resolved_key}.pub"
						echo
					fi
				else
					echo "[WARNING]: Key creation failed at '$resolved_key'."
					((missing_count++))
				fi
			elif [ -f "$resolved_key" ]; then
				ready_ssh_keys+=("$resolved_key")
				((kept_count++))
			else
				echo "[WARNING]: Key not found at '$resolved_key'."
				((missing_count++))
			fi
		done

		if [ "$missing_count" -eq 0 ] && { [ "$created_count" -gt 0 ] || [ "$kept_count" -gt 0 ]; }; then
			ssh_status="Ready ($created_count created, $kept_count kept)"
		elif [ "$created_count" -gt 0 ] || [ "$kept_count" -gt 0 ]; then
			ssh_status="Partial ($created_count created, $kept_count kept, $missing_count missing)"
		else
			ssh_status="Failed ($missing_count key(s))"
		fi
		;;
	0|skip|"")
		echo -e "\nSSH setup skipped."
		;;
	*)
		echo -e "\n[WARNING]: Unknown SSHMode '$SSHMode'. Skipping SSH setup."
		ssh_status="Invalid mode ($SSHMode)"
		;;
esac

if [ "${#ready_ssh_keys[@]}" -gt 0 ] && is_enabled "${SSHAddToAgent:-1}"; then
	if ! ssh-add -l >/dev/null 2>&1; then
		eval "$(ssh-agent -s)" >/dev/null
	fi
	for key_path in "${ready_ssh_keys[@]}"; do
		ssh-add "$key_path" 2>/dev/null && echo "Added '$key_path' to 'ssh-agent'."
	done
fi

# CLI.
echo -e "\nPress 'Ctrl+C' to skip an active login prompt."

# GitHub.
if is_enabled "${LoginGitHub:-1}"; then
	if command -v gh >/dev/null 2>&1; then
		echo "Logging into GitHub (gh)..."
		gh auth login
		github_status="Checked"
	else
		echo "[WARNING]: 'gh' CLI not found; skipping GitHub CLI login."
		github_status="CLI not installed"
	fi
else
	echo "Skipping GitHub login (LoginGitHub=$LoginGitHub)."
	github_status="Skipped"
fi

# GitLab.
if is_enabled "${LoginGitLab:-1}"; then
	if command -v glab >/dev/null 2>&1; then
		echo "Logging into GitLab (glab)..."
		glab auth login
		gitlab_status="Checked"
	else
		echo "[WARNING]: 'glab' CLI not found; skipping GitLab CLI login."
		gitlab_status="CLI not installed"
	fi
else
	echo "Skipping GitLab login (LoginGitLab=$LoginGitLab)."
	gitlab_status="Skipped"
fi

# Bitbucket.
if is_enabled "${LoginBitbucket:-0}"; then
	if command -v bkt >/dev/null 2>&1; then
		echo "Logging into Bitbucket (bkt)..."
		bkt auth login
		bitbucket_status="Checked (bkt)"
	elif command -v bb >/dev/null 2>&1; then
		echo "Logging into Bitbucket (bb)..."
		bb auth login
		bitbucket_status="Checked (bb)"
	else
		echo "No Bitbucket CLI ('bkt' or 'bb') found. Bitbucket Git over SSH uses your SSH key directly, or you can install 'bkt' / 'bb'."
		bitbucket_status="SSH / No CLI"
	fi
else
	echo "Skipping Bitbucket login (LoginBitbucket=$LoginBitbucket)."
	bitbucket_status="Skipped"
fi

# End.
echo -e "\nGit global configuration updated successfully!"
echo "Username:		$GitName"
echo "Email:		$GitEmail"
echo "GPG signing key ID:		$gpg_status"
echo "SSH key(s):		$ssh_status"
echo "GitHub login:		$github_status"
echo "GitLab login:		$gitlab_status"
echo "Bitbucket login:		$bitbucket_status"

read -r -s -p "Press [Enter] to continue..." && exit 0
