{ lib, config, ... }:
let
  prev = "nix-gc.service";
in
{
  options.local.maintenance.nix-optimise = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
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

  config = lib.mkIf config.local.maintenance.nix-optimise.enable {
    nix.optimise = {
      automatic = true;
      dates = [ config.local.maintenance.dates ];
    };

    systemd = {
      services.nix-optimise = {
        wants = [ prev ];
        after = [ prev ];
      };

      # remove RandomizedDelaySec - should probably add options upstream lol
      timers.nix-optimise.timerConfig = {
        Persistent = lib.mkForce config.local.maintenance.nix-optimise.persistent;
        RandomizedDelaySec = lib.mkForce config.local.maintenance.nix-optimise.randomizedDelaySec;
      };
    };
  };
}
