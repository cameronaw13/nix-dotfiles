#!/usr/bin/env bash

# Error handling
trap 'catch $? $LINENO' ERR
catch() {
  if [ "$1" != 0 ]; then
    echo "| Returned error code $1 on line $2" >&2
    echo "| Exiting..." >&2
  fi
  exit "$1"
}

# Continue dialog
user_continue() {
  local choice
  while :; do
    read -rp "Press 'y' to continue, 'n' to $1: " choice
    case "$choice" in
      y|Y) return 0;;
      n|N) return 1;;
    esac
  done
}

# Privilege de-escalation
if [ "$(id -u)" -lt 1000 ]; then
  echo "| Do not run with a system account!" >&2
  echo "|"
  read -rn 1 -p "(Press any key to exit) "
  exit 126
fi

# Begin
echo "| Welcome to the nixos-anywhere script!"
echo "| You will need to perform a couple manual steps before running this script"
echo "| These are listed under https://github.com/cameronaw13/nix-dotfiles"
echo "| Please complete these before running the script!"
echo "|"
echo "| Make sure you've audited the contents of this script before running!"
echo "|"
echo "| Note: It's recommended to run this within distrobox or your choice of container/virtualization"
echo "| software to isolate the script from critical environments."
echo "|"
user_continue "exit" && echo || exit 0

