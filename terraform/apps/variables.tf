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

variable "proxmox_api_token" {
  description = "API Token Proxmox (format: user@realm!tokenid=secret)"
  type        = string
  sensitive   = true
}

# ============================================================================
# LXC AUTHENTICATION
# ============================================================================

variable "lxc_root_password" {
  description = "Mot de passe root pour les containers LXC"
  type        = string
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "Clés SSH publiques pour l'accès aux containers"
  type        = string
  default     = ""
}
