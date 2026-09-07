{ inputs, ... }:
{
    imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/amazon-image.nix"
    ];


    services.openssh = {
        enable = true;
        hostKeys = [{
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
        }];
    };

    # system.hostPlatform = "x86_64-linux";
    system.stateVersion = "25.11";

    nix.settings.experimental-features = [ "flakes" "nix-command" ];

    networking.hosts = {
        "10.0.1.197" = [ "k8s-master" ];
        "10.0.1.83" = [ "k8s-worker1" ];
        "10.0.1.107" = [ "k8s-worker2" ];
        "10.0.1.210" = [ "k8s-worker3" ];
    };
}
