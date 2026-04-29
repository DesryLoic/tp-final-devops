# Documentation - TP Final DevOps 

Loïc Desry

Ce document détaille l'infrastructure mise en place pour le deploiement de l'API.

---

## Arborescence du projet

Voici comment sont organisés les fichiers pour garantir une structure claire :

```text
tp_final_desry_loic/
├── README.md
├── Partie1_Infrastructure/
│   ├── deploy.tf
│   ├── get_ip.sh
│   ├── install_k3s.yml
│   └── inventory.ini (généré automatiquement)
├── Partie2_Conteneurisation/
│   └── api-lacets/ (Dépôt cloné)
│       ├── Dockerfile
│       └── (reste du code source)
└── Partie3_Kubernetes/
    ├── api.yaml
    └── mysql.yaml
```
---

## 🛠️ Partie 1 : Préparation de l'infrastructure

L'objectif de cette première étape est de mettre en place les fondations techniques du projet. Nous automatisons le déploiement d'une machine virtuelle Debian et l'installation d'un **K3s**. 

### 1. Provisionnement de la VM (Terraform)
Nous utilisons **Terraform** pour définir et créer l'infrastructure. Le fichier `deploy.tf` configure une machine Debian sur VirtualBox avec les ressources optimisées (2 Go de RAM).

**Commande de déploiement :**
```bash
terraform apply -auto-approve
```

### 2. Récupération de l'IP et Inventaire (Bash)
Puisque la VM reçoit une adresse IP via DHCP, nous utilisons un script Bash `get_ip.sh`. Ce script remplit deux fonctions critiques :
* Extraire la nouvelle adresse IP de la VM.
* Générer dynamiquement le fichier `inventory.ini` utilisé par Ansible.

**Commande d'exécution :**
```bash
./get_ip.sh
```

### 3. Installation de K3s (Ansible)
Enfin, nous utilisons **Ansible** pour configurer la machine à distance. Le playbook `install_k3s.yml` se connecte à la VM via l'inventaire généré et installe automatiquement tous les composants nécessaires au cluster Kubernetes.

**Commande d'installation :**
```bash
ansible-playbook -i inventory.ini install_k3s.yml
```

---

## Partie 2 : Conteneurisation de l'application

L'objectif de cette partie est de packager l'API Node.js dans une image Docker optimisée et de la rendre disponible publiquement sur Docker Hub.

### 1. Optimisation du Dockerfile
Nous avons cloné le code source de l'API et créé un `Dockerfile`. Pour répondre aux fortes exigences d'optimisation de la taille de l'image, nous avons mis en place plusieurs bonnes pratiques :
* Utilisation du **Multi-stage build** (`AS builder`) pour isoler l'installation des dépendances et ne garder que le code compilé.
* Utilisation d'une image de base minimaliste **`node:18-alpine`**.
* Sécurisation du conteneur en utilisant l'utilisateur non-root `USER node`.

### 2. Build et Push sur Docker Hub
L'image a été construite localement puis poussée sur le registre public Docker Hub. L'optimisation a permis d'obtenir une image finale très légère (environ 50 Mo).

**Commandes exécutées :**
```bash
docker build -t loicdesry/api-lacets:latest .
docker push loicdesry/api-lacets:latest
```

---

## ☸️ Partie 3 : Déploiement sur Kubernetes

L'objectif de cette étape est de déployer notre application conteneurisée et sa base de données sur notre cluster K3s, en respectant de strictes contraintes de sécurité, de persistance et de haute disponibilité.

### 1. Base de données MySQL
Le manifeste de la base de données (`mysql.yaml`) est conçu pour être résilient :
* **Initialisation :** Un script SQL de création des tables est injecté automatiquement au démarrage via une `ConfigMap`.
* **Persistance :** Les données sont sauvegardées sur un disque virtuel grâce à un `PersistentVolumeClaim` (PVC) de 2 Go. Ainsi, même en cas de crash du pod MySQL, aucune donnée client ne sera perdue.
* **Sécurité réseau :** La base de données n'est accessible que depuis l'intérieur du cluster grâce à un Service de type `ClusterIP` nommé `mysql-service`.

### 2. Déploiement de l'API Node.js
Le manifeste de l'API (`api.yaml`) récupère l'image optimisée lors de la phase précédente et se connecte à MySQL. Il répond aux exigences suivantes :
* **Sécurité :** L'API est uniquement exposée en interne via un `ClusterIP`.
* **Haute disponibilité (Auto-scaling) :** Nous avons défini des `requests` et `limits` de CPU stricts. Un `HorizontalPodAutoscaler` (HPA) surveille cette charge : l'API tourne avec 1 pod au minimum, mais peut monter automatiquement jusqu'à 3 pods (Scale-out) si la charge CPU dépasse 50%.
* **Auto-guérison (Self-healing) :** En cas d'indisponibilité temporaire de la base de données (ex: lors de son initialisation), les pods de l'API crashent mais sont immédiatement et automatiquement redémarrés par Kubernetes jusqu'à stabilisation complète du système.

**Commandes de déploiement exécutées sur le cluster :**
```bash
kubectl apply -f mysql.yaml
kubectl apply -f api.yaml
```