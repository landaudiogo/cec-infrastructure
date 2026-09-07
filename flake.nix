{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/25.05";
        crate2nix = {
            url = "github:landaudiogo/crate2nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
    outputs = { self, nixpkgs, crate2nix, ... }@inputs:
    let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        frontend = pkgs.callPackage ./creds-server/frontend {};
    in
    {

        devShells.${system} =
            {
                default = pkgs.mkShell {
                    packages = with pkgs; [
                        (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
                        ]))
                    ] ++ [
                            zip
                            openssl
                            jre_minimal
                            confluent-platform
                        ];
                };
                frontend = pkgs.mkShell {
                    packages = with pkgs; [
                        nodejs
                        yarn
                    ];
                };
                backend = pkgs.mkShell {
                    packages = with pkgs; [
                        cargo
                        rustc
                        rust-analyzer
                        sqlite
                        pkg-config
                        openssl
                    ];
                    RUST_LOG="info";
                    CREDENTIALS_DIR="/home/landaudiogo/Repos/teaching/cec/cec-infrastructure/creds";
                    JWT_SECRET="terrible secret";
                };
            };
        packages.${system} =
            let
                crate2nixTools = crate2nix.lib.tools;
                crate = pkgs.callPackage (import ./creds-server/backend/default.nix) { inherit crate2nixTools; };
            in
            {
                default = self.packages.${system}.backend;
                backend = crate.rootCrate.build;
                frontend = frontend.package;
            };
        images.${system} =
            {
                backend = pkgs.dockerTools.buildImage {
                    name = "dclandau/cec-creds-backend";
                    tag = "latest";
                    copyToRoot = [
                        self.packages.${system}.backend
                        pkgs.cacert
                    ];
                    config = {
                        Entrypoint = [ "/bin/backend" ];
                    };
                };
                frontend = frontend.image;
            };
    };
}

