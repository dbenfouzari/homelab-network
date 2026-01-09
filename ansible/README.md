# Ansible - Gestion de Configuration Homelab

Documentation pour la gestion de configuration avec Ansible.

## Table des matières

- [Structure](#structure)
- [Inventory](#inventory)
- [Playbooks](#playbooks)
- [Commandes utiles](#commandes-utiles)
- [Dépannage](#dépannage)

## Structure

```
ansible/
├── inventory.yml              # Inventaire des hosts
├── playbooks/                 # Playbooks Ansible
│   └── proxmox-network-setup.yml
└── README.md                  # Ce fichier
```

## Inventory

L'inventaire définit tous les équipements gérés par Ansible.

**Fichier** : `inventory.yml`

**Groupes** :
- `proxmox_nodes` : Les 3 nodes du cluster Proxmox

**Variables importantes** :
- `ansible_ssh_pass` : Mot de passe SSH (depuis `.env`)
- `primary_interface` : Interface physique principale (eno1)
- `secondary_interface` : Interface USB Ethernet (enx...)
- `vlan_bridge` : Nom du bridge VLAN-aware (vmbr1)

## Playbooks

### proxmox-network-setup.yml

Configure les bridges réseau sur les nodes Proxmox pour supporter les VLANs.

**Ce qu'il fait** :
- Backup de `/etc/network/interfaces`
- Configure `vmbr1` en mode VLAN-aware
- Vérifie la configuration post-modification
- **Ne touche PAS à vmbr0** (pas de risque de perte de connexion)

**Usage simple** :
```bash
make setup-proxmox
```

**Usage avancé** :

#### Dry-run (voir ce qui serait modifié sans l'appliquer)
```bash
source scripts/load-env.sh && \
ansible-playbook -i inventory.yml playbooks/proxmox-network-setup.yml --check
```

#### Dry-run avec diff (voir les changements ligne par ligne)
```bash
source scripts/load-env.sh && \
ansible-playbook -i inventory.yml playbooks/proxmox-network-setup.yml --check --diff
```

#### Mode verbose (debug)
```bash
source scripts/load-env.sh && \
ansible-playbook -i inventory.yml playbooks/proxmox-network-setup.yml -vvv
```

#### Exécuter sur un seul node
```bash
source scripts/load-env.sh && \
ansible-playbook -i inventory.yml playbooks/proxmox-network-setup.yml --limit pve-host-1
```

#### Exécuter seulement certaines tasks (tags)
```bash
# Seulement le backup
source scripts/load-env.sh && \
ansible-playbook -i inventory.yml playbooks/proxmox-network-setup.yml --tags backup

# Seulement la configuration
source scripts/load-env.sh && \
ansible-playbook -i inventory.yml playbooks/proxmox-network-setup.yml --tags configure

# Seulement la vérification
source scripts/load-env.sh && \
ansible-playbook -i inventory.yml playbooks/proxmox-network-setup.yml --tags verify
```

#### Forcer le handler (redémarrer le réseau)
```bash
source scripts/load-env.sh && \
ansible-playbook -i inventory.yml playbooks/proxmox-network-setup.yml --tags configure,never
```

**⚠️ Attention** : Le handler `Reload networking` a le tag `never`, il ne s'exécute jamais automatiquement. Pour redémarrer le réseau, vous devez soit :
- Utiliser `--tags never` pour forcer les handlers
- Redémarrer manuellement : `ssh root@IP 'systemctl restart networking'`
- Rebooter les nodes : `ssh root@IP 'reboot'`

## Commandes utiles

### Test de connectivité
```bash
# Tester tous les nodes
make ansible-test

# Tester un node spécifique
source scripts/load-env.sh && \
ansible pve-host-1 -i inventory.yml -m ping
```

### Afficher l'inventory
```bash
# Format YAML (lisible)
make ansible-inventory

# Format JSON (pour scripts)
ansible-inventory -i inventory.yml --list
```

### Exécuter une commande ad-hoc
```bash
# Afficher l'uptime de tous les nodes
source scripts/load-env.sh && \
ansible proxmox_nodes -i inventory.yml -a "uptime"

# Vérifier la version de Proxmox
source scripts/load-env.sh && \
ansible proxmox_nodes -i inventory.yml -a "pveversion"

# Afficher la config réseau actuelle
source scripts/load-env.sh && \
ansible proxmox_nodes -i inventory.yml -a "cat /etc/network/interfaces"
```

### Vérifier les bridges
```bash
# Afficher les bridges configurés
source scripts/load-env.sh && \
ansible proxmox_nodes -i inventory.yml -a "brctl show"

# Vérifier si vmbr1 est VLAN-aware
source scripts/load-env.sh && \
ansible proxmox_nodes -i inventory.yml -a "grep -A 5 'vmbr1' /etc/network/interfaces"
```

## Dépannage

### Erreur : "Authentication failed"

**Problème** : Les mots de passe dans `.env` ne sont pas corrects ou les variables d'environnement ne sont pas chargées.

**Solution** :
```bash
# Vérifier que les variables sont définies
source scripts/load-env.sh
echo $PVE_HOST_1_PASSWORD

# Tester la connexion SSH manuelle
ssh root@192.168.2.101
```

### Erreur : "Host unreachable"

**Problème** : Le node n'est pas accessible sur le réseau.

**Solution** :
```bash
# Vérifier la connectivité réseau
ping 192.168.2.101

# Vérifier que SSH écoute
nc -zv 192.168.2.101 22
```

### Le playbook ne fait rien (toutes les tasks sont "ok")

**Cause** : La configuration est déjà appliquée (idempotence d'Ansible).

**Solution** : C'est normal ! Ansible ne refait pas les changements s'ils sont déjà appliqués.

### Restaurer un backup

Si la configuration réseau pose problème, restaurez le backup :

```bash
# Se connecter au node
ssh root@192.168.2.101

# Lister les backups disponibles
ls -la /etc/network/interfaces.backup.*

# Restaurer le backup
cp /etc/network/interfaces.backup.1736435678 /etc/network/interfaces

# Redémarrer le réseau
systemctl restart networking

# Ou rebooter
reboot
```

### Terminal VSCode qui crash

**Problème** : Bug connu de VSCode avec les erreurs Ansible/Make.

**Solution** : Utilise un terminal externe (Terminal.app, iTerm2) pour les commandes qui peuvent échouer.

## Variables d'environnement requises

Les variables suivantes doivent être définies dans `.env` :

```bash
PVE_HOST_1_PASSWORD="password_node1"
PVE_HOST_2_PASSWORD="password_node2"
PVE_HOST_3_PASSWORD="password_node3"
```

Ces variables sont automatiquement chargées par `scripts/load-env.sh` quand tu utilises `make`.
