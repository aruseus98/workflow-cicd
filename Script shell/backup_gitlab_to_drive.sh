#!/bin/bash

# Nom du conteneur Docker GitLab
GITLAB_CONTAINER_NAME=debian-gitlab-1

# Chemin du dossier de sauvegarde local pour GitLab
LOCAL_BACKUP_DIR=/home/debian/gitlab/data/backups

# Nom du remote Rclone configuré pour Google Drive
RCLONE_REMOTE_NAME="BackupDB-TheTiptop"

# Chemin de base sur Google Drive
REMOTE_BASE_DIR="Thé Tiptop/Backup GitLab"

# Obtenir la date actuelle dans le format yyyy-mm-dd
TODAYS_DATE=$(date +%Y-%m-%d)

# Exécuter la commande de sauvegarde GitLab
echo "Exécution de la sauvegarde GitLab..."
docker exec $GITLAB_CONTAINER_NAME gitlab-rake gitlab:backup:create

# Changer les permissions des fichiers de sauvegarde
echo "Modification des permissions des fichiers de sauvegarde..."
sudo chmod 644 $LOCAL_BACKUP_DIR/*

# Boucle sur les fichiers de sauvegarde
for backup_file in $LOCAL_BACKUP_DIR/*; do
    # Extraire le nom complet du fichier de sauvegarde
    backup_filename=$(basename $backup_file)
    
    # Extraire la date du nom de fichier
    backup_date=$(echo $backup_filename | grep -oP '\d{4}_\d{2}_\d{2}' | sed 's/_/-/g') #La commande grep -oP '\d{4}_\d{2}_\d{2}' est utilisée pour extraire la date du nom de fichier. Ensuite, sed 's/_/-/g' remplace les underscores (_) par des tirets (-) pour faire correspondre le format de la date à celui de TODAYS_DATE.

    # Vérifier si la date du fichier correspond à celle d'aujourd'hui
    if [ "$backup_date" == "$TODAYS_DATE" ]; then
        # Chemin complet du dossier de sauvegarde distant, y compris la date
        REMOTE_BACKUP_DIR="$REMOTE_BASE_DIR/$backup_date"

        # Récupérer la liste des fichiers dans le dossier distant
        existing_files=$(rclone lsf $RCLONE_REMOTE_NAME:"$REMOTE_BACKUP_DIR")

        # Vérifier si le fichier de sauvegarde existe déjà sur Google Drive
        if [[ $existing_files != *"$backup_filename"* ]]; then
            echo "Le fichier $backup_filename n'existe pas dans $REMOTE_BACKUP_DIR, transfert en cours..."

            # Transférer le fichier de sauvegarde vers le dossier spécifique sur Google Drive
            rclone copy $backup_file $RCLONE_REMOTE_NAME:"$REMOTE_BACKUP_DIR"

            echo "Backup $backup_file transferred to Google Drive in folder: $REMOTE_BACKUP_DIR"
        else
            echo "Un backup existant nommé $backup_filename est déjà présent dans $REMOTE_BACKUP_DIR, aucun transfert nécessaire."
        fi
    else
        echo "La date du fichier $backup_filename ne correspond pas à la date d'aujourd'hui $TODAYS_DATE."
    fi
done

echo "Les sauvegardes GitLab ont été vérifiées et transférées avec succès vers Google Drive."
