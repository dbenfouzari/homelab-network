.PHONY: help init plan apply destroy ansible-check ansible-deploy clean

# Variables
TF_DIR := terraform/core
ANSIBLE_DIR := ansible
INVENTORY := $(ANSIBLE_DIR)/inventory/production.yml

# Couleurs pour l'affichage
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

##@ Aide

help: ## Afficher l'aide
	@echo "$(CYAN)Homelab Infrastructure as Code$(NC)"
	@echo ""
	@echo "$(GREEN)Usage:$(NC)"
	@echo "  make <target>"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup

init: ## Initialiser Terraform
	@echo "$(CYAN)→ Initialisation de Terraform...$(NC)"
	cd $(TF_DIR) && terraform init
	@echo "$(GREEN)✓ Terraform initialisé$(NC)"

check-passwords: ## Vérifier que les mots de passe sont configurés
	@if [ -z "$$TF_VAR_proxmox_passwords" ]; then \
		echo "$(RED)✗ TF_VAR_proxmox_passwords non défini$(NC)"; \
		echo "$(YELLOW)Configurez les mots de passe:$(NC)"; \
		echo "  export TF_VAR_proxmox_passwords='{\"pve1\":\"pass1\",\"pve2\":\"pass2\",\"pve3\":\"pass3\"}'"; \
		echo "$(YELLOW)Ou créez terraform/core/terraform.tfvars (à ne PAS commit)$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Variables d'environnement configurées$(NC)"

##@ Terraform

plan: check-passwords ## Planifier les changements Terraform
	@echo "$(CYAN)→ Planification Terraform...$(NC)"
	cd $(TF_DIR) && terraform plan
	@echo "$(GREEN)✓ Plan généré$(NC)"

apply: check-passwords ## Appliquer les changements Terraform
	@echo "$(YELLOW)⚠️  Cette commande va créer/modifier l'infrastructure$(NC)"
	@echo "$(CYAN)→ Application des changements...$(NC)"
	cd $(TF_DIR) && terraform apply
	@echo "$(GREEN)✓ Infrastructure déployée$(NC)"

apply-auto: check-passwords ## Appliquer sans confirmation (DANGER)
	@echo "$(RED)⚠️  Application automatique (sans confirmation)$(NC)"
	cd $(TF_DIR) && terraform apply -auto-approve

destroy: check-passwords ## Détruire l'infrastructure (DANGER)
	@echo "$(RED)⚠️  Cette commande va SUPPRIMER toute l'infrastructure$(NC)"
	cd $(TF_DIR) && terraform destroy

show: ## Afficher l'état Terraform
	cd $(TF_DIR) && terraform show

output: ## Afficher les outputs Terraform
	cd $(TF_DIR) && terraform output

##@ Ansible

ansible-check: ## Vérifier la syntaxe Ansible
	@echo "$(CYAN)→ Vérification de la syntaxe Ansible...$(NC)"
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/playbooks/site.yml --syntax-check
	@echo "$(GREEN)✓ Syntaxe valide$(NC)"

ansible-inventory: ## Afficher l'inventaire Ansible
	@echo "$(CYAN)→ Inventaire Ansible:$(NC)"
	ansible-inventory -i $(INVENTORY) --list

ansible-ping: ## Tester la connectivité aux hosts
	@echo "$(CYAN)→ Test de connectivité...$(NC)"
	ansible all -i $(INVENTORY) -m ping

ansible-deploy: ## Déployer avec Ansible (tous les services)
	@echo "$(CYAN)→ Déploiement complet...$(NC)"
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/playbooks/site.yml

ansible-deploy-critical: ## Déployer uniquement l'infrastructure critique
	@echo "$(CYAN)→ Déploiement infrastructure critique...$(NC)"
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/playbooks/site.yml --tags "critical"

ansible-deploy-dns: ## Déployer AdGuard Home
	@echo "$(CYAN)→ Déploiement AdGuard Home...$(NC)"
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/playbooks/site.yml --tags "dns"

ansible-deploy-apps: ## Déployer les services applicatifs
	@echo "$(CYAN)→ Déploiement services applicatifs...$(NC)"
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/playbooks/site.yml --tags "apps"

ansible-deploy-media: ## Déployer les services média
	@echo "$(CYAN)→ Déploiement services média...$(NC)"
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/playbooks/site.yml --tags "media"

##@ Workflow complet

deploy-opnsense: init plan ## Workflow: Déployer OPNsense
	@echo "$(CYAN)→ Déploiement d'OPNsense...$(NC)"
	@echo "$(YELLOW)⚠️  Assurez-vous d'avoir uploadé l'ISO OPNsense sur Proxmox$(NC)"
	@echo "$(YELLOW)⚠️  Configurez la variable 'iso' dans terraform/core/main.tf$(NC)"
	@read -p "Continuer? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	$(MAKE) apply
	@echo ""
	@echo "$(GREEN)✓ VM OPNsense créée$(NC)"
	@echo "$(YELLOW)→ Prochaines étapes:$(NC)"
	@echo "  1. Accéder à la console Proxmox de la VM"
	@echo "  2. Suivre l'installation OPNsense depuis l'ISO"
	@echo "  3. Configurer LAN/WAN via la console"
	@echo "  4. Accéder au Web UI: https://192.168.2.254"
	@echo "  5. Suivre la doc: ~/Workspace/network/docs/migration-logs/phase-1-vpn/"

deploy-all: init apply ansible-deploy ## Workflow: Déployer tout (Terraform + Ansible)
	@echo "$(GREEN)✓ Déploiement complet terminé$(NC)"

##@ Maintenance

clean: ## Nettoyer les fichiers temporaires
	@echo "$(CYAN)→ Nettoyage...$(NC)"
	find . -type f -name "*.log" -delete
	find . -type f -name "*.retry" -delete
	cd $(TF_DIR) && rm -rf .terraform.lock.hcl
	@echo "$(GREEN)✓ Nettoyage terminé$(NC)"

fmt: ## Formater le code Terraform
	@echo "$(CYAN)→ Formatage Terraform...$(NC)"
	cd $(TF_DIR) && terraform fmt -recursive
	@echo "$(GREEN)✓ Code formaté$(NC)"

validate: init ## Valider la configuration Terraform
	@echo "$(CYAN)→ Validation Terraform...$(NC)"
	cd $(TF_DIR) && terraform validate
	@echo "$(GREEN)✓ Configuration valide$(NC)"

##@ Backup & Restore

backup: ## Sauvegarder l'état Terraform
	@echo "$(CYAN)→ Sauvegarde de l'état Terraform...$(NC)"
	mkdir -p backups
	cp $(TF_DIR)/terraform.tfstate backups/terraform.tfstate.$(shell date +%Y%m%d_%H%M%S)
	@echo "$(GREEN)✓ Sauvegarde créée$(NC)"

##@ Documentation

docs: ## Générer la documentation Terraform
	@echo "$(CYAN)→ Génération de la documentation...$(NC)"
	terraform-docs markdown table $(TF_DIR) > docs/terraform.md
	@echo "$(GREEN)✓ Documentation générée: docs/terraform.md$(NC)"

tree: ## Afficher l'arborescence du projet
	@tree -I '.git|.terraform|node_modules|__pycache__|*.pyc' -L 3
