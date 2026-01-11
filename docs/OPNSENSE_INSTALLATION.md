# Guide d'installation OPNsense

Ce guide vous accompagne dans l'installation et la configuration initiale d'OPNsense sur votre homelab.

> **Note** : Ce guide est fourni pour référence et reproductibilité. Si vous avez déjà OPNsense en production, ce guide vous permet de recréer l'infrastructure from scratch si nécessaire.

## Prérequis

- VM OPNsense créée via Terraform (VMID 200)
- Accès à l'interface web Proxmox de pve-host-1
- ISO OPNsense 25.7 montée sur la VM

## Architecture réseau cible

```
Internet
   ↓
Livebox (192.168.2.1)
   ↓
[vmbr0] ← WAN (net0)
   ↓
OPNsense VM (VMID 200)
   ↓
[vmbr1] ← LAN (net1) - VLAN-aware bridge
   ↓
Réseau interne segmenté (VLANs)
```

## Étape 1 : Démarrer la VM et lancer l'installation

1. **Ouvrir Proxmox Web UI** : https://192.168.2.10:8006
2. **Sélectionner** : pve-host-1 → VM 200 (opnsense)
3. **Démarrer la VM** : Bouton "Start"
4. **Ouvrir la console** : Bouton "Console" (noVNC)

### Installation OPNsense

5. **Attendre le boot** sur l'ISO OPNsense
6. **Login** : root / opnsense
7. **Lancer l'installer** : Taper `8` (Shell) puis `opnsense-importer`
   - Ou sélectionner directement l'option d'installation si proposée

8. **Suivre le wizard d'installation** :
   - Keymap : `French` ou `US` selon votre clavier
   - Install : `Install (UFS)`
   - Disk : Sélectionner le disque virtuel (16GB)
   - Confirm : `Yes`
   - Root password : **Définir un mot de passe fort** (à sauvegarder)

9. **Fin d'installation** :
   - Complete Installation : `Reboot`
   - La VM va redémarrer

10. **Éjecter l'ISO** (optionnel mais recommandé) :
    - Dans Proxmox : Hardware → CD/DVD Drive → "Do not use any media"
    - Ou laisser, le boot order privilégie le disque

## Étape 2 : Configuration initiale des interfaces

Après le reboot, OPNsense démarre sur le système installé.

### Assignation des interfaces

Au premier démarrage, OPNsense vous demande d'assigner les interfaces :

```
Valid interfaces are:
vtnet0  <MAC_ADDRESS>  (up)
vtnet1  <MAC_ADDRESS>  (up)

Do you want to configure LAGGs now? [y/N]: N
Do you want to configure VLANs now? [y/N]: N
```

**Répondre :**
- LAGGs : `N`
- VLANs : `N` (on les configurera via Web UI)

**Assigner les interfaces :**
```
Enter the WAN interface name: vtnet0
Enter the LAN interface name: vtnet1
```

**Confirmer** : `y`

### Configuration IP du LAN

OPNsense va vous demander l'IP du LAN :

```
Enter the new LAN IPv4 address: 10.0.0.1
Enter the new LAN IPv4 subnet bit count: 24
```

**Recommandation réseau LAN :**
- IP LAN : `10.0.0.1/24` (réseau management homelab)
- Ou : `172.16.0.1/24`
- Ou gardez le défaut : `192.168.1.1/24`

**DHCP Server :**
```
Do you want to enable the DHCP server on LAN? [y/N]: y
Enter the start address of the IPv4 client address range: 10.0.0.100
Enter the end address of the IPv4 client address range: 10.0.0.200
```

