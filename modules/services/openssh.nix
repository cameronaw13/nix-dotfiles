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
    ports = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ 22 ];
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config.services.openssh = {
    inherit (services.openssh) enable ports openFirewall;
  };
}
