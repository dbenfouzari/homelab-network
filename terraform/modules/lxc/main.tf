terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0"
    }
  }
}

resource "proxmox_lxc" "container" {
  # ============================================================================
  # BASIC CONFIGURATION
  # ============================================================================

  vmid        = var.vmid
  hostname    = var.hostname
  target_node = var.target_node
  description = var.description
  tags        = var.tags

  # ============================================================================
  # OS TEMPLATE
  # ============================================================================

  ostemplate   = var.ostemplate
  unprivileged = var.unprivileged

  # ============================================================================
  # COMPUTE RESOURCES
  # ============================================================================

  cores  = var.cores
  memory = var.memory
  swap   = var.swap

  # ============================================================================
  # BOOT OPTIONS
  # ============================================================================

  onboot     = var.onboot
  start      = var.start
  startup    = var.startup
  protection = var.protection

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================

  network {
    name     = var.network.name
    bridge   = var.network.bridge
    ip       = var.network.ip
    gw       = var.network.gw
    tag      = var.network.tag
    firewall = var.network.firewall != null ? var.network.firewall : false
  }

  nameserver   = var.nameserver
  searchdomain = var.searchdomain

  # ============================================================================
  # STORAGE CONFIGURATION
  # ============================================================================

  rootfs {
    storage = var.rootfs.storage
    size    = var.rootfs.size
  }

  # Points de montage additionnels
  dynamic "mountpoint" {
    for_each = var.mountpoint
    content {
      key     = mountpoint.value.key
      slot    = mountpoint.value.slot
      storage = mountpoint.value.storage
      size    = mountpoint.value.size
      mp      = mountpoint.value.mp
    }
  }

  # ============================================================================
  # AUTHENTICATION
  # ============================================================================

  password        = var.password
  ssh_public_keys = var.ssh_public_keys

  # ============================================================================
  # CONTAINER FEATURES
  # ============================================================================

  features {
    nesting = var.features.nesting != null ? var.features.nesting : false
    fuse    = var.features.fuse != null ? var.features.fuse : false
    keyctl  = var.features.keyctl != null ? var.features.keyctl : false
    mount   = var.features.mount
  }

  # ============================================================================
  # LIFECYCLE
  # ============================================================================

  lifecycle {
    ignore_changes = [
      # Ignorer les changements faits manuellement via l'UI Proxmox
      network,
      mountpoint,
    ]
  }
}
