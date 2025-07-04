{ lib, ... }:
{
  imports = [
    ./vcs.nix
    ./bash.nix
    ./neovim.nix
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
    isWheel = lib.mkOption {
      type = lib.types.bool;
    };
  };
}
