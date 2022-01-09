module "gitops_module" {
  source = "./module"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  kubeseal_cert = module.argocd-bootstrap.sealed_secrets_cert
  docker_server = "docker.io"
  docker_username = "test"
  docker_password = "password"
}