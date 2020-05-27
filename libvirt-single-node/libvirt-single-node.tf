provider "libvirt" {
  uri = "qemu:///system"
}

locals {
	hostname = "ubuntu-1"
	ip_addr = "192.168.122.100/24"
}

resource "libvirt_cloudinit_disk" "ubuntu" {
	name = "${local.hostname}-cloud-init.iso"
  pool = "default"
  user_data = templatefile("${path.module}/user-data.yaml", { hostname = local.hostname })
  network_config = templatefile("${path.module}/network-config.yaml", { ip = local.ip_addr })
}

resource "libvirt_volume" "ubuntu" {
  name = "${local.hostname}.qcow2"
  pool = "default"
  size = "42949672960"
  base_volume_name = "ubuntu-18.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_domain" "ubuntu" {
  name = local.hostname
  memory = "8192"
  vcpu = 4
  cloudinit = "libvirt_cloudinit_disk.${local.hostname}.id"
  
  network_interface {
    network_name = "default"
  }

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
		volume_id = "libvirt_volume.${local.hostname}.id"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}
