provider "libvirt" {
  uri = "qemu:///session"
}

resource "libvirt_cloudinit_disk" "cloud-init" {
  name = "cloud-init.iso"
  pool = "default"
  user_data = templatefile("${path.module}/user-data.yaml", { hostname = "ubuntu-1" })
  network_config = templatefile("${path.module}/network-config.yaml", { ip = "192.168.122.2/24" })
}

resource "libvirt_volume" "ubuntu-1" {
  name = "ubuntu-1.qcow2"
  pool = "default"
  size = "42949672960"
  base_volume_name = "ubuntu-18.04-server-cloudimg-amd64.img"
  base_volume_pool = "base"
  format = "qcow2"
}

resource "libvirt_domain" "ubuntu-1" {
  name = "ubuntu-1"
  memory = "8192"
  vcpu = 4
  cloudinit = libvirt_cloudinit_disk.cloud-init.id
  
  network_interface {
    bridge = "virbr0"
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
    volume_id = libvirt_volume.ubuntu-1.id
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}
