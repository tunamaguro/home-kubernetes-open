## 概要
他リソースを起動するのに必要なコンポーネントをインストールします。現状利用しているコンポーネントは以下の通りです

- ArgoCD
- local-path-provisioner
- Vault

## 1. ArgoCDのインストール
1. `argocd`ディレクトリに移動します
```bash
$ cd argocd
```

2. `terraform`を初期化します
```bash
$ terraform init
```

3. `ArgoCD`をデプロイします
```bash
$ terraform plan
$ terraform apply
```

4. `ArgoCD`にログインするためのパスワードを確認します
```bash
$ terraform output -json
```

5. `argocd`にログインする
```bash
$ kubectl port-forward -n argocd services/argocd-server 8080:443 (別ターミナルで)
$ argocd login localhost:8080
```

## 2. Vault以外のコンポーネントのデプロイ

```bash
$ argocd app create --file base-apps.yaml
$ $ argocd app sync argocd/base-apps
```

## 3. Vaultのインストール
1. GCPにてKMS用の鍵とサービスアカウントを作成する。サービスアカウントの鍵は`vault/credentials.json`という名前で保存しておく

2. `vault/vault-app.yaml.example`の`gcpckms`を設定に合わせて書き換え、`vault/vault-app.yaml`として保存する

3. vault Applicationを作成する
```bash
$ argocd app create --file vault/vault-app.yaml 
```

4. 同期する(この時同期が完了しないが気にしないでよい)
```bash
$ argocd app sync argocd/vault
```

4. KMSを利用するためのSecretを作成する
```bash
$ kubectl create secret generic gcp-kms-sa -n vault --from-file=vault/credentials.json 
```

5. vaultをunsealする
```bash
$ kubectl -n vault exec -it vault-0 -- vault operator init > vault/root_token
```

6. kubernetesの認証を構成する。詳細はドキュメント確認すること(https://developer.hashicorp.com/vault/docs/auth/kubernetes)
```bash
$ vault auth enable kubernetes
$ vault write auth/kubernetes/config kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
```

## 4. Vault-Secrets-Operatorの動作チェック

1. 動作チェックを行う。まずvaultにログインする
```bash
$ kubectl -n vault exec -it vault-0 -- sh
```
2. kv-v2シークレットエンジンを作成する
```bash
$ vault secrets enable -path demo-secret kv-v2
```

3. 適当なシークレットを作成する
```bash
$ vault kv put demo-secret/example user=fuga password=hoge123
```

4. 先ほど作成したシークレットを参照できるポリシーを作成する
```bash
$ vault policy write demo-secret - <<EOF
path "demo-secret/*" {
    capabilities = ["read"]
}
EOF
```

5. ポリシーを利用するロールを作成する。今回は`secret-demo`名前空間の`default`サービスアカウントに`demo-secret`ポリシーを紐づける

```bash
$ vault write auth/kubernetes/role/read-demo-secret \
bound_service_account_names=default \
bound_service_account_namespaces=secret-demo \
policies=demo-secret
```

> 設定を確認するには`vault read auth/kubernetes/role/read-demo-secret`を実行

6. デモ用アプリを作成する
```bash
$ kubectl apply -f secret-operator/tests/
```

7. シークレットが設定されているか確認する
```bash
$ kubectl -n secret-demo exec -it deployments/secret-demo -- ls -l /etc/secrets
total 0
lrwxrwxrwx 1 root root 11 Mar  3 16:23 _raw -> ..data/_raw
lrwxrwxrwx 1 root root 15 Mar  3 16:23 password -> ..data/password
lrwxrwxrwx 1 root root 11 Mar  3 16:23 user -> ..data/user
```

```bash
$ kubectl -n secret-demo exec -it deployments/secret-demo -- cat /etc/secrets/user
fuga
```

```bash
$ kubectl -n secret-demo exec -it deployments/secret-demo -- cat /etc/secrets/password
hoge123
```

8. シークレットを変更したときに変更されることを確認する
```bash
$ vault kv put demo-secret/example user=foo password=bar777
```

```bash
$ kubectl -n secret-demo exec -it deployments/secret-demo -- cat /etc/secrets/user
foo
```

```bash
$ kubectl -n secret-demo exec -it deployments/secret-demo -- cat /etc/secrets/password
bar777
```

```bash
$ kubectl -n secret-demo get rs
# replicasetsが増えていることを確認する
```

9. 作成したリソースを削除する

```bash
$ kubectl delete -f secret-operator/tests/
```

```bash
$ vault delete auth/kubernetes/role/read-demo-secret
$ vault policy delete demo-secret
$ vault kv delete demo-secret/example
$ vault secrets disable demo-secret
```