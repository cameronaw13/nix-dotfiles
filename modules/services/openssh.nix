{ lib, config, ... }:
let
  inherit (config.local) services;
in
{
  options.local.services.openssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    permitRoot = lib.mkOption {
      type = lib.types.str;
      default = "no";
    };
  };

  config = lib.mkIf services.openssh.enable {
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        PermitRootLogin = services.openssh.permitRoot;
      };
    };
    networking.firewall.allowedTCPPorts = lib.mkDefault [ 22 ];
  };
}
