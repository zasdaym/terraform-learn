provider "libvirt" {
  uri = "qemu:///system"
}

variable "hosts" {
  default = 3
}

resource "libvirt_pool" "vm" {
  name = "vm"
  type = "dir"
  path = "/home/zasda/vm/"
}

resource "libvirt_cloudinit_disk" "cloud-init" {
  name = "cloud-init-${count.index}.iso"
  pool = libvirt_pool.vm.name
  count = var.hosts
  user_data = templatefile("${path.module}/cloud-init.yaml", { hostname = "pod-${count.index + 1}" })
}

resource "libvirt_volume" "ubuntu_1804" {
  name = "ubuntu-18.04-server-cloudimg-amd64.img"
  pool = libvirt_pool.vm.name
  source = "https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "nodes" {
  name = "node-${count.index + 1}.qcow2"
  pool = libvirt_pool.vm.name
  base_volume_id = libvirt_volume.ubuntu_1804.id
  count = var.hosts
}

resource "libvirt_domain" "nodes" {
  name = "node-${count.index + 1}"
  memory = "512"
  vcpu = 1
  cloudinit = element(libvirt_cloudinit_disk.cloud-init.*.id, count.index)
  
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
    volume_id = element(libvirt_volume.nodes.*.id, count.index + 1)
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }

  count = var.hosts
}
