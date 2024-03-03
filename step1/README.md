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

## 2. local-path-provisioner

> この手順は2024/03に書かれたものです。更新により変更される可能性があるため公式リポジトリを確認してください
> https://github.com/rancher/local-path-provisioner

1. local-path-provisioner Applicationを作成する
```bash
$ argocd app create --file local-path-provisioner/local-path-provisioner-app.yaml 
```

2. 同期する
```bash
$ argocd app sync argocd/local-path-provisioner 
```

2. `STATUS`がHealtyなことを確認する
```bash
$ argocd app list
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