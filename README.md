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
1. Boot the nixos-minimal iso on the client computer
    - Ventoy is recommended to set up the bootable medium
    - The nixos iso can be found here
2. Set up networking on the client
    - Information can be found in the nixos manual
    - Make sure to take note of the client's local ip address as the host machine will use it during the install
3. Set a password through passwd for the default user (nixos) on the client
4. On the host machine, download the 'nixos-anywhere.sh' and run it
    - Its recommended to run the script in Distrobox or some other container/virtualization layer with systemd init to ensure system security
    - Wget or curl can be used to download the script through the command line
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
