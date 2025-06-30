# MIT Jörg Thalheim - https://github.com/Mic92/dotfiles/blob/c6cad4e57016945c4816c8ec6f0a94daaa0c3203/nixos/modules/upgrade-diff.nix
# TODO 2: For each user defined in local.users, perform switch against the sopsNix boolean
  # If sopsNix == false && /home/"$user"/.config/sops/age/keys.txt exists:
    # Delete the keys.txt file
    # Remove "$HOSTNAME"_"$user" from .sops.yaml
    # Regenerate secrets.yaml
  # If sopsNix == true && /home/"$user"/.config/sops/age/keys.txt doesn't exist:
    # Generate new age key as the keys.txt file
    # Add "$HOSTNAME"_"$user" to .sops.yaml
    # Regenerate secrets.yaml

{ lib, config, pkgs, ... }:
{
  system.activationScripts = let
    inherit (config.networking) hostName;
    userList = lib.strings.concatStringsSep " " (lib.attrsets.mapAttrsToList (name: value: "[${name}]='${lib.trivial.boolToString value.sopsNix}'") config.local.users);
  in {
    genUserkeys = {
      text = let
        yq = "${pkgs.yq-go}/bin/yq";
        age = "${pkgs.age}/bin/age-keygen";
        ssh-to-age = "${pkgs.ssh-to-age}/bin/ssh-to-age";
        sops = "${pkgs.sops}/bin/sops";
        sudo = "${pkgs.sudo}/bin/sudo";
      in ''
        secretsDir="/etc/nixos/secrets"
        declare -A userList=(${userList})
        for name in "''${!userList[@]}"; do
          keyFile="/home/$name/.config/sops/age/keys.txt"
          case "''${userList[$name]}" in
            false)
              if [ -f "$keyFile" ]; then
                rm "$keyFile"
                ${yq} -i 'del(.keys.[] | select(. | anchor == "'$HOSTNAME'_'$name'")) | del(.creation_rules[0].key_groups[0].age.[] | select(. | alias == "'$HOSTNAME'_'$name'"))' "$secretsDir/.sops.yaml"
              fi
              ;;
            true)
              if [ ! -f "$keyFile" ]; then
                ${sudo} -u "$name" mkdir -p /home/$name/.config/sops/age
                ${sudo} -u "$name" ${age} -o "$keyFile" 2>/dev/null
                currKey="$(${age} -y "$keyFile")"
                ${yq} -i '.keys += ("'$currKey'" | . anchor = "'$HOSTNAME'_'$name'") | .creation_rules[0].key_groups[0].age += ((.keys[-1] | anchor) | . alias |= .)' "$secretsDir/.sops.yaml"
              fi
              ;;
          esac
        done
        hostKey="$(${ssh-to-age} -private-key -i /etc/ssh/ssh_host_ed25519_key)"
        env SOPS_AGE_KEY="$hostKey" ${sops} --config "$secretsDir/.sops.yaml" updatekeys --yes "$secretsDir/secrets.yaml"
      '';
    };
    diff = {
      supportsDryActivation = true;
      text = let
        nvd = "${pkgs.nvd}/bin/nvd";
      in ''
        if [[ -e /run/current-system ]]; then
          ${nvd} --nix-bin-dir=${config.nix.package}/bin diff /run/current-system "$systemConfig"
        fi
      '';
    };
  };
}
