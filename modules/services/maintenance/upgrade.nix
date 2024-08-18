{ lib, config, inputs, pkgs, ... }:
let
  maintenance = config.local.services.maintenance;
in
{
  options.local.services.maintenance.upgrade = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf maintenance.upgrade.enable {
    system.autoUpgrade = {
      enable = lib.mkDefault true;
      dates = maintenance.dates;
      operation = "boot";
      flake = inputs.self.outPath;
      flags = [ "-L" ];
    };

    systemd.services.nixos-upgrade = {
      script = let
        nixos-rebuild = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
      in lib.mkForce ''
        ${nixos-rebuild} ${config.system.autoUpgrade.operation} ${toString config.system.autoUpgrade.flags}
      '';

      after = [ "auto-wol.service" "auto-pull.service" ];
      requires = lib.lists.optionals maintenance.upgrade.pull.enable [ "auto-pull.service" ];
    };
  };
}
