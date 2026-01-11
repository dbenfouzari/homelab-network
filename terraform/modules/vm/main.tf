terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
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

  cpu {
    cores   = var.cores
    sockets = var.sockets
  }

  memory  = var.memory
  balloon = var.balloon

  # ============================================================================
  # BOOT CONFIGURATION
  # ============================================================================

  start_at_node_boot = var.onboot

  # Startup/shutdown ordre (bloc remplaçant l'ancien attribut startup)
  dynamic "startup_shutdown" {
    for_each = var.startup != "" ? [1] : []
    content {
      order          = 1   # Correspond à order=1 dans var.startup
      startup_delay  = 60  # Correspond à up=60 dans var.startup
    }
  }

  boot    = var.boot
  agent   = var.agent
  bios    = var.bios
  machine = var.machine

  # ============================================================================
  # HARDWARE OPTIONS
  # ============================================================================

  tablet  = var.tablet
  hotplug = var.hotplug

  # ============================================================================
  # OS INSTALLATION - Clone or ISO
  # ============================================================================

  clone = var.clone

  # ============================================================================
  # NETWORK CONFIGURATION (v3 format avec id requis)
  # ============================================================================

  dynamic "network" {
    for_each = var.networks
    content {
      id       = network.key  # Index dans la liste (0, 1, 2, etc.)
      model    = network.value.model
      bridge   = network.value.bridge
      tag      = network.value.tag
      firewall = network.value.firewall != null ? network.value.firewall : false
    }
  }

  # ============================================================================
  # IP CONFIGURATION
  # ============================================================================

  ipconfig0 = length(var.ipconfig) > 0 ? var.ipconfig[0] : null
  ipconfig1 = length(var.ipconfig) > 1 ? var.ipconfig[1] : null
  ipconfig2 = length(var.ipconfig) > 2 ? var.ipconfig[2] : null

  nameserver   = var.nameserver
  searchdomain = var.searchdomain

  # ============================================================================
  # STORAGE CONFIGURATION (v3 format avec disks{})
  # ============================================================================

  disks {
    # ISO pour installation (ide2 par convention) - seulement si pas de clone
    dynamic "ide" {
      for_each = var.iso != null && var.clone == null ? [1] : []
      content {
        ide2 {
          cdrom {
            iso = var.iso
          }
        }
      }
    }

    # CloudInit drive (ide2) - seulement pour les VMs clonées avec cloud-init
    dynamic "ide" {
      for_each = var.clone != null && (var.ciuser != null || var.cipassword != null) ? [1] : []
      content {
        ide2 {
          cloudinit {
            storage = var.disk.storage
          }
        }
      }
    }

    # Disque principal selon le type (scsi, virtio, sata, ide)
    dynamic "scsi" {
      for_each = var.disk.type == "scsi" ? [var.disk] : []
      content {
        scsi0 {
          disk {
            storage    = scsi.value.storage
            size       = scsi.value.size
            cache      = scsi.value.cache != null ? scsi.value.cache : "none"
            iothread   = scsi.value.iothread != null ? scsi.value.iothread : false
            emulatessd = scsi.value.ssd != null ? scsi.value.ssd : false
            discard    = scsi.value.discard != null ? scsi.value.discard : false
          }
        }
      }
    }

    dynamic "virtio" {
      for_each = var.disk.type == "virtio" ? [var.disk] : []
      content {
        virtio0 {
          disk {
            storage  = virtio.value.storage
            size     = virtio.value.size
            cache    = virtio.value.cache != null ? virtio.value.cache : "none"
            iothread = virtio.value.iothread != null ? virtio.value.iothread : false
            discard  = virtio.value.discard != null ? virtio.value.discard : false
            # emulatessd n'est pas disponible pour virtio
          }
        }
      }
    }

    dynamic "sata" {
      for_each = var.disk.type == "sata" ? [var.disk] : []
      content {
        sata0 {
          disk {
            storage    = sata.value.storage
            size       = sata.value.size
            cache      = sata.value.cache != null ? sata.value.cache : "none"
            emulatessd = sata.value.ssd != null ? sata.value.ssd : false
            discard    = sata.value.discard != null ? sata.value.discard : false
          }
        }
      }
    }
  }

  # ============================================================================
  # CLOUD-INIT (si utilisé)
  # ============================================================================

  ciuser     = var.ciuser
  cipassword = var.cipassword
  sshkeys    = var.sshkeys

  # ============================================================================
  # LIFECYCLE
  # ============================================================================

  lifecycle {
    ignore_changes = [
      # Ignorer les changements faits manuellement via l'UI Proxmox
      network,
      # Note: on ne peut pas ignorer 'disks' car ça empêche le cloud-init de se configurer
      clone,
    ]
  }
}
