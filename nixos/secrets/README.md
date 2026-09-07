# Generate

Root ca:
```bash
cfssl genkey -initca config/kube-pki-cacert-csr.json | cfssljson -bare ./.decrypted/root-ca
nix run github:ryantm/agenix#agenix -- -e root-ca.pem.age < .decrypted/root-ca.pem
nix run github:ryantm/agenix#agenix -- -e root-ca-key.pem.age < .decrypted/root-ca-key.pem
```

apitoken:
```bash
head -c 16 /dev/urandom | od -An -t x | tr -d ' ' | nix run github:ryantm/agenix#agenix -- -e apitoken.age
```

cluster-admin:
```bash
cfssl gencert -ca ./.decrypted/root-ca.pem -ca-key ./.decrypted/root-ca-key.pem config/cluster-admin-csr.json | cfssljson -bare ./.decrypted/cluster-admin
```

Generate cluster-admin kubeconfig:
```bash
nix-instantiate --json --eval -E "(let kubeconfig = import ./config/kubeconfig.nix; in kubeconfig)" | nix run nixpkgs#jq
```


# Re-key

Rekey agenix:
```bash
KEY="root-ca.pem"
nix run github:ryantm/agenix#agenix -- -d "${KEY}.age" > ".decrypted/${KEY}"
rm "${KEY}.age"
nix run github:ryantm/agenix#agenix -- -e "${KEY}.age" < ".decrypted/${KEY}"
```
