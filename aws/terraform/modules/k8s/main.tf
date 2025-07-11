resource "kubernetes_service_account" "alb_controller" {
  provider = kubernetes

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = var.alb_iam_arn
    }
  }
}

resource "helm_release" "alb_controller" {
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  name    = "aws-load-balancer-controller"
  chart   = "aws-load-balancer-controller"
  version = "1.5.5"
  
  values = [templatefile("${path.module}/alb_values.tftpl", {
    cluster_name     = "pizza-eks"
    region           = "ap-northeast-2"
    service_account  = "aws-load-balancer-controller"
    vpc_id           = var.vpc_id
  })]
  depends_on = [kubernetes_service_account.alb_controller]
}

resource "helm_release" "prometheus_stack" {
  name       = "prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "75.4.0" 

  values = [<<-EOT
  grafana:
    service:
      type: LoadBalancer
  EOT
  ]
}