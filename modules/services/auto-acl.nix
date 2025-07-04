{ lib, config, pkgs, repopath, ... }:
let
  inherit (config.local) services;
in
{
  options.local.services.auto-acl = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf services.auto-acl.enable {
    systemd.services.auto-acl = {
      description = "NixOS declarative acl service";
      serviceConfig.Type = "oneshot";

      script = let
        setfacl = "${pkgs.acl}/bin/setfacl";
      in ''
        chgrp -R wheel "${repopath}"
        chmod -R g+s "${repopath}"
        chmod -R u=rwX,g=rwX,o=rX "${repopath}"
	chmod -R o= "${repopath}/secrets"
        ${setfacl} -dRm g::rw "${repopath}"
      '';

      wantedBy = [ "default.target" ];
    };
  };
}
