{ lib, config, ... }:
{
  options.git-cfg.enable = lib.mkEnableOption "enable git config module";

  config = lib.mkIf config.git-cfg.enable {
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
