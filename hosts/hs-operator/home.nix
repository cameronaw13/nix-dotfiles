{ lib, ... }:
{
  imports = [
    ../../modules/home-manager/users/default.nix
  ];
  
  cameron-home.enable = true;
}
