{
    imports = [
        ../modules/base-ami.nix
        ../modules/k8s-worker.nix
    ];
    
    services.kubernetes.kubelet.hostname = "k8s-worker1";
    networking.hostName = "ip-10-0-1-83";
    services.kubernetes.kubelet.extraOpts = "--node-labels=envoy=true";
}
