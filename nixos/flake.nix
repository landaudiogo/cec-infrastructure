{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
        agenix = {
            url = "github:ryantm/agenix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
    outputs = { self, nixpkgs, agenix, ... }@inputs:
        let
            system = "x86_64-linux";
            pkgs = import nixpkgs { inherit system; };
        in
        {
            devShells.${system} = {
                default = pkgs.mkShell {
                    packages = with pkgs; [
                        agenix.outputs.packages.${system}.agenix
                        pkgs.openssl
                        pkgs.cfssl
                        (python3.withPackages (py-pkgs: with py-pkgs; []))
                    ];
                };
                manifests = pkgs.mkShell {
                    packages = with pkgs; [
                        kubernetes-helm
                        kubectl
                        k9s
                    ];
                };
            };
            nixosConfigurations = {
                cec-k8s-master = nixpkgs.lib.nixosSystem {
                    inherit system;

                    specialArgs = { inherit inputs; };
                    modules = [
                        agenix.nixosModules.default
                        ./hosts/k8s-master.nix
                    ];
                }; 
                cec-k8s-worker1 = nixpkgs.lib.nixosSystem {
                    inherit system;

                    specialArgs = { inherit inputs; };
                    modules = [
                        agenix.nixosModules.default
                        ./hosts/k8s-worker1.nix
                    ];
                }; 
                cec-k8s-worker2 = nixpkgs.lib.nixosSystem {
                    inherit system;

                    specialArgs = { inherit inputs; };
                    modules = [
                        agenix.nixosModules.default
                        ./hosts/k8s-worker2.nix
                    ];
                }; 
                cec-k8s-worker3 = nixpkgs.lib.nixosSystem {
                    inherit system;

                    specialArgs = { inherit inputs; };
                    modules = [
                        agenix.nixosModules.default
                        ./hosts/k8s-worker3.nix
                    ];
                }; 
            };
        };
}
