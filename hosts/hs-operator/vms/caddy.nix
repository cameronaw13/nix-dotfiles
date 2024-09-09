{ lib, config, pkgs, inputs, ... }:
let
  inherit (config.local) microvms;
in
{
  imports = [
    ./default.nix
    ../../../modules/common
    ../../../modules/users.nix
    ../../../modules/services
    inputs.sops-nix.nixosModules.sops
    inputs.microvm.nixosModules.microvm
  ];

  config = {
    /* MicroVM config */
    microvm = {
      hypervisor = "cloud-hypervisor";
      socket = "control.socket";
      vcpu = 2;
      mem = 512;

      shares = [ {
        proto = "virtiofs";
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      } {
        proto = "virtiofs";
        tag = "secrets-for-users";
        source = "/run/secrets-for-users";
        mountPoint = "/run/secrets-for-users";
      } ];

      interfaces = [ {
        type = "macvtap";
        id = "hs-caddy";
        inherit (microvms.caddy) mac;
        macvtap = {
          inherit (microvms) link;
          mode = "bridge";
        };
      } ];
    };

    /* Networking */
    networking = {
      hostName = "hs-caddy";
      useDHCP = false;
    };
    systemd.network = {
      enable = true;
      networks."50-hs-caddy" = {
        networkConfig = {
          Address = "192.168.4.199/24";
          Gateway = "192.168.4.1";
          DNS = "9.9.9.9";
        };
        #linkConfig.RequiredForOnline = "routable";
      };
    };

    /* Root */
    #users.users.root.password = "test";

    /* Local Config */
    local = {
      # TODO: Add caddy service, probably disable ssh?  
      users.cameron = {
        uid = 1000;
        extraGroups = [ "wheel" ];
      };
    };

    sops = {
      defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
      /*age = {
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        keyFile = "/var/lib/sops-nix/keys.txt";
        generateKey = true;
      };*/
    };
    
    /* Statever */
    system.stateVersion = "24.05";
  };
}
