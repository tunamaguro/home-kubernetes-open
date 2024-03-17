## Install Cilium

1. Init cluster without kube-proxy
```bash
$ kubeadm init --skip-phases=addon/kube-proxy --other-option...
```

2. Setup Helm repository
```bash
$ helm repo add cilium https://helm.cilium.io/
```

3. Install Cilium
```bash
$ API_SERVER_IP=xxx.xxx.xxx.xxx
$ API_SERVER_PORT=xxx
$ helm install cilium cilium/cilium --version 1.15.2 \
    --namespace kube-system \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT}
    -f values.yaml
```

## Check Cilium setup

1. Wait Cilium node is ready
```bash
$ kubectl -n kube-system get pods -l k8s-app=cilium
```

2. Install Cilium CLI
```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

3.  Check Cilium status
```bash
$ cilium status --wait
```

4. Check network connectivity
```bash
$ cilium connectivity test
```

## Upgrade
```bash
$ helm cilium cilium/cilium  -n kube-system upgrade --version 1.15.2  --reuse-values -f values.yaml 
```

## Reference
- https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
- https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/