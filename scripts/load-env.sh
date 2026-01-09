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
if [ -z "$PVE_HOST_1_PASSWORD" ] || [ -z "$PVE_HOST_2_PASSWORD" ] || [ -z "$PVE_HOST_3_PASSWORD" ]; then
    echo "❌ Variables manquantes dans .env"
    echo "→ Les variables suivantes sont requises:"
    echo "   - PVE_HOST_1_PASSWORD"
    echo "   - PVE_HOST_2_PASSWORD"
    echo "   - PVE_HOST_3_PASSWORD"
    exit 1
fi

# Construire la variable TF_VAR_proxmox_passwords avec proper escaping
# Utilisation de jq pour construire le JSON correctement
export TF_VAR_proxmox_passwords=$(jq -n \
    --arg pve1 "$PVE_HOST_1_PASSWORD" \
    --arg pve2 "$PVE_HOST_2_PASSWORD" \
    --arg pve3 "$PVE_HOST_3_PASSWORD" \
    '{pve1: $pve1, pve2: $pve2, pve3: $pve3}')

# Vérifier que le JSON a été créé correctement
if [ -z "$TF_VAR_proxmox_passwords" ]; then
    echo "❌ Échec de la création de la variable TF_VAR_proxmox_passwords"
    exit 1
fi

echo "✓ Variables d'environnement chargées"
