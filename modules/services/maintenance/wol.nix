{ lib, config, ... }:
let
  macs = map (x: "\"" + x + "\"") config.local.services.maintenance.wakeOnLan.macList;
  macList = lib.strings.concatImapStrings (pos: x: " ") macs;
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
    persistent = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    randomizedDelaySec = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "0";
    };
  };

  config = lib.mkIf config.local.services.maintenance.wakeOnLan.enable {
    systemd = {
      services.wakeOnLan = {
        description = "NixOS maintenance wakeonlan service";
        serviceConfig.Type = "oneshot";
        startAt = config.local.services.maintenance.dates;
        
        script = let
          nix = "${config.nix.package}/bin/nix";
        in ''
          macList=(${macList})
          for i in "''${macList[@]}"; do
            ${nix} shell nixpkgs#wakeonlan --command wakeonlan "$i"
          done
        '';
      };

      timers.wakeOnLan = {
        timerConfig = {
          Persistent = config.local.services.maintenance.wakeOnLan.persistent;
          RandomizedDelaySec = config.local.services.maintenance.wakeOnLan.randomizedDelaySec;
        };
      };
    };
  };
}
