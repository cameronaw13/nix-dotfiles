# MIT Jörg Thalheim - https://github.com/Mic92/dotfiles/blob/c6cad4e57016945c4816c8ec6f0a94daaa0c3203/nixos/modules/upgrade-diff.nix
{ config, pkgs, ... }:
{
  system.activationScripts = {
    # TODO: Iterate through each user in /home, check if ~/.config/sops/age/keys.txt exists, if not, gen key and add to key list, afterwards insert all gen'd keys into .sops.yaml and regen secrets.yaml with added keys
    genSecrets = {
      text = ''
        echo "TODO"
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
