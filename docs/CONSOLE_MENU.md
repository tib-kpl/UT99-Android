# Menu console UT99

Branche : `feat/console-menu`.

Le menu utilise un logo d?tour?, une palette bordeaux/dor?e et des captures des
cartes install?es choisies al?atoirement. Les sous-menus affichent leur chemin
sous le logo. Retour figure dans la liste avec la m?me taille que les options.
Les listes longues ont une barre de d?filement manipulable au toucher.

Les actions des rubriques principales proviennent des objets UMenu existants.
La pr?paration des parties solo/bots et multijoueur adapte les contr?les natifs :
type de partie, carte, r?gles, r?glages, bots, serveur, rotation et mutateurs.
Les notifications d'origine restent responsables des configurations et voyages.
Le choix de carte affiche imm?diatement la capture ? droite du nom surlign?,
sans modifier la s?lection avant validation. Les cartes sans capture le signalent.

La campagne adapte la cr?ation du personnage, la s?lection du type de partie et
celle du niveau. Les fen?tres Ladder, leur inventaire et les notifications
originales g?rent toujours les sauvegardes, rangs, victoires et d?blocages.
Les types/niveaux verrouill?s ne peuvent pas ?tre lanc?s. Un trait dor? anim? et
un message signalent les nouveaux d?blocages ; les animations des anciens
panneaux ne sont plus dessin?es. Les autres ?crans sp?cialis?s restent natifs.

En jeu, Start ouvre le menu racine et un nouvel appui reprend la partie.
Retour/B remonte dans les sous-menus ; ? la racine, Reprendre ferme le menu.
Quitter la partie revient ? l'introduction hors r?seau pour pouvoir lancer un
autre mode. Les rubriques d'origine restent accessibles, avec leurs contraintes
natives (par exemple d?connexion disponible pour un client connect?).
La console conserve sa pause en mode Standalone, sans pause r?seau. Les modes
qui interdisent nativement la pause, comme certaines phases du didacticiel,
conservent cette r?gle.

Le flou GLES2 copie le framebuffer RGB, puis applique deux passes gaussiennes
sur le GPU avant de dessiner les ?l?ments du menu. L'?tat GL est restaur? pour
les dessins suivants. Les autres renderers ont un fond simplement assombri.

Navigation : croix/haut-bas, A/Entr?e pour valider, gauche-droite pour modifier
les valeurs, B/?chap pour revenir, souris et toucher. Dans un champ de texte,
Entr?e enregistre et ?chap annule ; le clavier Android est affich?.

## Reconstruction

Le package additionnel utilise le compilateur v400 (format 68). UMenu.u et
UTMenu.u restent inchang?s. Les fichiers n?cessaires sont copi?s dans
`build/console-menu`, sans modifier le jeu PC source.

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_console_menu.ps1 -GameDirectory C:\UnrealTournament
.\gradlew.bat assembleNormalDebug --offline --no-configuration-cache
```

Sources : `app/src/main/console_menu`. La traduction fran?aise source est UTF-8 ;
le script la convertit en Windows-1252 pour le moteur UE1. Ne pas ?diter l'asset
compil? `.frt` directement en UTF-8. L'installation rafra?chit les packages lors
d'une nouvelle installation d'APK et configure la racine personnalis?e.

## V?rification

Test sur Odin 2 Portal, application s?par?e `com.ast.ut99.consolemenutest` :
logo et espacement du chemin, navigation A/B/Start et tactile, aper?u Facing
Worlds au survol, rotation, configuration et lancement de CTF-Face h?berg?,
cr?ation du personnage du tournoi, niveaux et types initialement verrouill?s,
lancement du didacticiel et de DM-Barricade, reprise et sortie de partie.
Le flou est v?rifi? sur DM-Barricade. APK construit pour arm64-v8a et armeabi-v7a.
L'application originale et ses donn?es n'ont pas ?t? remplac?es.

? compl?ter sur appareil : victoire puis animation de d?blocage, reprise d'une
sauvegarde apr?s red?marrage, connexion ? un serveur distant, interfaces de mods,
OUYA et autres r?solutions. La compilation et l'acc?s initial ? la campagne ne
constituent pas une validation de toute sa progression.
