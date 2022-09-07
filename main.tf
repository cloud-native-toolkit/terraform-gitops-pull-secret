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

resource null_resource setup_gitops {
  depends_on = [module.setup_clis, module.seal_secrets]

  triggers = {
    name = local.name
    namespace = var.namespace
    yaml_dir = local.yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = local.type
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}' --debug"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
}
