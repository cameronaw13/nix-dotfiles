{ lib, ... }:
{
  imports = [
    ./ssh.nix
    ./maintenance.nix
  ];

  servicemgmt = {
    ssh.enable = lib.mkDefault true;
    maintenance.enable = lib.mkDefault false;
  };

  networking.firewall.allowedTCPPorts = lib.mkDefault [ 22 ];
  #networking.firewall.allowedUDPPorts = lib.mkDefault [ ];
}
