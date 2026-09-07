Install gateway:
```bash
kubectl kustomize --enable-helm ./gateway-controller | kubectl apply -f - --server-side
kubectl kustomize --enable-helm ./gateway | kubectl apply -f - --server-side
kubectl kustomize --enable-helm ./cert-manager | kubectl apply -f - --server-side
```
