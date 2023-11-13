# Workflow CI/CD

Mise en place du Workflow CI/CD dans le cadre de la formation MBA2 - Architecte Digital

Ce repo est composé d'un fichier principal pour la mise en place du Workflow

- docker-compose.yml

Exécuter la commande suivante:

    docker compose up

Il est ensuite composé de 2 dossiers et 3 sous-dossiers chacun (DEV, PREPROD, PROD) qui contiennent des Jenkinsfile.
1. Le déploiement d'un site web
2. Le déploiement d'une api

Enfin, il reste un dernier dossier qui contient un script shell qui automatise à l'aide d'un crontab la copie et l'envoie des sauvegardes des bases de données.

## Caractéristiques du serveur

Voici les caractéristiques du serveur sur lequel a été déployé ce workflow

- Hébergeur : OVH
- Modèle : VPS vps2020-elite-8-32-160
- vCores : 8
- Mémoire : 32 Go
- Stockage : 160 Go

Backup quotidien effectué
