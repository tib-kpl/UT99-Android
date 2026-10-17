# GOTY / OldUnreal : compatibilité du moteur Android

La branche `master` conserve le moteur Android natif avec deux menus au choix.
Elle ne
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
Les fonctionnalités propres au moteur 469 nécessitent encore des adaptations.
Relics et les personnages squelettiques demandent les extensions Android
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

`RelicsBindings` est également inclus. Une classe native de métadonnées
`UTMenu.UTExtraKeyBindings` permet de charger son package original sans
modifier `UTMenu.u`. Le menu Commandes ajoute les actions déclarées par les
mods et conserve leurs commandes complètes, notamment `mutate tossrelic`,
lors de l'affectation et de la relecture des touches. Le lecteur de
configuration ignore la marque UTF-8 initiale des fichiers récents pour
reconnaître leur première section `[public]`. Le scénario isolé
`tools/menu_audit/Classes/ExtraBindingsAudit.uc` vérifie ces étapes et la
réouverture sans doublon sur ARM64 et ARMv7, puis restaure la touche de test.

### Personnages squelettiques du bonus pack

Le moteur Android charge maintenant les objets `Animation` et `SkeletalMesh`
de `SkeletalChars.u` original. Les 68 séquences sont échantillonnées au
chargement en 1077 poses pour le rendu LOD v400 existant. Les os sont reliés
par leur nom, les rotations interpolées par quaternion et les influences
pondérées appliquées aux points locaux. L'arme utilise trois points d'attache
produits à partir de l'os de la main et du réglage original du maillage.
Les poses générées sont détachées du chargement différé pour éviter qu'un
rechargement du fichier ne les remplace par les tableaux source vides.

Cette adaptation garde l'interpolation de sommets et la précision des
sommets v400 entre les poses ; elle n'implémente pas le système d'animation
squelettique complet du moteur 469 ni les extensions de mods ultérieures.
Elle prend en charge le format des deux personnages du bonus pack, sans
modifier le package, son GUID ou ses indices d'objets. Un alias limité à
`Botpack.MaleSounds` résout les sons correspondants dans le package v400
`MaleSounds`, sans remplacer Botpack.

`UT99PhysicsAudit.SkeletalModelsAudit` contrôle le chargement des classes
Xan Mk2 et War Boss, puis leurs animations de repos, course et mort, avec
leurs textures. Ces scènes ont été vérifiées en ARM64 et ARMv7. Le scénario
n'est pas intégré à l'APK. Deux clients utilisant les classes originales ont
également rejoint le serveur 469 isolé : HUD, armes, adversaire et tirs sont
visibles ; la santé des deux joueurs passe de 100 à 50 côté serveur.
Ce test ne certifie pas tous les mods ou protections des serveurs publics.

La préparation inclut maintenant `SkeletalChars` et ses déclarations. Les
packages système modernes restent exclus et leur garde-fou reste actif.

### Compatibilité réseau

Les redirections `IpDrv.HTTPDownload` annoncées par le serveur sont maintenant
prises en charge en HTTP/HTTPS, avec fichiers bruts ou compressés `.uz`
(signatures 1234 et 5678). Le transfert et la décompression s'exécutent hors
du thread du jeu. La taille, l'en-tête et le GUID du package sont vérifiés
avant son placement en cache. Une erreur HTTP, une réponse invalide ou une
mauvaise version provoque un repli vers le canal fichier classique. Les
installations locales et leurs packages ne sont jamais écrasés.

Le téléchargement HTTP affiche le pourcentage et les Mo reçus/attendus lorsque
la taille de la réponse est connue. Pour `.uz`, il utilise la taille compressée
HTTP, pas celle du package décompressé. Si une réponse compressée n'annonce pas
sa taille, les Mo reçus restent affichés jusqu'à la fin du transfert.

Une copie de carte de test de 952119 octets, absente des deux consoles, a été
téléchargée par le miroir HTTP local sur Wi-Fi, puis chargée sur Thor et Odin
avec connexion au serveur 469. Les fichiers reçus correspondent au SHA-256
du fichier source. Le test d'un miroir fournissant un autre GUID confirme le
repli et la réception de la bonne carte. Ces essais ne constituent pas une
mesure du débit d'un serveur Internet. Sans miroir configuré par le serveur,
le téléchargement conserve le canal historique et ses limites.

Les replis successifs HTTP vers le canal fichier pouvaient bloquer la
connexion sur un package : le canal précédent était déjà libéré sur Android
mais encore en cours de fermeture côté serveur. La requête suivante pouvait
réutiliser ce même numéro trop tôt. Android préfère désormais un numéro de
canal encore inutilisé dans cette connexion. Les requêtes consécutives restent
ainsi distinctes pendant la fermeture des transferts précédents.

Les transitions répétées ont également exposé une libération prématurée de
canal pendant le ramasse-miettes. `RouteDestroy` pouvait déclencher le nettoyage
de sa connexion, qui supprimait ce même canal alors que son appel de destruction
était encore actif. Pendant ce nettoyage, Android appelle désormais la destruction
conditionnelle des canaux et laisse leur libération physique à la phase suivante
du ramasse-miettes. La suppression immédiate hors de ce cas reste inchangée.

Le scénario `UT99PhysicsAudit.NetworkTravelAudit` a fait suivre trois cartes
à deux clients, ARM64 et ARMv7, sur le serveur 469 isolé. La carte intermédiaire
est une copie de test de Crane avec un GUID distinct, absente des consoles.
Elle est reçue par HTTP ; deux textures absentes du miroir déclenchent ensuite
deux replis vers le canal fichier. Les six fichiers reçus sur les deux clients
correspondent aux SHA-256 des sources. Les clients retrouvent leur HUD et leur
arme sur chaque carte, puis leur adversaire au retour sur Oblivion. Les
scénarios et fichiers du jeu restent exclus de l'APK ; les journaux privés
restent dans `build`.

