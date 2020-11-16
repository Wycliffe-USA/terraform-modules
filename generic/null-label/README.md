# null-label


Terraform module designed to generate consistent names and tags for resources. Use `null-label` to implement a strict naming convention.

A label follows the following convention `{namespace}-{name}-{component}-{environment}-{stage}-{attributes}`. The delimiter (e.g. `-`) is interchangeable.
The label items are all optional. So if you prefer the term `stage` to `environment` you can exclude environment and the label `id` will look like `{namespace}-{name}-{component}-{stage}-{component}-{attributes}`.
If attributes are excluded but `stage` and `environment` are included, `id` will look like `{namespace}-{name}-{components}-{environment}-{stage}-{component}`

It's recommended to use one `null-label` module for every unique resource of a given resource type.
For example, if you have 10 instances, there should be 10 different labels.
However, if you have multiple different kinds of resources (e.g. instances, security groups, file systems, and elastic ips), then they can all share the same label assuming they are logically related.

NOTE The `null` refers to the primary Terraform [provider](httpswww.terraform.iodocsprovidersnullindex.html) used in this module.

Releases of this module from `1.1.0` only work with Terraform 0.13 or newer.  Releases prior to this are compatible with earlier versions of terraform like Terraform 0.11.

Originally based on https://github.com/cloudposse/terraform-null-label, version 0.21.0.

---

## Usage


IMPORTANT The `master` branch is used in `source` just as an example. In your code, do not pin to `master` because there may be breaking changes between releases.
Instead pin to the release tag (e.g. `ref=tagsx.y.z`) of one of our [latest releases].


### Simple Example

```hcl
module eg_prod_appname_api_label {
  source      = "github.com/Wycliffe-USA/terraform-modules//generic/null-label?ref=master"
  namespace   = "eg"
  name        = "appname"
  component   = "api"
  environment = "prod"
  attributes  = ["public"]
  delimiter   = -

  tags = {
    BusinessUnit = "XYZ",
    Snapshot     = true
  }
}
```

