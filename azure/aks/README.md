# Create an Azure Kubernetes cluster with access control based on Azure Active Directory and RBAC.

This repository contains opinionated Terraform that automates the deployment of an RBAC-enabled Azure Kubernetes Service cluster backed by Azure Active Directory.

Before getting started, read this [documentation page](https://docs.microsoft.com/en-us/azure/aks/aad-integration) that explains how to configure AKS to use RBAC and Azure Active Directory manually.  This repository is based on work done in this [blog post](https://dev.to/cdennig/fully-automated-creation-of-an-aad-integrated-kubernetes-cluster-with-terraform-15cm).


## Prerequisites

This project is written with Terraform **0.12.24**.

Manual steps required! This repository proposes Terraform that can automate the click procedure described in the previous link.  This must be enabled if running this code via Azure shell.  If instead you're running this in Terraform Enterprise, leave this feature disabled and perform the steps manually.  (more below).

## Azure Active Directory

To enable Azure Active Directory authorization with Kubernetes, you need to create three applications.  For more information on this, read the dev.to blog post, above.

- A server application, that will provide user authentication between Kubernetes and Azure Active Directory.
- A client application, that will provide user authentication between CLI tools like kubectl and Active Directory.
- A service principal and application, that will allow kubernetes to interact with Azure in order to create resources.

## Terraform deployment

The `aks` folder of this repository contains everything you need to deploy the cluster.

To deploy using this module, use terraform's module syntax and add any variables that you want to adjust to fill the different variables with the right names / values for your environment.

### Example module code
```
provider "azurerm" {
  version = "=2.4.0"
  features {}
  client_id = ''
  client_secret = ''
  subscription_id = ''
  tenant_id = ''
}

provider "azuread" {
  version = "~> 0.7"
  client_id = ''
  client_secret = ''
  subscription_id = ''
  tenant_id = ''
}

resource "azurerm_resource_group" "rg" {
  name     = "example-resource_group"
  location = "eastus"
}

module "aks" {
  source        = "https://github.com/Wycliffe-USA/terraform-modules//azure/aks/"
  app_name      = "my_app"
  app_env       = var.app_env
  client_id     = var.client_id
  client_secret = var.client_secret
  region        = "useast"
}
```

### Required Inputs
 - app_name: The name of the app you're deploying on this cluster or the name of the cluster.  Will be used in the naming resource groups, kubernetes cluster, etc. Alternatively, the primary name used in naming resources in this configuration.
 - app_env: The environment or tier for this cluster, such as dev, test, prod.
 - automate_admin_consent: Set this to true if running this code in Azure Cloud Shell, which allows for automating admin consent for the applications.
 - client_id: Azure id to manipulate Azure via terraform.
 - client_secret: Azure secret.
 - region: Azure region to build kubernetes in.

## Cluster Resource Naming.
The cluster and related resources use null-label standardized formatting to name it's components.  Generally, the naming convention for various components will be {app_namespace}-{app_name}-{app_env} - which can also have additional descriptions added on per component.  This can be configured using the aks_label_order variable.

## Networking
Kubernetes uses several network ranges.  Internally to Kubernetes, the `aks_service_cidr` (default: `10.11.4.0/22`) range is used by kubernetes services.  Additionally, `aks_docker_bridge_cidr` (default: `10.11.0.1/26`) is used by the docker bridge on hosts.  If these ranges conflict with your internal network, you should change them.

Kubernetes also exists within a Azure Virtual Network, which must be and must have a dedicated subnet within that vnet, specified by `aks_vnet_subnet_id`.

## Initialize Terraform.

```
$ terraform init
```

Create **JUST ONLY** the resource group and two client and server applications/passwords/service principals for this cluster. You only need to target the password resources as the
dependencies will naturally create the applications and the service principals:
```
$ terraform apply --target azurerm_resource_group.rg
$ terraform apply --target module.aks.azuread_service_principal.aks-aad-srv -target module.aks.azuread_service_principal.aks-aad-cli
[...]
Apply complete! Resources: [x] added, 0 changed, 0 destroyed.
```

<aside class="warning">
This next step must be done manually unless you have enable 'automate_admin_consent' and you are running this code on Azure Cloud Shell.  If those things are true, you may skip this manual step.

Those actions are **MANDATORY**. The client and server applications must be granted permissions, which **will not be done with Terraform for unless automate_admin_consent is enabled**: go on the Azure portal, choose *Azure Active Directory* in the left menu (or in the services), choose *App registrations* in the submenu, click all applications, click on the application name, then in the *View API permissions* of the application, and click on *Grant admin consent* (do the client application first, then the server application).
</aside>

Finalize the cluster configuration, including RBAC access via Azure.
```
$ terraform apply
Apply complete! Resources: [x] added, 0 changed, 0 destroyed.
```

## Connect to the cluster using RBAC and Azure AD

Once all you RBAC objects are defined in Kubernetes, you can get a Kubernetes configuration file that is not admin-enabled using the `az aks get-credentials` command without the `--admin` flag.  Don't forget to access the cluster group in AZ AD and add members who can access the cluster.

```
az aks get-credentials --resource-group RESOURCE_GROUP_NAME --name CLUSTER_NAME --admin
```

When you are going to use `kubectl` you are going to be asked to use the Azure Device Login authentication first:

```
kubectl get nodes

To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code ABCDEFGHI to authenticate.
```

### View the kubernetes dashboard
The dashboard is disabled by default.  To enable it, set `k8s_dashboard_enabled` to `true` in the terraform vars.  Alternatively, pass `az aks enable-addons --addons kube-dashboard --resource-group RESOURCE_GROUP_NAME --name CLUSTER_NAME` via the azure cli to temporarily enable it.  Pass `az aks disable-addons --addons kube-dashboard  --resource-group RESOURCE_GROUP_NAME --name CLUSTER_NAME` to disable it - or terraform will disable it again when it's next run.  Then follow the instructions below to start the proxy and connect to the dashboard.

```
az aks browse --resource-group RESOURCE_GROUP_NAME --name CLUSTER_NAME

To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code ABCDEFGHI to authenticate.
Starting to serve on 127.0.0.1:8001
```
Then open http://127.0.0.1:8001 in a browser.

## Troubleshoting
- You receive an error `The access token requested for audience https://graph.microsoft.com by application {GUID} in tenant {GUID} is missing the required claim role Directory.Read.All." Target="aadProfile.serverAppID"`: Follow the directions above to grant admin consent.