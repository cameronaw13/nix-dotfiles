{ lib, config, pkgs, repoPath, ... }:
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
    git = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      delta.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
    jj.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    gh.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    lazygit.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    delta.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    name = lib.mkOption {
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
        inherit (homepkgs.vcs.git) enable;
        package = lib.mkDefault pkgs.git;
        userName = homepkgs.vcs.name;
        userEmail = homepkgs.vcs.email;
        extraConfig = lib.mkMerge [
          { 
            init.defaultBranch = lib.mkDefault "master";
            safe.directory = [ repoPath "${repoPath}/secrets" ];
          }
          (lib.mkIf (homepkgs.vcs.signing && homepkgs.sops.enable) {
            commit.gpgsign = true;
            gpg.format = "ssh";
            gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
            user.signingkey = "~/.ssh/id_ed25519_key.pub";
          })
        ];
        delta = {
          inherit (homepkgs.vcs.git.delta) enable;
        };
      };
      jujutsu = {
        inherit (homepkgs.vcs.jj) enable;
        settings = lib.mkMerge [
          {
            user = {
              inherit (homepkgs.vcs) name email;
            };
            ui.pager = lib.mkDefault "less -FRX";
          }
          (lib.mkIf (homepkgs.vcs.signing && homepkgs.sops.enable) {
            signing = {
              behavior = "own";
              backend = "ssh";
              backends = {
                ssh.allowed-signers = "~/.ssh/allowed_signers";
              };
              key = "~/.ssh/id_ed25519_key.pub";
            };
            git.sign-on-push = lib.mkDefault false;
            ui.show-cryptographic-signatures = lib.mkDefault true;
          })
        ];
      };
      ssh = {
        inherit (homepkgs.sops) enable;
        matchBlocks = {
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
        inherit (homepkgs.vcs.gh) enable;
        settings.git_protocol = "ssh";
      };
      lazygit = {
        inherit (homepkgs.vcs.lazygit) enable;
        settings = lib.mkMerge [
          (lib.mkIf homepkgs.vcs.delta.enable {
            git.paging = {
              colorArg = "always";
              pager = "delta --dark --paging=never";
            };
          })
        ];
      };
    };

    sops = lib.mkIf homepkgs.sops.enable {
      secrets = {
        "${homepkgs.sops.path}/id_ed25519_key" = {
          path = "/home/${username}/.ssh/id_ed25519_key";
        };
        "${homepkgs.sops.path}/id_ed25519_key.pub" = {
          path = "/home/${username}/.ssh/id_ed25519_key.pub";
        };
        "${homepkgs.sops.path}/gh-hosts.yml" = lib.mkIf homepkgs.vcs.gh.enable {
          path = "/home/${username}/.config/gh/hosts.yml";
        };
      };
      templates = {
        "allowed_signers" = {
          content = "* ${config.sops.placeholder."${homepkgs.sops.path}/id_ed25519_key.pub"}";
          path = "/home/${username}/.ssh/allowed_signers";
        };
      };
    };
  };
}
