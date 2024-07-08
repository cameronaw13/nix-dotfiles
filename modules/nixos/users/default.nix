{ lib, ... }:
{
  imports = [
    ./cameron.nix
    ./filesystem.nix
  ];

  cameron-user.enable = lib.mkDefault false;
  filesystem-user.enable = lib.mkDefault false;
}
