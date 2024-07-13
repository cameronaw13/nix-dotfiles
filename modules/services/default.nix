{ lib, ... }:
{
  imports = [
    ./ssh.nix
  ];

  servicemgmt = {
    ssh.enable = lib.mkDefault true;
  };

  networking.firewall.allowedTCPPorts = lib.mkDefault [ 22 ];
  #networking.firewall.allowedUDPPorts = lib.mkDefault [ ];
}
