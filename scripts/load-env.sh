#!/usr/bin/env bash
# ============================================================================
# LOAD ENVIRONMENT VARIABLES
# ============================================================================
# Charge les variables depuis .env et les exporte pour Terraform/Ansible
#
# Usage:
#   source scripts/load-env.sh
#   make plan

set -e

# Vérifier que .env existe
if [ ! -f .env ]; then
    echo "❌ Fichier .env manquant"
    echo "→ Copiez .env.example vers .env et remplissez les valeurs"
    echo "   cp .env.example .env"
    exit 1
fi

# Charger les variables depuis .env
set -a
source .env
set +a

# Vérifier que les variables requises sont définies
# Passwords pour Ansible
if [ -z "$PVE_HOST_1_PASSWORD" ] || [ -z "$PVE_HOST_2_PASSWORD" ] || [ -z "$PVE_HOST_3_PASSWORD" ]; then
    echo "❌ Variables de mots de passe manquantes dans .env"
    echo "→ Les variables suivantes sont requises pour Ansible:"
    echo "   - PVE_HOST_1_PASSWORD"
    echo "   - PVE_HOST_2_PASSWORD"
    echo "   - PVE_HOST_3_PASSWORD"
    exit 1
fi

# API Token pour Terraform
if [ -z "$PVE_API_TOKEN" ]; then
    echo "❌ Variable PVE_API_TOKEN manquante dans .env"
    echo "→ Créez un token API dans Datacenter > Permissions > API Tokens"
    echo "   Format: root@pam!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    exit 1
fi

# API Keys OPNsense (optionnel - requis uniquement pour Ansible OPNsense)
if [ -n "$OPNSENSE_API_KEY" ] && [ -n "$OPNSENSE_API_SECRET" ]; then
    export OPNSENSE_API_KEY
    export OPNSENSE_API_SECRET
    echo "✓ Credentials OPNsense chargés"
fi

# Exporter les variables pour Terraform
export TF_VAR_proxmox_api_token="$PVE_API_TOKEN"
export TF_VAR_lxc_root_password="$LXC_ROOT_PASSWORD"

echo "✓ Variables d'environnement chargées"
