data "http" "terraform_cloud_ips" {
  url = "https://app.terraform.io/api/meta/ip-ranges"
}