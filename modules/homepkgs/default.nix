{ lib, ... }:
{
  imports = [
    ./vcs.nix
    ./bash
    ./nvim
    ./zellij
  ];

  options.local.homepkgs = {
    sops = { 
      enable = lib.mkOption {
        type = lib.types.bool;
      };
      path = lib.mkOption {
        type = lib.types.singleLineStr;
      };
    };
    isWheel = lib.mkOption {
      type = lib.types.bool;
    };
  };
}
