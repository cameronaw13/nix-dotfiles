{ lib, ... }:
{
  imports = [
    ./vim.nix
    ./htop.nix
    ./git.nix
  ];

  options.local.homepkgs.hostname = lib.mkOption {
    type = lib.types.str;
  };
}
