{ lib, config, pkgs, ... }:
let
  inherit (config.local.services) maintenance;
in
{
  options.local.services.maintenance.upgrade.pull = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    user = lib.mkOption {
      type = lib.types.singleLineStr;
    };
  };

  config = lib.mkIf (maintenance.upgrade.enable && maintenance.upgrade.pull.enable) {
    systemd.services.auto-pull = {
      description = "NixOS maintenance rebase service";
      serviceConfig = {
        Type = "oneshot";
        User = maintenance.upgrade.pull.user;
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
        ${git} fetch -v
        ${git} stash -u
        ${git} rebase origin/master
        status=$?

        if [ -n "$(${git} stash list)" ]; then
          ${git} stash pop
          status=$(( $status || $? ))
        fi

        if (( $status )); then
          echo "Rebase conflicts found. Manual intervention needed."
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