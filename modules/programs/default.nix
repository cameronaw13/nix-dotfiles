{ lib, ... }:
{
  imports = [
    ./vim.nix
    ./htop.nix
    ./git.nix
  ];

  options.homepkgs.hostname = lib.mkOption {
    type = lib.types.str;
  };
}
