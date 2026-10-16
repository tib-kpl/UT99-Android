# GOTY / OldUnreal : branche expérimentale

Cette branche conserve le moteur Android natif et le menu console. Elle ne
remplace pas le moteur par la version Linux et ne prétend pas exécuter les
packages système du moteur OldUnreal 469.

## Données récentes

Les cartes, textures, sons et musiques de l'installation GOTY peuvent être
préparés avec les packages système v400 correspondant au moteur Android :

```powershell
./tools/prepare_ut99_goty_data.ps1 `
  -CompatibleGameDirectory "<installation-UT99-v400>" `
  -GotyDirectory "<installation-UT99-GOTY>" `
  -OutputDirectory ./build/goty-android-data
```

Le dossier de sortie doit être nouveau et distinct des deux installations.
Les sources restent intactes. Le résultat peut être importé par le lanceur
Android comme un dossier UT99 habituel ou être placé dans une archive ZIP.
Les fichiers du jeu ne sont pas intégrés à l'APK ni publiés sur GitHub.

Le script conserve le `System` compatible et prend les quatre dossiers de
contenu dans l'installation GOTY. Les packages supplémentaires `de`,
`epiccustommodels` et `multimesh` passent également le chargement v400.
Les packages modernes
`Core`, `Engine`, `Botpack`, les interfaces et les autres packages système
ne sont pas substitués : ils nécessitent encore un portage distinct.
Les modèles squelettiques et les fonctionnalités propres au moteur 469
nécessitent encore des adaptations. Relics demande les extensions Android
décrites ci-dessous, présentes dans cette branche.

### Personnages bonus MultiMesh

La préparation inclut MultiMesh avec sa dépendance EpicCustomModels. Les
fichiers d'enregistrement des personnages, voix, bots et skins sont récupérés
dans `System` ou `SystemLocalized/int` et `SystemLocalized/frt`, puis placés
dans le `System` compatible. Les traductions du moteur et des interfaces
v400 restent celles de l'installation compatible.

Les 21 classes de MultiMesh ont été chargées/exportées avec le moteur v400.
Sur la Thor, le scénario `UT99PhysicsAudit.GotyModelsAudit` a chargé et affiché
successivement Nali, WarCow et Skaarj avec leurs textures et une animation de
repos. Ce test isolé ne certifie pas encore tous leurs comportements en
partie ni leur réplication réseau. Le scénario n'est pas intégré à l'APK.

### Reliques et sons du bonus pack

Le package `Relics.u` original est conservé. Le moteur Android complète en
mémoire la classe v400 `Engine.Mutator` avec `NextHUDMutator` et `bHUDMutator`.
Ces champs ont un stockage natif correspondant et participent au suivi des
références et au nettoyage des acteurs. Les imports autorisés se limitent à
ces deux champs précis ; les autres imports restent stricts. Engine.u, son
GUID et ses indices d'export ne sont pas modifiés.

Les sons PCM à 16 kHz de Relics provoquaient un arrêt dans le lecteur WAV,
limité à 11025/22050/44100 Hz. Android rééchantillonne désormais les fréquences
PCM intermédiaires vers un débit accepté par le mixeur, avec conversion des
points de boucle. Le fichier source reste intact.

Le scénario isolé `UT99PhysicsAudit.RelicsAudit` contrôle les six prises et
l'enregistrement du HUD, la régénération, la vitesse, l'absorption de défense,
la force, la survie de rédemption et la création de l'onde de vengeance.
Ces contrôles passent en ARMv7 ; prises, HUD, régénération et vitesse ont aussi
été vérifiés en ARM64. Le scénario n'est pas intégré à l'APK. La préparation des données inclut Relics et ses traductions ; elle
nécessite cette version du moteur Android, pas un exécutable v400 original.

Le scénario `RelicsNetworkAudit`, également réservé aux essais, donne une
relique de régénération aux deux clients d'un serveur 469. Les clients ARM64
et ARMv7 reçoivent la relique, affichent son icône et atteignent la santé 150
confirmée par le serveur.

`RelicsBindings` reste exclu : la classe `UTMenu.UTExtraKeyBindings` et sa
prise en charge par l'interface doivent encore être ajoutées. `SkeletalChars`
demande les objets audio déplacés dans Botpack, mais aussi les types natifs
`SkeletalMesh` et `Animation`, absents du moteur actuel. Leur prise en charge
ne se résume donc pas à un remplacement de référence audio. Le garde-fou sur
les packages système reste actif.

### Compatibilité réseau

Les redirections `IpDrv.HTTPDownload` annoncées par le serveur sont maintenant
prises en charge en HTTP/HTTPS, avec fichiers bruts ou compressés `.uz`
(signatures 1234 et 5678). Le transfert et la décompression s'exécutent hors
du thread du jeu. La taille, l'en-tête et le GUID du package sont vérifiés
avant son placement en cache. Une erreur HTTP, une réponse invalide ou une
mauvaise version provoque un repli vers le canal fichier classique. Les
installations locales et leurs packages ne sont jamais écrasés.

Une copie de carte de test de 952119 octets, absente des deux consoles, a été
téléchargée par le miroir HTTP local sur Wi-Fi, puis chargée sur Thor et Odin
avec connexion au serveur 469. Les fichiers reçus correspondent au SHA-256
du fichier source. Le test d'un miroir fournissant un autre GUID confirme le
repli et la réception de la bonne carte. Ces essais ne constituent pas une
mesure du débit d'un serveur Internet. Sans miroir configuré par le serveur,
le téléchargement conserve le canal historique et ses limites.

Le test JVM `tools/java_tests/RedirectDownloadAudit.java` prend un package
local et son fichier `.uz` produit par UCC. Il vérifie l'identité des données,
la redirection HTTP, les entrées tronquées, mille flux malformés, le code 404,
la taille incorrecte et l'annulation. Aucun fichier du jeu n'est livré avec
ce test.

Les clients Android négocient désormais jusqu'au protocole classique 432,
indépendamment de la version 400 du moteur et de ses packages système. Un
serveur v400 peut toujours négocier 400. Le navigateur LAN/Internet utilise
cette capacité réseau pour décider si le bouton de connexion est disponible.
Cela ne signifie pas que tous les mods et protections de serveurs 469 sont
compatibles avec le port Android.

L'audit ci-dessous charge chaque carte et exporte son niveau avec le moteur
v400 dans une copie isolée. Cela vérifie les références et le chargement,
mais ne remplace pas une partie jouée sur Android :

```powershell
./tools/audit_ut99_content.ps1 `
  -EngineDirectory "<installation-UT99-v400>" `
  -ContentDirectory "<installation-UT99-GOTY>"
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
./tools/build_ut99_physics_audit.ps1 -GameDirectory "<installation-UT99-v400>"
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

