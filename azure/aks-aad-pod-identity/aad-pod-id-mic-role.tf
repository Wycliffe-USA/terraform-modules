resource "kubernetes_cluster_role" "aad-pod-id-mic-role" {
  metadata {
    name = "aad-pod-id-mic-role"
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["*"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "nodes"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "create", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["create", "get", "update"]
  }

  rule {
    api_groups = ["aadpodidentity.k8s.io"]
    resources  = ["azureidentitybindings", "azureidentities"]
    verbs      = ["get", "list", "watch", "post", "update"]
  }

  rule {
    api_groups = ["aadpodidentity.k8s.io"]
    resources  = ["azureassignedidentities"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["aadpodidentity.k8s.io"]
    resources  = ["azurepodidentityexceptions"]
    verbs      = ["list", "update"]
  }

  depends_on = [
    helm_release.aad-pod-identity-crds
  ]
}