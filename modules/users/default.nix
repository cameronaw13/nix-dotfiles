{ lib, ... }:
{
  imports = [
    ./cameron.nix
    ./filesystem.nix
  ];

  usermgmt = {
    cameron.enable = lib.mkDefault false;
    filesystem.enable = lib.mkDefault false;
  };
}
