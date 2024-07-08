{ lib, config, ... }:
{
  options.cameron-home.enable = lib.mkEnableOption "enable cameron home module";

  config = lib.mkIf config.cameron-home.enable {
    home-manager.users.cameron = {
      home = {
        username = "cameron";
        homeDirectory = "/home/cameron";
        stateVersion = "24.05";
      };

      imports = [
        ../packages/default.nix
      ];
      vim-cfg.enable = true;
      git-cfg.enable = true;
      htop-cfg.enable = true;

      programs.bash = {
        enable = true;
        bashrcExtra = ''
          alias sudo="sudo ";
        '';
      };

      #home.file.allowed_signers = {
      #  enable = true;
      #  target = ".config/git/allowed_signers";
      #  text = "* ${builtins.readFile ../keys/cameron_id_ed25519.pub}";
      #};  
    };
  };
}
