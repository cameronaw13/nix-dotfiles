{ lib, config, pkgs, ... }:
let
  inherit (config.local) services;
in
{
  options.local.services.auto-acl = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    path = lib.mkOption {
      type = lib.types.path;
      default = "/etc/nixos";
    };
  };

  config = lib.mkIf services.auto-acl.enable {
    systemd.services.auto-acl = {
      description = "NixOS declarative acl service";
      serviceConfig.Type = "oneshot";

      script = let
        setfacl = "${pkgs.acl}/bin/setfacl";
      in ''
        chgrp -R wheel /etc/nixos
        chmod -R g+s /etc/nixos
        chmod -R u=rwX,g=rwX,o=rX /etc/nixos
	chmod -R o= /etc/nixos/secrets
        ${setfacl} -dRm g::rw /etc/nixos
      '';

      wantedBy = [ "default.target" ];
    };
  };
}
