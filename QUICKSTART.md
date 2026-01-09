# Guide de démarrage rapide

## 1. Configuration initiale (5 minutes)

### Prérequis
```bash
# Vérifier que vous avez les outils nécessaires
terraform version  # >= 1.5.0
ansible --version  # >= 2.14
make --version
```

### Configuration des mots de passe Proxmox

**Option A: Variables d'environnement (recommandé)**
```bash
export TF_VAR_proxmox_passwords='{"pve1":"votre_pass1","pve2":"votre_pass2","pve3":"votre_pass3"}'

# Ajouter à votre ~/.zshrc ou ~/.bashrc pour persistence
echo 'export TF_VAR_proxmox_passwords='"'"'{"pve1":"votre_pass1","pve2":"votre_pass2","pve3":"votre_pass3"}'"'"'' >> ~/.zshrc
```

**Option B: Fichier terraform.tfvars**
```bash
cd terraform/core
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Éditer avec vos vrais mots de passe
```

### Initialisation
```bash
make init
make validate
```

## 2. Déployer OPNsense (30 minutes)

### Préparer l'ISO
1. Télécharger OPNsense: https://opnsense.org/download/
2. Dans Proxmox Web UI: Datacenter → pve-host-1 → local → ISO Images → Upload
3. Noter le nom: `OPNsense-24.7-dvd-amd64.iso`

### Configurer et déployer
```bash
# Éditer terraform/core/main.tf
vim terraform/core/main.tf
# Ligne ~87: Décommenter et ajuster:
# iso = "local:iso/OPNsense-24.7-dvd-amd64.iso"

# Planifier
make plan

# Déployer
make deploy-opnsense
```

### Configuration OPNsense
1. Ouvrir la console Proxmox de la VM OPNsense (VM ID 100)
2. Suivre l'installation depuis l'ISO
3. Configuration initiale:
   - WAN: vtnet1 (DHCP depuis Livebox)
   - LAN: vtnet0 (192.168.2.254/24)
4. Accéder au Web UI: https://192.168.2.254
5. Suivre la doc complète: `~/Workspace/network/docs/migration-logs/phase-1-vpn/`

## 3. Vérifier le déploiement

```bash
# Vérifier l'état Terraform
make show

# Vérifier les outputs
make output

# Tester la connectivité OPNsense
curl -k https://192.168.2.254
```

## 4. Prochaines étapes

### Phase suivante: AdGuard Home
```bash
# Une fois OPNsense configuré et la migration VLAN faite
make ansible-deploy-dns
```

### Déployer tous les services
```bash
make ansible-deploy
```

## Commandes utiles

```bash
make help                    # Voir toutes les commandes
make plan                    # Planifier changements Terraform
make apply                   # Appliquer changements
make ansible-check          # Vérifier syntaxe Ansible
make ansible-inventory      # Voir l'inventaire
make clean                  # Nettoyer fichiers temporaires
```

## En cas de problème

### Erreur de connexion Proxmox
```bash
# Tester manuellement
curl -k https://192.168.2.101:8006/api2/json/version

# Vérifier les passwords
make check-passwords
```

### Réinitialiser Terraform
```bash
cd terraform/core
rm -rf .terraform .terraform.lock.hcl
make init
```

### Logs Terraform détaillés
```bash
export TF_LOG=DEBUG
make plan
```

## Documentation complète

- [README.md](README.md) - Documentation complète
- [Makefile](Makefile) - Toutes les commandes disponibles
- `~/Workspace/network/docs/` - Documentation réseau détaillée

## Support

Pour toute question, consultez la documentation ou créez une issue.
