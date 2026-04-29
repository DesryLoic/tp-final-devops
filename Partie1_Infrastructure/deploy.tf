terraform {
  required_providers {
    virtualbox = {
      source = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

variable "network_host_if" {
  description = "Nom de la carte reseau hote pour le bridge"
  type        = string
  default     = "MediaTek Wi-Fi 6E MT7922 (RZ616) 160MHz PCIe Adapter"
}

resource "virtualbox_vm" "debian_node" {
  count     = 1
  name      = "vm_tpfinal"
  image     = "https://vagrantcloud.com/generic/boxes/debian11/versions/4.3.12/providers/virtualbox.box"
  cpus      = 2
  memory    = "2048 mib"

  network_adapter {
    type           = "bridged"
    host_interface = var.network_host_if
  }
}

output "vm_ip" {
  value = virtualbox_vm.debian_node[0].network_adapter[0].ipv4_address
}
