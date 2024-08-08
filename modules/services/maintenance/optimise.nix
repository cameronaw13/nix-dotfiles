{ lib, config, ... }:
let
  maintenance = config.local.services.maintenance;
in
{
  options.local.services.maintenance.optimise = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf maintenance.optimise.enable {
    nix.optimise = {
      automatic = true;
      dates = [ maintenance.dates ];
    };

    systemd.services.nix-optimise = {
      serviceConfig.Type = "oneshot";
      after = [ "auto-wol.service" "nixos-upgrade.service" "nix-gc.service" ];
    };

    systemd.timers.nix-optimise = {
      timerConfig = {
        Persistent = lib.mkForce true;
        RandomizedDelaySec = lib.mkForce "0";
      };
    };
  };
}
