{ lib, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../../modules/home-manager/users/default.nix
  ];

  homeusers = {
    cameron.enable = true;
  };

  # NOTE: convert to imported attrset of options under "homeusers.<username>"
  home-manager.users.cameron.homepkgs = {
      vim.enable = true;
      git.enable = true;
      htop.enable = true;
  };
}
