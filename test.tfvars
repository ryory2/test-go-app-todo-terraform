# 「tfvars」は「terraform.tfvars」を自動で読み込む。別名を利用する場合、「-var-fileオプション」を利用する。
# terraform apply -var-file="staging.tfvars"

###########################################################
# Terraform Variables File
# このファイルはTerraformプロジェクト内で使用する変数を定義します。
###########################################################

###########################################################
# 一般設定
###########################################################

# AWSリージョンの設定
aws_region = "ap-northeast-1" # 使用するAWSリージョンを東京リージョンに設定

###########################################################
# 共通タグ設定
###########################################################

common_tags = {                  # 全てのリソースに共通して付与するタグの定義
  Environment = "terraform-test" # 環境を示すタグ（例: テスト環境）
  Owner       = "ore"            # リソースの所有者を示すタグ
}

###########################################################
# リソース名設定
###########################################################

vpc_name                         = "terraform-test-vpc"             # VPCの名前を設定
internet_gateway_name            = "terraform-test-igw"             # インターネットゲートウェイの名前を設定
public_subnet_name_1             = "terraform-test-public-subnet-1" # 1つ目のパブリックサブネットの名前を設定
public_subnet_name_2             = "terraform-test-public-subnet-2" # 2つ目のパブリックサブネットの名前を設定
availability_zone_1              = "ap-northeast-1a"                # 使用する1つ目のアベイラビリティゾーンを設定
availability_zone_2              = "ap-northeast-1c"                # 使用する2つ目のアベイラビリティゾーンを設定
route_table_name_1               = "terraform-test-public-rt-1"     # 1つ目のルートテーブルの名前を設定
route_table_name_2               = "terraform-test-public-rt-2"     # 2つ目のルートテーブルの名前を設定
security_group_name_alb          = "terraform-test-alb-sg"          # セキュリティグループ（alb）の名前を設定
security_group_name_backend      = "terraform-test-backend-sg"      # セキュリティグループ（backend）の名前を設定
security_group_name_frontend     = "terraform-test-frontend-sg"     # セキュリティグループ（frontend）の名前を設定
alb_name                         = "terraform-test-ecs-nginx-alb"   # ALBの名前を設定
target_group_name_frontend       = "terraform-test-ecs-frontend-tg" # ターゲットグループの名前を設定
target_group_name_backend        = "terraform-test-ecs-backend-tg"  # ターゲットグループの名前を設定
listener_name                    = "terraform-test-listener"        # ALBリスナーの名前を設定
iam_role_name_ecs_role           = "terraformEcsTaskRole"           # ECSタスク用IAMロールの名前を設定
iam_role_name_ecs_execution_role = "terraformEcsTaskExecutionRole"  # ECSタスク実行用IAMロールの名前を設定
ecs_task_definition_family       = "terraform-test-nginx-family"    # ECSタスク定義のファミリー名を設定
ecs_cluster_name                 = "terraform-test-ecs-cluster"     # ECSクラスターの名前を設定
ecs_service_name                 = "terraform-test-nginx-service"   # ECSサービスの名前を設定
domain_name                      = "impierrot.click"                # ホストゾーンの名前
acm_certificate_arn              = "arn:aws:acm:ap-northeast-1:990606419933:certificate/25144a76-2e9b-4b86-a32f-ebcbb330d81f"
route53_zone_id                  = "Z06442292XEXGMHMQLXK9" # 実際のホストゾーンIDに置き換えてください


###########################################################
# リソースグループ設定
###########################################################

resource_group_name = "terraform-test-resource-group" # リソースグループの名前を設定

resource_group_tags = {          # リソースグループに含めるタグの条件を設定
  Environment = "terraform-test" # 環境がterraform-testのリソースを含める
}

###########################################################
# コンテナ定義設定
###########################################################

container_definitions = [
  {
    name      = "frontend-container"                                                      # コンテナの名前を設定
    image     = "990606419933.dkr.ecr.ap-northeast-1.amazonaws.com/react-frontend:latest" # コンテナイメージを設定
    essential = true                                                                      # このコンテナが必須かどうかを設定
    portMappings = [                                                                      # コンテナのポートマッピングを設定
      {
        containerPort = 80    # コンテナ内でリッスンするポート
        hostPort      = 80    # ホスト側のポート
        protocol      = "tcp" # プロトコルをTCPに設定
      }
    ]
    environment = [ # 環境変数を設定
      {
        name  = "REACT_APP_SPRING_DATASOURCE_USERNAME" # 環境変数の名前
        value = "aaaaaaaaaaaaaaaaaaa"                  # 環境変数の値
      },
      {
        name  = "ENV_VAR_2" # 別の環境変数の名前
        value = "value2"    # 別の環境変数の値
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/terraform-test-nginx-family"
        "awslogs-region"        = "ap-northeast-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }
  ,
  {
    name      = "backend-container"                                                           # コンテナの名前を設定
    image     = "990606419933.dkr.ecr.ap-northeast-1.amazonaws.com/springboot-backend:latest" # コンテナイメージを設定
    essential = true                                                                          # このコンテナが必須かどうかを設定
    portMappings = [                                                                          # コンテナのポートマッピングを設定
      {
        containerPort = 8080  # コンテナ内でリッスンするポート
        hostPort      = 8080  # ホスト側のポート
        protocol      = "tcp" # プロトコルをTCPに設定
      }
    ]
    environment = [ # 環境変数を設定
      {
        name  = "SPRING_DATASOURCE_USERNAME" # 環境変数の名前
        value = "admin"                      # 環境変数の値
      },
      {
        name  = "SPRING_DATASOURCE_PASSWORD" # 別の環境変数の名前
        value = "XUiavro7C49If5uWgvEb"       # 別の環境変数の値
      },
      {
        name  = "SPRING_DATASOURCE_URL"                                                             # 別の環境変数の名前
        value = "jdbc:mysql://database-1.cdi2jb6zb2yt.ap-northeast-1.rds.amazonaws.com:3306/tododb" # 別の環境変数の値
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/terraform-test-nginx-family"
        "awslogs-region"        = "ap-northeast-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }
  # 2つ目のコンテナを定義する場合
  # ,
  # {
  #   name              = "sidecar" # 2つ目のコンテナの名前を設定
  #   image             = "busybox" # コンテナイメージを設定
  #   essential         = false     # このコンテナが必須かどうかを設定
  #   portMappings      = []        # ポートマッピングを設定（必要に応じて）
  #   environment       = []        # 環境変数を設定（必要に応じて）
  # }
]

###########################################################
# ロードバランサー設定
###########################################################

lb_container_name_frontend = "frontend-container" # ロードバランサーで使用するコンテナの名前（container_definitions.nameと同じにすること）
lb_container_port_frontend = 80                   # ロードバランサーで使用するコンテナのポート
lb_container_name_backend  = "backend-container"  # ロードバランサーで使用するコンテナの名前（container_definitions.nameと同じにすること）
lb_container_port_backend  = 8080                 # ロードバランサーで使用するコンテナのポート
