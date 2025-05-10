# EmClaud Budget

![Logo EmClaud Budget](assets/images/emclaud_logo.svg)

## Présentation

EmClaud Budget est une application de gestion financière personnelle complète, conçue pour aider les utilisateurs à suivre et gérer efficacement leurs finances. Développée avec Flutter, cette application offre une interface intuitive en mode sombre pour une expérience utilisateur optimale.

## Fonctionnalités

### Tableau de bord financier
- Vue d'ensemble claire de votre situation financière
- Visualisation graphique des revenus et dépenses
- Animations fluides pour une expérience utilisateur améliorée
- Effets visuels dynamiques pour célébrer les entrées d'argent

### Gestion des revenus
- Enregistrement des différentes sources de revenus
- Catégorisation par type (salaire, freelance, investissements, etc.)
- Suivi de la répartition des revenus
- Graphiques pour visualiser la distribution des sources de revenus

### Suivi des dépenses
- Enregistrement et catégorisation des dépenses
- Répartition visuelle par catégories (alimentation, transport, logement, etc.)
- Analyse des tendances de dépenses
- Alertes intelligentes sur les habitudes de dépenses

### Historique des transactions
- Vue chronologique des transactions
- Filtrage par période, catégorie ou montant
- Recherche avancée dans l'historique
- Exportation des données (fonctionnalité future)

### Personnalisation
- Interface exclusivement en mode sombre pour moins de fatigue visuelle
- Options de personnalisation des devises
- Paramètres ajustables selon vos préférences

## Technologies utilisées

- **Flutter** : Framework d'interface utilisateur multiplateforme
- **Dart** : Langage de programmation moderne et réactif
- **SQLite** : Base de données locale pour stocker vos informations financières en toute sécurité
- **Provider** : Gestion d'état pour une expérience fluide
- **fl_chart** : Visualisations graphiques avancées

## Installation

### Prérequis

Aucune installation spéciale n'est requise pour exécuter l'application via l'AppImage sur Linux.

### Installation rapide (Linux)

1. **Téléchargez** le fichier AppImage (`EmClaud_Budget-x86_64.AppImage`) depuis la source de distribution

2. **Rendez le fichier exécutable** en ouvrant un terminal et en saisissant :
   ```bash
   chmod +x chemin/vers/EmClaud_Budget-x86_64.AppImage
   ```
   Remplacez `chemin/vers/` par le chemin d'accès au dossier où se trouve le fichier

3. **Lancez l'application** en double-cliquant sur le fichier AppImage ou en exécutant :
   ```bash
   ./chemin/vers/EmClaud_Budget-x86_64.AppImage
   ```

### Installation système complète (Linux)

Pour une intégration complète dans votre système, suivez ces étapes :

1. **Installation pour lancement depuis n'importe quel terminal** :
   ```bash
   # Copiez l'AppImage dans un répertoire du PATH système
   sudo cp EmClaud_Budget-x86_64.AppImage /usr/local/bin/emclaud-budget
   
   # Rendez-le exécutable
   sudo chmod +x /usr/local/bin/emclaud-budget
   ```
   Vous pouvez maintenant lancer l'application en tapant simplement `emclaud-budget` dans n'importe quel terminal.

2. **Ajout au menu des applications** :
   ```bash
   # Créez un fichier .desktop
   cat > emclaud-budget.desktop << EOF
   [Desktop Entry]
   Version=1.0
   Type=Application
   Name=EmClaud Budget
   Comment=Application de gestion budgétaire personnalisée
   Exec=emclaud-budget
   Icon=/usr/local/share/icons/emclaud-budget.svg
   Terminal=false
   Categories=Office;Finance;
   Keywords=budget;finance;money;
   StartupNotify=true
   EOF
   
   # Créez un dossier pour l'icône
   sudo mkdir -p /usr/local/share/icons
   
   # Copiez l'icône
   sudo cp assets/images/emclaud_logo.svg /usr/local/share/icons/emclaud-budget.svg
   
   # Installez le raccourci dans le menu
   sudo cp emclaud-budget.desktop /usr/share/applications/
   ```
   
   L'application apparaîtra maintenant dans votre menu des applications, généralement dans la catégorie "Bureau" ou "Finance".

3. **Vérification de l'installation** :
   ```bash
   # Vérifiez que la commande est accessible
   which emclaud-budget
   
   # Lancez l'application
   emclaud-budget
   ```

### Compilation depuis la source

Si vous préférez compiler l'application vous-même :

1. **Prérequis** :
   - Flutter SDK (version 3.0 ou supérieure)
   - Git
   - Dépendances nécessaires pour le développement Flutter

2. **Clonez le dépôt** :
   ```bash
   git clone https://votre-repo/EmClaud_Budget.git
   cd EmClaud_Budget
   ```

3. **Installez les dépendances** :
   ```bash
   flutter pub get
   ```

4. **Compilez et exécutez l'application** :
   ```bash
   flutter run
   ```
   
   Ou pour compiler en mode release :
   ```bash
   flutter build linux --release
   ```

## Mise en route

Lors du premier lancement, EmClaud Budget vous guidera à travers les étapes suivantes :

1. **Écran d'accueil** : Visualisez le nouveau logo et le nom de l'application
2. **Configuration initiale** : Configurez vos préférences de devise et autres paramètres
3. **Tableau de bord** : Commencez à enregistrer vos revenus et dépenses

## Sécurité des données

Toutes vos données financières sont stockées localement sur votre appareil dans une base de données SQLite sécurisée. Aucune information n'est envoyée vers des serveurs externes, garantissant ainsi la confidentialité de vos informations financières.

## Contribution

Les contributions au projet sont les bienvenues. Si vous souhaitez contribuer :

1. Créez une branche (`git checkout -b amelioration-fonctionnalite`)
2. Effectuez vos modifications (`git commit -m 'Ajout d'une nouvelle fonctionnalité'`)
3. Poussez vers la branche (`git push origin amelioration-fonctionnalite`)
4. Ouvrez une Pull Request

## Licence

Ce projet est distribué sous licence [préciser la licence]. Voir le fichier LICENSE pour plus de détails.

## Contact

Pour toute question ou suggestion, n'hésitez pas à nous contacter à [votre-email@exemple.com].
