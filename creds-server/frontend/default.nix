{ pkgs, tag, ... }:
let
    frontendPackage = pkgs.buildNpmPackage {
        name = "creds-server-frontend";
        nativeBuildInputs = with pkgs; [
            nodejs
            yarn
            zip
        ];
        src = ./.;
        npmDepsHash = "sha256-JuvAU7WgQSTIM7bzZF9yEYEbNnoWn4x90p/2nitfWSY=";
        buildPhase = ''
            npm run build
            # zip -r dist.zip dist
        '';
        installPhase = ''
            # mv dist.zip $out
            mkdir $out
            mv dist $out/dist
        '';
    };
    caddyfile = pkgs.writeTextDir "etc/caddy/Caddyfile" ''
        :80 {
            root * /dist

            handle {
                try_files {path}.html {path} /
                file_server
            }
        }
    '';
in
rec {
    package = frontendPackage;
    image = pkgs.dockerTools.buildImage {
        name = "dclandau/cec-creds-frontend";
        inherit tag;
        copyToRoot = [
            caddyfile
            pkgs.caddy
            package
        ];
        config = {
            Entrypoint = [ 
                "/bin/caddy"
                "run"
                "--config"
                "/etc/caddy/Caddyfile"
            ];
        };
    };
}
