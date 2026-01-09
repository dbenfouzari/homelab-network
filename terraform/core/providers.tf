terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

# Provider pour pve-host-1 (192.168.2.101)
provider "proxmox" {
  alias = "pve1"

  pm_api_url      = var.proxmox_api_urls["pve1"]
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_passwords["pve1"]
  pm_tls_insecure = true  # Certificat auto-signé

  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox-pve1.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}

# Provider pour pve-host-2 (192.168.2.102)
provider "proxmox" {
  alias = "pve2"

  pm_api_url      = var.proxmox_api_urls["pve2"]
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_passwords["pve2"]
  pm_tls_insecure = true

  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox-pve2.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}

# Provider pour pve-host-3 (192.168.2.103)
provider "proxmox" {
  alias = "pve3"

  pm_api_url      = var.proxmox_api_urls["pve3"]
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_passwords["pve3"]
  pm_tls_insecure = true

  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox-pve3.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}
