{ lib, config, pkgs, ... }:
let
  inherit (config.local) homepkgs;
  inherit (config.home) username;
in
{
  options.local.homepkgs.vcs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    git.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    jj.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    gh.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    username = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "";
    };
    email = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "";
    };
    signing = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf homepkgs.vcs.enable {
    programs = {
      git = {
        enable = homepkgs.vcs.git.enable;
        package = lib.mkDefault pkgs.git;
        userName = homepkgs.vcs.username;
        userEmail = homepkgs.vcs.email;
        extraConfig = lib.mkMerge [
          { 
            init.defaultBranch = "master";
            safe.directory = [ homepkgs.repopath "${homepkgs.repopath}/secrets" ];
          }
          (lib.mkIf (homepkgs.vcs.signing && homepkgs.sopsNix) {
            commit.gpgsign = true;
            gpg.format = "ssh";
            gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
            user.signingkey = "~/.ssh/id_ed25519_key.pub";
          })
        ];
      };
      jujutsu = {
        enable = homepkgs.vcs.jj.enable;
        settings = lib.mkMerge [
          {
            user = {
              name = homepkgs.vcs.username;
              email = homepkgs.vcs.email;
            };
          }
          (lib.mkIf (homepkgs.vcs.signing && homepkgs.sopsNix) {
            signing = {
              behavior = "own";
              backend = "ssh";
              backends = {
                ssh.allowed-signers = "~/.ssh/allowed_signers";
              };
              key = "~/.ssh/id_ed25519_key.pub";
            };
            git.sign-on-push = false;
            ui.show-cryptographic-signatures = true;
          })
        ];
      };
      ssh = {
        enable = homepkgs.sopsNix;
        matchBlocks = lib.mkDefault {
          "github-host" = {
            host = "github.com";
            identitiesOnly = true;
            identityFile = [
              "~/.ssh/id_ed25519_key"
            ];
          };
          "gitlab-host" = {
            host = "gitlab.com";
            identitiesOnly = true;
            identityFile = [
              "~/.ssh/id_ed25519_key"
            ];
          };
        };
      };
      gh = {
        enable = homepkgs.vcs.gh.enable;
        settings.git_protocol = lib.mkDefault "ssh";
      };
    };

    sops = lib.mkIf homepkgs.sopsNix {
      secrets = {
        "${homepkgs.sopsDir}/id_ed25519_key" = {
          path = "/home/${username}/.ssh/id_ed25519_key";
        };
        "${homepkgs.sopsDir}/id_ed25519_key.pub" = {
          path = "/home/${username}/.ssh/id_ed25519_key.pub";
        };
      };
      templates."allowed_signers" = {
        content = "* ${config.sops.placeholder."${homepkgs.sopsDir}/id_ed25519_key.pub"}";
        path = "/home/${username}/.ssh/allowed_signers";
      };
    };
  };
}
