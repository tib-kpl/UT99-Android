# Menu console UT99

Branche : `feat/console-menu`.

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

Les panneaux complexes du navigateur de serveurs et de la console sont intégrés
dans le nouveau cadre avec un grand Retour ; leurs contrôles internes restent
natifs. La fenêtre de saisie d'adresse apparaît devant le navigateur, propose
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
| Déblocages | Message et progression testés avec un profil temporaire déjà avancé |
| Suppression | Annulation, confirmation, fichier actualisé et emplacement vide après redémarrage ; autres emplacements inchangés |
| Préférences | Sept rubriques et affichage des raccourcis ; annulation de capture |
| Joueur | Modèle 3D et affichage correct de « APERÇU » |
| Armes | Liste et aperçu restaurés lorsque les priorités enregistrées sont vides |
| Connexion | Boîte de réglage réseau, adresse/historique, saisie et retour au navigateur |
| LAN | Découverte d'un serveur PC et connexion réelle sur DM-Deck16][ depuis l'Odin |
| Retour multijoueur | Parties LAN → Retour → Multijoueur → Retour → Menu principal, vérifié sur Odin |
| En partie | Préférences sur fond flouté, Start reprend puis rouvre la racine, B reprend |
| Sortie de match | Retour direct au menu principal |

Le profil avancé temporaire a été supprimé. Une injection ADB de fichier `.ini`
doit conserver les droits d'écriture pour l'application : un fichier en mode
0644 appartenant à `shell` empêche les sauvegardes natives ; utiliser 0660 pour
les fichiers de test injectés dans ce répertoire.

Restent à valider : campagne complète avec une victoire réelle déclenchant un
déblocage, connexion réussie à un serveur distant, réorganisation d'armes et
lecture complète sur appareil, panneaux de mods, OUYA et autres résolutions.
Le test d'un profil avancé ne valide pas toute la progression de la campagne.

Le navigateur utilise désormais une liste adaptée à la manette pour LAN,
Internet et favoris. Les services News/Chat restent accessibles explicitement
dans cette liste ; Retour ne passe plus par leurs catégories intermédiaires.
La connexion LAN a été validée, contrairement à la connexion à un serveur distant.
