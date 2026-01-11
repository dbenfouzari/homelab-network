# Makefile pour Ansible OPNsense
# Usage: make backup, make configure, etc.

.PHONY: help backup configure wireguard firewall dns dhcp

# Configuration shell
SHELL := /bin/bash
.ONESHELL:

# Commande pour sourcer les variables d'environnement
ENV_LOAD = set -a && source ../.env && set +a

help:
	@echo "Commandes disponibles:"
	@echo "  make backup      - Backup de la configuration OPNsense"
	@echo "  make configure   - Configuration complète OPNsense"
	@echo "  make wireguard   - Configuration WireGuard VPN"
	@echo "  make firewall    - Configuration firewall"
	@echo "  make dns         - Configuration DNS"
	@echo "  make dhcp        - Configuration DHCP"

backup:
	@echo "📦 Backup de la configuration OPNsense..."
	$(ENV_LOAD) && ansible-playbook -i inventory/opnsense.yml playbooks/configure-opnsense.yml --tags=backup

configure:
	@echo "⚙️  Configuration complète OPNsense..."
	$(ENV_LOAD) && ansible-playbook -i inventory/opnsense.yml playbooks/configure-opnsense.yml

wireguard:
	@echo "🔐 Configuration WireGuard VPN..."
	$(ENV_LOAD) && ansible-playbook -i inventory/opnsense.yml playbooks/configure-opnsense.yml --tags=wireguard

firewall:
	@echo "🔥 Configuration firewall..."
	$(ENV_LOAD) && ansible-playbook -i inventory/opnsense.yml playbooks/configure-opnsense.yml --tags=firewall

dns:
	@echo "🌐 Configuration DNS..."
	$(ENV_LOAD) && ansible-playbook -i inventory/opnsense.yml playbooks/configure-opnsense.yml --tags=dns

dhcp:
	@echo "📡 Configuration DHCP..."
	$(ENV_LOAD) && ansible-playbook -i inventory/opnsense.yml playbooks/configure-opnsense.yml --tags=dhcp
