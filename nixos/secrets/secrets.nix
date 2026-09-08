let
    landaudiogo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1COVqebDaCGC+bD3A7MgmFYMf5lMrHDUz+MBUn/oej landaudiogo";
    k8s-master = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9BkabF1K2b04I0biV4k9f/015Pq8dtbpNT+N78MRL7 root@ip-10-0-1-197.eu-west-1.compute.internal";
    k8s-worker1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClJKW3djIHZ+BXRQ+XAz0GCpD638QKdq31uIToXNWzn root@ip-10-0-1-83.eu-west-1.compute.internal";
    k8s-worker2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyuvMEgFoQ6addEn/rZS1TpopmMVjucmI0NUW1RIfbc root@ip-10-0-1-107.eu-west-1.compute.internal";
    k8s-worker3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBs1h3EHuL2i6SGD1NPmtWku1YxjHCpBsLSOlZpt1HF0 root@ip-10-0-1-210.eu-west-1.compute.internal";
in
{
    "apitoken.age".publicKeys = [ landaudiogo k8s-master k8s-worker1 k8s-worker2 k8s-worker3 ];
    "root-ca.pem.age".publicKeys = [ landaudiogo k8s-master k8s-worker1 k8s-worker2 k8s-worker3 ];
    "root-ca-key.pem.age".publicKeys = [ landaudiogo k8s-master ];
    "creds-key.age".publicKeys = [ landaudiogo ];
    "creds-key.json.age".publicKeys = [ landaudiogo k8s-master ];
}
