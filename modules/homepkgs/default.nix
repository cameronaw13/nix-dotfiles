{ lib, ... }:
{
  imports = [
    ./vim.nix
    ./htop.nix
    ./git.nix
    ./ssh.nix
    ./bash.nix
    ./gh.nix
  ];

  options.local.homepkgs = {
    hostName = lib.mkOption {
      type = lib.types.singleLineStr;
    };
    sopsDir = lib.mkOption {
      type = lib.types.singleLineStr;
    };
    sopsNix = lib.mkOption {
      type = lib.types.bool;
    };
  };
}
