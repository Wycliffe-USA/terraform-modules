resource "kubernetes_daemonset" "nmi" {
  metadata {
    name      = "nmi"
    namespace = "default"
    labels = {
      component = "nmi"
      tier      = "node"
      k8s-app   = "aad-pod-id"
    }
  }

  spec {
    selector {
      match_labels = {
        component = "nmi"
        tier      = "node"
      }
    }

    template {
      metadata {
        labels = {
          component = "nmi"
          tier      = "node"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.aad-pod-id-nmi-service-account.metadata.0.name
        automount_service_account_token  = true
        host_network         = true
        volume {
          name = "iptableslock"
          host_path {
            path = "/run/xtables.lock"
            type = "FileOrCreate"
          }
        }

        container {
          name  = "nmi"
          image = "mcr.microsoft.com/k8s/aad-pod-identity/nmi:1.6.2"
          image_pull_policy = "Always"
          args  = ["--node=$(NODE_NAME)", "--http-probe-port=8085"]

          env {
            name = "HOST_IP"

            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name = "NODE_NAME"

            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          resources {
            limits {
              cpu    = "200m"
              memory = "512Mi"
            }

            requests {
              cpu    = "100m"
              memory = "256Mi"
            }
          }

          volume_mount {
            name       = "iptableslock"
            mount_path = "/run/xtables.lock"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "8085"
            }

            initial_delay_seconds = 10
            period_seconds        = 5
          }

          security_context {
            capabilities {
              add = ["NET_ADMIN"]
            }

            privileged = true
          }
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }
      }
    }

    strategy {
      type = "RollingUpdate"
    }
  }
}
