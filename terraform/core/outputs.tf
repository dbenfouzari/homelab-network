# ============================================================================
# INFRASTRUCTURE OUTPUTS
# ============================================================================

output "infrastructure_summary" {
  description = "Résumé de l'infrastructure déployée"
  value = {
    opnsense = {
      vm_id = module.opnsense.vm_id
      name  = module.opnsense.vm_name
      node  = module.opnsense.vm_node
      role  = "Firewall/Router - Gateway principal"
    }
  }
}
