output "ipv4_cidrs" {
  #TODO, need to parse the sub objects like api, vcs, sentinel, etc.  Which are needed?
  value = split("\n", trimspace(data.http.terraform_cloud_ips.response_body))
}