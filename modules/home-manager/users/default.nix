{ lib, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./cameron.nix
    ./filesystem.nix
  ];
  home-manager.extraSpecialArgs = { inherit inputs; };
  cameron-home.enable = lib.mkDefault false;
  filesystem-home.enable = lib.mkDefault false;
}
