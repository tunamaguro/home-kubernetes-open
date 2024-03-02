resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.52.0"
  namespace        = "argocd"
  create_namespace = true
  wait = true

  values = [file("./values.yaml")]

  description = "Install ArgoCD"
}
