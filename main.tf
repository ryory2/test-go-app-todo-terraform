###########################################################
# Terraform Main Configuration
# このファイルはTerraformプロジェクトの主要なリソースを定義します。
###########################################################

# 変数の利用: 各リソースブロック内でvar.<変数名>を使用して、変数を参照
# 「resource "aws_vpc" "リソース名" {]」リソース名: Terraform内でそのリソースを参照するためのローカル名
###########################################################
# プロバイダー設定
###########################################################

provider "aws" {
  region = var.aws_region
}

###########################################################
# ネットワークリソース設定
###########################################################

# VPCの作成
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16" # VPCのIPアドレス範囲を指定
  enable_dns_support   = true          # DNSサポートを有効化
  enable_dns_hostnames = true          # DNSホスト名を有効化

  tags = merge(var.common_tags, {
    Name = var.vpc_name
  })
}

# インターネットゲートウェイの作成
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id # 作成したVPCに関連付け

  tags = merge(var.common_tags, {
    Name = var.internet_gateway_name
  })
}

# パブリックサブネットの作成（1つ目）
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.vpc.id          # 作成したVPCに関連付け
  cidr_block        = "10.0.1.0/24"           # サブネットのIPアドレス範囲
  availability_zone = var.availability_zone_1 # アベイラビリティゾーンを指定

  tags = merge(var.common_tags, {
    Name = var.public_subnet_name_1
  })
}

# パブリックサブネットの作成（2つ目）
resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.vpc.id          # 作成したVPCに関連付け
  cidr_block        = "10.0.2.0/24"           # サブネットのIPアドレス範囲（適宜調整）
  availability_zone = var.availability_zone_2 # 2つ目のアベイラビリティゾーンを指定

  tags = merge(var.common_tags, {
    Name = var.public_subnet_name_2
  })
}

# ルートテーブルの作成（1つ目）
resource "aws_route_table" "public_rt_1" {
  vpc_id = aws_vpc.vpc.id # 作成したVPCに関連付け

  # 0.0.0.0/0（全てのIPv4アドレス）へのルートをインターネットゲートウェイに設定
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.common_tags, {
    Name = var.route_table_name_1
  })
}

# ルートテーブルの作成（2つ目）
resource "aws_route_table" "public_rt_2" {
  vpc_id = aws_vpc.vpc.id # 作成したVPCに関連付け

  # 0.0.0.0/0（全てのIPv4アドレス）へのルートをインターネットゲートウェイに設定
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.common_tags, {
    Name = var.route_table_name_2
  })
}

# サブネットとルートテーブルの関連付け（1つ目）
resource "aws_route_table_association" "public_association_1" {
  subnet_id      = aws_subnet.subnet_1.id         # 作成したパブリックサブネットに関連付け
  route_table_id = aws_route_table.public_rt_1.id # 作成したルートテーブルに関連付け
}

# サブネットとルートテーブルの関連付け（2つ目）
resource "aws_route_table_association" "public_association_2" {
  subnet_id      = aws_subnet.subnet_2.id         # 作成した2つ目のパブリックサブネットに関連付け
  route_table_id = aws_route_table.public_rt_2.id # 作成した2つ目のルートテーブルに関連付け
}

###########################################################
# ECSクラスター設定
###########################################################

# ECSクラスターの作成
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name # クラスターの名前

  tags = merge(var.common_tags, {
    Name = var.ecs_cluster_name
  })
}

###########################################################
# IAMロール設定
###########################################################

# IAMロールの作成（タスクロール）
resource "aws_iam_role" "ecs_task_role" {
  name = var.iam_role_name_ecs_role # ロールの名前

  # ロールの信頼ポリシーを設定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com" # ECSタスクサービスがこのロールを引き受けることを許可
      }
    }]
  })

  # 管理ポリシーをアタッチ（タスク実行に必要な権限）
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = merge(var.common_tags, {
    Name = var.iam_role_name_ecs_role
  })
}

# IAMロールの作成（タスク実行ロール）
resource "aws_iam_role" "ecs_task_execution_role" {
  name = var.iam_role_name_ecs_execution_role # ロールの名前

  # ロールの信頼ポリシーを設定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com" # ECSタスクサービスがこのロールを引き受けることを許可
      }
    }]
  })

  # 管理ポリシーをアタッチ（タスク実行に必要な権限）
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]

  tags = merge(var.common_tags, {
    Name = var.iam_role_name_ecs_execution_role
  })
}

