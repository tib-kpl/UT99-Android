# Historique des versions

Chaque version publiée contient deux APK signés : **console-menu** (menu
console/téléphone) et **classic-menu** (menu UT99 d'origine). Les correctifs du
moteur s'appliquent aux deux. Les versions sont publiées sur
[la page des releases](https://github.com/tib-kpl/UT99-Android/releases).

## 2.3.11

- Menu console : champs de saisie et listes déroulantes redessinés (fond
  sombre, liseré doré, texte blanc) ; petits boutons plats assortis au menu, à
  la place des contrôles en relief de style Windows.
- Le contour vert qu'Android dessinait autour du jeu après une navigation à la
  manette ou au clavier est supprimé.

## 2.3.10

- Menu console : pendant une saisie, le champ, le texte tapé et l'aide restent
  dans le quart supérieur de l'écran, au-dessus du clavier Android.
- L'étiquette du champ est en blanc au lieu de noir.

## 2.3.9

- Plus de page vide après la première recherche de serveurs LAN ou Internet :
  la fenêtre d'informations serveur du navigateur 469 est masquée.

## 2.3.8

- Ouverture du menu plus rapide depuis une carte microSD : la liste des cartes
  n'est plus relue en entier pour chaque carte (environ 0,6 s au lieu de
  1,5 à 2,7 s sur Odin 2).

## 2.3.7

- Retour à l'écran de verrouillage Android normal (le passage automatique du
  verrouillage sans code, ajouté en 2.3.5, est retiré).

## 2.3.6

- Ouverture du menu plus rapide avec les fichiers OldUnreal 469 : suppression
  d'un parcours de tous les objets à chaque entrée du menu, lecture des
  fichiers `.int` déplacée au démarrage du moteur.

## 2.3.5

- Multijoueur : le client annonce la version réseau 436 et rejoint les
  serveurs qui exigent 436 (« Serveur incompatible : UT requis 436 »).
  Les serveurs qui exigent 469 restent inaccessibles.

## 2.3.4

- Correction d'un plantage en partie (contacts entre joueurs, dégâts) avec les
  fichiers 469.
- Le rouage des réglages ne prend plus le focus de la manette au lancement ni à
  la sortie de veille.
- Clarté réglée à 6 par défaut à la première installation.

## 2.3.3

- Voix localisées du disque GOTY conservées pour la langue choisie
  (narration de l'intro, annonceur, joueurs) : français, espagnol, italien.

## 2.3.2

- Corrections du moteur pour les fichiers OldUnreal 469f : chargement de
  CTF-Coret, DM-Liandri, AS-Rook, DM-Turbine, voix de l'intro, textes UTF-8
  des menus, sons d'interface.
- Rouage de réglages Android en jeu : manette tactile (mode, opacité,
  disposition), langue du jeu, emplacement des données.
- Installation ou import dans n'importe quel dossier ; un dossier contenant
  déjà un jeu valide peut être utilisé sur place.
- Menu console : curseurs par pas entiers, aperçu de carte stable.

## 2.3.1

- Installation des données GOTY officielles (disque GOTY et dernier patch
  OldUnreal) avec choix de la langue et du stockage interne/microSD.

## 2.3.0

- Prise en charge des paquets système UT99 récents (OldUnreal 469) par le
  moteur Android natif.

## 2.2.3

- Pourcentage de téléchargement des paquets HTTP rétabli dans les deux menus.

## 2.2.2

- Compatibilité des propriétés Core et des API de script récentes.
