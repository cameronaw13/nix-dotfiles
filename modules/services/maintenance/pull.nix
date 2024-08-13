{ lib, config, pkgs, ... }:
let
  maintenance = config.local.services.maintenance;
  user = maintenance.gitPull.user;
in
{
  options.local.services.maintenance.gitPull = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    user = lib.mkOption {
      type = lib.types.singleLineStr;
    };
  };

  config = let
    hasGit = config.home-manager.users.${user}.local.homepkgs.git.enable;
  in lib.mkIf (maintenance.gitPull.enable && hasGit) {
    systemd.services.auto-pull = {
      description = "NixOS maintenance rebase service";
      serviceConfig = {
        Type = "oneshot";
        User = user;
        WorkingDirectory = "/etc/nixos";
      };
      startAt = maintenance.dates;

      path = with pkgs; [
        config.programs.ssh.package
      ];

      script = let
        git = "${pkgs.gitMinimal}/bin/git";
        hostname = config.networking.hostName;
      in ''
        if [ "$(${git} rev-parse origin/master)" = "$(${git} ls-remote --head origin master | cut -f1)" ]; then
          echo "No changes from remote master, skipping..."
          exit 0
        fi

        ${git} stash
        ${git} pull --rebase -v origin master
        status=$?
        ${git} stash pop
        if (( $status || $? )); then
          echo "Rebase conflict! Manual intervention needed."
          exit 1
        fi
        ${git} push --force-with-lease origin ${hostname}
      '';

      after = [ "auto-wol.service" ];
    };

    systemd.timers.auto-pull = {
      timerConfig = {
        Persistent = true;
        RandomizedDelaySec = "0";
      };
    };
  };
}
