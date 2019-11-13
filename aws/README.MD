# Amazon Web Services Provider
The modules in this directory are all specifically for use with Amazon Web
Services.

## Provider Configuration
In your application / Terraform configuration you need to define/configure
the `aws` provider like so:

```
provider "aws" {
  access_key = "${var.YOUR_ACCESS_KEY_VARNAME}"
  secret_key = "${var.YOUR_SECRET_KEY_VARNAME}"
  region = "${var.REGION_NAME}"
}
```

Original code snippets from https://www.terraform.io/docs/providers/aws/r/dynamodb_global_table.html and https://github.com/cloudposse/terraform-aws-dynamodb