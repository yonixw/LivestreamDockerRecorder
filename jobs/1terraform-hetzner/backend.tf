terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.38.1"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}