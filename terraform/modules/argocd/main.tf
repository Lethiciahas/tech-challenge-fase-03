variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "github_repo_url" {
  type    = string
  default = "https://github.com/owner/feature-flag.git"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  set {
    name  = "server.service.nodePortHttp"
    value = "30090"
  }
}

resource "kubectl_manifest" "argocd_app" {
  depends_on = [helm_release.argocd]

  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: ${var.project_name}-apps
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: ${var.github_repo_url}
        targetRevision: main
        path: gitops/base
      destination:
        server: https://kubernetes.default.svc
        namespace: ${var.project_name}-${var.environment}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML
}

output "argocd_url" {
  value = "http://<EC2_PUBLIC_IP>:30090"
}
