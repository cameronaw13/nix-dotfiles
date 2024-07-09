{ lib, ... }:
{
  imports = [
    ./cameron.nix
    ./filesystem.nix
  ];

  nixusers = {
    cameron.enable = lib.mkDefault false;
    filesystem.enable = lib.mkDefault false;
  };
}
