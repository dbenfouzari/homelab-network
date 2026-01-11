#!/usr/bin/env bash
# ============================================================================
# CREATE UBUNTU CLOUD-INIT TEMPLATE ON PROXMOX
# ============================================================================
#
# Ce script crée un template Ubuntu 24.04 LTS avec cloud-init sur Proxmox
# Le template peut ensuite être cloné rapidement via Terraform
#
# Usage:
#   ./scripts/create-ubuntu-template.sh [node] [template-id] [storage]
#
# Arguments (optionnels):
#   node        : Nom du node Proxmox (défaut: pve-host-1)
#   template-id : VMID du template (défaut: 9000)
#   storage     : Nom du storage (défaut: local-lvm)
#
# Exemple:
#   ./scripts/create-ubuntu-template.sh pve-host-1 9000 local-lvm
#
# Prérequis:
#   - SSH configuré vers le node Proxmox
#   - Accès root sur le node
#   - ~1GB d'espace disque libre
#
# Le template créé inclut:
#   - Ubuntu 24.04 LTS (Noble Numbat)
#   - QEMU Guest Agent
#   - Cloud-init configuré
#   - Disque virtio SCSI
#   - Network virtio
#   - Serial console
#   - VGA display
#
# ============================================================================

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Couleurs pour output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Paramètres par défaut
PROXMOX_NODE="${1:-pve-host-1}"
TEMPLATE_ID="${2:-9000}"
STORAGE="${3:-local-lvm}"

# Configuration Ubuntu Cloud Image
readonly UBUNTU_VERSION="24.04"
readonly UBUNTU_CODENAME="noble"
readonly IMAGE_URL="https://cloud-images.ubuntu.com/${UBUNTU_CODENAME}/current/${UBUNTU_CODENAME}-server-cloudimg-amd64.img"
readonly IMAGE_FILE="${UBUNTU_CODENAME}-server-cloudimg-amd64.img"

# Configuration template
readonly TEMPLATE_NAME="ubuntu-cloud-template"
readonly TEMPLATE_DESCRIPTION="Ubuntu ${UBUNTU_VERSION} LTS Cloud-Init Template"
readonly TEMPLATE_MEMORY=1024
readonly TEMPLATE_CORES=1
readonly TEMPLATE_SOCKETS=1
readonly TEMPLATE_DISK_SIZE="10G"

# ============================================================================
# FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

check_ssh_connection() {
    log_info "Vérification de la connexion SSH vers ${PROXMOX_NODE}..."
    if ! ssh -o ConnectTimeout=5 "root@${PROXMOX_NODE}" "exit" 2>/dev/null; then
        log_error "Impossible de se connecter à ${PROXMOX_NODE} via SSH"
        log_info "Assurez-vous que:"
        log_info "  1. SSH est configuré: ssh root@${PROXMOX_NODE}"
        log_info "  2. Votre clé SSH est autorisée sur le node"
        exit 1
    fi
    log_success "Connexion SSH OK"
}

check_template_exists() {
    log_info "Vérification si le template ${TEMPLATE_ID} existe déjà..."
    if ssh "root@${PROXMOX_NODE}" "qm status ${TEMPLATE_ID}" 2>/dev/null; then
        log_warning "Le template ${TEMPLATE_ID} existe déjà sur ${PROXMOX_NODE}"
        read -p "Voulez-vous le supprimer et recréer? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Suppression du template existant..."
            ssh "root@${PROXMOX_NODE}" "qm destroy ${TEMPLATE_ID}"
            log_success "Template supprimé"
        else
            log_info "Annulation. Utilisez un autre VMID ou supprimez manuellement le template."
            exit 0
        fi
    fi
}

download_image() {
    log_info "Téléchargement de l'image Ubuntu ${UBUNTU_VERSION} Cloud..."
    log_info "URL: ${IMAGE_URL}"

    # Télécharger sur le node Proxmox directement
    ssh "root@${PROXMOX_NODE}" bash <<EOF
        set -euo pipefail
        cd /tmp

        # Supprimer l'ancienne image si elle existe
        rm -f "${IMAGE_FILE}"

        # Télécharger avec wget (avec progression)
        wget -q --show-progress "${IMAGE_URL}" -O "${IMAGE_FILE}"

        if [ ! -f "${IMAGE_FILE}" ]; then
            echo "Erreur: Téléchargement échoué"
            exit 1
        fi

        # Vérifier la taille (doit être > 500MB)
        FILE_SIZE=\$(stat -f%z "${IMAGE_FILE}" 2>/dev/null || stat -c%s "${IMAGE_FILE}")
        if [ "\${FILE_SIZE}" -lt 500000000 ]; then
            echo "Erreur: Fichier trop petit (\${FILE_SIZE} bytes), téléchargement probablement corrompu"
            exit 1
        fi

        echo "Téléchargement terminé: \${FILE_SIZE} bytes"
EOF

    log_success "Image téléchargée"
}

