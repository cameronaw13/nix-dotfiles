#!/usr/bin/env bash

# Error handling
# TODO: Consider perl for actual error handling
set -E
trap 'catch $? $LINENO' ERR
catch() {
  if [ "$1" != 0 ]; then
    echo "| Returned error code $1 on line $2" >&2
    echo "| Exiting..." >&2
  fi
  rm "$tmp_blk" || true
  rm -rf "$tmp_repo" || true
  exit "$1"
}

# User input
user_choice() {
  # Note: cannot handle errors through trap
  local choice
  while :; do
    read -rp "- Press 'y' to continue, 'n' to $1: " choice
    case "$choice" in
      y|Y) return 0;;
      n|N) return 1;;
    esac
  done
}
user_verify() {
  read -rsn 1 -p "- (Press any key to $1) "
  echo
}

# Privilege de-escalation
if [ "$(id -u)" -lt 1000 ]; then
  echo "| Do not run with a system account!" >&2
  echo "|"
  user_verify "exit..."
  exit 126
fi

# Check if nix exists
if ! type -P nix; then
  echo "| Cannot find nix installation! Nix will be automatically installed..."
  echo "|"
  echo "| Note: The nix installation is very annoying to remove manually, make sure you're running in"
  echo "| a container or virtualized environment!"
  echo "|"
  user_choice "exit" || exit 0
  #dlg_nixmsg1=$(
  #  echo "| Cannot find nix installation!"
  #  echo "| Nix will be automatically installed..."
  #)
  #"${dialog[@]}" "${dlg_flags[@]}" \
  #  --yes-label "Continue" --no-label "Exit" \
  #  --yesno "$dlg_nixmsg1" 0 0 \
  #|| exit 0
  
  # Check for tcp command
  if type -P curl; then
    fetch=(curl -L )
  elif type -P wget; then
    fetch=(wget -q -O - )
  else
    echo "| Neither 'wget' nor 'curl' was found! Please install one of the two before continuing..."
    echo "|"
    user_verify "exit..."
    exit 127
  fi

  # Install multi-user nix if init exists, else single-user nix 
  [ -d /run/systemd/system ] && nix_mode="--daemon" || nix_mode="--no-daemon"
  echo "| Installing nix in '$nix_mode' mode"
  sh <("${fetch[@]}" https://nixos.org/nix/install) "$nix_mode"
  echo "| Nix install completed!"
  echo "| Restart your shell (eg: 'exec \"\$SHELL\"') and rerun this script to continue"
  echo "|"
  user_verify "exit..."
  #dlg_nixmsg2=$(
  #  echo "| Nix install completed!"
  #  echo "| Restart your shell (eg: 'exec \"\$SHELL\"') and restart this script to continue"
  #)
  #"${dialog[@]}" "${dlg_flags[@]}" --msgbox "$dlg_nixmsg2" 0 0
  exit 129
fi

# Set variables
dlg_flags=(--keep-tite --colors --no-mouse --no-collapse)
nix_flags=(--experimental-features "nix-command flakes")
type -P dialog && dialog="dialog" || dialog=(nix run nixpkgs\#dialog "${nix_flags[@]}" -- )
type -P git && git="git" || git=(nix run nixpkgs\#gitMinimal "${nix_flags[@]}" -- )
type -P jq && jq="jq" || jq=(nix run nixpkgs\#jq "${nix_flags[@]}" -- )
nix_editor=(nix run github:snowfallorg/nix-editor "${nix_flags[@]}" -- )

# Greeting message
dlg_greetmsg=$(
  echo "| Welcome to the nixos-anywhere script!";
  echo "| You'll need to perform a few manual steps before running this script.";
  echo "| These are documented under:";
  echo "- https://github.com/cameronaw13/nix-dotfiles/tree/installation?tab=readme-ov-file#setup";
  echo "| Please go through each step before running the script!";
  echo "|";
  echo "| Make sure you've audited the installation scripts and their dependencies before running";
  echo "| on real hardware!";
  echo "|";
  echo "| Note: It's recommended to run this within Distrobox or your choice of container/virtualization";
  echo "| software to isolate the script from critical environments.";
)
"${dialog[@]}" "${dlg_flags[@]}" \
  --yes-label "Continue" --no-label "Exit" \
  --yesno "$dlg_greetmsg" 0 0 \
|| exit 0

# Set options
while :; do
  #read -rp "Set a directory to store nixos-anywhere templates: " dir_choice
  #read -rp "Enter the user@ip_addr of the client machine: " addr_choice
  #read -rp "Enter desired hostname for the client machine: " host_choice
  dlg_optstitle="| Enter the required options to start the installation"
  dlg_optsout=$("${dialog[@]}" "${dlg_flags[@]}" \
    --ok-label "Continue" --cancel-label "Exit" \
    --form "$dlg_optstitle" 0 0 0 \
    "| Set a directory to store nixos-anywhere templates:" 1 1 "${dlg_optslist[0]}" 1 55 30 0 \
    "| Enter the user@ip_addr of the client machine:" 2 1 "${dlg_optslist[1]}" 2 55 30 0 \
    "| Enter the desired hostname for the client machine:" 3 1 "${dlg_optslist[2]}" 3 55 30 0 \
  2>&1 >/dev/tty) || exit 0
  readarray -t dlg_optslist <<< "$dlg_optsout"

  unset isEmpty
  for (( i=0 ; i <= 2 ; i++ )); do
    [ -z "${dlg_optslist["$i"]}" ] && isEmpty=true
  done
  if [ "$isEmpty" ]; then
    "${dialog[@]}" "${dlg_flags[@]}" \
      --ok-label "Return" \
      --msgbox "| One or more items are empty!" 5 34
    continue
  fi

  unset dlg_dirmsg
  dir_choice=$(realpath -m "$(echo "${dlg_optslist[0]}" | sed -r "s@^~@$HOME@g")")
  if [ -e "$dir_choice" ] && ! [ -d "$dir_choice" ]; then
    dlg_dirmsg=$(
      echo "| '$dir_choice' is an existing file!"
      echo "| Do you want to overwrite this file?"
    )
  elif [ -z "$(find "$dir_choice" -prune -empty -type d || echo "DNE")" ]; then
    dlg_dirmsg=$(
      echo "| '$dir_choice' is an existing non-empty directory!"
      echo "| Do you want to continue using this directory?"
    )
  fi
  if [ -n "$dlg_dirmsg" ]; then
    "${dialog[@]}" "${dlg_flags[@]}" \
      --aspect 12 --no-label "Return" \
      --yesno "$dlg_dirmsg" 0 0 \
    || continue
  fi
  
  addr_choice="${dlg_optslist[1]}"
  echo "Probing address '$addr_choice'..."
  addr_check=$(ssh -o BatchMode=yes -o ConnectionAttempts=1 -o ConnectTimeout=20 "$addr_choice" 2>&1) || true
  if echo "$addr_check" | grep -q \
    -e "No route to host" \
    -e "Name or service not known" \
    -e "Connection timed out" \
  ; then
    "${dialog[@]}" "${dlg_flags[@]}" \
      --aspect 12 --ok-label "Return" \
      --msgbox "| No host found under address '$addr_choice'!" 0 0
    continue
  fi
  
  host_choice="${dlg_optslist[2]}"
  
  #dir_choice="$(realpath -m "$(echo "$dir_choice" | sed -r "s@^~@$HOME@g")")"
  #echo

  #echo "| Template Directory: '$dir_choice'"
  #echo "| Client Username & IP Address: '$addr_choice'"
  #echo "| Client Hostname: '$host_choice'"
  #echo "|"
  #user_choice "repeat option setup" && echo && break
  dlg_optsmsg=$(
    echo "| Template Directory: '$dir_choice'"
    echo "| Client Username & IP Address: '$addr_choice'"
    echo "| Client Hostname: '$host_choice'"
    echo "|"
    echo "| Do you wish to continue?"
  )
  "${dialog[@]}" "${dlg_flags[@]}" \
    --yes-label "Continue" --no-label "Return" \
    --yesno "$dlg_optsmsg" 0 0 \
  && break
done

# Variable setup
# TODO: Check if necessary programs are installed, nix run otherwise (a la nixos-bootstrap.sh)
tmp_repo=$(mktemp -d)
templates="$dir_choice"/templates/nixos-anywhere
"${git[@]}" clone --branch installation --no-checkout --depth 1 https://github.com/cameronaw13/nix-dotfiles.git "$tmp_repo"
rm "$dir_choice" || true
mkdir -p "$dir_choice"
mv -f --backup=numbered "$tmp_repo"/.git "$dir_choice"
rmdir "$tmp_repo"

origPWD="$PWD"
dir_sublist=(templates hosts)
for dir in "${dir_sublist[@]}"; do
  if [ -d "$dir_choice"/"$dir" ]; then
    dlg_submsg=$(
      echo "| '$dir_choice' already includes a '$dir' folder"
      echo "| Do you wish to overwrite this?"
    )
    "${dialog[@]}" "${dlg_flags[@]}" \
      --aspect 15 \
      --yesno "$dlg_submsg" 0 0 \
    || continue
  fi
  cd "$dir_choice" || exit 1
  "${git[@]}" restore --worktree --staged "$dir"
  cd "$origPWD" || exit 1
done

mkdir -p "$HOME"/.ssh
if [ ! -f "$dir_choice"/client-key ]; then
  ssh-keygen -t ed25519 -C "$USER@$HOSTNAME" -N "" -f "$dir_choice"/client-key
fi
ssh-copy-id -i "$dir_choice"/client-key "$addr_choice"

# Copy nix-dotfiles repo # TODO: Change branch to master when merged
#wget -P "$dir_choice" -O "$dir_choice"/nix-dotfiles.zip https://github.com/cameronaw13/nix-dotfiles/archive/refs/heads/installation.zip
#unzip -Bj "$dir_choice"/nix-dotfiles.zip "nix-dotfiles-installation/templates/nixos-anywhere/*" -d "$templates"

# Add ssh key to configuration.nix template
"${nix_editor[@]}" "$templates"/configuration.nix users.users.bootstrap.openssh.authorizedKeys.keys --arr "  \"$(cat "$dir_choice"/client-key.pub)\"" --inplace

# Check if client requires sudo password
if ! ssh -i "$dir_choice"/client-key "$addr_choice" -t sudo -n true; then
  dlg_usermsg=$(
    echo "| It seems that '$addr_choice' requires a sudo password!";
    echo "| The installation requires this account to have passwordless sudo.";
    echo "|"
    echo "| Follow Step 3 under 'Setup' in the README to fix this issue:";
    echo "- https://github.com/cameronaw13/nix-dotfiles/tree/installation?tab=readme-ov-file#setup";
    echo "|";
    echo "| If needed, press (Ctrl+Z) and use the 'fg' command to suspend and resume the script.";
    echo "|";
  )
  "${dialog[@]}" "${dlg_flags[@]}" \
    --aspect 10 --ok-label "Continue" \
    --msgbox "$dlg_usermsg" 0 0
fi

# Check if creating a new host under the client
#host_dir="nix-dotfiles-installation/hosts/$host_choice"
#is_newhost=true
#if unzip -l "$dir_choice"/nix-dotfiles.zip | grep -q "$host_dir"; then
if [ -d "$dir_choice"/hosts/"$host_choice" ]; then
  #echo "| It seems that the '$host_choice' host is already defined in nix-dotfiles!"
  #echo "| Do you want to copy $host_choice's disk-config?"
  #echo "|"
  #if user_choice "skip"; then
  #  clone_host=true
  #fi
  dlg_clonemsg=$(
    echo "| It seems that the '$host_choice' host is already defined in nix-dotfiles."
    echo "| Do you want to copy $host_choice's disk-config?"
  )
  "${dialog[@]}" "${dlg_flags[@]}" \
    --aspect 12 \
    --yesno "$dlg_clonemsg" 0 0 \
  && clone_host=true
fi

# Obtain client's filesystem in tempfile
tmp_blk=$(mktemp)
ssh -i "$dir_choice"/client-key "$addr_choice" \
  -t lsblk -o PATH,SIZE,TYPE,MOUNTPOINT,PARTTYPENAME,FSTYPE,MODEL --json --tree \
  | "${jq[@]}" | sed -r "s/null/---/g" > "$tmp_blk"

# Pull disk-config.nix if host already exists
if ! [ "$clone_host" ]; then
  # TODO: Move to verification to allow moving back & forth
  "${dialog[@]}" "${dlg_flags[@]}" \
    --exit-label "Continue" \
    --textbox "$tmp_blk" 0 0
else
  # Unzip host's disk-config
  #unzip -Bj "$dir_choice"/nix-dotfiles.zip "$host_dir"/disk-config.nix -d "$templates"
  cp -f --backup=numbered "$dir_choice/hosts/$host_choice/disk-config.nix" "$templates" 
  
  # Get list of defined disks from hostname's dotfiles
  IFS=" " read -ra disk_list <<< "$(nix-instantiate --strict --eval --expr 'with import <nixpkgs> { };
  lib.strings.concatStringsSep " " (lib.attrsets.mapAttrsToList (name: value: name) (
    import '"$templates"'/disk-config.nix { }
  ).disko.devices.disk)' | tr -d '"')"

  # Dialog setup
  #dlg_idisk=0
  #dlg_diskflags=("example-disk:" 1 1 "/dev/sda" 1 20 -20 0)
  #for i in "${!disk_list[@]}"; do
  #  dlg_diskflags+=("${disk_list["$i"]}:" $(( "$i"+3 )) 1 "${disk_pathlist["$i"]}" $(( "$i"+3 )) 20 20 0)
  #done

  set -x
  # Dialog session
  dlg_idisk=0
  trap 'rm "$tmp_blk" && exit "$1"' SIGINT
  while :; do 
    case "$dlg_idisk" in
      # NOTE: chosen pre/post operators avoids falsey error codes
      0)
        # Client lsblk output
        "${dialog[@]}" "${dlg_flags[@]}" \
          --exit-label "Continue" \
          --textbox "$tmp_blk" 0 0
        (( ++dlg_idisk ))
        ;;
      1)
        # Disk path user input
        dlg_disktitle="For each disk defined in the '$host_choice' config, define an installation path"
        dlg_diskflags=("example-disk:" 1 1 "/dev/sda" 1 20 -20 0)
        for i in "${!disk_list[@]}"; do
          dlg_diskflags+=("${disk_list["$i"]}:" $(( "$i"+3 )) 1 "${disk_pathlist["$i"]}" $(( "$i"+3 )) 20 20 0)
        done

        disk_pathout=$("${dialog[@]}" "${dlg_flags[@]}" \
          --ok-label "Continue" --cancel-label "Go Back" \
          --form "$dlg_disktitle" 0 0 0 "${dlg_diskflags[@]}" \
        2>&1 >/dev/tty) || (( dlg_idisk-- )) 
        readarray -t disk_pathlist <<< "$disk_pathout"
        if [ -n "$(echo "${disk_pathlist[*]}" | tr -d ' ')" ]; then
          dlg_ipath=0
          (( ++dlg_idisk ))
        fi
        ;;
      2)
        # Full path user choices
        # TODO: replace ids with keypair list where keys=index w/ path to avoid decrement loop
        if (( "$dlg_ipath" >= "${#disk_pathlist[@]}" )); then
          while :; do
            (( dlg_ipath-- ))
            [ -n "${disk_pathlist["$dlg_ipath"]}" ] || (( "$dlg_ipath" < 0 )) && break
          done
          (( ++dlg_idisk ))
        elif (( "$dlg_ipath" < 0 )); then
          (( --dlg_idisk ))
        elif [ -z "${disk_pathlist["$dlg_ipath"]}" ]; then
          (( ++dlg_ipath ))
        else
          readarray -t disk_idlist < <(ssh -i "$dir_choice"/client-key "$addr_choice" \
            -t udevadm info --no-pager --root --query symlink "${disk_pathlist["$dlg_ipath"]}" \
            | grep -Po "/dev/disk/by-id/[A-Za-z0-9\-\_]+")
          if [ -z "${disk_idlist[*]}" ]; then
            "${dialog[@]}" "${dlg_flags[@]}" \
              --msgbox "Disk path '${disk_pathlist["$dlg_ipath"]}' is invalid!" 0 0
            dlg_ipath=-1
          else
            unset dlg_idflags
            disk_idlist+=("${disk_pathlist["$dlg_ipath"]}")
            for id in "${disk_idlist[@]}"; do
              IFS=" " read -ra dlg_idflags <<< "${dlg_idflags[*]} $id off"
            done

            if ! disk_finalpaths["$dlg_ipath"]=$("${dialog[@]}" "${dlg_flags[@]}" \
              --no-items --cancel-label "Go Back" \
              --radiolist "Select a path for '${disk_list["$dlg_ipath"]}':\n(Id paths are recommended)" 0 0 0 \
              "${dlg_idflags[@]}" \
            2>&1 >/dev/tty); then
              while :; do
                (( --dlg_ipath ))
                [ -n "${disk_pathlist["$dlg_ipath"]}" ] || (( "$dlg_ipath" < 0 )) && break
              done
            elif [ -n "${disk_finalpaths["$dlg_ipath"]}" ]; then
              (( ++dlg_ipath ))
            fi
          fi
        fi
        ;;
      3)
        # Confirm final paths
        dlg_diskmsg=$(
          echo "| Confirming installation paths for $host_choice's disk-config:";
          echo "|";
          for i in "${!disk_list[@]}"; do
            echo "| ${disk_list["$i"]}: '${disk_finalpaths["$i"]}'";
          done
        )
        if "${dialog[@]}" "${dlg_flags[@]}" \
          --yes-label "Confirm" --no-label "Go Back" \
          --yesno "$dlg_diskmsg" 0 0 \
        ; then
          (( ++dlg_idisk ))
        else
          (( --dlg_idisk ))
        fi
        ;;
      *)
        rm "$tmp_blk"
        break
        ;;
    esac
  done
  trap SIGINT

  # Add disks to configuration.nix template
  for i in "${!disk_list[@]}"; do
    "${nix_editor[@]}" "$templates"/configuration.nix disko.devices.disk."${disk_list["$i"]}".device --val "\"${disk_finalpaths["$i"]}\"" --inplace
    (( ++disk_curr ))
  done