## Interpolation des animations

Sur Android, l'ancienne fonction `appFloor` convertissait `F-0.5` en entier
par troncature. Par exemple, elle renvoyait 0 pour 1,4. Le rendu de maillage
sélectionnait alors la mauvaise paire de poses et utilisait parfois un
coefficient d'interpolation supérieur à 1, avant de revenir brusquement à la
paire suivante. La boucle de repos du Nettoyeur/Enforcer rend ce défaut visible.

La branche Android utilise maintenant `floorf`. Le test natif
`tools/native_tests/animation_interpolation.cpp` inclut directement l'en-tête
de production. Il vérifie les arrondis négatifs/positifs et une piste de poses
périodique sur deux boucles. Avant correction, 3501 échantillons extrapolaient
et le saut maximal atteignait 0,999 ; après correction, aucun n'extrapole et le
pas maximal vaut environ 0,001, conforme à l'échantillonnage. Le test passe sur
l'Odin en ARM64 et ARMv7. Les 192 traversées d'Oblivion et les trois contrôles
mur/plafond/sol ont également été rejoués avec succès après ce changement.
L'observation manuelle de la boucle du Nettoyeur sur l'Odin confirme un
mouvement fluide après correction.

Le mutateur de test `UT99PhysicsAudit.AnimationObserve` permet d'observer
l'animation normale en solo sans bots. Il n'est pas intégré à l'APK.

## APK expérimental

### Essais réseau

Un serveur OldUnreal 469 local isolé a été rejoint par deux clients Android
(Odin et Thor), avec les packages système v400. Le test contrôle le HUD,
l'arme et l'inventaire, la visibilité de l'autre joueur, les déplacements et
les dégâts confirmés par le serveur. Un package de test absent est téléchargé
par le canal fichier, placé en cache puis chargé avant l'entrée en partie.
Les tirs ont réduit la santé des deux joueurs de 100 à 50. Une connexion au
serveur Windows v400 de référence a aussi abouti, avec négociation 400 et
affichage du HUD et de l'arme après le début du match.
Cela valide ce scénario classique, sans certifier les mods qui utilisent de
nouvelles fonctions natives ou les protections propres aux clients PC.

Les anciennes configurations générées désactivaient tous les téléchargements.
Une migration unique rétablit `AllowDownloads=True` dans `AndroidUT99.ini`.
Les modifications de ce réglage faites après la migration sont conservées.
Les refus de téléchargement, rejets et erreurs de connexion restent affichés
dans le menu jusqu'à validation, au lieu d'un message blanc fugitif.

Le mutateur `UT99PhysicsAudit.NetworkPlayAudit` est un scénario de test à deux
clients pour DM-Oblivion. Il les place face à face une fois armés et journalise
leur état côté serveur. Il ne doit pas être activé dans une partie normale.
Il n'est pas inclus dans l'APK.

La sonde ci-dessous peut inspecter le canal de contrôle d'un serveur de test :

```powershell
python tools/probe_ut99_network.py 127.0.0.1 --port 7777 --version 432
```

Elle ne rejoint pas la partie, ne télécharge aucun fichier et ne démontre pas
la compatibilité des acteurs. La valeur annoncée par cette sonde sert
uniquement à comparer les réponses de négociation du serveur.

Les pushes sur `feat/oldunreal-goty-compat` compilent l'APK normal ARMv7/ARM64
et publient une préversion GitHub `goty-compat-*`, distincte des versions du
menu console. La signature utilise les mêmes secrets CI que les autres APK.
L'APK conserve l'identifiant de l'application principale ; les essais locaux
utilisent des identifiants séparés pour préserver l'installation habituelle.
