/*
 * Configures storage classes
 * Persistent volumes created with these classes must match the type (LRS/ZRS) that the storage account was created with.
 */
resource "kubernetes_storage_class" "azurefile_standard_zrs_retain" {
  metadata {
    name = "azurefile-standard-zrs-retain"
    labels = {
      "kubernetes.io/cluster-service" = "true"
    }
  }

  mount_options       = ["file_mode=0777", "dir_mode=0777", "mfsymlinks", "uid=0", "gid=0", "cache=strict"]
  parameters          = {
    skuName = "Standard_ZRS"
  }
  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Retain"
}

resource "kubernetes_storage_class" "azurefile_premium_zrs_retain" {
  metadata {
    name = "azurefile-premium-zrs-retain"
    labels = {
      "kubernetes.io/cluster-service" = "true"
    }
  }

  mount_options       = ["file_mode=0777", "dir_mode=0777", "mfsymlinks", "uid=0", "gid=0", "cache=strict"]
  parameters          = {
    skuName = "Premium_ZRS"
  }
  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Retain"
}

resource "kubernetes_storage_class" "azurefile_standard_lrs_retain" {
  metadata {
    name = "azurefile-standard-lrs-retain"
    labels = {
      "kubernetes.io/cluster-service" = "true"
    }
  }

  allow_volume_expansion = true
  mount_options       = ["file_mode=0777", "dir_mode=0777", "mfsymlinks", "uid=0", "gid=0", "cache=strict"]
  parameters          = {
    skuName = "Standard_LRS"
  }
  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Retain"
}

resource "kubernetes_storage_class" "azurefile_premium_lrs_retain" {
  metadata {
    name = "azurefile-premium-lrs-retain"
    labels = {
      "kubernetes.io/cluster-service" = "true"
    }
  }

  allow_volume_expansion = true
  mount_options       = ["file_mode=0777", "dir_mode=0777", "mfsymlinks", "uid=0", "gid=0", "cache=strict"]
  parameters          = {
    skuName = "Premium_LRS"
  }
  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Retain"
}

resource "kubernetes_storage_class" "azurefile_standard_grs_retain" {
  metadata {
    name = "azurefile-standard-grs-retain"
    labels = {
      "kubernetes.io/cluster-service" = "true"
    }
  }

  allow_volume_expansion = true
  mount_options       = ["file_mode=0777", "dir_mode=0777", "mfsymlinks", "uid=0", "gid=0", "cache=strict"]
  parameters          = {
    skuName = "Standard_GRS"
  }
  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Retain"
}

resource "kubernetes_storage_class" "azurefile_standard_gzrs_retain" {
  metadata {
    name = "azurefile-standard-gzrs-retain"
    labels = {
      "kubernetes.io/cluster-service" = "true"
    }
  }

  allow_volume_expansion = true
  mount_options       = ["file_mode=0777", "dir_mode=0777", "mfsymlinks", "uid=0", "gid=0", "cache=strict"]
  parameters          = {
    skuName = "Standard_GZRS"
  }
  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Retain"
}

resource "kubernetes_storage_class" "azure_managed_premium_lrs_retain" {
  metadata {
    name = "azure-managed-premium-lrs-retain"

    labels = {
      "kubernetes.io/cluster-service" = "true"
    }
  }

  parameters             = {
    cachingmode        = "ReadOnly"
    kind               = "Managed"
    storageaccounttype = "Premium_LRS"
  }

  reclaim_policy         = "Retain"
  storage_provisioner    = "kubernetes.io/azure-disk"
  allow_volume_expansion = true
  volume_binding_mode    = "Immediate"
}