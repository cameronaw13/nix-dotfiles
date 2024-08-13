{ lib, ... }:
{
  imports = [
    ./vim.nix
    ./htop.nix
    ./git.nix
    ./ssh.nix
    ./bash.nix
  ];

  options.local.homepkgs.hostname = lib.mkOption {
    type = lib.types.singleLineStr;
  };
}