Une seconde rotation avec le cache rempli termine également les trois étapes,
sans réception HTTP ou fichier supplémentaire. Ce contrôle reproduisait le
crash de nettoyage avant la correction de durée de vie des canaux.

`tools/check_ut99_network_travel_audit.ps1` vérifie les trois étapes dans les
journaux serveur et clients ; `-ColdDownloads` exige aussi la réception HTTP
de la carte et les deux numéros de canal distincts pour les textures.
`-WarmCache` exige au contraire l'absence de nouvelles demandes de fichiers.

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

Les mods de serveurs publics peuvent importer des API apparues après v400,
même lorsque leurs fonctions ne s'exécutent que côté serveur. Le moteur
ajoute en mémoire les fonctions de chaînage de `Mutator`, dont
`HandleEndGame`, `HandleRestartGame`, `HandlePickupQuery`, `PreventDeath`,
`ModifyLogin` et les filtres de messages, avec leurs signatures et paramètres
de sortie. Il ajoute aussi `NextMessageMutator`, `RegisterHUDMutator`,
`Actor.PostNetBeginPlay`, `HUD.ProcessKeyEvent`, `PlayerPawn.LastMessageWindow`
et les champs de visage/police de `Botpack.ChallengeHUD` attendus par ces mods.
Les imports ajoutés restent valides entre vérification et chargement effectif
des packages ; les autres imports restent stricts. Aucun package du jeu
n'est réécrit. `PostNetBeginPlay` est envoyé sur le client après la réception
initiale des propriétés, une seule fois par ouverture de canal d'acteur.

Le scénario `tools/network_api_audit` vérifie ces comportements sur un serveur
récent avec des clients ARM32 et ARM64. Il complète les essais de connexion
publique ; il ne valide pas toutes les extensions de tous les serveurs.
Les modules natifs propres à d'autres plateformes restent hors de ce périmètre.

Les pushes sur `master` compilent deux APK ARMv7/ARM64 et publient une seule
release GitHub normale `build-<run>-<attempt>`, contenant les deux fichiers :

- `UT99-Android-<version>-fr-classic-menu-release.apk` : menu UT99 classique,
  variante Gradle `classic` ;
- `UT99-Android-<version>-fr-console-menu-release.apk` : menu console/téléphone,
  variante Gradle `normal`.

Les deux APK partagent le même moteur, les mêmes correctifs et les mêmes
données de jeu. Seul le choix du menu au lancement change. Le contrôle
`tools/check_menu_variants.py` bloque la publication si leurs fichiers
diffèrent en dehors du code Java compilé : bibliothèques natives, ressources,
manifeste et assets doivent être identiques. Les futurs correctifs restent
communs aux deux variantes, développées ensemble dans `master`. La CI exige la
clé de signature habituelle avant publication. Les deux variantes conservent
l'identifiant de l'application principale : installer l'une remplace l'autre
en conservant les données et rétablit le menu correspondant, même après un
changement de variante. Les essais locaux utilisent un identifiant séparé
pour préserver l'installation habituelle. Le statut de release ne signifie
pas que tous les packages système et mods 469 sont compatibles.

## Étape Core 469f

Le moteur Android reconnaît maintenant `PointerProperty`, avec un stockage
adapté à la largeur des pointeurs ARM32/ARM64 et sans considérer ces valeurs
comme des références UObject. La saisie textuelle accepte `None` et refuse
les adresses numériques. Les API Core `Locs`, `Repl`, `RandRange`, `ClearConfig`,
`StaticClearConfig`, `GetDefaultValue`, `SetUTracing` et `IsUTracing` sont
implémentées. Les fonctions absentes du Core v400 sont ajoutées en mémoire avec
leurs signatures précises et une liste fermée d'imports autorisés ; les
fichiers du jeu restent intacts. `SetPropertyText` fournit aussi le booléen
attendu par les scripts récents, tout en conservant les appels v400 sans retour.

Le scénario `tools/core_format_audit` passe ses 22 contrôles sur ARMv7 et ARM64,
avec les paquets système v400. Le contrôle supplémentaire d'un appel compilé
contre la signature v400 sans retour passe aussi. Les 18 vérifications d'API
concordent avec le moteur PC officiel 469f-rc5. Un essai diagnostique isolé
charge le `Core.u` officiel 469f-rc5 et démarre DM-Oblivion sur les deux
architectures, avec Engine/Botpack v400 ; les mêmes 22 contrôles passent.

**La prise en charge complète des fichiers système 469 n'est pas terminée.**
Avec le paquet Engine récent, le premier blocage identifié est le changement
de format de `Engine.Actor.Touching`, auparavant tableau statique d'objets.
Les structures natives, les anciens imports et les accès du moteur aux
contacts doivent être adaptés ensemble. Registry et les autres différences
natives restent à vérifier. Le lanceur publié exige donc encore Core,
Engine et Botpack v400 ; l'essai Core seul ne justifie pas de lever ce contrôle.

L'installation automatique depuis les sources officielles reste à réaliser
après cette compatibilité. Elle devra conserver l'import des fichiers propres
à l'utilisateur, proposer le dossier cible et **le choix de la langue avant le
téléchargement**, avec la langue de l'appareil présélectionnée et modifiable.
Ce parcours sera commun aux deux variantes de menu.