**IPv6 :** `N` (sauf si vous voulez l'activer)

## Étape 3 : Accéder à l'interface Web

### Option A : Depuis votre PC (si connecté au même réseau)

Si votre PC est sur le réseau 192.168.2.0/24 (même réseau que le WAN) :

1. **Activer l'accès Web sur WAN temporairement** :
   - Dans la console OPNsense : Option `8` (Shell)
   ```bash
   configctl webgui restart
   ```
   - Accéder via : https://192.168.2.??? (IP du WAN)
   - **⚠️ À désactiver après configuration !**

### Option B : Depuis une VM sur vmbr1 (recommandé)

Créer une VM temporaire sur vmbr1 pour accéder au LAN d'OPNsense.

### Option C : Via port forwarding Proxmox (quick & dirty)

1. SSH sur pve-host-1
2. Créer un tunnel :
   ```bash
   ssh -L 8443:10.0.0.1:443 root@pve-host-1
   ```
3. Accéder via : https://localhost:8443

### Première connexion Web UI

1. **URL** : https://10.0.0.1 (ou IP LAN choisie)
2. **Login** : root
3. **Password** : celui défini lors de l'installation
4. **Accepter le certificat auto-signé**

## Étape 4 : Configuration initiale via Web UI

### Wizard de configuration

OPNsense lance un wizard au premier accès :

1. **General Information**
   - Hostname : `opnsense`
   - Domain : `homelab.local` (ou votre domaine)
   - Primary DNS : `1.1.1.1` (Cloudflare)
   - Secondary DNS : `8.8.8.8` (Google)

2. **Time Server Information**
   - Timezone : `Europe/Paris`
   - NTP Server : `pool.ntp.org`

3. **Configure WAN Interface**
   - Type : `DHCP` (si Livebox donne une IP)
   - Ou `Static` si vous voulez fixer : `192.168.2.200/24` gateway `192.168.2.1`

4. **Configure LAN Interface**
   - Déjà configuré, valider

5. **Set Root Password**
   - Confirmer le mot de passe

6. **Reload** : Cliquer sur "Reload"

## Étape 5 : Sécurisation et configuration avancée

### Désactiver l'accès Web sur WAN

⚠️ **Important pour la sécurité** :

1. **System → Settings → Administration**
2. **Listen Interfaces** : Sélectionner uniquement `LAN`
3. **Save**

### Créer un utilisateur admin non-root

1. **System → Access → Users**
2. **Add User** :
   - Username : `admin`
   - Password : mot de passe fort
   - Full name : `Administrator`
   - Group membership : `admins`
3. **Save**

### Configurer le firewall de base

1. **Firewall → Rules → LAN**
2. Par défaut, tout le trafic LAN est autorisé (règle par défaut)
3. Ajouter des règles selon vos besoins

### Activer le QEMU Guest Agent (optionnel)

```bash
# Dans la console OPNsense (option 8 - Shell)
pkg install qemu-guest-agent
service qemu-guest-agent enable
service qemu-guest-agent start
```

Puis dans Terraform, changer `agent = 1` et redémarrer la VM.

## Étape 6 : Configuration VLANs (avancé)

### Créer les VLANs sur l'interface LAN

1. **Interfaces → Other Types → VLAN**
2. **Add** :
   - Parent interface : `vtnet1` (LAN)
   - VLAN tag : `10`
   - Description : `VLAN10_SERVICES`
3. Répéter pour chaque VLAN souhaité

### Assigner les VLANs

1. **Interfaces → Assignments**
2. Ajouter chaque VLAN créé
3. **Save**

### Configurer chaque interface VLAN

1. **Interfaces → [VLAN10]**
2. **Enable** : cocher
3. **IPv4 Configuration Type** : `Static`
4. **IPv4 address** : `10.10.0.1/24`
5. **Save** et **Apply**

### Configurer DHCP par VLAN

1. **Services → DHCPv4 → [VLAN10]**
2. **Enable** : cocher
3. **Range** : `10.10.0.100` à `10.10.0.200`
4. **DNS servers** : `10.10.0.1` (OPNsense)
5. **Save**

## Étape 7 : Tests et validation

### Tester la connectivité

1. **Diagnostics → Ping**
   - Tester : `8.8.8.8`, `google.com`
   - Depuis WAN et LAN

2. **Diagnostics → States → Status**
   - Vérifier que le NAT fonctionne

### Vérifier les services

1. **System → Diagnostics → Services**
   - Tous les services doivent être "running"

### Backup de la configuration

⚠️ **Important** :

1. **System → Configuration → Backups**
2. **Download configuration** : Sauvegarder le fichier XML
3. Stocker dans `/docs/backups/` ou gestionnaire de secrets

## Étape 8 : Finalisation Terraform

Une fois OPNsense installé et configuré :

1. **Mettre à jour** [opnsense.tf](../terraform/core/opnsense.tf) :
   ```hcl
   onboot = true  # Activer le démarrage automatique
   agent  = 1     # Si QEMU agent installé
   ```

2. **Retirer l'ISO** :
   ```hcl
   iso = null  # Plus besoin de l'ISO
   ```

3. **Appliquer** :
   ```bash
   make plan
   make apply
   ```

## Prochaines étapes

- [ ] Configuration Ansible pour automatiser OPNsense
- [ ] Configuration des VLANs réseau
- [ ] Mise en place des règles firewall avancées
- [ ] Configuration VPN (OpenVPN, WireGuard)
- [ ] Monitoring et logging (Unbound DNS, Suricata IDS, etc.)

## Troubleshooting

### La VM ne boot pas

- Vérifier que l'ISO est bien montée
- Vérifier le boot order dans Proxmox
- Console : regarder les logs de boot

### Impossible d'accéder à l'interface Web

- Vérifier l'IP du LAN : `ifconfig` dans la console
- Vérifier le firewall de votre PC
- Essayer depuis une autre VM sur vmbr1

### Pas de connexion Internet sur WAN

- Vérifier que vtnet0 obtient une IP DHCP de la Livebox
- Console option `2` : Set interface IP address → WAN → DHCP
- Diagnostics → Ping → Tester 8.8.8.8

### Performance réseau faible

- Vérifier que `virtio` est utilisé pour les NICs
- Activer hardware offloading : System → Settings → Tunables
  - `net.inet.tcp.tso` = 1
  - `net.inet.tcp.lro` = 1

## Ressources

- [Documentation OPNsense](https://docs.opnsense.org/)
- [Forum OPNsense](https://forum.opnsense.org/)
- [Architecture réseau homelab](./ARCHITECTURE.md)
