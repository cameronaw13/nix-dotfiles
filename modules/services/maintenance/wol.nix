{ lib, config, pkgs, ... }:
let
  maintenance = config.local.services.maintenance;
in
{
  options.local.services.maintenance.wakeOnLan = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    macList = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
    };
  };

  config = lib.mkIf maintenance.wakeOnLan.enable {
    systemd.services.auto-wol = {
      description = "NixOS maintenance wakeonlan service";
      serviceConfig.Type = "oneshot";
      startAt = maintenance.dates;
      
      script = let
        nix = "${config.nix.package}/bin/nix";
        wakeonlan = "${pkgs.wakeonlan}/bin/wakeonlan";
        macAddrs = lib.strings.concatStringsSep " " maintenance.wakeOnLan.macList;
      in ''
        macList=(${macAddrs})
        for i in "''${macList[@]}"; do
          #${nix} shell nixpkgs#wakeonlan --command wakeonlan "$i"
          ${wakeonlan} "$i"
        done
      '';
    };

    systemd.timers.auto-wol = {
      timerConfig = {
        Persistent = true;
        RandomizedDelaySec = "0";
      };
    };
  };
}
