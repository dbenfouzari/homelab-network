# ============================================================================
# PROXMOX CLUSTER CONFIGURATION
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
  description = "Utilisateur Proxmox (format: user@pam ou user@pve)"
  type        = string
  default     = "root@pam"
  sensitive   = true
}

variable "proxmox_passwords" {
  description = "Mots de passe Proxmox par node (utiliser variables d'environnement TF_VAR_proxmox_passwords)"
  type        = map(string)
  sensitive   = true
  # Exemple d'utilisation :
  # export TF_VAR_proxmox_passwords='{"pve1":"pass1","pve2":"pass2","pve3":"pass3"}'
  # Ou dans terraform.tfvars (à ne PAS commit) :
  # proxmox_passwords = {
  #   pve1 = "password_node_1"
  #   pve2 = "password_node_2"
  #   pve3 = "password_node_3"
  # }
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "network_legacy" {
  description = "Configuration réseau legacy (VLAN 1 - avant migration)"
  type = object({
    cidr    = string
    gateway = string
    bridge  = string
  })
  default = {
    cidr    = "192.168.2.0/24"
    gateway = "192.168.2.1"  # Livebox
    bridge  = "vmbr0"
  }
}

variable "network_vlans" {
  description = "Configuration des VLANs (après migration)"
  type = map(object({
    vlan_id     = number
    cidr        = string
    gateway     = string
    description = string
  }))
  default = {
    mgmt = {
      vlan_id     = 10
      cidr        = "192.168.10.0/24"
      gateway     = "192.168.10.1"  # OPNsense
      description = "Management - Infrastructure"
    }
    iot = {
      vlan_id     = 20
      cidr        = "192.168.20.0/24"
      gateway     = "192.168.20.1"
      description = "IoT devices"
    }
    guest = {
      vlan_id     = 30
      cidr        = "192.168.30.0/24"
      gateway     = "192.168.30.1"
      description = "Guest network"
    }
    home = {
      vlan_id     = 40
      cidr        = "192.168.40.0/24"
      gateway     = "192.168.40.1"
      description = "Home - Famille"
    }
  }
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "storage_config" {
  description = "Configuration des storage pools Proxmox"
  type = map(object({
    type        = string
    content     = list(string)
    description = string
  }))
  default = {
    local = {
      type        = "dir"
      content     = ["vztmpl", "iso", "backup"]
      description = "Local storage sur node"
    }
    local-lvm = {
      type        = "lvm"
      content     = ["images", "rootdir"]
      description = "Local LVM pour VMs/LXCs"
    }
  }
}

# ============================================================================
# DNS CONFIGURATION
# ============================================================================

variable "dns_servers" {
  description = "Serveurs DNS (legacy et futurs)"
  type = object({
    legacy = list(string)
    future = list(string)
  })
  default = {
    legacy = ["192.168.2.1", "1.1.1.1"]        # Livebox + Cloudflare
    future = ["192.168.10.2", "192.168.2.1"]  # AdGuard Home + fallback
  }
}

# ============================================================================
# DEFAULT VALUES
# ============================================================================

variable "default_nameserver" {
  description = "Serveur DNS par défaut pour les VMs/LXCs"
  type        = string
  default     = "192.168.2.1"  # Livebox (legacy)
}

variable "default_searchdomain" {
  description = "Domaine de recherche DNS"
  type        = string
  default     = "local"
}

variable "ssh_keys" {
  description = "Clés SSH publiques pour les VMs/LXCs"
  type        = list(string)
  default     = []  # À remplir avec vos clés
}
