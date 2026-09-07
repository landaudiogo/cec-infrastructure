Open ports for security group:

tcp 22     external
tcp 8888
tcp 6443
tcp 10250
udp 8285   internal
udp 8472   internal

to make it easier, all tcp and udp ports are available for the security group the vms are in
0-65535 tcp launch-wizard-1
0-65535 udp launch-wizard-1

```bash
nixos-rebuild --flake .#cec-k8s-master --target-host root@34.253.139.248 switch
nixos-rebuild --flake .#cec-k8s-worker1 --target-host root@108.132.235.40 switch
nixos-rebuild --flake .#cec-k8s-worker2 --target-host root@34.249.239.191 switch
nixos-rebuild --flake .#cec-k8s-worker3 --target-host root@34.248.168.117 switch
```
