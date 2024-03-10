## 概要

いろいろ便利なものをインストールします。現状利用しているものは以下の通りです

- external-dns
- cert-manager
- cloudflare-tunnel

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

## cloudflare tunnel用のシークレットを作成する
1. tunnel用のトークンをvaultに登録する
```bash
$ vault kv put kv/cloudflare-tunnel/tunnel-1 token=<token>
$ vault kv put kv/cloudflare-tunnel/tunnel-2 token=<token>
```

2. ポリシーを作成する
```bash
$ vault policy write read-cloudflare-tunnel -  << EOF
path "kv/data/cloudflare-tunnel/*" {
    capabilities = ["read"]
}
EOF
```

3. ロールを作成する
```bash
$ vault write auth/kubernetes/role/read-cloudflare-tunnel \
bound_service_account_names=default \
bound_service_account_namespaces=cloudflare-tunnel \
policies=read-cloudflare-tunnel
```

## Applicationのデプロイ

1. リソースをデプロイする

```bash
$ argocd app create --file app.yaml 
$ argocd app sync argocd/base-extensions
```