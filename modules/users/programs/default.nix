{ lib, ... }:
{
  imports = [
    ./vim.nix
    ./htop.nix
    ./git.nix
    ./ssh.nix
  ];

  options.local.homepkgs.hostname = lib.mkOption {
    type = lib.types.str;
  };
}
