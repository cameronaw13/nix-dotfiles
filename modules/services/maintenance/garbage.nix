{ lib, config, ... }:
let
  inherit (config.local.services) maintenance;
in
{
  options.local.services.maintenance.collectGarbage = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    options = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "";
    };
  };

  config = lib.mkIf maintenance.collectGarbage.enable {
    nix.gc = {
      automatic = true;
      inherit (maintenance) dates;
      inherit (maintenance.collectGarbage) options;
      persistent = true;
    };

    systemd.services.nix-gc = {
      after = [
        "auto-wol.service"
        "auto-pull.service"
        "nixos-upgrade.service"
        "nix-optimise.service"
      ];
    };
  };
}
