{ lib, config, ... }:
let
  inherit (config.local) homepkgs;
  inherit (homepkgs.bash) scripts;
in
{
  options.local.homepkgs.bash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    scripts = {
      sudo = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
      rebuild = {
        enable = lib.mkOption {
          type = lib.types.addCheck lib.types.bool (x: !x || homepkgs.git.enable);
          default = false;
        };
        path = lib.mkOption {
          type = lib.types.path;
          default = "/etc/nixos";
        };
      };
    };
  };

  config = lib.mkIf homepkgs.bash.enable {
    programs.bash = {
      enable = lib.mkDefault true;
      bashrcExtra = lib.strings.concatStringsSep "\n" (
        lib.lists.optional scripts.sudo.enable ''
          alias sudo="sudo "
        '' ++
        lib.lists.optional scripts.rebuild.enable ''
          alias rebuild="bash ~/Scripts/rebuild.sh"
        ''
      );
    };

    home.file.rebuild = lib.mkIf scripts.rebuild.enable {
      enable = lib.mkDefault true;
      target = "Scripts/rebuild.sh";
      force = true;
      text = ''
        #!/usr/bin/env bash
        toplevel=$(git rev-parse --show-toplevel)
        if [ "$toplevel" != "${scripts.rebuild.path}" ]; then
          echo "Please run within '${scripts.rebuild.path}' directory"
          exit 1
        fi
        if [ -z "$1" ]; then
          echo "No operation specified. Refer to nixos-rebuild(8)"
          exit 1
        fi

        echo "-- Rebase --"
        git fetch -v
        git stash -u
        git rebase origin/master
        status=$?
        if [ -n "$(git stash list)" ]; then
          git stash pop
          status=$(( $status || $? ))
        fi
        if (( $status )); then
          echo "Rebase conflicts found. Manual intervention needed."
          exit 1
        fi
        git push --force-with-lease origin ${homepkgs.hostname}

        echo "-- Rebuild --"
        git add -Av
        sudo nixos-rebuild "$1" --option eval-cache false
        if (( $? )); then
          echo "'nixos-rebuild $1' failed, exiting..."
          exit 1
        fi

        echo "-- Commit --"
        message=$(git diff --cached --numstat)
        if [ "$message" = "" ]; then
          echo "no changes found, skipping commit..."
          exit 0
        fi
        git commit -m "nixos-rebuild: $1" -m "added   deleted"$'\n'"$message"
        git push origin ${homepkgs.hostname}
      '';
    };
  };
}
