{ lib, config, inputs, ... }:
let
  flakeUpdate =
    if config.local.services.maintenance.autoUpgrade.commit then
      "nix flake update --commit-lock-file"
    else
      "nix flake update";
in
{
  options.local.services.maintenance.autoUpgrade = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    commit = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf config.local.services.maintenance.autoUpgrade.enable {
    system.autoUpgrade = {
      enable = true;
      operation = "boot";
      flake = inputs.self.outPath;
      flags = [ "-L" ]; # print build logs
    };

    systemd.services.nixos-upgrade.preStart = flakeUpdate;
  };
}
