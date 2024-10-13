#!/usr/bin/env bash

# Error handling
trap 'catch $? $LINENO' ERR
catch() {
  if [ "$1" != 0 ]; then
    echo "Returned error code $1 on line $2" >&2
    echo "Exiting..." >&2
  fi
  exit "$1"
}

# Continue dialog
user_continue() {
  local choice
  while :; do
    read -rp "Press [y|Y] to continue, [n|N] to $1: " choice
    case "$choice" in
      y|Y) return 0;;
      n|N) return 1;;
    esac
  done
}

# Privilege de-escalation
if [ "$(id -u)" -lt 1000 ]; then
  echo "Do not run with a system account!" >&2
  echo "Exiting..." >&2
  exit 126
fi

# Begin
echo "Welcome to the nixos-anywhere script!"
echo "You will need to perform a couple manual steps before running this script"
echo "These are listed under https://github.com/cameronaw13/nix-dotfiles"
echo "Please complete these before running the script!"
echo
echo "Make sure you've audited the contents of this script before running!"
echo
echo "Note: It's recommended to run this within distrobox or your choice of container/virtualization"
echo "software to isolate the script from critical environments."
echo
user_continue "exit" && echo || exit 0

# Check if nix exists
if ! command -v nix; then
  echo "Cannot find nix installation. Nix will be automatically installed"
  user_continue "exit" && echo || exit 0

  # Install multi/single-user nix based on existance of systemd init directory
  [ -d /run/systemd/system ] && nix_option="--daemon" || nix_option="--no-daemon"
  echo "Installing nix in '$nix_option' mode"
  sh <(curl -L https://nixos.org/nix/install) "$nix_option"
  echo "Nix install completed!"

  echo "Restart your shell (eg: 'exec \"\$SHELL\"') and restart this script to continue"
  echo
  read -rsn 1 -p "(Press any key to exit...)"
  echo
  exit 129
fi
  
# Set options
while :; do
  read -rp "Set a directory to store nixos-anywhere templates: " dir_choice
  read -rp "Enter the user@ip_addr of the client machine: " addr_choice
  read -rp "Enter desired hostname for the client machine: " hostname_choice
  dir_choice="$(echo "$dir_choice" | sed -r "s@~@$HOME@g")"
  echo

  echo "Template Directory: '$dir_choice'"
  echo "Client Username & IP Address: '$addr_choice'"
  echo "Client Hostname: '$hostname_choice'"
  echo
  user_continue "repeat verification" && echo && break
done

# Variable setup
mkdir -p "$dir_choice"
mkdir -p "$HOME"/.ssh
if [ ! -f "$dir_choice"/client-key ]; then
  yes '' | ssh-keygen -t ed25519 -C "$USER@$HOSTNAME" -f "$dir_choice"/client-key
fi
ssh-copy-id -i "$dir_choice"/client-key "$addr_choice"

# Pull nixos-anywhere templates # TODO: Change branch to master when merged
wget -P "$dir_choice" -O "$dir_choice"/nix-dotfiles.zip https://github.com/cameronaw13/nix-dotfiles/archive/refs/heads/installation.zip
unzip -Bj "$dir_choice"/nix-dotfiles.zip "nix-dotfiles-installation/templates/nixos-anywhere/*" -d "$dir_choice"/templates

# Add ssh key to configuration.nix template
ssh_curr=$(( $(grep -n "openssh.authorizedKeys.keys" "$dir_choice"/templates/configuration.nix | cut -d: -f1) + 2 ))
sed -i "${ssh_curr}i \      \"$(cat "$dir_choice"/client-key.pub)\"" "$dir_choice"/templates/configuration.nix

# Check if client requires sudo password
if ! ssh -i "$dir_choice"/client-key "$addr_choice" -t "sudo -n true"; then
  echo "It seems that "$addr_choice" requires a sudo password!"
  echo "The installation does not recommend using an account that requires password for sudo."
  echo "To fix this issue, you can add config under 'security.sudo.extraRules' on the client."
  echo "Documentation can be found at 'https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/security/sudo.nix'."
  echo
  echo "If your client isn't running NixOS, you can add '{USER} ALL=(ALL) NOPASSWD: ALL' to"
  echo "your client's '/etc/sudoers' file through the 'sudo visudo' command."
  echo "Alternatively, you can use the client's root account instead as long as 'PermitRootLogin'"
  echo "is set to 'yes' under '/etc/ssh/sshd_config'."
  echo
  echo "If needed, use (Ctrl+Z) and 'fg' to suspend and continue the current script."
  echo
  user_continue "exit" && echo || exit 0
fi

# Pull disk-config.nix if hostname exists
hostname_dir="nix-dotfiles-installation/hosts/$hostname_choice"
if unzip -l "$dir_choice"/nix-dotfiles.zip | grep -q "$hostname_dir"; then
  unzip -Bj "$dir_choice"/nix-dotfiles.zip "$hostname_dir"/disk-config.nix -d "$dir_choice"/templates
  
  # Get list of defined disks from hostname's dotfiles
  IFS=" " read -ra disk_list <<< "$(nix-instantiate --strict --eval --expr 'with import <nixpkgs> { };
  lib.strings.concatStringsSep " " (lib.attrsets.mapAttrsToList (name: value: name) (
    import '"$dir_choice"'/templates/disk-config.nix { }
  ).disko.devices.disk)' | tr -d '"')"
  
  # Add disks to configuration.nix template
  disk_curr=$(( $(grep -n "disko.devices.disk" "$dir_choice"/templates/configuration.nix | cut -d: -f1) + 2 ))
  for disk in "${disk_list[@]}"; do
    sed -i "${disk_curr}i \    $disk.device = ...;" "$dir_choice"/templates/configuration.nix
    ((disk_curr++))
  done
# else
  # # Add template ESP size depending on UEFI support
  # esp_size=$(ssh -i "$dir_choice"/client-key "$addr_choice" -t -- \
  #   "! [ -d /sys/firmware/efi/efivars ]" && echo "64M" || echo "512M")
  # esp_curr=$(( $(grep -n "ESP" "$dir_choice"/templates/configuration.nix | cut -d: -f1) + 2 ))
  # sed -i "${esp_curr}i \              size = \"${esp_size}\";" "$dir_choice"/templates/disk-config.nix
fi
echo

# Add hostname & hostId to configuration.nix template
hostname_curr=$(grep -n "services.openssh.enable" "$dir_choice"/templates/configuration.nix | cut -d: -f1)
hostId=$(head -c4 /dev/urandom | od -A none -t x4 | tr -d " ")
sed -i "${hostname_curr}i\\
  networking.hostName = \"$hostname_choice\";\\
  networking.hostId = \"$hostId\";
" "$dir_choice"/templates/configuration.nix

# Print client block devices
while :; do
  echo "Do you want to print block device information from the client machine?"
  read -rp "(Client disk locations need to be manually added before install) [Y/n]: " block_choice
  echo
  case "$block_choice" in
    y|Y|"")
      ssh -i "$dir_choice"/client-key "$addr_choice" -t "sudo fdisk -l"
      echo
      echo "Block device information retrieved!"
      echo
      user_continue "exit" && echo || exit 0
      break
      ;;
    n|N)
      break
      ;;
  esac
