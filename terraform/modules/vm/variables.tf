# ============================================================================
# REQUIRED VARIABLES
# ============================================================================

variable "vmid" {
  description = "ID unique de la VM dans Proxmox (ex: 100)"
  type        = number
}

variable "name" {
  description = "Nom de la VM (ex: opnsense)"
  type        = string
}

variable "target_node" {
  description = "Node Proxmox cible (ex: pve-host-1)"
  type        = string
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "networks" {
  description = "Configuration des interfaces réseau"
  type = list(object({
    model   = string        # Modèle de carte réseau (virtio, e1000, etc.)
    bridge  = string        # Bridge Proxmox (vmbr0, vmbr1, etc.)
    tag     = optional(number)  # VLAN tag (optionnel)
    firewall = optional(bool)   # Activer le firewall Proxmox
  }))
  default = [{
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }]
}

variable "ipconfig" {
  description = "Configuration IP pour chaque interface (format Proxmox: ip=x.x.x.x/yy,gw=x.x.x.x)"
  type        = list(string)
  default     = ["dhcp"]
}

variable "nameserver" {
  description = "Serveurs DNS (séparés par des espaces)"
  type        = string
  default     = "192.168.2.1 1.1.1.1"
}

variable "searchdomain" {
  description = "Domaine de recherche DNS"
  type        = string
  default     = "local"
}

# ============================================================================
# COMPUTE RESOURCES
# ============================================================================

variable "cores" {
  description = "Nombre de CPU cores"
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Nombre de CPU sockets"
  type        = number
  default     = 1
}

variable "memory" {
  description = "RAM en MB"
  type        = number
  default     = 2048
}

variable "balloon" {
  description = "RAM minimum avec ballooning (0 = désactivé)"
  type        = number
  default     = 0
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "disk" {
  description = "Configuration du disque principal"
  type = object({
    storage = string  # Storage pool (local-lvm, etc.)
    size    = string  # Taille du disque (ex: 32G)
    type    = string  # Type de disque (scsi, virtio, sata, ide)
    format  = optional(string)  # Format (raw, qcow2)
    cache   = optional(string)  # Mode cache (none, writeback, writethrough)
    iothread = optional(bool)   # Activer iothread
    ssd     = optional(bool)    # Émuler SSD
    discard = optional(bool)    # Activer discard/TRIM
  })
  default = {
    storage = "local-lvm"
    size    = "32G"
    type    = "virtio"
    format  = "raw"
    cache   = "none"
  }
}

variable "additional_disks" {
  description = "Disques supplémentaires (optionnels)"
  type = list(object({
    storage = string
    size    = string
    type    = string
    format  = optional(string)
    cache   = optional(string)
  }))
  default = []
}

# ============================================================================
# OS CONFIGURATION
# ============================================================================

variable "clone" {
  description = "Template à cloner (optionnel)"
  type        = string
  default     = null
}

variable "iso" {
  description = "ISO à monter (format: storage:iso/file.iso)"
  type        = string
  default     = null
}

variable "cdrom" {
  description = "Configuration du CD-ROM"
  type        = string
  default     = null
}

variable "boot" {
  description = "Ordre de boot (ex: order=scsi0;ide2;net0)"
  type        = string
  default     = "order=scsi0"
}

variable "bios" {
  description = "Type de BIOS (seabios ou ovmf pour UEFI)"
  type        = string
  default     = "seabios"
}

variable "machine" {
  description = "Type de machine (ex: q35)"
  type        = string
  default     = null
}

# ============================================================================
# HARDWARE OPTIONS
# ============================================================================

variable "agent" {
  description = "Activer QEMU Guest Agent (1 = activé)"
  type        = number
  default     = 0
}

variable "onboot" {
  description = "Démarrer la VM au boot du node"
  type        = bool
  default     = true
}

variable "startup" {
  description = "Options de démarrage (ex: order=1,up=30,down=60)"
  type        = string
  default     = ""
}

variable "protection" {
  description = "Protection contre suppression accidentelle"
  type        = bool
  default     = false
}

variable "tablet" {
  description = "Activer le périphérique tablette USB (meilleur contrôle souris)"
  type        = bool
  default     = true
}

variable "hotplug" {
  description = "Périphériques hotplug autorisés (network,disk,cpu,memory,usb)"
  type        = string
  default     = "network,disk,usb"
}

# ============================================================================
# CLOUD-INIT (optionnel)
# ============================================================================

variable "cloudinit_cdrom_storage" {
  description = "Storage pour le CD-ROM cloud-init"
  type        = string
  default     = null
}

variable "ciuser" {
  description = "Utilisateur cloud-init"
  type        = string
  default     = null
}

variable "cipassword" {
  description = "Mot de passe cloud-init"
  type        = string
  default     = null
  sensitive   = true
}

variable "sshkeys" {
  description = "Clés SSH publiques (séparées par \\n)"
  type        = string
  default     = null
}

# ============================================================================
# METADATA
# ============================================================================

variable "description" {
  description = "Description de la VM"
  type        = string
  default     = "Managed by Terraform"
}

variable "tags" {
  description = "Tags pour la VM (séparés par ;)"
  type        = string
  default     = ""
}
