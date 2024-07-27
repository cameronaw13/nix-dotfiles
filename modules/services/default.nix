{ lib, ... }:
{
  imports = [
    ./ssh.nix
    ./maintenance.nix
    ./postfix.nix
  ];

  servicemgmt = {
    ssh.enable = lib.mkDefault true;
    maintenance.enable = lib.mkDefault false;
    postfix.enable = lib.mkDefault false;
  };

  networking.firewall = lib.mkDefault {
    allowedTCPPorts = [ 22 ];
    #allowedUDPPorts = [ ];
  };
}
