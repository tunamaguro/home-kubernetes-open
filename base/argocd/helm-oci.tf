resource "kubernetes_secret" "grafana-operator-oci" {
  metadata {
    namespace = "argocd"
    name      = "grafana-operator-oci"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = {
    "url"     = "ghcr.io/grafana/helm-charts"
    "name"    = "grafana-charts"
    "type"    = "helm"
    enableOCI = "true"
  }
  depends_on = [helm_release.argocd]
}
