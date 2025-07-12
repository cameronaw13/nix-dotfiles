{ lib, config, pkgs, repoPath, ... }:
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

  config = {
    systemd.services.auto-acl = {
      inherit (services.auto-acl) enable;
      description = "NixOS declarative acl service";
      serviceConfig.Type = "oneshot";

      script = let
        setfacl = "${pkgs.acl}/bin/setfacl";
      in ''
        set -x
        chgrp -R wheel "${repoPath}"
        chmod -R g+s "${repoPath}"
        chmod -R u=rwX,g=rwX,o=rX "${repoPath}"
        chmod -R o= "${repoPath}/secrets"
        ${setfacl} -dRm g::rw "${repoPath}"
      '';

      wantedBy = [ "default.target" ];
    };
  };
}
