{
  inputs = {
    #self.submodules = true;
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-secrets = {
      url = "git+file:///etc/nixos/secrets";
      flake = false;
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, ... } @inputs: let
    system = "x86_64-linux";
    repopath = "/etc/nixos";
    pkgsUnstable = nixpkgs-unstable.legacyPackages.${system};
  in {
    nixosConfigurations = {
      dl-operator = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit repopath pkgsUnstable inputs; };
        modules = [
          ./hosts/dl-operator/configuration.nix
        ];
      };
      /*dl-caddy = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/dl-operator/vms/caddy.nix
        ];
      };*/
      templates = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/templates/configuration.nix
        ];
      };
    };
  };
}
