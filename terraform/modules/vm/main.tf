terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  # ============================================================================
  # BASIC CONFIGURATION
  # ============================================================================

  vmid        = var.vmid
  name        = var.name
  target_node = var.target_node
  description = var.description
  tags        = var.tags

  # ============================================================================
  # COMPUTE RESOURCES
  # ============================================================================

  cores   = var.cores
  sockets = var.sockets
  memory  = var.memory
  balloon = var.balloon

  # ============================================================================
  # BOOT CONFIGURATION
  # ============================================================================

  onboot    = var.onboot
  startup   = var.startup
  boot      = var.boot
  agent     = var.agent
  bios      = var.bios
  machine   = var.machine

  # ============================================================================
  # HARDWARE OPTIONS
  # ============================================================================

  tablet     = var.tablet
  hotplug    = var.hotplug
  protection = var.protection

  # ============================================================================
  # OS INSTALLATION
  # ============================================================================

  clone = var.clone
  iso   = var.iso

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================

  dynamic "network" {
    for_each = var.networks
    content {
      model    = network.value.model
      bridge   = network.value.bridge
      tag      = network.value.tag
      firewall = network.value.firewall != null ? network.value.firewall : false
    }
  }

  # Configuration IP (cloud-init ou manual)
  dynamic "ipconfig0" {
    for_each = length(var.ipconfig) > 0 ? [var.ipconfig[0]] : []
    content {
      ip  = ipconfig0.value != "dhcp" ? ipconfig0.value : null
      gw  = ipconfig0.value != "dhcp" ? null : null
    }
  }

  dynamic "ipconfig1" {
    for_each = length(var.ipconfig) > 1 ? [var.ipconfig[1]] : []
    content {
      ip = ipconfig1.value
    }
  }

  dynamic "ipconfig2" {
    for_each = length(var.ipconfig) > 2 ? [var.ipconfig[2]] : []
    content {
      ip = ipconfig2.value
    }
  }

  nameserver    = var.nameserver
  searchdomain  = var.searchdomain

  # ============================================================================
  # STORAGE CONFIGURATION
  # ============================================================================

  # Disque principal
  dynamic "disk" {
    for_each = [var.disk]
    content {
      type      = disk.value.type
      storage   = disk.value.storage
      size      = disk.value.size
      format    = disk.value.format != null ? disk.value.format : "raw"
      cache     = disk.value.cache != null ? disk.value.cache : "none"
      iothread  = disk.value.iothread != null ? disk.value.iothread : false
      ssd       = disk.value.ssd != null ? disk.value.ssd : false
      discard   = disk.value.discard != null ? disk.value.discard : false
    }
  }

  # Disques additionnels
  dynamic "disk" {
    for_each = var.additional_disks
    content {
      type    = disk.value.type
      storage = disk.value.storage
      size    = disk.value.size
      format  = disk.value.format != null ? disk.value.format : "raw"
      cache   = disk.value.cache != null ? disk.value.cache : "none"
    }
  }

  # ============================================================================
  # CLOUD-INIT (si utilisé)
  # ============================================================================

  cloudinit_cdrom_storage = var.cloudinit_cdrom_storage
  ciuser                  = var.ciuser
  cipassword              = var.cipassword
  sshkeys                 = var.sshkeys

  # ============================================================================
  # LIFECYCLE
  # ============================================================================

  lifecycle {
    ignore_changes = [
      # Ignorer les changements faits manuellement via l'UI Proxmox
      network,
      disk,
      clone,
    ]
  }
}
