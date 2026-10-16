# Menu console UT99

Branche : `feat/console-menu`.

Orientation obligatoire : paysage. Les activités de lancement et de jeu sont
verrouillées en `landscape`, et le jeu réapplique ce verrouillage au démarrage.
L'adaptation des menus cible les tailles et proportions d'écrans en paysage ;
aucune mise en page portrait n'est prévue.

Le menu utilise un logo détouré, une palette bordeaux/dorée et des captures de
cartes installées choisies aléatoirement. Les sous-menus affichent leur chemin
sous le logo. Retour figure dans la liste avec la même taille que les options.
Les listes longues disposent d'une barre de défilement tactile.

## Fonctionnement

Les rubriques principales utilisent les actions UMenu existantes. La préparation
des parties adapte leurs contrôles natifs : type de partie, carte, règles,
réglages, bots, serveur, rotation et mutateurs. Les notifications originales
restent responsables des configurations et des changements de niveau.
Le choix de carte affiche immédiatement une capture nette à droite du nom
surligné ; les cartes sans capture le signalent.

La campagne présente la création du personnage, les sauvegardes, les types de
partie, les niveaux, les objectifs d'Assaut et les équipes alliées/adverses.
Les fenêtres Ladder et leur inventaire conservent les victoires, rangs,
sauvegardes et déblocages. Les types et niveaux verrouillés restent inaccessibles.
Un trait doré animé et un message signalent les nouveaux déblocages, avec les
sons et la progression d'origine. Les sauvegardes disposent d'actions Reprendre
et Supprimer, avec confirmation de suppression.

Les préférences, la configuration du joueur, les priorités d'armes et les
confirmations utilisent également les grandes options du menu. Les modèles 3D
et les descriptions originales sont conservés. Les raccourcis affichent leur
valeur réelle et restent assignables à la manette. Les armes peuvent être
réordonnées avec gauche/droite, avec une action pour lire leur description.

LAN, Internet et favoris partagent une page dédiée : nom, carte, joueurs et ping,
dix serveurs par page. Gauche/droite change de page sans déplacer la sélection ;
les boutons tactiles et le numéro de page restent visibles. Recherche, options
et retour ont un texte légèrement doré pour les distinguer des serveurs.
La recherche filtre le nom, la carte, le type et l'adresse ; les options offrent
le tri par nom/ping/carte/joueurs et l'actualisation. Les détails d'un serveur
conservent ses joueurs/règles, copie d'adresse, tests de ping et gestion des
favoris (ajout, modification, suppression). Le navigateur avancé conserve les
onglets et contrôles natifs ; News, Chat et console restent intégrés dans le
nouveau cadre avec un grand Retour. La fenêtre de saisie d'adresse propose
une saisie au clavier Android, l'historique et la validation d'origine. Le
navigateur peut être fermé puis rouvert sans rester attaché à un cadre masqué.

En partie, Start ouvre le menu racine ; un nouvel appui reprend depuis les
sous-menus. Retour/B remonte et reprend à la racine. Quitter la partie ouvre
directement le menu principal hors réseau pour permettre de lancer un autre
mode. La pause reste celle de la console native en Standalone ; les parties
réseau continuent. Les restrictions natives du didacticiel restent applicables.

Le flou GLES2 copie le framebuffer RGB puis applique deux passes gaussiennes.
L'état GL est restauré avant de dessiner le menu. Le jeu reste visible derrière.
Le recentrage du pointeur invisible n'altère pas la sélection à la manette.

Les événements Android de la croix directionnelle et du bouton A passent par
une file SDL afin de conserver les appuis courts entre deux images. Chaque
pression directionnelle est traitée, sans délai entre deux appuis distincts.
La capture de raccourcis reçoit la touche physique sans activer ensuite une
option du menu. B et Start conservent leurs chemins de retour dédiés.

