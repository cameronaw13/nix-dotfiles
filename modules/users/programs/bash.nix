{ lib, config, ... }:
let
  homepkgs = config.local.homepkgs;
  username = config.home.username;
in
{
  options.local.homepkgs.bash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    scripts = {
      sudo = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      rebuild = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf homepkgs.bash.enable {
    programs.bash = {
      enable = lib.mkDefault true;
      bashrcExtra = lib.strings.concatStringsSep "\n" (
        lib.lists.optional (homepkgs.bash.scripts.sudo) ''
          alias sudo="sudo "
        '' ++
        lib.lists.optional (homepkgs.bash.scripts.rebuild && homepkgs.git.enable) ''
          alias rebuild="bash ~/Scripts/rebuild.sh"
        ''
      );
    };

    home.file.rebuild = lib.mkIf (homepkgs.bash.scripts.rebuild && homepkgs.git.enable) {
      enable = lib.mkDefault true;
      target = "Scripts/rebuild.sh";
      force = true;
      text = ''
        #!/usr/bin/env bash

        toplevel=$(git rev-parse --show-toplevel)
        if [ "$toplevel" != "/etc/nixos" ]; then
          echo "Please run within '/etc/nixos' directory"
          exit 1
        fi

        if [ -z $1 ]; then
          echo "No operation specified. Refer to nixos-rebuild(8)"
          exit 1
        fi
        
        git checkout ${homepkgs.hostname}
        git add -Av
        sudo nixos-rebuild $1 --option eval-cache=false
        
        message=$(git diff --cached --numstat)
        if [ "$message" = "" ]; then
          echo "No changes found, skipping commit..."
          exit 0
        fi

        git commit -m "nixos-rebuild: $1" -m "added   deleted"$'\n'"$message"
        git push origin ${homepkgs.hostname}
      '';
    };
  };
}
