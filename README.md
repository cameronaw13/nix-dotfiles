# Nix-Dotfiles - Homelab edition
A personal multi-host nixos flakes config repository ran across two selfhosted servers. Manages everything in my homelab, including but not limited to:
- Bootstrapping installation (bash, nixos-anywhere)
- Block device management and wipe on boot (disko, nixos impermanence)
- Automatic maintenance and system optimisations (nixos srvos, systemd)
- Abstracted user and virtual machine interfaces (nixos modules, nixos microvms)
- Continuous Development workflows (git, github-actions)



## Installation
Two devices are needed to perform the install, a host and the client device to install to.
The host device will run the first script 'nixos-anywhere.sh' that sets up the initial installation onto the client.
After installation is complete, 'nixos-boostrap.sh' is ran on the client to set up and rebuild nixos using this repository.

### Setup
1. Run any linux distribution that supports kexec on the client
    - If you want a fresh environment the [nixos-minimal iso](https://nixos.org/download/) is recommended but most distributions will work
    - [Ventoy](https://www.ventoy.net/en/index.html) is recommended to set up a bootable medium
2. Set up networking on the client
    - Take note of the given ip address for installation
3. Set a password for a user on the client
    - You'll need to be able to login to this user during installation to add ssh keys
    - The user must be able to use sudo without a password by adding `username ALL=(ALL) NOPASSWD: ALL` to the '/etc/sudoers' file or by modifying [security.sudo.extraRules](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/security/sudo.nix#L83) if using NixOS
    - You can alternatively use the root user. In this case, make sure that you enable root login by setting `PermitRootLogin=yes` in the '/etc/ssh/sshd_config' file or by modifying [services.openssh.settings.PermitRootLogin](https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/networking/ssh/sshd.nix#L386) if using NixOS
4. On the host machine, run the 'nixos-anywhere.sh' script:
    ```bash
    bash <(curl -sSL https://raw.githubusercontent.com/cameronaw13/nix-dotfiles/refs/heads/installation/nixos-anywhere.sh)
    ```
    - To ensure system security, you can run the script within Distrobox or any other containerization/virtualization service
5. Follow the process to install nixos and bootstrap nix-dotfiles on the client machine



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
