{ lib, ... }:
{
  imports = [
    ./ssh.nix
    ./postfix.nix
    ./maintenance/default.nix
  ];

  networking.firewall = lib.mkDefault {
    allowedTCPPorts = [ 22 ];
    #allowedUDPPorts = [ ];
  };
}
