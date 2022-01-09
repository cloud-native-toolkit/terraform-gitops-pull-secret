locals {
  name          = local.secret_name
  bin_dir       = module.setup_clis.bin_dir
  secret_dir    = "${path.cwd}/.tmp/${local.name}/secrets"
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/sealed-secrets"
  secret_name   = "${var.username}-${lower(var.server)}"
  layer = "infrastructure"
  type  = "base"
  application_branch = "main"
  namespace = var.namespace
  layer_config = var.gitops_config[local.layer]
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

resource null_resource create_secret {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${local.yaml_dir}'"

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

  source = "github.com/cloud-native-toolkit/terraform-util-seal-secrets.git?ref=v1.0.0"

  source_dir    = local.secret_dir
  dest_dir      = local.yaml_dir
  kubeseal_cert = var.kubeseal_cert
  label         = local.name
}

resource null_resource setup_gitops {
  depends_on = [module.setup_clis, module.seal_secrets]

  provisioner "local-exec" {
    command = "${local.bin_dir}/igc gitops-module '${local.name}' -n '${var.namespace}' --contentDir '${local.yaml_dir}' --serverName '${var.server_name}' -l '${local.layer}' --type '${local.type}' --debug"

    environment = {
      GIT_CREDENTIALS = yamlencode(var.git_credentials)
      GITOPS_CONFIG   = yamlencode(var.gitops_config)
    }
  }
}
