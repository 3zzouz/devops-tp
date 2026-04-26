terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-devops-tp"
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = "devops-tp"
  }
}

resource "kubernetes_limit_range" "app" {
  metadata {
    name      = "limits"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "200m"
        memory = "128Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "64Mi"
      }
    }
  }
}
