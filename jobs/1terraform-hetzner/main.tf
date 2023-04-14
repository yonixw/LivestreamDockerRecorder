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

resource "hcloud_ssh_key" "ssh_main" {
   name       = "${var.prefix}_ssh_main"
   public_key = file("${var.pub_path}")
   labels =  merge(
        {
            Resource = "SSH_KEY",
            Provisioner = "Terraform",
            Prefix = "${var.prefix}"
        },
        var.tags
    )
}

resource "hcloud_volume" "volume_main" {
  name      = "${var.prefix}_volume_main"
  size      = 60
  server_id = hcloud_server.server_main.id
  automount = true
  format    = "ext4"
  
   labels =  merge(
        {
            Resource = "Volume",
            Provisioner = "Terraform",
            Prefix = "${var.prefix}"
        },
        var.tags
    )
}

resource "hcloud_server" "server_main" {
  name        = "${var.prefix}_server"
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
    hcloud_ssh_key.ssh_main.id
  ]

  depends_on = [
    hcloud_primary_ip.ip_main,
    hcloud_ssh_key.ssh_main,
  ]
}