###########################################################
# セキュリティグループ設定
###########################################################

# セキュリティグループの作成（ALB用）
resource "aws_security_group" "alb_sg" {
  name        = var.security_group_name_alb  # セキュリティグループの名前
  description = "Allow HTTP inbound traffic" # 説明
  vpc_id      = aws_vpc.vpc.id               # 作成したVPCに関連付け

  # インバウンドルールの設定
  ingress {
    description = "HTTP from anywhere" # ルールの説明（SG→ALBの順でリクエストが処理されるが、80も許可しないとALBまでたどり着かずリダイレクトがされないため許可）
    from_port   = 80                   # 許可するポート範囲の開始
    to_port     = 80                   # 許可するポート範囲の終了
    protocol    = "tcp"                # プロトコルをTCPに設定
    cidr_blocks = ["0.0.0.0/0"]        # 全世界からのアクセスを許可
  }

  # インバウンドルールの設定
  ingress {
    description = "backend"     # ルールの説明（8080については許可せず、ALBが/api/*の場合に8080へルーティングする）
    from_port   = 8080          # 許可するポート範囲の開始
    to_port     = 8080          # 許可するポート範囲の終了
    protocol    = "tcp"         # プロトコルをTCPに設定
    cidr_blocks = ["0.0.0.0/0"] # 全世界からのアクセスを許可
  }

  # インバウンドルールの設定
  ingress {
    description = "https"       # ルールの説明
    from_port   = 443           # 許可するポート範囲の開始
    to_port     = 443           # 許可するポート範囲の終了
    protocol    = "tcp"         # プロトコルをTCPに設定
    cidr_blocks = ["0.0.0.0/0"] # 全世界からのアクセスを許可
  }

  # アウトバウンドルールの設定
  egress {
    from_port   = 0             # 許可するポート範囲の開始
    to_port     = 0             # 許可するポート範囲の終了
    protocol    = "-1"          # 全てのプロトコルを許可
    cidr_blocks = ["0.0.0.0/0"] # 全世界へのアクセスを許可
  }

  tags = merge(var.common_tags, {
    Name = var.security_group_name_alb
  })
}

# # セキュリティグループの作成（バックエンド用）
# resource "aws_security_group" "backend_sg" {
#   name        = var.security_group_name_backend # セキュリティグループの名前
#   description = "Allow HTTP inbound traffic"    # 説明
#   vpc_id      = aws_vpc.vpc.id                  # 作成したVPCに関連付け

#   # # インバウンドルールの設定
#   # ingress {
#   #   description = "backend" # ルールの説明
#   #   from_port   = 8080      # 許可するポート範囲の開始
#   #   to_port     = 8080      # 許可するポート範囲の終了
#   #   protocol    = "tcp"     # プロトコルをTCPに設定
#   #   # cidr_blocks = ["0.0.0.0/0"] # 全世界からのアクセスを許可
#   #   security_groups = [aws_security_group.alb_sg.id] # ALBのSGからのトラフィックのみ許可
#   # }

#   # インバウンドルールの設定
#   ingress {
#     description = "https"       # ルールの説明
#     from_port   = 443           # 許可するポート範囲の開始
#     to_port     = 443           # 許可するポート範囲の終了
#     protocol    = "tcp"         # プロトコルをTCPに設定
#     cidr_blocks = ["0.0.0.0/0"] # 全世界からのアクセスを許可
#   }

#   # インバウンドルールの設定
#   ingress {
#     description = "https"       # ルールの説明
#     from_port   = 8080          # 許可するポート範囲の開始
#     to_port     = 8080          # 許可するポート範囲の終了
#     protocol    = "tcp"         # プロトコルをTCPに設定
#     cidr_blocks = ["0.0.0.0/0"] # 全世界からのアクセスを許可
#   }

#   # インバウンドルールの設定
#   ingress {
#     description = "https"       # ルールの説明
#     from_port   = 80            # 許可するポート範囲の開始
#     to_port     = 80            # 許可するポート範囲の終了
#     protocol    = "tcp"         # プロトコルをTCPに設定
#     cidr_blocks = ["0.0.0.0/0"] # 全世界からのアクセスを許可
#   }

