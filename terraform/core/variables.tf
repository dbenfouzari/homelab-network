# ============================================================================
# PROXMOX CONFIGURATION
# ============================================================================

variable "proxmox_api_urls" {
  description = "URLs des APIs Proxmox pour chaque node"
  type        = map(string)
  default = {
    pve1 = "https://192.168.2.101:8006/api2/json"
    pve2 = "https://192.168.2.102:8006/api2/json"
    pve3 = "https://192.168.2.103:8006/api2/json"
  }
}

variable "proxmox_user" {
  description = "Utilisateur Proxmox"
  type        = string
  default     = "root@pam"
  sensitive   = true
}

variable "proxmox_passwords" {
  description = "Mots de passe Proxmox par node"
  type        = map(string)
  sensitive   = true
}
