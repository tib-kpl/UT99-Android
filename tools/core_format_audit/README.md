# Formats et API Core récents

Scénario isolé, absent des APK publiées et ne contenant aucun fichier du jeu.
Compiler avec les outils officiels récents ; les chemins désignent des copies
locales choisies par la personne qui exécute le test :

```powershell
./tools/build_ut99_network_api_audit.ps1 `
  -GameDirectory <dossier-outils-UT-recents> `
  -ContentDirectory <dossier-contenu-GOTY> `
  -AuditPackage UT99CoreFormatAudit
```

`ContentDirectory` est facultatif si les outils et les données se trouvent dans
la même installation. Le compilateur et les sources sont copiés dans `build` ;
les installations fournies ne sont pas modifiées. Le script réinitialise aussi
la configuration de test `CoreFormatFixture.ini`.

Copier le paquet produit `build/core-format-audit/System/UT99CoreFormatAudit.u`
et `tools/core_format_audit/CoreFormatFixture.ini` dans le `System` d'une copie
de test Android. Réinitialiser cet INI avant chaque exécution : les tests de
suppression de configuration le modifient volontairement. Utiliser :

```
DM-Oblivion?game=Botpack.DeathMatchPlus?mutator=UT99CoreFormatAudit.PointerAudit,UT99CoreFormatAudit.CoreFunctionsAudit?MinPlayers=0
```

Démarrer effectivement le match avec le bouton de tir, laisser passer quelques
secondes et récupérer le journal tamponné. Aucun bot n'est nécessaire.

```powershell
./tools/check_ut99_core_format_audit.ps1 `
  -ClientLogs @('./build/core-arm32.log','./build/core-arm64.log')
```

Le contrôle exige 4 PASS de propriétés et 18 PASS d'API, les deux marqueurs de
fin et une trace réelle de `CoreFunctions.TraceProbe`. Il rejette les échecs,
les doublons et les erreurs critiques.

Les propriétés `pointer` et leur tableau sont compilés avec le compilateur
469f. Le test construit 32 objets et vérifie la disposition des champs voisins,
les valeurs par défaut, la conversion de `None`, le refus d'une adresse
numérique et le résultat booléen de `SetPropertyText`.

Les API contrôlées sont `Locs`, `Repl`, `RandRange`, `SetUTracing`, `IsUTracing`,
`GetDefaultValue`, `ClearConfig` et `StaticClearConfig`. Les mêmes 18 contrôles
peuvent tourner sur le moteur PC officiel, depuis le `System` préparé :

```powershell
./UCC.exe UT99CoreFormatAudit.CoreFunctionsCommandlet ini=NetworkAPIAudit.ini
```

Réinitialiser `CoreFormatFixture.ini` avant cette commande également. Le cas
`Repl` avec une recherche vide est volontairement absent de la comparaison PC :
le moteur officiel testé boucle jusqu'à manquer de mémoire. Android renvoie la
chaîne d'origine dans ce cas.

Pour vérifier un appel compilé contre la signature v400 **void**, compiler
également `tools/physics_audit`, ajouter
`UT99PhysicsAudit.LegacyPropertyAudit` à la liste des mutateurs et passer
`-Legacy` au contrôleur. L'affectation doit fonctionner et le nom constant de
l'objet doit rester intact.

Ces tests passent sur ARMv7 et ARM64 avec Core v400, et les 22 contrôles passent
également dans un essai isolé avec Core 469f-rc5 et Engine/Botpack v400. Cela ne
valide pas Engine 469, Registry, tous les usages de pointeurs natifs, les
fonctionnalités de jeu 469 ou tous les mods. Le lanceur publié conserve son
contrôle des paquets système v400. Retirer les mutateurs, paquets et INI de
test ainsi que toute URL de diagnostic après vérification.