#   # アウトバウンドルールの設定
#   egress {
#     from_port   = 0             # 許可するポート範囲の開始
#     to_port     = 0             # 許可するポート範囲の終了
#     protocol    = "-1"          # 全てのプロトコルを許可
#     cidr_blocks = ["0.0.0.0/0"] # 全世界へのアクセスを許可
#   }

#   tags = merge(var.common_tags, {
#     Name = var.security_group_name_backend
#   })
# }

# # セキュリティグループの作成（フロントエンド用）
# resource "aws_security_group" "frontend_sg" {
#   name        = var.security_group_name_frontend # セキュリティグループの名前
#   description = "Allow HTTP inbound traffic"     # 説明
#   vpc_id      = aws_vpc.vpc.id                   # 作成したVPCに関連付け

#   # # インバウンドルールの設定
#   # ingress {
#   #   description = "frontend" # ルールの説明
#   #   from_port   = 80         # 許可するポート範囲の開始
#   #   to_port     = 80         # 許可するポート範囲の終了
#   #   protocol    = "tcp"      # プロトコルをTCPに設定
#   #   # cidr_blocks = ["0.0.0.0/0"] # 全世界からのアクセスを許可
#   #   security_groups = [aws_security_group.alb_sg.id] # ALBのSGからのトラフィックのみ許可
#   # }

#   # インバウンドルールの設定
#   ingress {
#     description = "https"       # ルールの説明
#     from_port   = 443           # 許可するポート範囲の開始
#     to_port     = 443           # 許可するポート範囲の終了
#     protocol    = "tcp"         # プロトコルをTCPに設定
#     cidr_blocks = ["0.0.0.0/0"] # 全世界からのアクセスを許可
#   }

#   # インバウンドルールの設定
#   ingress {
#     description = "https"       # ルールの説明
#     from_port   = 8080          # 許可するポート範囲の開始
#     to_port     = 8080          # 許可するポート範囲の終了
#     protocol    = "tcp"         # プロトコルをTCPに設定
#     cidr_blocks = ["0.0.0.0/0"] # 全世界からのアクセスを許可
#   }

#   # インバウンドルールの設定
#   ingress {
#     description = "https"       # ルールの説明
#     from_port   = 80            # 許可するポート範囲の開始
#     to_port     = 80            # 許可するポート範囲の終了
#     protocol    = "tcp"         # プロトコルをTCPに設定
#     cidr_blocks = ["0.0.0.0/0"] # 全世界からのアクセスを許可
#   }

#   # アウトバウンドルールの設定
#   egress {
#     from_port   = 0             # 許可するポート範囲の開始
#     to_port     = 0             # 許可するポート範囲の終了
#     protocol    = "-1"          # 全てのプロトコルを許可
#     cidr_blocks = ["0.0.0.0/0"] # 全世界へのアクセスを許可
#   }

#   tags = merge(var.common_tags, {
#     Name = var.security_group_name_frontend
#   })
# }

###########################################################
# 署名書の取得
###########################################################

# 既存のACM証明書を取得
data "aws_acm_certificate" "certificate" {
  domain      = var.domain_name # 証明書のドメイン名
  statuses    = ["ISSUED"]      # 証明書のステータス
  most_recent = true            # 最新の証明書を取得

  # サブドメインがある場合は、subject_alternative_namesで指定
  # subject_alternative_names = ["www.example.com"]

  lifecycle {
    # ドメインの末尾にドットを付けない
    # nameの指定方法に注意
    # DNS検証の場合、証明書のステータスが "ISSUED" であることを確認
  }
}

###########################################################
# ALB設定
###########################################################

# Application Load Balancer（ALB）の作成
resource "aws_lb" "alb" {
  name               = var.alb_name                   # ALBの名前
  internal           = false                          # インターネット向けALBを指定
  load_balancer_type = "application"                  # ALBのタイプを指定
  security_groups    = [aws_security_group.alb_sg.id] # ALBに関連付けるセキュリティグループ
  subnets = [
    aws_subnet.subnet_1.id, # 1つ目のサブネット
    aws_subnet.subnet_2.id  # 2つ目のサブネット
  ]
  enable_deletion_protection = false # 削除保護を無効化

  tags = merge(var.common_tags, {
    Name = var.alb_name
  })
}

###########################################################
# ALBリスナー設定
###########################################################

