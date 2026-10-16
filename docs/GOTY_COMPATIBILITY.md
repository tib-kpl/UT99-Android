# GOTY / OldUnreal : branche expérimentale

Cette branche conserve le moteur Android natif et le menu console. Elle ne
remplace pas le moteur par la version Linux et ne prétend pas exécuter les
packages système du moteur OldUnreal 469.

## Données récentes

Les cartes, textures, sons et musiques de l'installation GOTY peuvent être
préparés avec les packages système v400 correspondant au moteur Android :

```powershell
./tools/prepare_ut99_goty_data.ps1 `
  -CompatibleGameDirectory C:\UnrealTournament `
  -GotyDirectory H:\Jeux\UnrealTournament `
  -OutputDirectory ./build/goty-android-data
```

Le dossier de sortie doit être nouveau et distinct des deux installations.
Les sources restent intactes. Le résultat peut être importé par le lanceur
Android comme un dossier UT99 habituel ou être placé dans une archive ZIP.
Les fichiers du jeu ne sont pas intégrés à l'APK ni publiés sur GitHub.

Le script conserve le `System` compatible et prend les quatre dossiers de
contenu dans l'installation GOTY. Les packages supplémentaires `de` et
`epiccustommodels` passent également le chargement v400. Les packages modernes
`Core`, `Engine`, `Botpack`, les interfaces et les autres packages système
ne sont pas substitués : ils nécessitent encore un portage distinct.
Les Relics, MultiMesh, modèles squelettiques et les fonctionnalités propres
au moteur 469 ne sont donc pas annoncés comme pris en charge.

Le protocole réseau reste v400. Les serveurs OldUnreal 469 exigent au minimum
432 : cette branche ne permet donc pas encore de les rejoindre. Porter les
échanges réseau et les packages requis est un chantier distinct ; modifier
simplement le numéro annoncé ne suffirait pas à établir la compatibilité.

L'audit ci-dessous charge chaque carte et exporte son niveau avec le moteur
v400 dans une copie isolée. Cela vérifie les références et le chargement,
mais ne remplace pas une partie jouée sur Android :

```powershell
./tools/audit_ut99_content.ps1 `
  -EngineDirectory C:\UnrealTournament `
  -ContentDirectory H:\Jeux\UnrealTournament
```

Le rapport est écrit dans `build/goty-content-audit/report.json`.
Les 96 cartes de l'installation de référence ont passé cet audit, dont
23 au format 69. Le jeu de données préparé contient 96 cartes, 112 textures,
29 packages de sons et 30 musiques. Les autres fichiers présents dans les
dossiers sources, notamment les sauvegardes de packages, ne sont pas copiés.

Le lanceur accepte les cartes au format 69 tout en conservant le contrôle
strict des packages système v400. Le lecteur de polices et les fonctions de
mesure/dessin prennent en charge la table de caractères des polices au format
69, y compris les indices de glyphes supérieurs à 255. Sans cette adaptation,
`LadderFonts.UTLadder16` provoquait un arrêt au premier affichage du HUD.
Le format est décrit par les en-têtes du
[SDK officiel OldUnreal](https://github.com/OldUnreal/UnrealTournamentPatches/releases/tag/v469e).

Sur la Thor, ce jeu de données a été lancé depuis CityIntro puis testé dans
DM-Crane : rendu de la carte, arme, HUD, textes français et menu console.
Cela ne valide pas encore une partie complète sur chacune des 96 cartes.

`audit_ut99_data.ps1` compare les signatures des packages système et des
cartes choisies. DM-Oblivion est identique dans les deux installations et sur
les consoles : son problème de descente ne se corrige pas par remplacement
de la carte.

## Collisions dans Oblivion

Le cas capturé sur l'Odin se situe près de
`(-494.7016, -543.1790, -157.3358)`, contre le bord gauche d'une descente.
Un bot a aussi été enregistré immobile dans ce passage malgré une
accélération vers l'avant.

Deux comportements du port se combinent : la marge des balayages BSP
augmente avec leur longueur, ce qui maintient le personnage trop haut sur
la pente ; une tentative de montée contre le mur rencontre ensuite le bord
d'un plafond et utilise sa normale pour le glissement. Le personnage finit
par ne plus pouvoir avancer lorsqu'une petite composante du déplacement
pousse vers le mur.

Le correctif Android utilise une marge BSP constante de 0,1 unité. Lorsqu'une
tentative de marche ne produit aucun déplacement horizontal, il essaie de
glisser contre le mur initial à hauteur du sol, avec un nouveau déplacement
soumis aux collisions ordinaires. La carte et les blocs de collision restent
actifs. Il s'agit d'une correction indépendante dans le moteur du port,
pas d'une copie des sources privées du moteur OldUnreal.

OldUnreal documente ses propres corrections des blocages contre les pentes
dans ses [notes officielles](https://github.com/OldUnreal/UnrealTournamentPatches/blob/master/ReleaseNotes.md).

### Régression reproductible

```powershell
./tools/build_ut99_physics_audit.ps1 -GameDirectory C:\UnrealTournament
```

Le package produit est `build/physics-audit/System/UT99PhysicsAudit.u`.
Il n'est pas livré avec l'APK. Sur une installation de test, lancer :

```text
DM-Oblivion?game=Botpack.DeathMatchPlus?mutator=UT99PhysicsAudit.OblivionWallAudit
```

Le test utilise un personnage temporaire et rejoue les contacts dans les
deux couloirs, avec quatre directions, quatre modes/vitesses et six pas de
simulation (30, 60, 90, 120, 144 et 200 Hz). Les 192 traversées passent sur la
Thor avec le correctif. Dans le couloir gauche, 72 des 96 variantes échouaient
avant la correction. Le moteur Windows v400 et le moteur OldUnreal récents
passaient ces mêmes 96 variantes.

Le test manuel sur l'Odin, en longeant le bord gauche signalé, confirme
également un passage fluide après correction.

```powershell
./tools/check_ut99_physics_audit.ps1 -LogPath ./build/physics-audit/android-wall-both-sides.log
```

Le mutateur `UT99PhysicsAudit.CollisionBoundaries` contrôle aussi un balayage
contre le décor, un saut sous un plafond et dix secondes au repos. Les trois
contrôles passent sur la Thor. Ces essais ne constituent pas une validation
exhaustive de toutes les cartes, des movers ou du jeu en réseau.

### Diagnostic facultatif

Dans l'INI moteur actif, la clé ci-dessous active des traces de position et
de collision pour le joueur local et les pawns qui tentent de bouger sans
progresser. Elle est désactivée par défaut et ne modifie pas la physique.

```ini
[Engine.GameEngine]
AndroidCollisionDiagnostics=True
```

Les APK debug peuvent lire une URL de scénario dans
`<dossier UT99>/physics-test-url.txt` au démarrage. Les APK release ignorent
ce fichier et démarrent normalement sur CityIntro.

## APK expérimental

Les pushes sur `feat/oldunreal-goty-compat` compilent l'APK normal ARMv7/ARM64
et publient une préversion GitHub `goty-compat-*`, distincte des versions du
menu console. La signature utilise les mêmes secrets CI que les autres APK.
L'APK conserve l'identifiant de l'application principale ; les essais locaux
utilisent des identifiants séparés pour préserver l'installation habituelle.
