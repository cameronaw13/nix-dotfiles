{ lib, config, ... }:
{
  options.homepkgs.git.enable = lib.mkEnableOption "git config module";

  config = lib.mkIf config.homepkgs.git.enable {
    programs.git = {
      enable = lib.mkDefault true;
      userName = "cameronaw13";
      userEmail = "cameronawichman@gmail.com";
      extraConfig = {
        init.defaultBranch = "master";
      };
    };
  };
}