# ALBリスナーの作成（ポート80へのリクエストは許可しない）
# resource "aws_lb_listener" "http_listener" {
#   load_balancer_arn = aws_lb.alb.arn # 作成したALBのARNを指定
#   port              = "80"           # リスナーがリッスンするポート
#   protocol          = "HTTP"         # プロトコルをHTTPに設定

#   # デフォルトアクションとしてターゲットグループにフォワード
#   default_action {
#     type             = "forward"                           # アクションタイプをフォワードに設定
#     target_group_arn = aws_lb_target_group.frontend_tg.arn # フォワード先のターゲットグループARNを指定
#   }

#   tags = merge(var.common_tags, {
#     Name = var.listener_name
#   })
# }

# HTTPリスナー（ポート80）でHTTPSにリダイレクト
resource "aws_lb_listener" "http_redirect_to_https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn              # 既存のALBのARN
  port              = "443"                       # HTTPSポート
  protocol          = "HTTPS"                     # プロトコル
  ssl_policy        = "ELBSecurityPolicy-2016-08" # SSLポリシー
  depends_on        = [aws_lb_target_group.frontend_tg, aws_lb_target_group.backend_tg]

  certificate_arn = data.aws_acm_certificate.certificate.arn # 取得した証明書のARN
  # certificate_arn = var.acm_certificate_arn # 取得した証明書のARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn # 既存のターゲットグループのARN
  }

  tags = merge(var.common_tags, {
    Name = "HTTPS-Listener"
  })
}



###########################################################
# ALB設定（ルール）
###########################################################
# フロントエンド用ターゲットグループへのパスベースルール
resource "aws_lb_listener_rule" "frontend_rule" {   # フロントエンド用のロードバランサーリスナールールを定義
  listener_arn = aws_lb_listener.https_listener.arn # HTTPリスナーのARNを指定
  priority     = 200                                # ルールの優先度を設定（数値が低いほど高優先度）

  action {                                                 # アクションブロックの開始
    type             = "forward"                           # アクションのタイプを「フォワード」に設定
    target_group_arn = aws_lb_target_group.frontend_tg.arn # フロントエンドターゲットグループのARNを指定
  }                                                        # アクションブロックの終了

  condition {         # 条件ブロックの開始
    path_pattern {    # パスパターン条件を定義
      values = ["/*"] # パスが「/frontend/」で始まるリクエストを対象
    }
  } # 条件ブロックの終了
}   # フロントエンドルールリソースの終了

# バックエンド用ターゲットグループへのパスベースルール
resource "aws_lb_listener_rule" "backend_rule" {    # バックエンド用のロードバランサーリスナールールを定義
  listener_arn = aws_lb_listener.https_listener.arn # HTTPSリスナーのARNを指定
  priority     = 100                                # ルールの優先度を設定（フロントエンドより低優先度）

  action {                                                # アクションブロックの開始
    type             = "forward"                          # アクションのタイプを「フォワード」に設定
    target_group_arn = aws_lb_target_group.backend_tg.arn # バックエンドターゲットグループのARNを指定
  }                                                       # アクションブロックの終了

  condition {             # 条件ブロックの開始
    path_pattern {        # パスパターン条件を定義
      values = ["/api/*"] # パスが「/api/」で始まるリクエストを対象
    }
  } # 条件ブロックの終了
}   # バックエンドルールリソースの終了


###########################################################
# ターゲットグループ設定
###########################################################

# ターゲットグループの作成
resource "aws_lb_target_group" "frontend_tg" {
  # awsvpc ネットワークモードでは、ターゲットグループの target_type を ip に設定する必要がある（タスク定義で指定されているネットワークモードが awsvpc）
  name        = var.target_group_name_frontend # ターゲットグループの名前
  port        = 80                             # ターゲットグループがリッスンするポート
  protocol    = "HTTP"                         # プロトコルをHTTPに設定
  vpc_id      = aws_vpc.vpc.id                 # 作成したVPCに関連付け
  target_type = "ip"                           # ターゲットタイプをIPに設定

  # ヘルスチェックの設定
  health_check {
    path                = "/"       # ヘルスチェックに使用するパス
    interval            = 30        # ヘルスチェックの間隔（秒）
    timeout             = 5         # ヘルスチェックのタイムアウト（秒）
    healthy_threshold   = 2         # ヘルシーと見なす連続成功回数
    unhealthy_threshold = 2         # アンヘルシーと見なす連続失敗回数
    matcher             = "200-299" # 正常と見なすHTTPステータスコードの範囲
  }

  tags = merge(var.common_tags, {
    Name = var.target_group_name_frontend
  })
}

