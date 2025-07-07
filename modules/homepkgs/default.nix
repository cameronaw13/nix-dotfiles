{ lib, ... }:
{
  imports = [
    ./vcs.nix
    ./bash.nix
    ./neovim.nix
  ];

  options.local.homepkgs = {
    repoPath = lib.mkOption {
      type = lib.types.path;
    };
    scrtPath = lib.mkOption {
      type = lib.types.path;
    };
    hostName = lib.mkOption {
      type = lib.types.singleLineStr;
    };
    sopsDir = lib.mkOption {
      type = lib.types.singleLineStr;
    };
    sopsNix = lib.mkOption {
      type = lib.types.bool;
    };
    isWheel = lib.mkOption {
      type = lib.types.bool;
    };
  };
}
