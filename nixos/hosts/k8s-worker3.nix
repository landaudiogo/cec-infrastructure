{
    imports = [
        ../modules/base-ami.nix
        ../modules/k8s-worker.nix
    ];
    
    services.kubernetes.kubelet.hostname = "k8s-worker3";
    networking.hostName = "ip-10-0-1-210";
    services.kubernetes.kubelet.extraOpts = "--node-labels=envoy=true";
}