# ターゲットグループの作成
resource "aws_lb_target_group" "backend_tg" {
  # awsvpc ネットワークモードでは、ターゲットグループの target_type を ip に設定する必要がある（タスク定義で指定されているネットワークモードが awsvpc）
  name        = var.target_group_name_backend # ターゲットグループの名前
  port        = 8080                          # ターゲットグループがリッスンするポート
  protocol    = "HTTP"                        # プロトコルをHTTPに設定
  vpc_id      = aws_vpc.vpc.id                # 作成したVPCに関連付け
  target_type = "ip"                          # ターゲットタイプをIPに設定

  # ヘルスチェックの設定
  health_check {
    path                = "/api/health-check" # ヘルスチェックに使用するパス
    interval            = 30                  # ヘルスチェックの間隔（秒）
    timeout             = 5                   # ヘルスチェックのタイムアウト（秒）
    healthy_threshold   = 2                   # ヘルシーと見なす連続成功回数
    unhealthy_threshold = 2                   # アンヘルシーと見なす連続失敗回数
    matcher             = "200-299"           # 正常と見なすHTTPステータスコードの範囲
  }

  tags = merge(var.common_tags, {
    Name = var.target_group_name_backend
  })
}
###########################################################
# Route 53ホストゾーンの取得（NSレコードの更新に時間がかかるため、なにかがない限りやらない）
###########################################################

# # Route 53ホストゾーンのリソースを定義します。
# resource "aws_route53_zone" "route53_zone" {
#   name = var.domain_name # 作成するホストゾーンのドメイン名を指定

#   # ホストゾーンにタグを付与します。タグはマップ形式で指定。
#   tags = var.common_tags
# }

# # Aレコードを作成し、ALBへのエイリアスとして設定
# resource "aws_route53_record" "route53_record" {
#   zone_id = aws_route53_zone.route53_zone.zone_id # 取得したホストゾーンIDを指定
#   name    = var.domain_name                       # Aレコードの名前を変数から指定
#   type    = "A"                                   # レコードタイプをAに設定

#   alias {
#     name    = aws_lb.alb.dns_name # ALBのDNS名をエイリアス先として指定
#     zone_id = aws_lb.alb.zone_id  # ALBのゾーンIDを指定
#     # name                   = data.aws_lb.target_alb.dns_name # ALBのDNS名をエイリアス先として指定
#     # zone_id                = data.aws_lb.target_alb.zone_id  # ALBのゾーンIDを指定
#     evaluate_target_health = true # ターゲットのヘルスチェックを有効化
#   }
# }

# # ドメインレジストラに自動生成されたネームサーバー名を登録
# resource "aws_route53domains_registered_domain" "registered_domain" {
#   domain_name = var.domain_name

#   name_server {
#     name = aws_route53_zone.route53_zone.name_servers[0]
#   }
#   name_server {
#     name = aws_route53_zone.route53_zone.name_servers[1]
#   }
#   name_server {
#     name = aws_route53_zone.route53_zone.name_servers[2]
#   }
#   name_server {
#     name = aws_route53_zone.route53_zone.name_servers[3]
#   }
#   tags = var.common_tags
# }

# ドメイン名でホストゾーンを検索
data "aws_route53_zone" "route53_zone" {
  name         = var.domain_name # 管理したいドメイン名を入力（末尾にドットを付ける）
  private_zone = false           # パブリックホストゾーンの場合はfalse、プライベートの場合はtrue
}

# Aレコードを作成し、ALBへのエイリアスとして設定
resource "aws_route53_record" "route53_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id # 取得したホストゾーンIDを指定
  # zone_id = var.route53_zone_id # 取得したホストゾーンIDを指定
  name = var.domain_name # Aレコードの名前を変数から指定
  type = "A"             # レコードタイプをAに設定

  alias {
    name    = aws_lb.alb.dns_name # ALBのDNS名をエイリアス先として指定
    zone_id = aws_lb.alb.zone_id  # ALBのゾーンIDを指定
    # name                   = data.aws_lb.target_alb.dns_name # ALBのDNS名をエイリアス先として指定
    # zone_id                = data.aws_lb.target_alb.zone_id  # ALBのゾーンIDを指定
    evaluate_target_health = true # ターゲットのヘルスチェックを有効化
  }
}

