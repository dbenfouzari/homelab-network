# ============================================================================
# VM OUTPUTS
# ============================================================================

output "vm_id" {
  description = "ID de la VM dans Proxmox"
  value       = proxmox_vm_qemu.vm.vmid
}

output "vm_name" {
  description = "Nom de la VM"
  value       = proxmox_vm_qemu.vm.name
}

output "vm_node" {
  description = "Node Proxmox hébergeant la VM"
  value       = proxmox_vm_qemu.vm.target_node
}

output "default_ipv4_address" {
  description = "Adresse IPv4 par défaut (si disponible via QEMU agent)"
  value       = proxmox_vm_qemu.vm.default_ipv4_address
}

output "ssh_host" {
  description = "Host SSH (IPv4 par défaut ou nom)"
  value       = proxmox_vm_qemu.vm.default_ipv4_address != null ? proxmox_vm_qemu.vm.default_ipv4_address : proxmox_vm_qemu.vm.name
}

output "vm_state" {
  description = "État de la VM"
  value       = proxmox_vm_qemu.vm.agent
}
