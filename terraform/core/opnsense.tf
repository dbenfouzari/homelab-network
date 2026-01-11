# ============================================================================
# OPNSENSE FIREWALL/ROUTER VM
# ============================================================================
# VM OPNsense pour gérer le routage et la sécurité du homelab
#
# Architecture réseau:
#   - WAN (net0): vmbr0 → Réseau management/Livebox (192.168.2.0/24)
#   - LAN (net1): vmbr1 → Bridge VLAN-aware pour réseau interne segmenté
#
# Installation:
#   1. Terraform crée la VM et boot sur l'ISO
#   2. Installation manuelle d'OPNsense via la console Proxmox
#   3. Configuration initiale via console (assignation WAN/LAN)
#   4. Configuration avancée via Web UI (https://LAN_IP)
#   5. Plus tard: Ansible pour automatiser la config OPNsense
#
# IMPORTANT: Cette VM sera créée mais PAS démarrée automatiquement.
# Vous devez l'installer manuellement avant de la gérer avec Ansible.

module "opnsense" {
  source = "../modules/vm"

  # Provider configuration
  providers = {
    proxmox = proxmox.pve1  # pve-host-1 a l'accès WAN direct
  }

  # ============================================================================
  # BASIC CONFIGURATION
  # ============================================================================

  vmid        = 200
  name        = "opnsense"
  target_node = "pve-host-1"
  description = "OPNsense Firewall/Router - Infrastructure critique"
  tags        = "firewall;router;critical"

  # ============================================================================
  # COMPUTE RESOURCES
  # ============================================================================

  cores   = 2      # OPNsense recommande 2+ cores pour routage performant
  sockets = 1
  memory  = 2048   # 2GB RAM (minimum recommandé pour OPNsense)
  balloon = 0      # Désactiver le ballooning pour stabilité

  # ============================================================================
  # BOOT CONFIGURATION
  # ============================================================================

  onboot  = false  # NE PAS démarrer automatiquement (installation manuelle d'abord)
  startup = "order=1,up=60"  # Une fois configuré, démarrer en premier (ordre 1)
  boot    = "order=ide2;scsi0"  # Boot sur IDE (ISO) puis disque
  agent   = 0      # Pas de QEMU Guest Agent (FreeBSD, pas installé par défaut)
  bios    = "ovmf"  # UEFI (recommandé pour OPNsense moderne)
  machine = "q35"   # Type de machine moderne

  # ============================================================================
  # HARDWARE OPTIONS
  # ============================================================================

  tablet     = true   # Meilleure intégration souris dans console noVNC
  hotplug    = "network,disk,usb"
  protection = false  # Pas de protection (pour permettre suppression via Terraform)

  # ============================================================================
  # OS INSTALLATION
  # ============================================================================

  # ISO OPNsense uploadé sur pve-host-1
  iso = "local:iso/OPNsense-25.7-dvd-amd64.iso"

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================

  networks = [
    {
      # WAN - Réseau management via Livebox (transition)
      model    = "virtio"
      bridge   = "vmbr0"
      tag      = null      # Pas de VLAN (réseau flat)
      firewall = false
    },
    {
      # LAN - Bridge VLAN-aware pour réseau interne
      model    = "virtio"
      bridge   = "vmbr1"
      tag      = null      # Pas de tag VLAN sur le port (trunk)
      firewall = false     # OPNsense gère son propre firewall
    }
  ]

  # Pas de configuration IP automatique (installation manuelle)
  ipconfig = []

  # ============================================================================
  # STORAGE CONFIGURATION
  # ============================================================================

  disk = {
    type    = "scsi"
    storage = "local-lvm"  # Stockage LVM sur pve-host-1
    size    = "16G"        # 16GB (OPNsense recommande 8GB minimum)
    format  = "raw"
    cache   = "writethrough"  # Meilleure durabilité pour firewall critique
    iothread = false         # Désactivé (pas compatible avec SCSI LSI)
    ssd     = true           # Optimisations SSD si applicable
    discard = true           # TRIM/discard pour SSD
  }

  additional_disks = []  # Pas de disques additionnels pour l'instant

  # ============================================================================
  # CLOUD-INIT (non utilisé pour OPNsense)
  # ============================================================================

  ciuser     = null
  cipassword = null
  sshkeys    = null
}
