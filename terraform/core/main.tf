# ============================================================================
# OPNSENSE FIREWALL/ROUTER
# ============================================================================
# VM critique déployée sur pve-host-1
# Gateway principal du réseau, gère les VLANs et le VPN WireGuard

module "opnsense" {
  source = "../modules/vm"

  # Provider Proxmox
  providers = {
    proxmox = proxmox.pve1
  }

  # ============================================================================
  # IDENTIFICATION
  # ============================================================================

  vmid        = 100
  name        = "opnsense"
  target_node = "pve-host-1"
  description = "OPNsense Firewall/Router - Gateway principal avec VPN WireGuard"
  tags        = "firewall;router;critical"

  # ============================================================================
  # COMPUTE RESOURCES
  # ============================================================================

  cores   = 2
  sockets = 1
  memory  = 4096  # 4GB RAM pour OPNsense
  balloon = 0     # Pas de ballooning pour la stabilité

  # ============================================================================
  # NETWORK INTERFACES
  # ============================================================================
  # Interface 0 (vtnet0) = LAN
  # Interface 1 (vtnet1) = WAN

  networks = [
    {
      # LAN - Interface interne (temporairement 192.168.2.x, puis 192.168.10.1)
      model    = "virtio"
      bridge   = var.network_legacy.bridge
      firewall = false
    },
    {
      # WAN - Interface vers Livebox (192.168.2.x)
      model    = "virtio"
      bridge   = var.network_legacy.bridge
      firewall = false
    }
  ]

  # Configuration IP temporaire (legacy - VLAN 1)
  # LAN : 192.168.2.254 (temporaire, passera en 192.168.10.1 après migration VLAN)
  # WAN : DHCP depuis Livebox
  ipconfig = [
    "ip=192.168.2.254/24,gw=192.168.2.1",  # LAN temporaire
    "dhcp"                                  # WAN en DHCP
  ]

  nameserver    = join(" ", var.dns_servers.legacy)
  searchdomain  = var.default_searchdomain

  # ============================================================================
  # STORAGE
  # ============================================================================

  disk = {
    storage  = "local-lvm"
    size     = "32G"
    type     = "virtio"
    format   = "raw"
    cache    = "none"
    iothread = true
    ssd      = true
    discard  = true
  }

  # ============================================================================
  # OS INSTALLATION
  # ============================================================================

  # À configurer : télécharger l'ISO OPNsense sur Proxmox
  # iso = "local:iso/OPNsense-24.7-dvd-amd64.iso"
  iso = null  # À remplir après upload de l'ISO

  # Ordre de boot : disque en premier (après installation)
  boot = "order=virtio0;ide2"
  bios = "seabios"

  # ============================================================================
  # HARDWARE OPTIONS
  # ============================================================================

  agent      = 0      # Pas de QEMU agent pour OPNsense
  onboot     = true   # Démarrage automatique CRITIQUE
  startup    = "order=1,up=30,down=60"  # Démarrer en premier
  protection = true   # Protection contre suppression accidentelle
  tablet     = true
  hotplug    = "network,disk,usb"
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "opnsense_vm_id" {
  description = "ID de la VM OPNsense"
  value       = module.opnsense.vm_id
}

output "opnsense_name" {
  description = "Nom de la VM OPNsense"
  value       = module.opnsense.vm_name
}

output "opnsense_node" {
  description = "Node Proxmox hébergeant OPNsense"
  value       = module.opnsense.vm_node
}
