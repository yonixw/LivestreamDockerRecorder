### Server creation with one linked primary ip (ipv4)
resource "hcloud_primary_ip" "ip_main" {
    name          = "${var.prefix}_ip_main"
    datacenter    = "${var.htz_datacenter}"
    type          = "ipv4"
    assignee_type = "server"
    auto_delete   = true
    
    labels =  merge(
        {
            Resource = "IPv4_Public",
            Provisioner = "Terraform",
            Prefix = "${var.prefix}"
        },
        var.tags
    )
}

resource "hcloud_ssh_key" "ssh_deploy" {
   name       = "${var.prefix}_ssh_deploy"
   public_key = file("${var.ssh_deploy_pub_path}")
   labels =  merge(
        {
            Resource = "SSH_KEY",
            Provisioner = "Terraform",
            Prefix = "${var.prefix}"
        },
        var.tags
    )
}

data "hcloud_ssh_key" "ssh_shared" {
  fingerprint = "${var.ssh_shared_fingerprint}"
}

resource "hcloud_server" "server_main" {
  name        = "${var.prefix}-server" # No underscore!
  datacenter  = "${var.htz_datacenter}" 
  image       = "${var.vm_image}"
  server_type = "${var.vm_type}"

   labels =  merge(
        {
            Resource = "Server",
            Provisioner = "Terraform",
            Prefix = "${var.prefix}"
        },
        var.tags
    )

  public_net {
    ipv4_enabled = true
    ipv4 = hcloud_primary_ip.ip_main.id
    ipv6_enabled = false
  }

  ssh_keys = [
    data.hcloud_ssh_key.ssh_shared.id, # shared used for debug for all deploys
    hcloud_ssh_key.ssh_deploy.id # temp used for deploy only
  ]

  depends_on = [
    hcloud_primary_ip.ip_main,
  ]

}



