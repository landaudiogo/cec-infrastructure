{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
        cec-assignment.url = "github:ec-labs/cec-assignment";
        agenix = {
            url = "github:ryantm/agenix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
    outputs = { self, nixpkgs, cec-assignment, agenix, ... }@inputs:
        let
            system = "x86_64-linux";
            pkgs = import nixpkgs { inherit system; };
        in
        {
            devShells.${system} = {
                default = pkgs.mkShell {
                    packages = with pkgs; [
                        agenix.outputs.packages.${system}.agenix
                        cec-assignment.outputs.packages.${system}.notifications-service
                        pkgs.openssl
                        pkgs.cfssl
                        (python3.withPackages (py-pkgs: with py-pkgs; [
                            jinja2
                        ]))
                        jre_minimal
                        jq
                        zip
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

                cec-k8s-worker-medium1 = nixpkgs.lib.nixosSystem {
                    inherit system;

                    specialArgs = { inherit inputs; };
                    modules = [
                        agenix.nixosModules.default
                        ./hosts/k8s-worker-medium1.nix
                    ];
                }; 
                cec-k8s-worker-medium2 = nixpkgs.lib.nixosSystem {
                    inherit system;

                    specialArgs = { inherit inputs; };
                    modules = [
                        agenix.nixosModules.default
                        ./hosts/k8s-worker-medium2.nix
                    ];
                }; 
                cec-k8s-worker-medium3 = nixpkgs.lib.nixosSystem {
                    inherit system;

                    specialArgs = { inherit inputs; };
                    modules = [
                        agenix.nixosModules.default
                        ./hosts/k8s-worker-medium3.nix
                    ];
                }; 
            };
        };
}
