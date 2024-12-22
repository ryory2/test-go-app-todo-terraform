###########################################################
# Terraform Variables File
# このファイルはTerraformプロジェクト内で使用する変数を定義します。
###########################################################

###########################################################
# 一般設定
###########################################################

# プロバイダー用のリージョン変数
variable "aws_region" {
  description = "AWSのリージョン"
  type        = string
  default     = "ap-northeast-1" # 東京リージョンをデフォルト値として設定
}

# 共通のタグ用変数
variable "common_tags" {
  description = "リソースに付与する共通タグ"
  type        = map(string)
  default = {
    Name = "terraform-test" # 共通のNameタグ
  }
}

###########################################################
# リソース名設定
###########################################################

variable "vpc_name" {
  description = "VPCの名前タグ"
  type        = string
  default     = "terraform-vpc"
}

variable "internet_gateway_name" {
  description = "インターネットゲートウェイの名前タグ"
  type        = string
  default     = "terraform-igw"
}

variable "public_subnet_name_1" {
  description = "パブリックサブネットの1つ目の名前タグ"
  type        = string
  default     = "terraform-public-subnet-1"
}

variable "public_subnet_name_2" {
  description = "パブリックサブネットの2つ目の名前タグ"
  type        = string
  default     = "terraform-public-subnet-2"
}

variable "availability_zone_1" {
  description = "1つ目のアベイラビリティゾーン"
  type        = string
  default     = "ap-northeast-1a"
}

variable "availability_zone_2" {
  description = "2つ目のアベイラビリティゾーン"
  type        = string
  default     = "ap-northeast-1c"
}

variable "route_table_name_1" {
  description = "ルートテーブルの名前タグ1"
  type        = string
  default     = "terraform-public-rt-1"
}

variable "route_table_name_2" {
  description = "ルートテーブルの名前タグ2"
  type        = string
  default     = "terraform-public-rt-2"
}

variable "alb_name" {
  description = "Application Load Balancerの名前"
  type        = string
  default     = "ecs-nginx-alb"
}

variable "listener_name" {
  description = "ALBリスナーの名前"
  type        = string
  default     = "listener"
}

variable "target_group_name_frontend" {
  description = "ターゲットグループの名前"
  type        = string
  default     = "ecs-nginx-tg"
}

variable "target_group_name_backend" {
  description = "ターゲットグループの名前"
  type        = string
  default     = "ecs-nginx-tg"
}

variable "security_group_name_alb" {
  description = "セキュリティグループ（ALB）の名前"
  type        = string
  default     = "alb-sg"
}

variable "security_group_name_backend" {
  description = "セキュリティグループ（バックエンド）の名前"
  type        = string
  default     = "alb-sg"
}

variable "security_group_name_frontend" {
  description = "セキュリティグループ（フロントエンド）の名前"
  type        = string
  default     = "alb-sg"
}

variable "iam_role_name_ecs_execution_role" {
  description = "IAMロール(タスク実行ロール)の名前"
  type        = string
  default     = "ecsTaskExecutionRole"
}

variable "iam_role_name_ecs_role" {
  description = "IAMロール(タスクロール)の名前"
  type        = string
  default     = "ecsTaskRole"
}

variable "ecs_task_definition_family" {
  description = "ECSタスク定義のファミリー名"
  type        = string
  default     = "nginx-task"
}

variable "ecs_cluster_name" {
  description = "ECSクラスターの名前"
  type        = string
  default     = "terraform-cluster"
}

variable "ecs_service_name" {
  description = "ECSサービスの名前"
  type        = string
  default     = "nginx-service"
}

###########################################################
# リソースグループ設定
###########################################################

variable "resource_group_name" {
  description = "リソースグループの名前"
  type        = string
  default     = "prod-resource-group"
}

variable "resource_group_tags" {
  description = "リソースグループに含めるタグの条件"
  type        = map(string)
  default = {
    Environment = "Production"
  }
}

###########################################################
# コンテナ定義設定
###########################################################

variable "container_definitions" {
  description = "List of container definitions for the ECS task"
  type = list(object({
    name      = string
    image     = string
    essential = bool
    portMappings = list(object({
      containerPort = number
      hostPort      = number
      protocol      = string
    }))
    environment = optional(list(object({
      name  = string
      value = string
    })), [])
    logConfiguration = optional(object({
      logDriver = string
      options   = map(string)
    }), null)
  }))
  default = [
    {
      name      = "nginx"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/log"
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name         = "sidecar"
      image        = "busybox"
      essential    = false
      portMappings = []
      environment  = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/log"
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ]
}

###########################################################
# ロードバランサー設定
###########################################################

# フロントエンド
# ロードバランサー用のコンテナ名
variable "lb_container_name_frontend" {
  description = "Load Balancerで使用するコンテナの名前"
  type        = string
  default     = "nginx"
}

# ロードバランサー用のコンテナポート
variable "lb_container_port_frontend" {
  description = "Load Balancerで使用するコンテナのポート"
  type        = number
  default     = 80
}

# バックエンド
# ロードバランサー用のコンテナ名
variable "lb_container_name_backend" {
  description = "Load Balancerで使用するコンテナの名前"
  type        = string
  default     = "nginx"
}

# ロードバランサー用のコンテナポート
variable "lb_container_port_backend" {
  description = "Load Balancerで使用するコンテナのポート"
  type        = number
  default     = 80
}


###########################################################
# ドメイン設定
###########################################################
variable "domain_name" {
  description = "ドメイン名"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the existing ACM certificate"
  type        = string
}

variable "route53_zone_id" {
  description = "ID of the existing Route 53 Hosted Zone"
  type        = string
}
