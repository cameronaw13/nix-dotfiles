# Nix-Dotfiles - Homelab edition
A personal multi-host nixos flakes config repository ran across two selfhosted servers. Manages everything in my homelab, including but not limited to:
- Bootstrapping installation (bash, nixos-anywhere)
- Block device management and wipe on boot (disko, nixos impermanence)
- Automatic maintenance and system optimisations (nixos srvos, systemd)
- Abstracted user and virtual machine interfaces (nixos modules, nixos microvms)
- Continuous Development workflows (git, github-actions)



## Installing
Two devices are needed to perform the install, a host and client device.
The host device will run the first script 'nixos-anywhere.sh' that sets up the initial installation onto the client.
After installation is complete, 'nixos-boostrap.sh' is ran on the client to set up and rebuild nixos using this repository.

### Nixos-Anywhere.sh setup
1. Boot the [nixos-minimal iso](https://nixos.org/download/) on the client computer
    - [Ventoy](https://www.ventoy.net/en/index.html) is recommended to set up the bootable medium
    - Can also use an existing linux machine if you're willing to overwrite its current installation
2. Set up networking on the client
    - Information for wireless networking setup can be found in [the nixos manual](https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual-networking)
    - Make sure both an ip address and dns are given to the client
    - Take note of the client's username and ip address for installation 
3. Set a password for the desired user on the client
    - If using the root user, make sure that 'PermitRootLogin' is set to 'yes' to access the client
4. On the host machine, run the 'nixos-anywhere.sh' script
    - Its recommended to run the script in Distrobox or some other container/virtualization layer with systemd init to ensure system security
    - Example:
        ```
        bash <(curl -sSL https://raw.githubusercontent.com/cameronaw13/nix-dotfiles/refs/heads/installation/nixos-anywhere.sh)
        ```
5. Follow the process to install nixos on the client machine



## TODO
Still a WIP as development progress is tracked below:
- Add home-manager & basic configs ✓
- Integrate nix flakes ✓
- Modularize users and packages between hosts ✓
- Add git & github integration ✓
- Add sops-nix secrets management ✓
- Flesh out essential hs-operator packages and services ✓
- Add github workflows, branching, ci, etc ✓
- Handle multi-user permissions ✓
- Implement disko & impermanence
- Create microVMs (fully/partially declarative) and oci-containers
- Create vpn/forward-proxy, public & private reverse-proxy, and IAM environments
- Write multi-host management scripts
- Begin zt-mainframe setup replicating hs-operator's implementation
- Develop user & filesystem management environment
- Create media, *linux iso*, password mgmt, etc. environments  
- Create multi-host maintenance services
- Install nixos on bare-metal



## Useful References
- Flakes, modularization, sops-nix:
    - https://www.youtube.com/@vimjoyer
- Modularization, flakes options, home-manager, git:
    - https://www.youtube.com/@librephoenix
- Sops-nix, secrets submodule:
    - https://www.youtube.com/@Emergent_Mind
- Option implementations/syntax:
    - https://github.com/NixOS/nixpkgs
- Server security options:
    - https://github.com/nix-community/srvos
- Various configurations:
    - https://github.com/Mic92/dotfiles
- Flake workflows:
    - https://github.com/dmadisetti/.dots/blob/template/.github/workflows
- ZFS configuration:
    - https://wiki.nixos.org/wiki/ZFS
    - https://openzfs.github.io/openzfs-docs/Getting%20Started/NixOS/
