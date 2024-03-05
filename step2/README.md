## 概要

Service type: LoadBalancerやIngressなどの他から利用されるリソースをインストールします。現状利用しているものは以下の通りです

- MetalLB
- ingress-nginx
- external-dns
- cert-manager

## MetalLB用のIPアドレスの調整
1. `l2-loadbalancer/address_pool.yaml`のaddressesを使いたいIPアドレスの範囲に合わせて変更する。現状は`192.168.20.230`~`192.168.20.254`のレンジを使用している

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: primary-pool
  namespace: metallb
spec:
  addresses:
  - 192.168.20.230-192.168.20.254 # <--この部分
```

## external-dnsおよびcert-managerで利用するトークン作成およびシークレット作成

1. Cloudflareのトークンを作成する。それぞれで必要な権限は以下を確認すること
- external-dns: https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/cloudflare.md
- cert-manager: https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/

2. トークンをvaultに格納する
```bash
$ kubectl -n vault exec -it vault-0 -- sh
```

```bash
$ vault secrets enable -path kv kv-v2
```

```bash
$ vault kv put kv/external-dns/cf-token token=<your-token>
$ vault kv put kv/cert-manager/cf-token token=<your-token>
```

3. vaultから読み込む為のポリシーを作成する
```bash
$ vault policy write read-external-dns -  << EOF
path "kv/data/external-dns/*" {
    capabilities = ["read"]
}
EOF
$ vault policy write read-cert-manager -  << EOF
path "kv/data/cert-manager/*" {
    capabilities = ["read"]
}
EOF 
```

4. ロールを作成する
```bash
$ vault write auth/kubernetes/role/read-external-dns \
bound_service_account_names=default \
bound_service_account_namespaces=external-dns \
policies=read-external-dns
$ vault write auth/kubernetes/role/read-cert-manager \
bound_service_account_names=default \
bound_service_account_namespaces=cert-manager \
policies=read-cert-manager
```

5. リソースをデプロイする

```bash
$ argocd app create --file app.yaml 
$ argocd app sync argocd/step2
```