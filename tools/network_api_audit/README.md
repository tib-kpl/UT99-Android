# API de scripts des serveurs récents

Scénario isolé, non inclus dans les APK. Il doit être compilé avec un
compilateur UT récent, car il importe volontairement des fonctions absentes
du package Engine v400. Le script copie les outils dans `build` et ne
modifie pas l'installation fournie.

```powershell
./tools/build_ut99_network_api_audit.ps1 -GameDirectory <installation-UT99-GOTY>
```

Copier `build/network-api-audit/System/UT99NetworkAPIAudit.u` dans les copies
de test du serveur et des clients. Conserver les packages système v400
compatibles des clients Android. Déclarer côté serveur :

```ini
[Engine.GameEngine]
ServerPackages=UT99NetworkAPIAudit
```

Lancer le serveur récent avec cette URL, puis connecter les clients :

```
DM-Oblivion?game=Botpack.DeathMatchPlus?MinPlayers=0?mutator=UT99NetworkAPIAudit.CompatAudit
```

Le scénario vérifie les valeurs par défaut, les appels `Super`, le chaînage
sur deux mutateurs et les paramètres de sortie : booléens, octets, noms,
classes, objets, chaînes et vecteurs. Il vérifie aussi l'inscription unique
au HUD, son traitement de touches de base et `PlayerPawn.LastMessageWindow`.
L'événement `PostNetBeginPlay` doit être appelé une seule fois et lire la
valeur initiale répliquée `469`, différente de sa valeur par défaut `0`.

Collecter les journaux après quelques secondes de partie (le fichier est
tamponné), puis exécuter :

```powershell
./tools/check_ut99_network_api_audit.ps1 -ClientLogs @('./build/client-arm64.log','./build/client-arm32.log') -Network
```

Chaque client doit produire exactement un PASS pour les 15 contrôles et
`NET_API COMPLETE`, sans FAIL ni erreur critique. Un lancement solo avec
la même URL permet de tester les 14 contrôles sans événement réseau ;
omettre alors `-Network`. Retirer le mutateur et toute URL de diagnostic
après les essais.

Cette vérification ne garantit pas la compatibilité de tous les mods ni
des bibliothèques natives et anti-triches propres à d'autres plateformes.
