{ lib, config, ... }:
{
  options.local.homepkgs.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf config.local.homepkgs.ssh.enable {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "config" = {
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