fi
echo

# Add hostname & hostId to configuration.nix template
#hostname_curr=$(grep -n "services.openssh.enable" "$templates"/configuration.nix | cut -d: -f1)
hostId=$(head -c4 /dev/urandom | od -A none -t x4 | tr -d " ")
"${nix_editor[@]}" "$templates"/configuration.nix networking.hostName --val "\"$host_choice\"" --inplace
"${nix_editor[@]}" "$templates"/configuration.nix networking.hostId --val "\"$hostId\"" --inplace

# Add hostname to flake.nix template
sed -i "s/NEW_HOSTNAME/$host_choice/g" "$templates"/flake.nix

# Final user verification
while :; do
  #echo "| Setup for nixos-anywhere is partially complete. You still need to verify the template files!"
  #echo "| Make sure to define 'disko.devices.disk' in templates/configuration.nix based on the"
  #echo "| client's block device layout to properly boot nixos."
  #echo "| templates/disk-config.nix may still need an implementation based on your configuration."
  #echo "|"
  #echo "| Suspend the script (Ctrl+Z) and cd into '$templates' to perform verification."
  #echo "| You can return to this script with 'fg', see builtins(1)."
  #echo "|"
  #user_verify "continue..."

  #echo "| Are you *completely* sure that everything is configured properly? ALL disks on"
  #echo "| '$addr_choice' will be COMPLETELY ERASED if improperly set up!"
  #echo "|"
  #user_choice "repeat verification" && echo && break
  dlg_verifymsg1=$(
    echo "| Setup for nixos-anywhere is partially complete. You still need to verify the template files!"
    echo "|"
    echo "| If this is a new host or the previous host's disk-config wasn't copied, make sure to define"
    echo "| 'templates/disk-config.nix' and 'disk.devices.disk' within 'templates/configuration.nix' to"
    echo "| properly boot nixos!"
    echo "|"
    echo "| Suspend the script (Ctrl+Z) and cd into '$templates' to perform the verification."
    echo "| You can return to this script with 'fg', see builtins(1)."
  )
  "${dialog[@]}" "${dlg_flags[@]}" \
    --aspect 12 --ok-label "Continue" \
    --msgbox "$dlg_verifymsg1" 0 0

  dlg_verifymsg2=$(
    echo "| Are you *completely* sure that everything is configured properly? ALL disks on"
    echo "| '$addr_choice' will be COMPLETELY ERASED if improperly set up!"
  )
  "${dialog[@]}" "${dlg_flags[@]}" \
    --aspect 15 --no-label "Go Back" \
    --yesno "$dlg_verifymsg2" 0 0 \
  && break