# Check if nix exists
if ! command -v nix; then
  echo "| Cannot find nix installation. Nix will be automatically installed"
  echo "|"
  user_continue "exit" && echo || exit 0

  # Install multi/single-user nix based on existance of systemd init directory
  [ -d /run/systemd/system ] && nix_option="--daemon" || nix_option="--no-daemon"
  echo "| Installing nix in '$nix_option' mode"
  sh <(curl -L https://nixos.org/nix/install) "$nix_option"
  echo "| Nix install completed!"
  echo "| Restart your shell (eg: 'exec \"\$SHELL\"') and restart this script to continue"
  echo "|"
  read -rsn 1 -p "(Press any key to exit...)"
  echo
  exit 129
fi
  
# Set options
while :; do
  read -rp "Set a directory to store nixos-anywhere templates: " dir_choice
  read -rp "Enter the user@ip_addr of the client machine: " addr_choice
  read -rp "Enter desired hostname for the client machine: " hostname_choice
  dir_choice="$(realpath -m $(echo "$dir_choice" | sed -r "s@^~@$HOME@g"))"
  echo

  echo "| Template Directory: '$dir_choice'"
  echo "| Client Username & IP Address: '$addr_choice'"
  echo "| Client Hostname: '$hostname_choice'"
  echo "|"
  user_continue "repeat verification" && echo && break
done

# Variable setup
# TODO: Check if necessary programs are installed, nix run otherwise (a la nixos-bootstrap.sh)
expfeats=(--experimental-features "nix-command flakes")
template_dir="$dir_choice"/templates/nixos-anywhere
mkdir -p "$template_dir"
mkdir -p "$HOME"/.ssh
if [ ! -f "$dir_choice"/client-key ]; then
  ssh-keygen -t ed25519 -C "$USER@$HOSTNAME" -N "" -f "$dir_choice"/client-key
fi
ssh-copy-id -i "$dir_choice"/client-key "$addr_choice"

# Pull nixos-anywhere templates # TODO: Change branch to master when merged
wget -P "$dir_choice" -O "$dir_choice"/nix-dotfiles.zip https://github.com/cameronaw13/nix-dotfiles/archive/refs/heads/installation.zip
unzip -Bj "$dir_choice"/nix-dotfiles.zip "nix-dotfiles-installation/templates/nixos-anywhere/*" -d "$template_dir"

# Add ssh key to configuration.nix template
#ssh_curr=$(( $(grep -n "openssh.authorizedKeys.keys" "$template_dir"/configuration.nix | cut -d: -f1) + 2 ))
#sed -i "${ssh_curr}i \      \"$(cat "$dir_choice"/client-key.pub)\"" "$template_dir"/configuration.nix
nix run github:snowfallorg/nix-editor "${expfeats[@]}" -- "$template_dir"/configuration.nix users.users.bootstrap.openssh.authorizedKeys.keys --arr "  \"$(cat "$dir_choice"/client-key.pub)\"" --inplace


# Check if client requires sudo password
if ! ssh -i "$dir_choice"/client-key "$addr_choice" -t "sudo -n true"; then
  echo "| It seems that "$addr_choice" requires a sudo password!"
  echo "| The installation does not recommend using an account that requires password for sudo."
  echo "| Follow Step 3 under 'Setup' in the README to fix this issue: https://github.com/cameronaw13/nix-dotfiles/tree/installation?tab=readme-ov-file#setup"
  echo "|"
  echo "| If needed, use (Ctrl+Z) and 'fg' to suspend and resume the script."
  echo "|"
  user_continue "exit" && echo || exit 0
fi

# Print client filesystem
echo "| Client filesystem will be printed in the next step. Take note of this info, block device paths"
echo "| need to be manually declared during the installation!"
echo "|"
read -rn 1 -p "(Press any key to continue) "
echo
printf "%.s=" $(seq 1 $(tput cols))
ssh -i "$dir_choice"/client-key "$addr_choice" -t "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,PARTTYPENAME,FSTYPE,PATH,MODEL"
printf "%.s=" $(seq 1 $(tput cols))
echo
echo "| Successfully fetched filesystem info!"
echo "|"
read -rn 1 -p "(Press any key to continue) "

# Pull disk-config.nix if hostname exists
# TODO: Cleanup, shouldn't be this many for loops
hostname_dir="nix-dotfiles-installation/hosts/$hostname_choice"
if unzip -l "$dir_choice"/nix-dotfiles.zip | grep -q "$hostname_dir"; then
  unzip -Bj "$dir_choice"/nix-dotfiles.zip "$hostname_dir"/disk-config.nix -d "$template_dir"
  
  # Get list of defined disks from hostname's dotfiles
  IFS=" " read -ra disk_list <<< "$(nix-instantiate --strict --eval --expr 'with import <nixpkgs> { };
  lib.strings.concatStringsSep " " (lib.attrsets.mapAttrsToList (name: value: name) (
    import '"$template_dir"'/disk-config.nix { }
  ).disko.devices.disk)' | tr -d '"')"

  # Create input dialog for block device paths
  for i in "${!disk_list[@]}"; do
    dialog_items+=("${disk_list["$i"]}:" $(( "$i"+3 )) 1 "" $(( "$i"+3 )) 20 20 0)
  done
  disk_paths=$(dialog --colors --erase-on-exit --title "Declare Installation Disks" --form "\\ZbInsert the block device path of each disk" $(( "${#dialog_items[@]}"+9 )) 60 0 "Example:" 1 1 "/dev/sda" -20 20 0 "${dialog_items[@]}" 2>&1 >/dev/tty)
  
  # TODO: Substitute basic block device names with full ids to prevent reodering issues
  # for disks with multiple ids, a radiolist will pop up for each disk; user chooses the desired id to insert into the config
  # eg: udevadm info --no-pager --root --query symlink /dev/sda | grep -Po "/dev/disk/by-id/[A-Za-z0-9\-\_]+"

  # TODO: Add user verification before adding disks to config
  
  # Add disks to configuration.nix template
  #disk_curr=$(( $(grep -n "disko.devices.disk" "$template_dir"/configuration.nix | cut -d: -f1) + 2 ))
  for i in "${!disk_list[@]}"; do
    #sed -i "${disk_curr}i \    $disk.device = \"XXXXX\";" "$template_dir"/configuration.nix
    nix run github:snowfallorg/nix-editor "${expfeats[@]}" -- "$template_dir"/configuration.nix disko.devices.disk."${disk_list["$i"]}".device --val "\"XXXXX\"" --inplace
    ((disk_curr++))
  done
fi
echo

# Add hostname & hostId to configuration.nix template
hostname_curr=$(grep -n "services.openssh.enable" "$template_dir"/configuration.nix | cut -d: -f1)
hostId=$(head -c4 /dev/urandom | od -A none -t x4 | tr -d " ")
#sed -i "${hostname_curr}i\\
#  networking.hostName = \"$hostname_choice\";\\
#  networking.hostId = \"$hostId\";
#" "$template_dir"/configuration.nix
nix run github:snowfallorg/nix-editor "${expfeats[@]}" -- "$template_dir"/configuration.nix networking.hostName --val "\"$hostname_choice\"" --inplace
nix run github:snowfallorg/nix-editor "${expfeats[@]}" -- "$template_dir"/configuration.nix networking.hostId --val "\"$hostId\"" --inplace

# Add hostname to flake.nix template
sed -i "s/HOSTNAME/$hostname_choice/g" "$template_dir"/flake.nix

# Final user verification
while :; do
  echo "| Setup for nixos-anywhere is partially complete. You still need to verify the template files!"
  echo "| Make sure to define 'disko.devices.disk' in templates/configuration.nix based on the"
  echo "| client's block device layout to properly boot nixos."
  echo "| templates/disk-config.nix may still need an implementation based on your configuration."
  echo "|"
  echo "| Suspend the script (Ctrl+Z) and cd into '$template_dir' to perform verification."
  echo "| You can return to this script with 'fg', see builtins(1)."
  echo "|"
  user_continue "exit" && echo || exit 0

  echo "| Are you *completely* sure that everything is configured properly? ALL disks on"
  echo "| '$addr_choice' will be COMPLETELY ERASED if improperly set up!"
  echo "|"
  user_continue "repeat verification" && echo && break
done

# Nixos-Anywhere
nix run github:nix-community/nixos-anywhere "${expfeats[@]}" -- \
  --generate-hardware-config nixos-generate-config "$template_dir"/hardware-configuration.nix \
  --flake "$template_dir"#"$hostname_choice" \
  --extra-files "$dir_choice"/templates \
  -i "$dir_choice"/client-key \
  "$addr_choice"

# Remove old host identification
ip_choice=$(echo "$addr_choice" | cut -d@ -f2)
ssh-keygen -R "$ip_choice"

echo "| Nixos is now installed!"
echo "|"
user_continue "exit" && echo || exit 0

# Run 'nixos-bootstrap.sh' on the client
#ssh -i "$dir_choice"/client-key bootstrap@"$ip_choice" -t -- "bash <(curl -sSL https://raw.githubusercontent.com/cameronaw13/nix-dotfiles/refs/heads/installation/nixos-bootstrap.sh)"

echo "| Installation and boostrap completed! NixOS is now ready to use!"
echo "|"
read -rn 1 -p "(Press any key to exit) "
echo
exit 0
