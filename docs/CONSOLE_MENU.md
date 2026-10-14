# Menu console UT99

Branche : `feat/console-menu`.

Le menu principal utilise une liste verticale, un fond anthracite avec le logo
original UT teinté bordeaux, une sélection rouge et des accents dorés. Les fenêtres
de configuration utilisent le thème doré natif d'UT99.

Les listes sont lues depuis les objets UMenu existants. Chaque action appelle
`BeforeExecuteItem` puis `ExecuteItem` de l'objet original : pas de copie de la
logique des parties, des options ou des mods. Les entrées désactivées et cochées
ainsi que les sous-menus restent pris en compte. Les longues listes défilent avec
la sélection.

La rubrique Tournoi / Parties conserve « Démarrer Unreal Tournament » et
« Reprendre un tournoi sauvegardé ». Ces actions ouvrent les écrans Ladder natifs
(profil, difficulté, progression, sauvegarde). Le menu en liste s'efface pendant
les fenêtres natives et les écrans de campagne verrouillés. Il réapparaît après
leur fermeture. Les fenêtres de campagne conservent leur interface native.

Navigation : haut/bas, Entrée ou A pour valider, gauche/Retour arrière ou B pour
revenir, Échap/Start pour revenir via la console. Souris et toucher sont conservés.
Le stick conserve le curseur existant ; la croix directionnelle parcourt la liste.
B reste assignable dans les fenêtres de configuration des contrôles.

## Reconstruction

Le package additionnel est compilé avec le compilateur du jeu v400 (format 68).
Les fichiers UMenu.u et UTMenu.u existants restent inchangés.

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_console_menu.ps1 -GameDirectory C:\UnrealTournament
.\gradlew.bat assembleNormalDebug
```

Les fichiers du jeu nécessaires à la compilation sont copiés dans
`build/console-menu` ; le répertoire du jeu source n'est pas modifié. Les sources
UnrealScript se trouvent dans `app/src/main/console_menu/Classes`.

Le démarrage installe le package et ses traductions puis configure la racine
`UT99ConsoleMenu.UT99ConsoleRoot`, y compris pour une installation existante.
La langue des actions originales continue d'utiliser les traductions du jeu.

## Vérification sur appareil

- Ouvrir le menu au lancement et pendant une partie ; croix, A/B, Start, clavier,
  souris et toucher doivent fonctionner sans validation double.
- Démarrer un tournoi, créer un profil, finir une épreuve et reprendre le profil
  après redémarrage. Vérifier que le menu ne recouvre pas les écrans Ladder.
- Lancer une partie contre les bots, héberger/rejoindre une partie réseau.
- Ouvrir et fermer les préférences ; modifier puis vérifier un réglage sauvegardé.
- Vérifier les mods installés, leurs sous-menus et les longues listes.
- Vérifier les menus de messages et de communication pendant une partie.
- Vérifier les résolutions basses OUYA et les appareils Android 32/64 bits.
