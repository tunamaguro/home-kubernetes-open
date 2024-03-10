provider "helm" {
  kubernetes {
    config_path = var.kube_config_file
  }
}

provider "kubernetes" {
  config_path = var.kube_config_file
}
