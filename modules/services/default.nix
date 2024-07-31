{ lib, ... }:
{
  imports = [
    ./ssh.nix
    ./maintenance.nix
    ./postfix.nix
  ];

  networking.firewall = lib.mkDefault {
    allowedTCPPorts = [ 22 ];
    #allowedUDPPorts = [ ];
  };
}
