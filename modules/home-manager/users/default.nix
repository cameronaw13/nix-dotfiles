{ lib, ... }:
{
  imports = [
    ./cameron.nix
    ./filesystem.nix
  ];

  homeusers = {
    cameron.enable = lib.mkDefault false;
    filesystem.enable = lib.mkDefault false;
  };
}