###########################################################
# ECSタスク定義設定
###########################################################

# タスク定義の作成
resource "aws_ecs_task_definition" "nginx_task" {
  family                   = var.ecs_task_definition_family           # タスク定義のファミリー名
  network_mode             = "awsvpc"                                 # ネットワークモードをawsvpcに設定（Fargate必須）
  requires_compatibilities = ["FARGATE"]                              # Fargate互換性を指定
  cpu                      = "256"                                    # タスクに割り当てるCPUユニット
  memory                   = "512"                                    # タスクに割り当てるメモリ（MiB）
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn # タスク実行ロールのARN（ECR からイメージを Pull したり、ログを CloudWatchLogs に記録するために使用）
  task_role_arn            = aws_iam_role.ecs_task_role.arn           # タスクロールのARN（実行されるコンテナに付与されるロール）

  # コンテナ定義を変数から取得
  container_definitions = jsonencode(var.container_definitions)

  tags = merge(var.common_tags, {
    Name = var.ecs_task_definition_family
  })
}

###########################################################
# ECSサービス設定
###########################################################

# ECSサービスの作成
resource "aws_ecs_service" "nginx_service" {
  name                 = var.ecs_service_name                   # サービスの名前
  cluster              = aws_ecs_cluster.ecs_cluster.id         # 作成したECSクラスターに関連付け
  task_definition      = aws_ecs_task_definition.nginx_task.arn # 使用するタスク定義のARNを指定
  desired_count        = 1                                      # 起動するタスクの数
  launch_type          = "FARGATE"                              # Fargateランチタイプを指定
  force_new_deployment = true                                   # デプロイを強制する場合

  # ネットワーク設定
  network_configuration {
    subnets          = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id] # サービスを配置するサブネット
    security_groups  = [aws_security_group.alb_sg.id]                   # セキュリティグループを指定
    assign_public_ip = true                                             # パブリックIPを割り当て
    # security_groups = [                                        # セキュリティグループを指定
    #   aws_security_group.frontend_sg.id,
    #   aws_security_group.backend_sg.id
    # ]
  }

  # ロードバランサー設定
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn # 使用するターゲットグループのARNを指定
    container_name   = var.lb_container_name_frontend      # タスク内のコンテナ名を指定
    container_port   = var.lb_container_port_frontend      # コンテナがリッスンするポートを指定
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn # バックエンドターゲットグループ
    container_name   = var.lb_container_name_backend
    container_port   = var.lb_container_port_backend # バックエンドコンテナのポートを指定
  }

  tags = merge(var.common_tags, {
    Name = var.ecs_service_name
  })
}

###########################################################
# ログ設定
###########################################################

# CloudWatch Log Groupの作成
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/${var.ecs_task_definition_family}"
  retention_in_days = 7 # ログの保持期間（日数）。必要に応じて調整してください。

  tags = merge(var.common_tags, {
    Name = "${var.ecs_task_definition_family}-log-group"
  })
}

###########################################################
# リソースグループ設定
###########################################################

# リソースグループの作成
resource "aws_resourcegroups_group" "resource_group" {
  name        = var.resource_group_name # リソースグループの名前
  description = "Resource group for Production environment"

  # リソースグループに含めるリソースのタグベースのルールを定義
  resource_query {
    query = jsonencode({
      ResourceTypeFilters = [
        # "AWS::Route53::HostedZone", # サポートされていないためコメントアウト
        # "AWS::IAM::Role",           # サポートされていないためコメントアウト
        "AWS::EC2::VPC",
        "AWS::EC2::InternetGateway",
        "AWS::EC2::Subnet",
        "AWS::EC2::RouteTable",
        "AWS::EC2::SecurityGroup",
        "AWS::ElasticLoadBalancingV2::LoadBalancer",
        "AWS::ElasticLoadBalancingV2::TargetGroup",
        "AWS::ElasticLoadBalancingV2::Listener",
        "AWS::ECS::TaskDefinition",
        "AWS::ECS::Cluster",
        "AWS::ECS::Service"
      ]
      TagFilters = [
        for key, value in var.resource_group_tags : {
          Key    = key
          Values = [value]
        }
      ]
    })
  }

  tags = merge(var.common_tags, {
    Name = var.resource_group_name
  })
}
