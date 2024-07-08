{ lib, ... }:
{
  imports = [
    ./ssh.nix
  ];

  ssh-service.enable = lib.mkDefault true;

  networking.firewall.allowedTCPPorts = lib.mkDefault [ 22 ];
  #networking.firewall.allowedUDPPorts = lib.mkDefault [ ];
}
