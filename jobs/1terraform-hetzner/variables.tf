variable "hcloud_token" {
  type = string
  sensitive = true # Requires terraform >= 0.14
}

variable "prefix" {
  type = string
}

variable "htz_datacenter" {
  # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server#datacenter
  # https://docs.hetzner.com/general/others/data-centers-and-connection/
  # https://docs.hetzner.com/cloud/general/locations/
  # fsn1-dc14 (Falkenstein, Germany) (18) - Biggest + Has all products
  # nbg1-dc3 (Nuremberg, Germany) (5)
  # hel1-dc2 (Helsinki, Finland) (6)
  # ash-dc1 (US Ashburn, VA)
  # hil-dc1 (US Hillsboro, OR)
  default = "fsn1-dc14"
}

variable "tags" {
    default = {
        Project = "LivestreamRecorder"
    }
    type = map(string)
}

variable "ssh_deploy_pub_path" {
  type = string
}

variable "ssh_shared_fingerprint" {
  type = string
  default = "1c:0f:d6:55:94:06:50:cc:54:d4:fe:12:b1:cd:8d:d3" #md5 fingerprint
}

variable "vm_image" {
    # took from hetzner ui ${type}-${ver}
    type = string
    default = "ubuntu-22.04" 
}

variable "vm_type" {
    # lower case of hetzner variation.. check variation per region (=datacenter)
    type = string
    default = "cpx31"
}