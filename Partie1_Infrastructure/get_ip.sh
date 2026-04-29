#!/bin/bash

echo "🔍 Récupération de l'adresse IP depuis Terraform..."

# extraction de l'ip brute
VM_IP=$(terraform output -raw vm_ip)

# vérification pour savoir si terraform a bien renvoyé quelque chose
if [ -z "$VM_IP" ]; then
    echo "❌ Erreur : Impossible de récupérer l'IP. La VM est-elle bien démarrée ?"
    exit 1
fi

echo "✅ IP trouvée : $VM_IP"
echo "📝 Génération du fichier inventory.ini..."

# on écrit ou écrase le fichier inventory.ini avec les bonnes informations
cat <<EOF > inventory.ini
[k3s_master]
debian-k3s ansible_host=$VM_IP

[k3s_master:vars]
ansible_user=vagrant
ansible_password=vagrant
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "🎉 Fichier inventory.ini généré avec succès !"