create_template() {
    log_info "Création du template ${TEMPLATE_ID} sur ${PROXMOX_NODE}..."

    ssh "root@${PROXMOX_NODE}" bash <<EOF
        set -euo pipefail

        # Créer la VM
        qm create ${TEMPLATE_ID} \
            --name "${TEMPLATE_NAME}" \
            --description "${TEMPLATE_DESCRIPTION}" \
            --memory ${TEMPLATE_MEMORY} \
            --cores ${TEMPLATE_CORES} \
            --sockets ${TEMPLATE_SOCKETS} \
            --net0 virtio,bridge=vmbr0 \
            --serial0 socket \
            --vga serial0 \
            --agent enabled=1 \
            --bios seabios \
            --machine q35 \
            --ostype l26

        # Importer le disque
        qm importdisk ${TEMPLATE_ID} /tmp/${IMAGE_FILE} ${STORAGE}

        # Attacher le disque
        qm set ${TEMPLATE_ID} \
            --scsihw virtio-scsi-pci \
            --scsi0 ${STORAGE}:vm-${TEMPLATE_ID}-disk-0 \
            --boot order=scsi0 \
            --bootdisk scsi0

        # Redimensionner le disque
        qm resize ${TEMPLATE_ID} scsi0 ${TEMPLATE_DISK_SIZE}

        # Ajouter le drive cloud-init
        qm set ${TEMPLATE_ID} --ide2 ${STORAGE}:cloudinit

        # Configuration cloud-init par défaut
        qm set ${TEMPLATE_ID} \
            --citype nocloud \
            --ipconfig0 ip=dhcp

        # Convertir en template
        qm template ${TEMPLATE_ID}

        # Nettoyage
        rm -f /tmp/${IMAGE_FILE}

        echo "Template créé avec succès!"
EOF

    log_success "Template ${TEMPLATE_ID} créé sur ${PROXMOX_NODE}"
}

show_summary() {
    echo ""
    echo "============================================================================"
    log_success "TEMPLATE UBUNTU CLOUD-INIT CRÉÉ AVEC SUCCÈS"
    echo "============================================================================"
    echo ""
    echo "  Node Proxmox : ${PROXMOX_NODE}"
    echo "  Template ID  : ${TEMPLATE_ID}"
    echo "  Nom          : ${TEMPLATE_NAME}"
    echo "  Storage      : ${STORAGE}"
    echo "  Ubuntu       : ${UBUNTU_VERSION} LTS"
    echo ""
    echo "============================================================================"
    echo "UTILISATION DANS TERRAFORM"
    echo "============================================================================"
    echo ""
    echo "  module \"ma_vm\" {"
    echo "    source = \"../modules/vm\""
    echo ""
    echo "    clone      = \"${TEMPLATE_NAME}\""
    echo "    ciuser     = \"admin\""
    echo "    cipassword = \"votre-mot-de-passe\""
    echo "    sshkeys    = \"votre-clé-ssh-publique\""
    echo ""
    echo "    # ... autres paramètres"
    echo "  }"
    echo ""
    echo "============================================================================"
    echo "PROCHAINES ÉTAPES"
    echo "============================================================================"
    echo ""
    echo "  1. Vérifier le template dans Proxmox Web UI"
    echo "  2. Utiliser 'clone = \"${TEMPLATE_NAME}\"' dans vos modules VM"
    echo "  3. Définir ciuser/cipassword/sshkeys pour chaque VM"
    echo "  4. terraform apply"
    echo ""
    log_info "Documentation: docs/CLOUD_INIT_TEMPLATE.md"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo ""
    echo "============================================================================"
    echo "CRÉATION TEMPLATE UBUNTU CLOUD-INIT"
    echo "============================================================================"
    echo ""
    echo "  Node Proxmox : ${PROXMOX_NODE}"
    echo "  Template ID  : ${TEMPLATE_ID}"
    echo "  Storage      : ${STORAGE}"
    echo "  Ubuntu       : ${UBUNTU_VERSION} LTS"
    echo ""

    # Vérifications préalables
    check_ssh_connection
    check_template_exists

    # Création du template
    download_image
    create_template

    # Résumé
    show_summary
}

# Exécution
main "$@"
