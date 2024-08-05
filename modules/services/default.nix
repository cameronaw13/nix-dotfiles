{ lib, ... }:
{
  imports = [
    ./ssh.nix
    ./postfix.nix
  ];

  networking.firewall = lib.mkDefault {
    allowedTCPPorts = [ 22 ];
    #allowedUDPPorts = [ ];
  };
}
