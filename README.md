# Homelab Infrastructure as Code

Infrastructure as Code (IaC) pour mon homelab personnel avec Terraform et Ansible.

## Vue d'ensemble

Ce repository gère l'infrastructure complète du homelab:

- **Terraform**: Provisionnement de l'infrastructure Proxmox (VMs, LXCs)
- **Ansible**: Configuration des services et applications
- **Git**: Versionnement et traçabilité des changements

### Architecture

```
Proxmox Cluster (3 nodes)
├── pve-host-1 (192.168.2.101) - Infrastructure critique
│   └── OPNsense VM (192.168.2.254) - Firewall/Router/VPN
├── pve-host-2 (192.168.2.102) - Services réseau & apps
│   ├── AdGuard Home LXC (192.168.10.2)
│   ├── n8n LXC (192.168.10.10)
│   └── Dolibarr LXC (192.168.10.11)
└── pve-host-3 (192.168.2.103) - Services média
    ├── Immich LXC (192.168.10.12)
    ├── Plex LXC (192.168.10.20)
    ├── Radarr LXC (192.168.10.21)
    └── Sonarr LXC (192.168.10.22)
```

### VLANs

- **VLAN 1 (legacy)**: 192.168.2.0/24 - Réseau transitoire actuel
- **VLAN 10 (MGMT)**: 192.168.10.0/24 - Infrastructure & Management
- **VLAN 20 (IOT)**: 192.168.20.0/24 - Objets connectés
- **VLAN 30 (GUEST)**: 192.168.30.0/24 - Invités
- **VLAN 40 (HOME)**: 192.168.40.0/24 - Famille

## Prérequis

### Logiciels requis

- Terraform >= 1.5.0
- Ansible >= 2.14
- Python 3.x
- Make (optionnel mais recommandé)

```bash
# macOS
brew install terraform ansible python3 make

# Linux (Debian/Ubuntu)
apt install terraform ansible python3 make
```

### Configuration Proxmox

1. Créer un utilisateur API ou utiliser root@pam
2. Activer l'API REST sur chaque node (port 8006)
3. Accepter les certificats auto-signés

### Variables d'environnement

Configurer les mots de passe Proxmox:

```bash
# Option 1: Variable d'environnement (recommandé)
export TF_VAR_proxmox_passwords='{"pve1":"password1","pve2":"password2","pve3":"password3"}'

# Option 2: Fichier terraform.tfvars (à ne PAS commit)
cat > terraform/core/terraform.tfvars <<EOF
proxmox_passwords = {
  pve1 = "password_node_1"
  pve2 = "password_node_2"
  pve3 = "password_node_3"
}
EOF
```

## Démarrage rapide

### 1. Initialisation

```bash
# Cloner le repo
git clone <repo-url> homelab-iac
cd homelab-iac

# Initialiser Terraform
make init

# Valider la configuration
make validate
```

### 2. Déployer OPNsense (première étape critique)

```bash
# 1. Uploader l'ISO OPNsense sur Proxmox
#    Télécharger depuis: https://opnsense.org/download/
#    Uploader via Proxmox Web UI: Datacenter → Storage → local → ISO Images

# 2. Configurer le chemin ISO dans terraform/core/main.tf
#    Décommenter et ajuster: iso = "local:iso/OPNsense-24.7-dvd-amd64.iso"

# 3. Planifier
make plan

# 4. Déployer
make deploy-opnsense

# 5. Configurer OPNsense via console Proxmox
#    Suivre: ~/Workspace/network/docs/migration-logs/phase-1-vpn/
```

### 3. Déployer les services avec Ansible

```bash
# Vérifier la syntaxe
make ansible-check

# Tester la connectivité
make ansible-ping

# Déployer tout
make ansible-deploy

# Ou déployer par phase
make ansible-deploy-critical  # Infrastructure critique
make ansible-deploy-dns       # AdGuard Home
make ansible-deploy-apps      # Services applicatifs
make ansible-deploy-media     # Services média
```

## Commandes Make

Exécuter `make help` pour voir toutes les commandes disponibles.

### Setup
- `make init` - Initialiser Terraform
- `make check-passwords` - Vérifier les variables d'environnement

### Terraform
- `make plan` - Planifier les changements
- `make apply` - Appliquer les changements
- `make destroy` - Détruire l'infrastructure (DANGER)
- `make show` - Afficher l'état actuel
- `make output` - Afficher les outputs

### Ansible
- `make ansible-check` - Vérifier la syntaxe
- `make ansible-inventory` - Afficher l'inventaire
- `make ansible-ping` - Tester la connectivité
- `make ansible-deploy` - Déployer tous les services
- `make ansible-deploy-{dns,apps,media}` - Déployer par catégorie

