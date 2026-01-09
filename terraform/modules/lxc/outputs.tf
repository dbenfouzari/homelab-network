# ============================================================================
# CONTAINER OUTPUTS
# ============================================================================

output "container_id" {
  description = "ID du container dans Proxmox"
  value       = proxmox_lxc.container.vmid
}

output "container_hostname" {
  description = "Hostname du container"
  value       = proxmox_lxc.container.hostname
}

output "container_node" {
  description = "Node Proxmox hébergeant le container"
  value       = proxmox_lxc.container.target_node
}

output "container_ip" {
  description = "Configuration IP du container"
  value       = proxmox_lxc.container.network[0].ip
}
