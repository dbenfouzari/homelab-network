# Template Ubuntu Cloud-Init pour Proxmox

Ce guide explique comment créer et utiliser un template Ubuntu avec cloud-init sur Proxmox pour déployer rapidement des VMs via Terraform.

## Qu'est-ce que Cloud-Init ?

Cloud-init est un outil standard de l'industrie pour initialiser des instances cloud. Il permet de :

- **Configurer automatiquement** : utilisateurs, mots de passe, clés SSH
- **Personnaliser le réseau** : IP statique, DHCP, DNS
- **Exécuter des scripts** : au premier démarrage
- **Installer des packages** : directement lors du provisioning

## Avantages du template cloud-init

### Sans template (méthode traditionnelle)
```
Déployer VM → Installer OS manuellement (15-20 min)
  → Configurer réseau → Créer utilisateur → Installer packages
  → Total : ~30 minutes par VM
```

### Avec template cloud-init
```
Terraform apply → VM prête en 10-15 secondes ✨
```

### Bénéfices
- ⚡ **Déploiement ultra-rapide** : 10-15 secondes vs 30 minutes
- 🤖 **Automatisation complète** : zéro interaction manuelle
- 🔄 **Reproductible** : configuration identique à chaque fois
- 🧪 **Idéal pour dev/test** : créer/détruire des VMs facilement
- 📦 **Standardisé** : même base pour toutes vos VMs

## Création du template

### Étape 1 : Exécuter le script

```bash
# Depuis la racine du projet
cd /Users/dbenfouzari/Workspace/homelab/homelab-iac

# Rendre le script exécutable
chmod +x scripts/create-ubuntu-template.sh

# Créer le template sur pve-host-1
./scripts/create-ubuntu-template.sh

# Ou avec des paramètres personnalisés
./scripts/create-ubuntu-template.sh pve-host-1 9000 local-lvm
```

### Paramètres du script

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| node | Nom du node Proxmox | `pve-host-1` |
| template-id | VMID du template | `9000` |
| storage | Storage Proxmox | `local-lvm` |

### Ce que fait le script

1. ✅ Vérifie la connexion SSH vers Proxmox
2. ⬇️ Télécharge Ubuntu 24.04 LTS Cloud Image (~700MB)
3. 🔧 Crée une VM template avec :
   - QEMU Guest Agent activé
   - Cloud-init configuré
   - Disque virtio SCSI (10GB par défaut, extensible)
   - Network virtio
   - Serial console
4. 🗑️ Nettoie les fichiers temporaires
5. ✨ Template prêt à l'emploi

### Durée d'exécution

- **Première fois** : 2-3 minutes (téléchargement inclus)
- **Recréation** : ~30 secondes

### Troubleshooting création

#### Erreur SSH

```bash
[ERROR] Impossible de se connecter à pve-host-1 via SSH
```

**Solution** : Configurer SSH
```bash
# Tester la connexion
ssh root@pve-host-1

# Si ça ne fonctionne pas, copier votre clé SSH
ssh-copy-id root@pve-host-1
```

#### Template existe déjà

Le script vous demandera si vous voulez le supprimer et recréer. Répondez `y` pour continuer.

#### Téléchargement échoue

Vérifier la connectivité Internet du node Proxmox :
```bash
ssh root@pve-host-1 "ping -c 3 cloud-images.ubuntu.com"
```

## Utilisation dans Terraform

### Configuration minimale

```hcl
module "ma_vm" {
  source = "../modules/vm"

  vmid        = 100
  name        = "test-vm"
  target_node = "pve-host-1"

  # Cloner depuis le template
  clone = "ubuntu-cloud-template"

  # Configuration cloud-init
  ciuser     = "admin"
  cipassword = "MonMotDePasse123!"

  # Autres paramètres...
  cores  = 2
  memory = 2048
}
```

### Configuration avec clé SSH

```hcl
module "ma_vm" {
  source = "../modules/vm"

  vmid  = 100
  name  = "test-vm"
  clone = "ubuntu-cloud-template"

  # Utilisateur avec clé SSH (recommandé)
  ciuser   = "admin"
  sshkeys  = file("~/.ssh/id_rsa.pub")

  # Optionnel: mot de passe de fallback
  cipassword = "BackupPassword123!"
}
```

### Configuration réseau statique

```hcl
module "ma_vm" {
  source = "../modules/vm"

  vmid  = 100
  name  = "test-vm"
  clone = "ubuntu-cloud-template"

  ciuser     = "admin"
  cipassword = "MotDePasse123!"

  # IP statique
  ipconfig = [
    "ip=10.0.0.50/24,gw=10.0.0.1"
  ]
}
```

### Configuration multi-réseau

```hcl
module "ma_vm" {
  source = "../modules/vm"

  vmid  = 100
  name  = "test-vm"
  clone = "ubuntu-cloud-template"

  ciuser     = "admin"
  cipassword = "MotDePasse123!"

  # Plusieurs interfaces réseau
  networks = [
    {
      model  = "virtio"
      bridge = "vmbr0"
      tag    = null
    },
    {
      model  = "virtio"
      bridge = "vmbr1"
      tag    = 10  # VLAN 10
    }
  ]

  ipconfig = [
    "ip=dhcp",                      # Interface 0 en DHCP
    "ip=10.10.0.50/24,gw=10.10.0.1" # Interface 1 statique
  ]
}
```

## Connexion à la VM

### Après le déploiement

1. **Attendre le boot** (~10-15 secondes)
2. **Se connecter** :

