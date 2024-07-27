# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# TODO: Create install, rebuild, flake, home-manager scripts for config management
# View rebuild errors:
# sudo bash -c "nixos-rebuild switch &>/etc/nixos/nixos-switch.log || (cat /etc/nixos/nixos-switch.log | grep --color -e \"error\" -e \" at \" && exit 1)"

{ pkgs, inputs, ... }:
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
  ];

  /* Users */
  usermgmt = {
    cameron.enable = true;
  };
  home-manager.users = {
    cameron.homepkgs = {
      vim.enable = true;
      git.enable = true;
      htop.enable = true;
      ssh.enable = true;
    };
  };

  /* Services */
  servicemgmt = {
    maintenance.enable = true;
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
    secrets = {
      "postfix/smtp-email" = {};
      "postfix/smtp-password" = {};
    };
  };

  /* System */
  system.stateVersion = "24.05";
}