## Compilation

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_console_menu.ps1 -GameDirectory C:\UnrealTournament
.\gradlew.bat assembleNormalDebug --offline --no-configuration-cache
```

Sources : `app/src/main/console_menu`. La traduction source est UTF-8 ; le script
la convertit en Windows-1252 pour UE1. Ne pas modifier l'asset compilé `.frt`
directement en UTF-8. L'installation rafraîchit les packages et configure la
racine personnalisée. UnrealScript compilé avec UCC v400, format de package 68.

## Vérifications sur Odin 2 Portal

Application séparée : `com.ast.ut99.consolemenutest`. L'application originale et
ses données n'ont pas été remplacées. APK construit pour arm64-v8a et armeabi-v7a.

| Parcours | Résultat observé |
| --- | --- |
| Navigation | A/B/Start, toucher, trois directions rapides : trois options parcourues |
| Cartes | Aperçu immédiat, Facing Worlds, rotation et lancement de CTF-Face hébergé |
| Tournoi enregistré | Liste, reprise, choix du niveau, adversaire puis lancement |
| Campagne | Personnage, verrouillages, équipes DOM/CTF, objectifs/équipes Assaut, Challenge |
| Déblocages | Combat automatisé sur un profil temporaire : victoire en DM-Fractal, position 3 → 4, Domination déverrouillée et sauvegardée |
| Suppression | Annulation, confirmation, fichier actualisé et emplacement vide après redémarrage ; autres emplacements inchangés |
| Préférences | Sept rubriques et affichage des raccourcis ; annulation de capture |
| Joueur | Modèle 3D et affichage correct de « APERÇU » |
| Armes | Liste/aperçu restaurés, échange gauche/droite et sauvegarde des priorités, description complète affichée |
| Connexion | Boîte de réglage réseau, adresse/historique, saisie et retour au navigateur |
| LAN | Découverte d'un serveur PC et connexion réelle sur DM-Deck16][ depuis l'Odin |
| Liste Internet | Plus de 800 serveurs, cartes/places/pings, pagination directionnelle et tactile, recherche Morpheus et règles du serveur |
| Retour multijoueur | Parties LAN → Retour → Multijoueur → Retour → Menu principal, vérifié sur Odin |
| En partie | Préférences sur fond flouté, Start reprend puis rouvre la racine, B reprend |
| Sortie de match | Retour direct au menu principal |

Le profil avancé temporaire a été supprimé. Une injection ADB de fichier `.ini`
doit conserver les droits d'écriture pour l'application : un fichier en mode
0644 appartenant à `shell` empêche les sauvegardes natives ; utiliser 0660 pour
les fichiers de test injectés dans ce répertoire.

Restent à valider : campagne complète jusqu'au trophée final,
connexion réussie à un serveur distant compatible, panneaux de mods,
OUYA et autres résolutions en paysage.
Le test de victoire automatisée valide la transition native et le déblocage,
mais ne constitue pas une campagne complète jouée à la main. Le package de test
et le profil temporaire ont été retirés de l'application après ce contrôle.

Le navigateur utilise désormais une liste adaptée à la manette pour LAN,
Internet et favoris. Les services News/Chat restent accessibles explicitement
dans cette liste ; Retour ne passe plus par leurs catégories intermédiaires.
La connexion LAN a été validée, contrairement à la connexion à un serveur distant.

Le port utilise le moteur 400. Les serveurs annonçant une version minimale
supérieure sont indiqués comme incompatibles ; le test distant a reçu
`UPGRADE MINVER=433 VER=469`. Adapter le menu ne change pas le protocole du moteur.

## Publication CI

### Correctif LAN Android

Les configurations anciennes peuvent laisser les débits `Engine.Player` à zéro.
La connexion réussit alors, mais la file réseau ne se vide plus : les acteurs,
les armes et les informations du HUD ne sont plus répliqués vers le client.
Le moteur Android rétablit un débit de 20 000 en LAN et de 10 000 sur Internet
si la valeur configurée est inférieure au minimum accepté de 500.
Les valeurs configurées valides sont conservées.

Le tri des acteurs du serveur avait aussi une écriture qui utilisait et
incrémentait le même index dans une affectation. Avec l'évaluation du membre
de droite avant celui de gauche, la première entrée restait indéfinie et
le tri plantait à la connexion. L'incrément est désormais séparé.

Validation sur deux consoles physiques, dans des applications de test séparées :
Thor hôte / Odin client sur CTF-Face, puis Odin hôte / Thor client sur
DM-Deck16][. Les deux connexions réussissent, les hôtes restent actifs et
les clients affichent leurs armes, vie, munitions et scores. Sur Deck16,
les autres personnages et leurs déplacements sont également visibles côté
client. Le débit négocié dans les journaux est de 20 000. Compilation réussie
pour ARM64 et ARMv7. Ces essais ne constituent pas un test de longue durée.

Le workflow `.github/workflows/build.yml` publie les builds de `feat/console-menu`
dans une préversion GitHub distincte, avec un tag `console-menu-<run>-<attempt>`
et l'APK normal `UT99-Android-<version>-fr-console-menu-normal-release.apk`.
Il utilise les secrets de signature Android du dépôt, vérifie la signature et
ne remplace pas la release principale « Latest ». Sans secrets, le fichier porte
explicitement le suffixe `-unsigned` et nécessite une signature pour installation.
