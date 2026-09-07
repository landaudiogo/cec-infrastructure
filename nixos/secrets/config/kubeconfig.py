from pathlib import Path

import json
import base64

SCRIPT_DIR = Path(__file__).parent
DECRYPTED_DIR = SCRIPT_DIR / "../.decrypted"

kubeconfig = {
    "apiVersion": "v1",
    "kind": "Config",
    "clusters": [
      {
        "name": "local",
        "cluster": {
            "certificate-authority-data": base64.b64encode(bytes((DECRYPTED_DIR / "root-ca.pem").read_text(), "utf-8")).decode(),
            "server":  "https://k8s-master.cec.dlandau.nl:6443",
        },
      },
    ],
    "users": [
      {
        "name": "cluster-admin",
        "user": {
            "client-certificate-data": base64.b64encode(bytes((DECRYPTED_DIR / "cluster-admin.pem").read_text(), "utf-8")).decode(),
            "client-key-data": base64.b64encode(bytes((DECRYPTED_DIR / "cluster-admin-key.pem").read_text(), "utf-8")).decode(),
        },
      }
    ],
    "contexts": [
        {
            "context": {
                "cluster": "local",
                "user": "cluster-admin",
            },
            "name": "local",
        }
    ],
    "current-context": "local",
}
print(json.dumps(kubeconfig, indent=4))