done

# Final user verification
while :; do
  echo "Setup for nixos-anywhere is partially complete. You still need to verify the template files!"
  echo "Make sure to define 'disko.devices.disk' in templates/configuration.nix based on the"
  echo "client's block device layout to properly boot nixos."
  echo "templates/disk-config.nix may still need an implementation based on your configuration."
  echo
  echo "Suspend the script (Ctrl+Z) and cd into '$dir_choice/templates' to perform verification."
  echo "You can return to this script with 'fg', see builtins(1)."
  echo
  echo "Note: to edit files, you can use either 'nix run' or 'nix shell' with the"
  echo "'--experimental-features \"nix-command flakes\"' flag enabled to run packages"
  echo "More details of their usage are found using their '--help' flag"
  echo
  user_continue "exit" && echo || exit 0

  echo "Are you *completely* sure that everything is configured properly? ALL disks on"
  echo "'$hostname_choice' will be COMPLETELY ERASED if improperly set up!"
  echo
  user_continue "repeat verification" && echo && break
done

# Nixos-Anywhere
nix run --experimental-features "nix-command flakes" \
  github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config "$dir_choice"/templates/hardware-configuration.nix \
  --flake "$dir_choice"/templates#nixos-client \
  --extra-files "$dir_choice/templates" \
  -i "$dir_choice"/client-key \
  "$addr_choice"

# Remove old host identification
ssh-keygen -R "$addr_choice"

echo "Nixos is now installed!"
user_continue "exit" && echo || exit 0

# Run 'nixos-bootstrap.sh' on the client
ip_choice=$(echo "$addr_choice" | cut -d@ -f2)
#ssh -i "$dir_choice"/client-key bootstrap@"$addr_choice" -t -- "bash <(curl -sSL https://raw.githubusercontent.com/cameronaw13/nix-dotfiles/refs/heads/installation/nixos-bootstrap.sh)"

echo "Installation and boostrap completed! NixOS is now ready to use!"
echo
read -rn 1 -p "(Press any key to exit) "
exit 0
