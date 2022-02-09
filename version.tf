terraform {
  required_version = ">= 0.15.0"

  required_providers {
    gitops = {
      source  = "cloudnativetoolkit.dev/cntk/gitops"
    }
  }
}