This will create an `id` with the value of `eg-appname-api-prod-public` because when generating `id`, the default order is `namespace`, `name`, `component`, `environment`, `stage`,  `name`, `attributes`
(you can override it by using the `label_order` variable, see [Advanced Example 3](#advanced-example-3)).

Now reference the label when creating an instance

```hcl
resource aws_instance eg_prod_appname_api_label {
  instance_type = t1.micro
  tags          = module.eg_prod_appname_api_label.tags
}
```

Or define a security group

```hcl
resource aws_security_group eg_prod_appname_api_label {
  vpc_id = var.vpc_id
  name   = module.eg_prod_appname_api_label.id
  tags   = module.eg_prod_appname_api_label.tags
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [0.0.0.00]
  }
}
```


### Advanced Example

Here is a more complex example with two instances using two different labels. Note how efficiently the tags are defined for both the instance and the security group.

```hcl
module eg_appname_prod_abc_label {
  source     = github.com/Wycliffe-USA/terraform-modules//generic/null-label?ref=master
  namespace  = eg
  stage      = prod
  name       = appname
  attributes = [abc]
  delimiter  = -

  tags = {
    BusinessUnit = XYZ,
    Snapshot     = true
  }
}

resource aws_security_group eg_appname_prod_abc {
  name = module.eg_appname_prod_abc_label.id
  tags = module.eg_appname_prod_abc_label.tags
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = tcp
    cidr_blocks = [0.0.0.00]
  }
}

resource aws_instance eg_appname_prod_abc {
   instance_type          = t1.micro
   tags                   = module.eg_appname_prod_abc_label.tags
   vpc_security_group_ids = [aws_security_group.eg_appname_prod_abc.id]
}

module eg_appname_prod_xyz_label {
  source     = github.com/Wycliffe-USA/terraform-modules//generic/null-label?ref=master
  namespace  = eg
  stage      = prod
  name       = appname
  attributes = [xyz]
  delimiter  = -

  tags = {
    BusinessUnit = XYZ,
    Snapshot     = true
  }
}

resource aws_security_group eg_appname_prod_xyz {
  name = module.eg_appname_prod_xyz_label.id
  tags = module.eg_appname_prod_xyz_label.tags
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = tcp
    cidr_blocks = [0.0.0.00]
  }
}

resource aws_instance eg_appname_prod_xyz {
   instance_type          = t1.micro
   tags                   = module.eg_appname_prod_xyz_label.tags
   vpc_security_group_ids = [aws_security_group.eg_appname_prod_xyz.id]
}
```

### Advanced Example 2

Here is a more complex example with an autoscaling group that has a different tagging schema than other resources and requires its tags to be in this format, which this module can generate

```hcl
tags = [
    {
        key = Name,
        propagate_at_launch = 1,
        value = namespace-stage-name
    },
    {
        key = Namespace,
        propagate_at_launch = 1,
        value = namespace
    },
    {
        key = Stage,
        propagate_at_launch = 1,
        value = stage
    }
]
```

Autoscaling group using propagating tagging below (full example [autoscalinggroup](examplesautoscalinggroupmain.tf))

```hcl
################################
# null-label example #
################################
module label {
  source    = ....
  namespace = cp
  stage     = prod
  name      = app

  tags = {
    BusinessUnit = Finance
    ManagedBy    = Terraform
  }

  additional_tag_map = {
    propagate_at_launch = true
  }
}

#######################
# Launch template     #
#######################
resource aws_launch_template default {
  # null-label example used here Set template name prefix
  name_prefix                           = ${module.label.id}-
  image_id                              = data.aws_ami.amazon_linux.id
  instance_type                         = t2.micro
  instance_initiated_shutdown_behavior  = terminate

  vpc_security_group_ids                = [data.aws_security_group.default.id]

  monitoring {
    enabled                             = false
  }
  # null-label example used here Set tags on volumes
  tag_specifications {
    resource_type                       = volume
    tags                                = module.label.tags
  }
}

######################
# Autoscaling group  #
######################
resource aws_autoscaling_group default {
  # null-label example used here Set ASG name prefix
  name_prefix                           = ${module.label.id}-
  vpc_zone_identifier                   = data.aws_subnet_ids.all.ids
  max_size                              = 1
  min_size                              = 1
  desired_capacity                      = 1

  launch_template = {
    id                                  = aws_launch_template.default.id
    version                             = $$Latest
  }

  # null-label example used here Set tags on ASG and EC2 Servers
  tags                                  = module.label.tags_as_list_of_maps
}
```

### Advanced Example 3

See [complete example](.examplescomplete)

This example shows how you can pass the `context` output of one label module to the next label_module,
allowing you to create one label that has the base set of values, and then creating every extra label
as a derivative of that.

```hcl
module label1 {
  source      = github.com/Wycliffe-USA/terraform-modules//generic/null-label?ref=master
  namespace   = CompanyName
  environment = UAT
  stage       = build
  name        = Winston Churchroom
  attributes  = [fire, water, earth, air]
  delimiter   = -

  label_order = [name, environment, stage, attributes]

  tags = {
    City        = Dublin
    Environment = Private
  }
}

module label2 {
  source    = github.com/Wycliffe-USA/terraform-modules//generic/null-label?ref=master
  context   = module.label1.context
  name      = Charlie
  stage     = test
  delimiter = +

  tags = {
    City        = London
    Environment = Public
  }
}

module label3 {
  source    = github.com/Wycliffe-USA/terraform-modules//generic/null-label?ref=master
  name      = Starfish
  stage     = release
  context   = module.label1.context
  delimiter = .

  tags = {
    Eat    = Carrot
    Animal = Rabbit
  }
}
```

This creates label outputs like this

```hcl
label1 = {
  attributes = [
    fire,
    water,
    earth,
    air,
  ]
  delimiter = -
  id = winstonchurchroom-uat-build-fire-water-earth-air
  name = winstonchurchroom
  namespace = companyname
  stage = build
}
label1_context = {
  additional_tag_map = {}
  attributes = [
    fire,
    water,
    earth,
    air,
  ]
  delimiter = -
  enabled = true
  environment = uat
  label_order = [
    name,
    environment,
    stage,
    attributes,
  ]
  name = winstonchurchroom
  namespace = companyname
  regex_replace_chars = [^a-zA-Z0-9-]
  stage = build
  tags = {
    Attributes = fire-water-earth-air
    City = Dublin
    Environment = Private
    Name = winstonchurchroom
    namespace = companyname
    Stage = build
  }
}
label1_tags = {
  Attributes = fire-water-earth-air
  City = Dublin
  Environment = Private
  Name = winstonchurchroom
  namespace = companyname
  Stage = build
}
label2 = {
  attributes = [
    fire,
    water,
    earth,
    air,
  ]
  delimiter = +
  id = charlie+uat+test+firewaterearthair
  name = charlie
  namespace = companyname
  stage = test
}
label2_context = {
  additional_tag_map = {}
  attributes = [
    fire,
    water,
    earth,
    air,
  ]
  delimiter = +
  enabled = true
  environment = uat
  label_order = [
    name,
    environment,
    stage,
    attributes,
  ]
  name = charlie
  namespace = companyname
  regex_replace_chars = [^a-zA-Z0-9-]
  stage = test
  tags = {
    Attributes = firewaterearthair
    City = London
    Environment = Public
    Name = charlie
    namespace = companyname
    Stage = test
  }
}
label2_tags = {
  Attributes = firewaterearthair
  City = London
  Environment = Public
  Name = charlie
  namespace = companyname
  Stage = test
}
label3 = {
  attributes = [
    fire,
    water,
    earth,
    air,
  ]
  delimiter = .
  id = starfish.uat.release.firewaterearthair
  name = starfish
  namespace = companyname
  stage = release
}
label3_context = {
  additional_tag_map = {}
  attributes = [
    fire,
    water,
    earth,
    air,
  ]
  delimiter = .
  enabled = true
  environment = uat
  label_order = [
    name,
    environment,
    stage,
    attributes,
  ]
  name = starfish
  namespace = companyname
  regex_replace_chars = [^a-zA-Z0-9-]
  stage = release
  tags = {
    Animal = Rabbit
    Attributes = firewaterearthair
    City = Dublin
    Eat = Carrot
    Environment = uat
    Name = starfish
    namespace = companyname
    Stage = release
  }
}
label3_tags = {
  Animal = Rabbit
  Attributes = firewaterearthair
  City = Dublin
  Eat = Carrot
  Environment = uat
  Name = starfish
  namespace = companyname
  Stage = release
}

```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| additional_tag_map | Additional tags for appending to each tag map | map(string) | `<map>` | no |
| attributes | Additional attributes (e.g. `1`) | list(string) | `<list>` | no |
| context | Default context to use for passing state between label invocations. Ex, CompanyName | object | `<map>` | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes` | string | `-` | no |
| enabled | Set to false to prevent the module from creating any resources | bool | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | string | `` | no |
| label_order | The naming order of the id output and Name tag | list(string) | `<list>` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | string | `` | no |
| component | Solution component, e.g. 'api' or 'frontend' or 'cluster' | string | `` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | string | `` | no |
| regex_replace_chars | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed | string | `/[^a-zA-Z0-9-]/` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | string | `` | no |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | map(string) | `<map>` | no |


## Outputs

 Name  Description 
-------------------
 attributes  List of attributes 
 context  Context of this module to pass to other label modules 
 delimiter  Delimiter between `namespace`, `environment`, `stage`, `name` and `attributes` 
 environment  Normalized environment 
 id  Disambiguated ID 
 label_order  The naming order of the id output and Name tag 
 name  Normalized name 
 component Normalized component name
 namespace  Normalized namespace 
 stage  Normalized stage 
 tags  Normalized Tag map 
 tags_as_list_of_maps  Additional tags as a list of maps, which can be used in several AWS resources 

