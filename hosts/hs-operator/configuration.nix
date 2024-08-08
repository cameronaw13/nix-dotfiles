{ pkgs, config, inputs, ... }:
{
  imports = [ 
    ./hardware-configuration.nix
    ../../modules/common.nix
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
  networking.hostName = "hs-operator";
  networking.defaultGateway = "192.168.4.1";
  networking.nameservers = [ "9.9.9.9" ];
  
  /* System Packages */
  environment.systemPackages = with pkgs; [
    # Host-specific system packages
    inxi
    pciutils
    tree
    sops
  ];

  /* Local Users */
  local.users = {
    cameron.enable = true;
  };
  home-manager.users = {
    cameron.local.homepkgs = {
      vim.enable = true;
      htop.enable = true;
      git = {
        enable = true;
        username = "cameronaw13";
        email = "cameronawichman@gmail.com";
      };
    };
  };
  
  /* Local Services */
  local.services = {
    postfix = {
      enable = true;
      sender = "cameronserverlog@gmail.com";
      receiver = "cameronawichman@gmail.com";
    };
    
    maintenance = {
      wakeOnLan = {
        enable = true;
        macList = [ "0c:9d:92:1a:49:94" ];
      };
      autoUpgrade = {
        enable = true;
        user = "cameron";
        commit = true;
      };
      collectGarbage = {
        enable = false;
        options = "--delete-older-than 30d";
      };
      optimise.enable = true;
      poweroff.enable = true;
      
      dates = "Mon *-*-* 02:15:00";
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

  /* System */
  system.stateVersion = "24.05";
}
