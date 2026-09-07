{
    imports = [
        ../modules/base-ami.nix
        ../modules/k8s-master.nix
    ];
    
    services.kubernetes.kubelet.hostname = "k8s-master";
    networking.hostName = "ip-10-0-1-197";
}
