{ lib, ... }:
{
  imports = [
    ./openssh.nix
    ./postfix.nix
    ./auto-acl.nix
    ./maintenance/default.nix
  ];

  networking.firewall = lib.mkDefault {
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };
}
