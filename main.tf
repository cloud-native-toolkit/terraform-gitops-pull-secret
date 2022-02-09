locals {
  name          = local.secret_name
  bin_dir       = module.setup_clis.bin_dir
  namespace = var.namespace
  secret_dir    = "${path.cwd}/.tmp/${local.namespace}/${local.name}/secrets"
  yaml_dir      = "${path.cwd}/.tmp/${local.namespace}/${local.name}/sealed-secrets"
  layer = "infrastructure"
  type  = "base"
  application_branch = "main"
  
  layer_config = var.gitops_config[local.layer]
  default_secret_name = replace(replace("${var.docker_username}-${lower(var.docker_server)}", "/[^a-z0-9-.]/", "-"), "/-+/", "-")
  secret_name   = var.secret_name != "" ? var.secret_name : local.default_secret_name
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  clis = ["jq", "kubectl", "igc"]
}

resource null_resource create_secret {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.secret_name}' '${var.namespace}' '${local.secret_dir}'"

    environment = {
      BIN_DIR  = module.setup_clis.bin_dir
      SERVER   = var.docker_server
      USERNAME = var.docker_username
      PASSWORD = nonsensitive(var.docker_password)
    }
  }
}

module seal_secrets {
  depends_on = [null_resource.create_secret]

  source = "github.com/cloud-native-toolkit/terraform-util-seal-secrets.git"

  source_dir    = local.secret_dir
  dest_dir      = local.yaml_dir
  kubeseal_cert = var.kubeseal_cert
  label         = local.name
}


resource gitops_module module {
  name        = local.name
  namespace   = var.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer       = local.layer
  type        = local.type
  config      = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
