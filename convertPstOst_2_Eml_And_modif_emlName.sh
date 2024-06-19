#!/bin/bash


# Recherche à partir de ce dossier
SEARCH_DIRECTORY="./"

# Définir le nombre de CPU utilisés
nbCPU=10

# Fonction pour renommer un fichier
rename_mail() {
    local mail="$1"
    
    # Affichage du nom du fichier origine
    echo "Fichier Origine : $mail"
    
    # Récupération de : année + mois + jour + heure
    DATE_STRING=$(/usr/bin/grep -m 1 "^Date: " "$mail" | /usr/bin/awk '{print $3, $4, $5, $6}')
    
    # Vérifier que DATE_STRING n'est pas vide
    if [ -z "$DATE_STRING" ]; then
        echo "Erreur: Date introuvable dans le fichier $mail"
        return
    fi
    
    # Extraire les composants de la date
    JOUR=$(/usr/bin/echo "$DATE_STRING" | /usr/bin/awk '{print $1}')
    MOIS=$(/usr/bin/echo "$DATE_STRING" | /usr/bin/awk '{print $2}')
    ANNEE=$(/usr/bin/echo "$DATE_STRING" | /usr/bin/awk '{print $3}')
    HEURE=$(/usr/bin/echo "$DATE_STRING" | /usr/bin/awk '{print $4}')
    
    # Modification de la notation des mois
    case $MOIS in
        Jan) MOIS='01' ;;
        Feb) MOIS='02' ;;
        Mar) MOIS='03' ;;
        Apr) MOIS='04' ;;
        May) MOIS='05' ;;
        Jun) MOIS='06' ;;
        Jul) MOIS='07' ;;
        Aug) MOIS='08' ;;
        Sep) MOIS='09' ;;
        Oct) MOIS='10' ;;
        Nov) MOIS='11' ;;
        Dec) MOIS='12' ;;
        *) 
            echo "Erreur: Mois inconnu $MOIS dans le fichier $mail"
            return
            ;;
    esac

    # Formatage de la date
    DATE="${ANNEE}-${MOIS}-${JOUR}_${HEURE}"
    
    # Construction des noms de fichiers
    SUFFIXE=".eml"
    DIR_PATH=$(/usr/bin/dirname "$mail")
    FILENAME=$(/usr/bin/basename -s "$SUFFIXE" "$mail")
    
    FILENAME_ORIGINE="$DIR_PATH/${FILENAME}${SUFFIXE}"
    FILENAME_NEW="$DIR_PATH/${DATE}_${FILENAME}${SUFFIXE}"
    
    # Renommage du fichier
    /usr/bin/mv "$FILENAME_ORIGINE" "$FILENAME_NEW"
    
    # Affichage du nom du fichier modifié
    echo "Fichier Renommé : $FILENAME_NEW"
}




searchMailBox() {
    # Trouver tous les fichiers PST et OST
    mailbox=$(find "$SEARCH_DIRECTORY" -type f \( -name "*.pst" -o -name "*.ost" \))

    # Boucle sur chaque fichier trouvé
    for file in $mailbox; do
        echo "Traitement du fichier : $file"
        
        # Extraire les boîtes mail avec readpst
        readpst -M -u -b -e "$file"
        
        # Vérifier si l'extraction a réussi
        if [ $? -eq 0 ]; then
            echo "Extraction réussie pour $file"
        else
            echo "Erreur lors de l'extraction pour $file"
            continue
        fi
    done
}

# Recherche des boîtes mails
searchMailBox

# Export de la fonction pour être utilisée par les sous-processus (ici xargs mais ça peut-être un find -exec ...)
export -f rename_mail

# Utilisation de find et xargs pour le multithreading
/usr/bin/find "$SEARCH_DIRECTORY" -type f -name "*.eml" -print0 | /usr/bin/xargs -0 -P $nbCPU -n 1 -I {} bash -c 'rename_mail "$@"' _ {}

