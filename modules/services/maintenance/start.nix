{ config, ... }:
let
  maintenance = config.local.services.maintenance;
  dependants = [
    "auto-wol.service"
    "nixos-upgrade.service"
    "nix-gc.service"
    "nix-optimise.service"
    "auto-poweroff.service"
    "auto-mail.service"
  ];
in
{
  systemd.services.auto-start = {
    description = "NixOS maintenance startup helper";
    serviceConfig.Type = "oneshot";
    startAt = maintenance.dates;

    script = ''
      echo "Starting maintenance job..."
    '';

    requiredBy = dependants;
    before = dependants;
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  systemd.timers.auto-start = {
    timerConfig = {
      Persistent = true;
      RandomizedDelaySec = "0";
    };
  };
}