### Workflows
- `make deploy-opnsense` - Workflow complet OPNsense
- `make deploy-all` - Déployer infrastructure + services

### Maintenance
- `make clean` - Nettoyer les fichiers temporaires
- `make fmt` - Formater le code Terraform
- `make validate` - Valider la configuration
- `make backup` - Sauvegarder l'état Terraform

## Structure du repository

```
homelab-iac/
├── terraform/
│   ├── core/              # Infrastructure principale
│   │   ├── providers.tf   # Providers Proxmox (3 nodes)
│   │   ├── variables.tf   # Variables globales
│   │   ├── main.tf        # OPNsense et infrastructure critique
│   │   └── outputs.tf     # Outputs Terraform
│   ├── apps/              # Services applicatifs (n8n, Dolibarr, etc.)
│   ├── media/             # Services média (Plex, Radarr, Sonarr)
│   └── modules/
│       ├── vm/            # Module VM réutilisable
│       └── lxc/           # Module LXC réutilisable
├── ansible/
│   ├── inventory/
│   │   └── production.yml # Inventaire complet
│   ├── playbooks/
│   │   └── site.yml       # Playbook principal
│   └── roles/             # Rôles Ansible par service
├── scripts/
│   ├── backup/            # Scripts de sauvegarde
│   ├── deploy/            # Scripts de déploiement
│   └── maintenance/       # Scripts de maintenance
├── docs/                  # Documentation
│   ├── SETUP.md          # Guide de setup détaillé
│   ├── MIGRATION.md      # Plan de migration VLAN
│   └── TROUBLESHOOTING.md
├── Makefile              # Commandes Make
├── README.md             # Ce fichier
└── .gitignore
```

## Ordre de déploiement recommandé

### Phase 1: Infrastructure critique (FAIT)
1. ✅ OPNsense - Firewall/Router/VPN
   - Créer la VM avec Terraform
   - Installer depuis ISO via console Proxmox
   - Configurer via Web UI (https://192.168.2.254)
   - Installer plugin WireGuard
   - Configurer VPN

### Phase 2: Services réseau
2. AdGuard Home - DNS filtré
   - Déployer avec `make ansible-deploy-dns`
   - Configurer les zones DNS par VLAN

### Phase 3: Migration VLAN (À PLANIFIER)
- Migrer progressivement du VLAN 1 vers VLANs segmentés
- Documenter chaque étape

### Phase 4: Services applicatifs
3. n8n - Workflows et automatisations
4. Dolibarr - ERP/CRM
5. Immich - Gestion de photos

### Phase 5: Services média
6. Plex - Serveur média
7. Radarr - Gestion films
8. Sonarr - Gestion séries

## Documentation

- [Guide de setup complet](docs/SETUP.md)
- [Plan de migration VLAN](docs/MIGRATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Architecture réseau](docs/architecture/network-topology.md)
- [Procédure de backup/restore](docs/procedures/backup-restore.md)

Documentation réseau complète: `~/Workspace/network/docs/`

## Sécurité

### Secrets et mots de passe

- **NE JAMAIS** committer de mots de passe en clair
- Utiliser des variables d'environnement ou Terraform Cloud
- Le fichier `terraform.tfvars` est dans `.gitignore`

### Fichiers sensibles à exclure

```
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
ansible/vault_pass.txt
```

## Sauvegarde et restauration

### Sauvegarder l'état Terraform

```bash
make backup
```

### Sauvegarder les services

```bash
./scripts/backup/backup-all.sh
```

Les backups sont stockés dans `backups/` (gitignore).

## Contribution

Pour modifier l'infrastructure:

1. Créer une branche: `git checkout -b feature/nouvelle-vm`
2. Modifier les fichiers Terraform/Ansible
3. Tester: `make plan` et `make ansible-check`
4. Commit: `git commit -m "Add: nouvelle VM pour service X"`
5. Push et créer une PR

## Dépannage

### Erreur de connexion Proxmox

```bash
# Vérifier la connectivité
curl -k https://192.168.2.101:8006/api2/json/version

# Vérifier les credentials
make check-passwords
```

### Ansible ne peut pas se connecter

```bash
# Tester manuellement
ssh root@192.168.10.2

# Vérifier l'inventaire
make ansible-inventory

# Ping tous les hosts
make ansible-ping
```

### Plus d'aide

- [Guide de troubleshooting](docs/TROUBLESHOOTING.md)
- Issues GitHub: [Lien à configurer]

## Licence

Privé - Usage personnel uniquement

## Auteur

Donovan Ben Fouzari
