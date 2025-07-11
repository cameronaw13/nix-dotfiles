{ pkgs, inputs, ... }:
{
  imports = [ 
    ./hardware-configuration.nix
    ./extra-hardware.nix
    ../../modules
    inputs.sops-nix.nixosModules.sops
  ];

  /* System Packages */
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
    tree
    btop
    fzf
    ;
  };

  /* Local Config */
  local = {
    ## Cameron ##
    users.cameron = {
      uid = 1000;
      extraGroups = [ "wheel" ];
      linger = true;
      sops = true;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+F0TjRt4MED8xhkzDL0VZo5XGspRlGkQgTTNcwacRR cameron@ye-olde-workhorse"
      ];
      userPackages = builtins.attrValues {
        inherit (pkgs)
        sops
        ;
      };
      homePackages = {
        bash.scripts = {
          fullrebuild.enable = true;
          createpr.enable = true;
        };
        vcs = {
          enable = true;
          git.delta.enable = false;
          name = "cameronaw13";
          email = "cameronawichman@gmail.com";
          signing = true;
        };
        neovim = {
          enable = true;
          aliases = [ "nvim" "vim" "vi" ];
        };
        zellij.enable = true;
      };
    };
    ## Filesystem ##
    users.filesystem = {
      uid = 1001;
      sops = true;
      userPackages = builtins.attrValues {
        inherit (pkgs)
        ;
      };
      /*homePackages = {
        neovim.enable = true;
      };*/
    };
    ## Services ##
    services = {
      postfix = {
        enable = true;
        sender = "cameronserverlog@gmail.com";
        rootAliases = [ "cameronawichman@gmail.com" ];
      };
      maintenance = {
        dates = "Fri *-*-* 04:15:00";
        wakeOnLan = {
          enable = false;
          macList = [ "0c:9d:92:1a:49:94" ];
        };
        upgrade = {
          enable = false;
          pull = {
            enable = false;
            user = "cameron";
          };
        };
        collectGarbage = {
          enable = false;
          options = "--delete-older-than 14d";
        };
        poweroff = {
          enable = false;
          timeframe = 120; # 2 min
        };
        mail = {
          filters = [
            "]: deleting '/"
            "]: removing stale link from '/"
            "]: Rebasing ("
            "]: removing profile version "
          ];
        };
      };
    };
  };

  /* MicroVMs */
  # microvm.autostart = [ "dl-caddy" ];

  /* Secrets */
  sops = {
    defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
    age = {
      # Generate private age key per host
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/keys.txt";
      generateKey = true;
    };
  };

  /* Virtual Console */
  console = {
    #earlySetup = true;
    font = "ter-v32b";
    keyMap = "us";
    packages = builtins.attrValues {
      inherit (pkgs)
      terminus_font
      ;
    };
  };

  /* Systemd */
  systemd = {
    enableEmergencyMode = false; # try to allow remote access during emergencies
    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  /* Cleanup */
  nix.settings = {
    min-free = 7000 * 1024 * 1024; # 7000 MiB, Start when free space < min-free
    max-free = 7000 * 1024 * 1024; # 7000 MiB, Stop when used space < max-free
  };
  boot = {
    tmp.cleanOnBoot = true;
    /*loader = {
      grub.configurationLimit = 100;
      systemd-boot.configurationLimit = 100;
    };*/
  };
}
