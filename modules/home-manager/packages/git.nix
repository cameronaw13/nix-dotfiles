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
        #commit.gpgsign = true;
        #gpg.format = "ssh";
        #user.signingkey = "~/.ssh/id_ed25519.pub";
      };
    };

    # Allowed_signers must be managed within each user:
    /* home.file.allowed_signers = {
      enable = lib.mkDefault true;
      target = ".config/git/allowed_signers";
      text = "* ${builtins.readFile ssh-key}";
    };*/
  };
}
