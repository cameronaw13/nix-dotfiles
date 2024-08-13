# MIT Jörg Thalheim - https://github.com/Mic92/dotfiles/blob/c6cad4e57016945c4816c8ec6f0a94daaa0c3203/nixos/modules/upgrade-diff.nix
{ config, pkgs, ... }:
{
  system.activationScripts = {
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
    /*git = {
      supportsDryActivation = false;
      text = let 
        git = "${pkgs.gitMinimal}/bin/git";
        hostname = config.networking.hostName;
      in ''
        ${git} checkout ${hostname}
        ${git} add -Av
        message=$(${git} diff --cached --stat)
        if [ "$message" != "" ]; then
          ${git} commit -m "$message"
          ${git} push origin ${hostname}
        else
          echo "No changes, skipping commit..."
        fi
      '';
    };*/
  };
}
