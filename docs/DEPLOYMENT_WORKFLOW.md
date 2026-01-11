# Workflow de déploiement du homelab

Ce document explique comment déployer l'infrastructure complète from scratch.

## Vue d'ensemble

Le homelab est géré avec une approche Infrastructure as Code :
- **Terraform** : Provisionning des VMs sur Proxmox
- **Ansible** : Configuration des services et applications
- **Secrets** : Gérés via `.env` et chargés avec `scripts/load-env.sh`

## Déploiement from scratch

### Prérequis

1. **Cluster Proxmox** configuré et accessible
2. **SSH** configuré vers les nodes Proxmox
3. **Terraform** installé localement
4. **Ansible** installé localement
5. **Fichier .env** configuré avec les secrets

### Étape 1 : Configuration initiale

```bash
# Cloner le repo
git clone <repo-url>
cd homelab-iac

# Copier le template .env et le configurer
cp .env.example .env
vim .env

# Charger les variables
source scripts/load-env.sh
```

### Étape 2 : Configuration réseau Proxmox

```bash
# Configurer les bridges VLAN-aware sur les nodes
cd ansible
ansible-playbook playbooks/proxmox-network.yml
```

Résultat :
- `vmbr0` : Bridge management (192.168.2.0/24)
- `vmbr1` : Bridge VLAN-aware pour réseau interne

### Étape 3 : Créer le template Ubuntu cloud-init

```bash
# Créer le template sur pve-host-1
./scripts/create-ubuntu-template.sh 192.168.2.101 9000 local-lvm
```

Résultat :
- Template VMID 9000 `ubuntu-cloud-template` disponible pour clonage

### Étape 4 : Déployer OPNsense (optionnel)

> **Note** : Si vous avez déjà OPNsense en production, passez cette étape.

```bash
cd terraform/core

# Déployer la VM OPNsense
terraform init
terraform apply -target=module.opnsense

# Installer manuellement via la console Proxmox (voir docs/OPNSENSE_INSTALLATION.md)
```

Résultat :
- VM 200 OPNsense avec WAN sur vmbr0 et LAN sur vmbr1

### Étape 5 : Déployer les services

```bash
# Déployer toute l'infrastructure core
cd terraform/core
terraform apply

# Configurer les services via Ansible
cd ../../ansible
ansible-playbook playbooks/configure-all.yml
```

## Structure du projet

```
homelab-iac/
├── terraform/
│   ├── core/              # Infrastructure core (OPNsense, etc.)
│   │   └── opnsense.tf    # VM OPNsense
│   ├── modules/
│   │   └── vm/            # Module VM réutilisable
│   └── services/          # Services applicatifs (Immich, N8N, etc.)
├── ansible/
│   ├── inventory/         # Inventaire des hosts
│   ├── playbooks/         # Playbooks de configuration
│   └── roles/             # Rôles Ansible
├── scripts/
│   ├── create-ubuntu-template.sh  # Création template cloud-init
│   └── load-env.sh                # Chargement variables .env
└── docs/
    ├── OPNSENSE_INSTALLATION.md   # Guide installation OPNsense
    ├── CLOUD_INIT_TEMPLATE.md     # Guide template cloud-init
    └── DEPLOYMENT_WORKFLOW.md     # Ce fichier
```

## Maintenance

### Backup

```bash
# Backup complet
make backup-all

# Backup d'un service spécifique
make backup-immich
```

### Updates

```bash
# Mettre à jour tous les services
make update-all

# Mettre à jour un service spécifique
ansible-playbook playbooks/update-immich.yml
```

### Health checks

```bash
# Vérifier l'état de tous les services
make health-check
```

## Disaster recovery

### Scénario 1 : Recréer une VM

```bash
# Détruire et recréer une VM spécifique
cd terraform/core
terraform destroy -target=module.opnsense
terraform apply -target=module.opnsense

# Reconfigurer via Ansible
cd ../../ansible
ansible-playbook playbooks/configure-opnsense.yml
```

### Scénario 2 : Recréer tout le cluster

1. Réinstaller Proxmox sur les nodes
2. Suivre le workflow complet depuis l'étape 1
3. Restaurer les backups des services

## Troubleshooting

### Template cloud-init ne fonctionne pas

Voir [docs/CLOUD_INIT_TEMPLATE.md](CLOUD_INIT_TEMPLATE.md#troubleshooting)

### OPNsense n'est pas accessible

Voir [docs/OPNSENSE_INSTALLATION.md](OPNSENSE_INSTALLATION.md#troubleshooting)

### Problèmes Terraform

```bash
# Rafraîchir l'état
terraform refresh

# Réimporter une ressource
terraform import module.opnsense.proxmox_vm_qemu.vm pve-host-1/qemu/200
```

## Références

- [Terraform Proxmox Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [OPNsense Documentation](https://docs.opnsense.org/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
