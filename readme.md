## 使い方
- このフォルダ内でコンソールを開く
## 前提
- Amazon CLIが利用（認証情報を登録している）
## 各手順
　「terraform init」初期化
　「terraform validate」バリデーションチェック
　「terraform plan -var-file="test.tfvars"」標準出力に内容が表示されるので実行内容をチェック
　「terraform apply -var-file="test.tfvars" -auto-approve」実行内容をAWSへ適用
　「terraform destroy -var-file="test.tfvars"」すべて削除