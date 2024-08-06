{ lib, config, ... }:
let
  prev = "nixos-upgrade.service";
in
{
  options.local.services.maintenance.nix-gc = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    options = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "";
    };
  };

  config = lib.mkIf config.local.services.maintenance.nix-gc.enable {
    nix.gc = {
      automatic = true;
      dates = config.local.services.maintenance.dates;
      options = config.local.services.maintenance.nix-gc.options;
      persistent = true;
    };

    systemd.services.nix-gc = {
      wants = [ prev ];
      after = [ prev ];
    };
  };
}
