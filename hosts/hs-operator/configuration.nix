{ pkgs, inputs, ... }:
{
  imports = [ 
    ./hardware-configuration.nix
    ../../modules/common/default.nix
    ../../modules/users/default.nix
    ../../modules/services/default.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
  ];

  /* Virtual Console */
  console = {
    earlySetup = true;
    #font = "";
    keyMap = "us";
  };

  /* Networking */
  systemd.network = {
    enable = true;
    networks."50-ens18" = {
      matchConfig.Name = "ens18";
      address = [ "192.168.4.200/24" ];
      gateway = [ "192.168.4.1" ];
      dns = [ "9.9.9.9" ];
    };
    links."50-ens18" = {
      matchConfig.OriginalName = "ens18";
      linkConfig.WakeOnLan = "magic";
    };
  };
  networking = {
    useDHCP = false;
    hostName = "hs-operator";
  };
  
  /* System Packages */
  environment.systemPackages = with pkgs; [
    # Host-specific system packages
    tree
  ];

  /* Local Users */
  local.users = {
    cameron.enable = true;
  };

  home-manager.users = {
    cameron.local.homepkgs = {
      bash.scripts = {
        rebuild = true;
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
  
  /* Local Services */
  local.services = {
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
        timeframe = "120";
      };
      mail = {
        filters = [
          "]: deleting '/"
          "]: removing stale link from '/"
          "]: Rebasing ("
        ];
      };
    };
  };
  
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

  /* Cleanup */
  nix.settings.min-free = 7000 * 1024 * 1024; # 7000 MiB, Start when free space < min-free
  nix.settings.max-free = 7000 * 1024 * 1024; # 7000 MiB, Stop when used space < max-free

  /* Systemd */
  systemd = {
    enableEmergencyMode = false; # try to allow remote access during emergencies
    watchdog = {
      runtimeTime = "30s"; # time system hangs before reboot # watchdog sends signal every runtimeTime/2
      rebootTime = "30s"; # time reboot hangs before force reboot
    };
    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  /* State */
  system.stateVersion = "24.05";
}
