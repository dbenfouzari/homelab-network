# ============================================================================
# ADGUARD HOME - DNS SERVER WITH AD BLOCKING
# ============================================================================
# Container AdGuard Home pour filtrage DNS et blocage publicitaire
#
# Architecture DNS:
#   Clients → AdGuard (192.168.2.53) → Upstream DNS (Cloudflare 1.1.1.1)
#             ↓ (résolution .lan)
#             Unbound OPNsense (192.168.2.254)
#
# Fonctionnalités:
#   - Filtrage publicitaire et anti-tracking au niveau DNS
#   - Interface web de gestion (port 3000)
#   - Statistiques et logs détaillés
#   - Gestion de blocklists personnalisables
#
# Installation:
#   1. Terraform crée le LXC Debian 13
#   2. Ansible installe et configure AdGuard Home
#   3. Configuration via Web UI (http://192.168.2.53:3000)
#   4. Configuration DHCP pour pointer les clients vers AdGuard

module "adguard" {
  source = "../modules/lxc"

  # Provider configuration
  providers = {
    proxmox = proxmox.pve1
  }

  # ============================================================================
  # BASIC CONFIGURATION
  # ============================================================================

  vmid        = 300
  hostname    = "adguard"
  target_node = "pve-host-1"
  description = "AdGuard Home - DNS avec filtrage publicitaire"
  tags        = "dns;adblock;infrastructure"

  # ============================================================================
  # OS TEMPLATE
  # ============================================================================

  ostemplate   = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
  unprivileged = true  # Container non privilégié pour sécurité

  # ============================================================================
  # COMPUTE RESOURCES
  # ============================================================================

  cores  = 1     # 1 core suffisant pour DNS
  memory = 512   # 512MB RAM (AdGuard est léger)
  swap   = 512   # Swap égal à la RAM

  # ============================================================================
  # BOOT OPTIONS
  # ============================================================================

  onboot     = true   # Démarrer automatiquement
  start      = true   # Démarrer après création
  startup    = "order=2,up=30"  # Démarrer après OPNsense (ordre 2)
  protection = false  # Pas de protection (pour permettre suppression)

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================

  network = {
    name     = "eth0"
    bridge   = "vmbr1"            # Bridge VLAN-aware
    ip       = "192.168.2.53/24"  # IP fixe pour DNS
    gw       = "192.168.2.254"    # Gateway = OPNsense
    tag      = null               # Pas de VLAN (réseau LAN principal)
    firewall = false
  }

  nameserver   = "192.168.2.254"  # OPNsense comme DNS pendant l'installation
  searchdomain = "lan"

  # ============================================================================
  # STORAGE CONFIGURATION
  # ============================================================================

  rootfs = {
    storage = "local-lvm"
    size    = "4G"  # 4GB suffisant pour AdGuard + logs
  }

  mountpoint = []  # Pas de points de montage additionnels

  # ============================================================================
  # AUTHENTICATION
  # ============================================================================

  password        = var.lxc_root_password
  ssh_public_keys = var.ssh_public_keys

  # ============================================================================
  # CONTAINER FEATURES
  # ============================================================================

  features = {
    nesting = false  # Pas besoin de nesting pour AdGuard
    fuse    = false
    keyctl  = false
    mount   = null
  }
}
