let
    landaudiogo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1COVqebDaCGC+bD3A7MgmFYMf5lMrHDUz+MBUn/oej landaudiogo";
    k8s-master = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9BkabF1K2b04I0biV4k9f/015Pq8dtbpNT+N78MRL7 root@ip-10-0-1-197.eu-west-1.compute.internal";
    k8s-worker1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClJKW3djIHZ+BXRQ+XAz0GCpD638QKdq31uIToXNWzn root@ip-10-0-1-83.eu-west-1.compute.internal";
    k8s-worker2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyuvMEgFoQ6addEn/rZS1TpopmMVjucmI0NUW1RIfbc root@ip-10-0-1-107.eu-west-1.compute.internal";
    k8s-worker3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBs1h3EHuL2i6SGD1NPmtWku1YxjHCpBsLSOlZpt1HF0 root@ip-10-0-1-210.eu-west-1.compute.internal";
    k8s-worker-medium1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJsi8rWE14VFJM4ArQ3SsKaaPhJQvITzxfGGyWL/Geg+ root@ip-10-0-1-135.eu-west-1.compute.internal";
    k8s-worker-medium2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAGBtTGBDXCpiwm+QCZ9uby07bxDkPjyqSnxSMX/4Eh5 root@ip-10-0-1-17.eu-west-1.compute.internal";
    k8s-worker-medium3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBVMWgwdgCVKabm1nO1h6a7Vuy0DteGFX+pclhTMBADH root@ip-10-0-1-198.eu-west-1.compute.internal";
in
{
    "apitoken.age".publicKeys = [ 
        landaudiogo 
        k8s-master 
        k8s-worker1 k8s-worker2 k8s-worker3 
        k8s-worker-medium1 k8s-worker-medium2 k8s-worker-medium3 
    ];
    "root-ca.pem.age".publicKeys = [ 
        landaudiogo 
        k8s-master 
        k8s-worker1 k8s-worker2 k8s-worker3
        k8s-worker-medium1 k8s-worker-medium2 k8s-worker-medium3 
    ];

    "root-ca-key.pem.age".publicKeys = [ landaudiogo k8s-master ];
    "creds-key.json.age".publicKeys = [ landaudiogo k8s-master ];
    "creds-backend.json.age".publicKeys = [ landaudiogo k8s-master ];
    "kafka-keystore.json.age".publicKeys = [ landaudiogo k8s-master ];
    "database-secret.json.age".publicKeys = [ landaudiogo k8s-master ];
    "demo-mock.json.age".publicKeys = [ landaudiogo k8s-master ];
    "demo-consistency.json.age".publicKeys = [ landaudiogo k8s-master ];
    "demo-stress.json.age".publicKeys = [ landaudiogo k8s-master ];
    "experiment-producer-mock-secret.json.age".publicKeys = [ landaudiogo k8s-master ];
    "experiment-producer-consistency-secret.json.age".publicKeys = [ landaudiogo k8s-master ];
    "experiment-producer-stress-secret.json.age".publicKeys = [ landaudiogo k8s-master ];
    "database-init.json.age".publicKeys = [ landaudiogo k8s-master ];
    "external-services.yaml.age".publicKeys = [ landaudiogo k8s-master ];
    "grafana.json.age".publicKeys = [ landaudiogo k8s-master ];

    "students.json.age".publicKeys = [ landaudiogo ];
    "groups.json.age".publicKeys = [ landaudiogo ];
    "creds-key.age".publicKeys = [ landaudiogo ];
    "kafka-keystore-key.age".publicKeys = [ landaudiogo ];
    "experiment-producer-mock.json.age".publicKeys = [ landaudiogo ];
    "experiment-producer-consistency.json.age".publicKeys = [ landaudiogo ];
    "experiment-producer-stress.json.age".publicKeys = [ landaudiogo ];
    "init.sql.age".publicKeys = [ landaudiogo ];
    "http-group-id.age".publicKeys = [ landaudiogo ];
    "event-secret.age".publicKeys = [ landaudiogo ];
}
