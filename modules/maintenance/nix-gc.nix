{ lib, config, ... }:
let
  prev = "nixos-upgrade.service";
in
{
  options.local.maintenance.nix-gc = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    options = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "";
    };
  };

  config = lib.mkIf config.local.maintenance.nix-gc.enable {
    nix.gc = {
      automatic = true;
      dates = config.local.maintenance.dates;
      options = config.local.maintenance.nix-gc.options;
      persistent = true;
    };

    systemd.services.nix-gc = {
      wants = [ prev ];
      after = [ prev ];
    };
  };
}
