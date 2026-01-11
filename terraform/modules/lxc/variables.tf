# ============================================================================
# BASIC CONFIGURATION
# ============================================================================

variable "vmid" {
  description = "VMID du container LXC"
  type        = number
}

variable "hostname" {
  description = "Nom d'hôte du container"
  type        = string
}

variable "target_node" {
  description = "Node Proxmox cible"
  type        = string
}

variable "description" {
  description = "Description du container"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags pour le container (séparés par des points-virgules)"
  type        = string
  default     = ""
}

# ============================================================================
# OS TEMPLATE
# ============================================================================

variable "ostemplate" {
  description = "Template OS à utiliser (ex: local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst)"
  type        = string
}

variable "unprivileged" {
  description = "Créer un container non-privilégié"
  type        = bool
  default     = true
}

# ============================================================================
# COMPUTE RESOURCES
# ============================================================================

variable "cores" {
  description = "Nombre de cœurs CPU"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Mémoire RAM en MB"
  type        = number
  default     = 512
}

variable "swap" {
  description = "Swap en MB"
  type        = number
  default     = 512
}

# ============================================================================
# BOOT OPTIONS
# ============================================================================

variable "onboot" {
  description = "Démarrer automatiquement au boot du node"
  type        = bool
  default     = true
}

variable "start" {
  description = "Démarrer le container après sa création"
  type        = bool
  default     = true
}

variable "startup" {
  description = "Ordre de démarrage"
  type        = string
  default     = ""
}

variable "protection" {
  description = "Protection contre la suppression accidentelle"
  type        = bool
  default     = false
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "network" {
  description = "Configuration réseau"
  type = object({
    name     = string
    bridge   = string
    ip       = string
    gw       = string
    tag      = optional(number)
    firewall = optional(bool)
  })
}

variable "nameserver" {
  description = "Serveur DNS"
  type        = string
  default     = ""
}

variable "searchdomain" {
  description = "Domaine de recherche DNS"
  type        = string
  default     = ""
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "rootfs" {
  description = "Configuration du système de fichiers racine"
  type = object({
    storage = string
    size    = string
  })
}

variable "mountpoint" {
  description = "Points de montage additionnels"
  type = list(object({
    key     = string
    slot    = number
    storage = string
    size    = string
    mp      = string
  }))
  default = []
}

# ============================================================================
# AUTHENTICATION
# ============================================================================

variable "password" {
  description = "Mot de passe root du container"
  type        = string
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "Clés SSH publiques (une par ligne)"
  type        = string
  default     = ""
}

# ============================================================================
# CONTAINER FEATURES
# ============================================================================

variable "features" {
  description = "Features du container"
  type = object({
    nesting = optional(bool)
    fuse    = optional(bool)
    keyctl  = optional(bool)
    mount   = optional(string)
  })
  default = {
    nesting = false
    fuse    = false
    keyctl  = false
    mount   = null
  }
}
