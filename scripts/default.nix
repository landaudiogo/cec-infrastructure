{ pkgs ? import <nixpkgs> {}, tag, ... }:
let
    inherit (pkgs) stdenv lib dockerTools;
in
rec {
    packages = {
        create-topics = 
            let
                runtimeDeps = with pkgs; [
                    coreutils
                    apacheKafka
                    bash
                ];
            in
            stdenv.mkDerivation {
                name = "create-topics";
                dontUnpack = true;
                buildInputs = [ pkgs.makeWrapper ];
                installPhase = ''
                    mkdir -p $out/bin
                    install -Dm555 ${./create-topics.sh} $out/bin/create-topics
                    wrapProgram $out/bin/create-topics --prefix PATH : ${lib.makeBinPath runtimeDeps}
                '';
            };
    };
    images = {
        create-topics = dockerTools.buildImage {
            name = "dclandau/cec-create-topics";
            inherit tag;
            copyToRoot = [
                packages.create-topics
            ];
            config = {
                Entrypoint = [ "/bin/create-topics" ];
            };
        };
    };
}
