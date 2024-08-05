{ lib, config, ... }:
let
  prev = "nix-gc.service";
in
{
  options.local.services.maintenance.nix-optimise = {
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

  config = lib.mkIf config.local.services.maintenance.nix-optimise.enable {
    nix.optimise = {
      automatic = true;
      dates = [ config.local.services.maintenance.dates ];
    };

    systemd = {
      services.nix-optimise = {
        wants = [ prev ];
        after = [ prev ];
      };

      # remove RandomizedDelaySec - should probably add options upstream lol
      timers.nix-optimise.timerConfig = {
        Persistent = lib.mkForce config.local.services.maintenance.nix-optimise.persistent;
        RandomizedDelaySec = lib.mkForce config.local.services.maintenance.nix-optimise.randomizedDelaySec;
      };
    };
  };
}
