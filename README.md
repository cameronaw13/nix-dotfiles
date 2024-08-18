TODO:
- 
- Add home-manager & basic configs ✓
- Integrate nix flakes ✓
- Modularize users and packages between hosts ✓
- Add git & github integration ✓
- Add sops-nix secrets management ✓
- Flesh out essential hs-operator packages and services ✓
- Add github workflows, branching, ci, etc ✓
- Implement disko
- Implement impermanence
- Create microVMs (fully/partially declarative) and oci-containers
- Create vpn/forward-proxy, public & private reverse-proxy, and IAM environments
- Write multi-host management scripts
- Begin zt-mainframe setup replicating hs-operator's implementation
- Develop user & filesystem management environment
- Create media, *linux iso*, password mgmt, etc. environments  
- Create multi-host maintenance services
- Install nixos on bare-metal

References:
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
