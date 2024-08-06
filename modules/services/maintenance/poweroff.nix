{ lib, config, pkgs, ...}:
let
  prev = "nix-optimise.service";
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
        Number of seconds system uptime must be under to determine if the system should shutdown afterwards. Otherwise the system reboots. Uptime is calculated at the start of the maintenance service.
      '';
    };
    persistent = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    randomizedDelaySec = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "0";
    };
  };

  config = lib.mkIf config.local.services.maintenance.poweroff.enable {
    systemd = {
      services.auto-poweroff = {
        description = "NixOs maintenance poweroff service";
        serviceConfig.Type = "oneshot";
        startAt = config.local.services.maintenance.dates;

        script = let
          date = "${pkgs.coreutils}/bin/date";
          systemctl = "${config.systemd.package}/bin/systemctl";
          timeframe = config.local.services.maintenance.poweroff.timeframe;
        in ''
          timer=$(${systemctl} show auto-poweroff.timer | grep "LastTriggerUSec=" | cut -d " " -f3) 
          elapsed=$(( $(${date} +%s) - $(${date} -d $timer +%s) ))

          uptime=$(grep -Eo ^[0-9]+ -r /proc/uptime)

          timeframe=${timeframe}

          if (( $uptime - $elapsed < $timeframe )); then
            shutdown
          else
            shutdown -r
          fi
        '';

        wants = [ prev ];
        after = [ prev ];
      };

      timers.auto-poweroff = {
        timerConfig = {
          Persistent = config.local.services.maintenance.poweroff.persistent;
          RandomizedDelaySec = config.local.services.maintenance.poweroff.randomizedDelaySec;
        };
      };
    };
  };
}
