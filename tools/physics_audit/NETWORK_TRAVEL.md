# Rotation de cartes sur un serveur récent

Scénario isolé, exclu de l'APK. Ne pas activer sur un serveur normal.
Compiler le package avec `tools/build_ut99_physics_audit.ps1`, puis le copier
dans les installations de test du serveur et des deux clients. Le serveur
doit aussi déclarer `ServerPackages=UT99PhysicsAudit`.

Préparer uniquement dans une copie de test :

- `DM-DownloadAudit.unr`, copie d'Oblivion avec un GUID distinct ;
- `DM-TravelAudit.unr`, copie de Crane avec un autre GUID distinct ;
- `DM-Oblivion.unr`, carte originale de retour.

Le miroir HTTP contient `DM-TravelAudit.unr.uz`, compressé avec UCC. Pour
exercer les replis, ne pas y mettre `noxxpack.utx.uz` ni `xutfx.utx.uz`.
Les clients doivent avoir ces deux textures absentes ou non compatibles avec
les GUID du serveur, ainsi qu'aucune copie en cache de la carte intermédiaire.
Conserver les packages système compatibles des clients Android.

Lancer le serveur de test avec :

```
DM-DownloadAudit?game=Botpack.DeathMatchPlus?MinPlayers=0?mutator=UT99PhysicsAudit.NetworkTravelAudit
```

Connecter les deux clients. Le scénario démarre le match et attend deux
joueurs armés avant chaque transition. Il s'arrête après l'arrivée sur
Oblivion. À cette dernière étape, il place les joueurs face à face pour
contrôler également la réplication de l'adversaire. Les étapes sont déduites
du nom de la carte ; aucun état de progression n'est écrit dans la configuration.

Vérifier les journaux collectés avec :

```powershell
./tools/check_ut99_network_travel_audit.ps1 `
  -ServerLog ./build/travel-server.log `
  -ClientLogs @('./build/travel-client-1.log','./build/travel-client-2.log') `
  -ColdDownloads
```

Comparer aussi les SHA-256 des trois packages en cache sur chaque appareil
avec leurs sources serveur. Rejouer sans effacer le cache doit aboutir sans
nouvelle réception de ces fichiers ; remplacer alors `-ColdDownloads` par
`-WarmCache`. Cette seconde rotation couvre aussi le nettoyage des anciens
canaux lors du retour vers une carte déjà chargée.

Avant la correction d'allocation des canaux, un client restait bloqué sur
la deuxième texture. Après correction, les deux requêtes de repli utilisent
des canaux distincts et les deux clients terminent la rotation. Validé sur
Odin ARM64 et Thor ARMv7, avec les classes originales Xan Mk2 et War Boss.
