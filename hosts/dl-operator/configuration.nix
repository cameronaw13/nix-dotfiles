{ lib, pkgs, inputs, ... }:
{
  imports = [ 
    ./hardware-configuration.nix
    ./extra-hardware-conf.nix
    ../../modules/default.nix
    inputs.sops-nix.nixosModules.sops
    #inputs.microvm.nixosModules.host
  ];

  /* System Packages */
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
    ;
  };

  /* Local Config */
  local = {
    ## Cameron ##
    users.cameron = {
      uid = 1000;
      extraGroups = [ "wheel" ];
      linger = true;
      sopsNix = true;
      userPackages = builtins.attrValues {
        inherit (pkgs)
        sops
        age
        tree
        ;
      };
      homePackages = {
        bash = {
          editor = "vim";
          scripts = {
            rebuild.enable = true;
            createpr.enable = true;
          };
        };
        vim.enable = true;
        git = {
          enable = true;
          username = "cameronaw13";
          email = "cameronawichman@gmail.com";
          signing = true;
          gh.enable = true;
        };
        ssh.enable = true;
        htop.enable = true;
      };
    };
    ## Filesystem ##
    /*users.filesystem = {
      uid = 1001;
      extraGroups = [ "wheel" ];
      userPackages = builtins.attrValues {
        inherit (pkgs)
        tree
        ;
      };
      homePackages = {
        vim.enable = true;
        git = {
          enable = true;
          username = "cameronaw13";
          email = "cameronawichman@gmail.com";
          signing = true;
          gh.enable = true;
        };
        htop.enable = true;
      };
    };*/
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
          enable = true;
          macList = [ "0c:9d:92:1a:49:94" ];
        };
        upgrade = {
          enable = true;
          pull = {
            enable = true;
            user = "cameron";
          };
        };
        collectGarbage = {
          enable = true;
          options = "--delete-older-than 14d";
        };
        poweroff = {
          enable = true;
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
    earlySetup = true;
    #font = "ter-v28b";
    keyMap = "us";
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
    loader = {
      grub.configurationLimit = 10;
      systemd-boot.configurationLimit = 10;
    };
  };
}
