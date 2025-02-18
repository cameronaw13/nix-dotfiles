{ lib, config, ... }:
let
  inherit (config.local) homepkgs;
  inherit (homepkgs.bash) editor scripts;
in
{
  options.local.homepkgs.bash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    editor = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    scripts = {
      path = lib.mkOption {
        type = lib.types.path;
        default = "/etc/nixos";
      };
      /*editor = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        type = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
      };*/
      rebuild = {
        enable = lib.mkOption {
          type = lib.types.addCheck lib.types.bool (x: !x || homepkgs.git.enable);
          default = false;
        };
      };
      createpr = {
        enable = lib.mkOption {
          type = lib.types.addCheck lib.types.bool (x: !x || homepkgs.git.enable);
          default = false;
        };
      };
    };
  };

  config = lib.mkIf homepkgs.bash.enable {
    programs.bash = {
      enable = lib.mkDefault true;
      bashrcExtra = lib.strings.concatStringsSep "\n" (
        lib.lists.optional (editor != null) ''
          alias sudo="sudo VISUAL='${editor}'"
        '' ++
        lib.lists.optional scripts.rebuild.enable ''
          alias rebuild="bash ~/Scripts/rebuild.sh"
        '' ++
        lib.lists.optional scripts.createpr.enable ''
          alias createpr="bash ~/Scripts/createpr.sh"
        ''
      );
    };

    home.file.rebuild = lib.mkIf scripts.rebuild.enable {
      target = "Scripts/rebuild.sh";
      force = true;
      text = ''
        #!/usr/bin/env bash
        toplevel=$(git rev-parse --show-toplevel)
        if [ "$toplevel" != "${scripts.path}" ]; then
          echo "Please run within '${scripts.path}' directory"
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
          git stash pop -q
          status=$(( status || $? ))
        fi
        if (( status )); then
          echo "Rebase conflicts found. Manual intervention needed."
          exit 1
        fi
        git push --force-with-lease origin ${homepkgs.hostName}

        echo "-- Rebuild --"
        git add -Av
        if ! sudo nixos-rebuild "$1" --option eval-cache false; then
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
        git push origin ${homepkgs.hostName}
      '';
    };
    home.file.createpr = lib.mkIf scripts.createpr.enable {
      target = "Scripts/createpr.sh";
      force = true;
      text = ''
        #!/usr/bin/env bash
        tabs 4
        toplevel=$(git rev-parse --show-toplevel)
        if [ "$toplevel" != "${scripts.path}" ]; then
          echo "Please run within '${scripts.path}' directory"
          exit 1
        fi
        base="master"
        head="${homepkgs.hostName}"
        read -rp "PR Title: " title
        body="$(git log origin/master..HEAD --reverse --format=%s$'\n```\n'%b$'```')"
        fmtbody="$(sed "s/^/\t/g" <<< "$body")"

        printf "\nBase: %s" "$base"
        printf "\nHead: %s" "$head"
        printf "\nTitle: '%s'" "$title"
        printf "\nBody:\n%s\n\n" "$fmtbody"

        read -rp "Do you wish to continue? (y/N): " choice
        case "$choice" in
          y|Y) gh pr create --base "$base" --head "$head" --title "$title" --body "$body";;
        esac
      '';
    };
  };
}