```bash
# Via SSH (si clé configurée)
ssh admin@<IP_DE_LA_VM>

# Ou avec mot de passe
ssh admin@<IP_DE_LA_VM>
# Password: celui défini dans cipassword
```

### Obtenir l'IP de la VM

#### Méthode 1 : Console Proxmox

1. Ouvrir la console noVNC de la VM
2. Login avec `admin` / mot de passe
3. Exécuter : `ip addr show`

#### Méthode 2 : QEMU Guest Agent

```bash
# Depuis votre poste
ssh root@pve-host-1 "qm guest cmd <VMID> network-get-interfaces" | jq
```

#### Méthode 3 : Output Terraform (si configuré)

```hcl
output "vm_ip" {
  value = module.ma_vm.default_ipv4_address
}
```

## Personnalisation avancée

### Scripts au démarrage

```hcl
module "ma_vm" {
  source = "../modules/vm"

  # ... config de base ...

  # Script à exécuter au premier boot
  cicustom = "user=local:snippets/mon-script.yml"
}
```

Créer `/var/lib/vz/snippets/mon-script.yml` sur Proxmox :
```yaml
#cloud-config
packages:
  - docker.io
  - git
  - htop

runcmd:
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker admin
```

### Installer des packages automatiquement

Via Terraform :
```hcl
# Note: Nécessite de créer un snippet cloud-config sur Proxmox
# Pas supporté directement par le provider Terraform Proxmox v3
```

Ou via Ansible après le déploiement (recommandé).

## Maintenance du template

### Mettre à jour le template

Ubuntu Cloud Images sont mis à jour régulièrement. Pour obtenir la dernière version :

```bash
# Recréer le template (il supprimera l'ancien)
./scripts/create-ubuntu-template.sh
```

**Fréquence recommandée** : Tous les 2-3 mois

### Créer plusieurs templates

Vous pouvez créer différents templates pour différents usages :

```bash
# Template standard
./scripts/create-ubuntu-template.sh pve-host-1 9000 local-lvm

# Template avec plus de ressources (si vous modifiez le script)
./scripts/create-ubuntu-template.sh pve-host-1 9001 local-lvm

# Template Ubuntu 22.04 (si vous modifiez la version dans le script)
./scripts/create-ubuntu-template.sh pve-host-1 9002 local-lvm
```

### Supprimer le template

```bash
ssh root@pve-host-1 "qm destroy 9000"
```

Ou via l'interface web Proxmox.

## Exemples d'utilisation

### VM temporaire pour admin OPNsense

Voir [temp-admin-vm.tf](../terraform/core/temp-admin-vm.tf)

```bash
cd terraform/core
terraform apply -target=module.temp_admin

# Après usage
terraform destroy -target=module.temp_admin
```

### VM de développement

```hcl
module "dev_vm" {
  source = "../modules/vm"

  vmid        = 101
  name        = "dev-workstation"
  target_node = "pve-host-1"

  clone = "ubuntu-cloud-template"

  cores  = 4
  memory = 8192

  ciuser   = "dev"
  sshkeys  = file("~/.ssh/id_rsa.pub")

  disk = {
    storage = "local-lvm"
    size    = "50G"  # Plus d'espace pour le dev
  }
}
```

### VM de test éphémère

```hcl
module "test_vm" {
  source = "../modules/vm"

  vmid        = 999
  name        = "test-temp"
  target_node = "pve-host-1"

  clone = "ubuntu-cloud-template"

  cores  = 1
  memory = 1024

  ciuser     = "test"
  cipassword = "test123"

  protection = false  # Facile à supprimer
}
```

Déployer et détruire :
```bash
terraform apply -target=module.test_vm
# Faire des tests...
terraform destroy -target=module.test_vm
```

## Comparaison avec d'autres méthodes

| Méthode | Temps | Automatisation | Complexité |
|---------|-------|----------------|------------|
| **Cloud-Init Template** | 15s | ✅ Totale | ⭐ Simple |
| ISO + Installation manuelle | 30min | ❌ Manuelle | ⭐⭐⭐ Complexe |
| Packer + Ansible | 20min | ✅ Totale | ⭐⭐⭐⭐ Très complexe |
| Container (LXC) | 5s | ✅ Totale | ⭐⭐ Moyenne |

**Recommandation** : Cloud-Init template pour un équilibre parfait entre simplicité et puissance.

## Références

- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Proxmox Cloud-Init Support](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

## FAQ

### Le template fonctionne-t-il sur tous les nodes Proxmox ?

Non, le template est créé sur un node spécifique (par défaut `pve-host-1`). Pour l'utiliser sur d'autres nodes :
- **Option 1** : Recréer le template sur chaque node
- **Option 2** : Utiliser un storage partagé (NFS, Ceph) pour le template

### Puis-je utiliser Debian au lieu d'Ubuntu ?

Oui ! Modifiez le script pour utiliser les Debian Cloud Images :
```bash
IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
```

### Le mot de passe cloud-init est-il sécurisé ?

Pour la production, utilisez :
1. **Clés SSH uniquement** (pas de cipassword)
2. **Secrets manager** pour stocker les mots de passe
3. **Ansible** pour la configuration post-déploiement

### Combien d'espace disque prend le template ?

~2GB sur le storage Proxmox. Les VMs clonées utilisent du thin-provisioning (espace utilisé réel, pas réservé).

### Puis-je customiser l'image cloud avant de créer le template ?

Oui, avec des outils comme Packer, mais c'est plus complexe. Le template par défaut convient pour 90% des cas.