done

# Nixos-Anywhere
nix run github:nix-community/nixos-anywhere "${nix_flags[@]}" -- \
  --generate-hardware-config nixos-generate-config "$templates"/hardware-configuration.nix \
  --flake "$templates"#"$host_choice" \
  --extra-files "$dir_choice"/templates \
  -i "$dir_choice"/client-key \
  "$addr_choice"

# Remove old host identification
ip_choice=$(echo "$addr_choice" | cut -d@ -f2)
ssh-keygen -R "$ip_choice"

#echo "| Nixos is now installed!"
#echo "|"
#user_verify "continue..."
dlg_donemsg=$(
  echo "| Nixos is now installed on '$ip_choice'!"
  echo "| You can continue to automatically run the bootstrap script or exit to"
  echo "| perform the setup manually"
)
"${dialog[@]}" "${dlg_flags[@]}" \
  --yes-label "Continue" --no-label "Exit" \
  --yesno "$dlg_donemsg" 0 0 \
|| exit 0

# Run 'nixos-bootstrap.sh' on the client
#ssh -i "$dir_choice"/client-key bootstrap@"$ip_choice" \
#  -t bash <(curl -sSL https://raw.githubusercontent.com/cameronaw13/nix-dotfiles/refs/heads/installation/nixos-bootstrap.sh)

#echo "| Installation and boostrap completed! NixOS is now ready to use!"
#echo "|"
#user_verify "exit..."
"${dialog[@]}" "${dlg_flags[@]}" \
  --ok-label "Exit" \
  --msgbox "| The installation and bootstrap is done! NixOS is now ready to use!" 0 0
exit 0
