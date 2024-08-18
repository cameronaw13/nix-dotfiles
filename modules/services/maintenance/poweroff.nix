{ lib, config, pkgs, ...}:
let
  inherit (config.local.services) maintenance;
in
{
  options.local.services.maintenance.poweroff = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    timeframe = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "300"; # 5 min
      description = ''
        Number of seconds system uptime must be under to determine if the system should shutdown
        afterwards. Otherwise the system reboots. Uptime is calculated at the start of the maintenance
        service.
      '';
    };
  };

  config = lib.mkIf maintenance.poweroff.enable {
    systemd.services.auto-poweroff = {
      description = "NixOS maintenance poweroff service";
      serviceConfig.Type = "oneshot";
      startAt = maintenance.dates;

      script = let
        date = "${pkgs.coreutils}/bin/date";
        inherit (maintenance.poweroff) timeframe;
      in ''
        timer=$(systemctl show auto-poweroff.timer | grep "LastTriggerUSec=" | cut -d " " -f3) 
        elapsed=$(( $(${date} +%s) - $(${date} -d $timer +%s) ))

        uptime=$(grep -Eo ^[0-9]+ -r /proc/uptime)
        initUptime=$(( $uptime - $elapsed ))

        timeframe=${timeframe}

        echo "Uptime: ''${initUptime}s"
        echo "Shutdown timeframe: ''${timeframe}s"

        if (( $initUptime < $timeframe )); then
          shutdown
        else
          shutdown -r
        fi
      '';

      after = [
        "auto-wol.service"
        "auto-pull.service"
        "nixos-upgrade.service"
        "nix-gc.service"
        "nix-optimise.service"
      ];
    };

    systemd.timers.auto-poweroff = {
      timerConfig = {
        Persistent = true;
        RandomizedDelaySec = "0";
      };
    };
  };
}
