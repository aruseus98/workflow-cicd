#!/bin/bash

# Chemin du dossier de sauvegarde local
LOCAL_BACKUP_DIR=./backups

# Nom du remote Rclone configuré pour Google Drive
RCLONE_REMOTE_NAME="BackupDB-TheTiptop"

# Chemin de base sur Google Drive
REMOTE_BASE_DIR="Thé Tiptop/Backup base de données"

# Obtenir la date actuelle dans le format yyyy-mm-dd
TODAYS_DATE=$(date +%Y-%m-%d)

# Boucle sur les fichiers de sauvegarde
for backup_file in $LOCAL_BACKUP_DIR/*; do
    # Extraire le nom complet du fichier de sauvegarde
    backup_filename=$(basename $backup_file)
    
    # Extraire la date du nom de fichier
    backup_date=$(echo $backup_filename | grep -oP '\d{4}-\d{2}-\d{2}')

    # Vérifier si la date a été trouvée
    if [ ! -z "$backup_date" ]; then
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
    fi
done
