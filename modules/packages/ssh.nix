{ lib, config, ... }:
{
  options.homepkgs.ssh.enable = lib.mkEnableOption "ssh config module";

  config = lib.mkIf config.homepkgs.ssh.enable {
    programs.ssh = {
      enable = lib.mkDefault true;
      matchBlocks = {
        "github" = {
          host = "github.com";
          identitiesOnly = true;
          identityFile = [
            "~/.ssh/id_ed25519"
          ];
        };
      };
    };
  };
}
