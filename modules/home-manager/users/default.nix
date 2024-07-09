{ lib, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./cameron.nix
    ./filesystem.nix
  ];
  home-manager.extraSpecialArgs = { inherit inputs; };

  homeusers = {
    cameron.enable = lib.mkDefault false;
    filesystem.enable = lib.mkDefault false;
  };
}
