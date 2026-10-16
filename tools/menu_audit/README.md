# Essai des raccourcis des mods

`ExtraBindingsAudit` est un mutateur de diagnostic, exclu de l?APK.
Compiler ce dossier comme package `UT99MenuAudit` avec UCC v400, en ajoutant
`EditPackages=UT99MenuAudit` apr?s `UT99ConsoleMenu` dans la configuration
de compilation isol?e. Le package du menu et ses d?pendances doivent ?tre
pr?sents dans ce m?me environnement.

Dans une installation de test avec RelicsBindings et ses fichiers `.int` et
`.frt`, lancer :

```
DM-Oblivion?game=Botpack.DeathMatchPlus?mutator=UT99MenuAudit.ExtraBindingsAudit?MinPlayers=0
```

Le sc?nario v?rifie les m?tadonn?es, la d?couverte du fournisseur, la ligne
dans Commandes, l?affectation de J ? `mutate tossrelic`, puis sa relecture
apr?s fermeture et r?ouverture du menu, sans ligne dupliqu?e. Il restaure
ensuite l?affectation initiale de J. Attendre le message
`EXTRA_BINDINGS restored temporary J binding` avant de fermer l?application.
Utiliser uniquement une configuration de test : une interruption avant la
restauration laisse la touche temporairement modifi?e. Les fichiers GOTY
avec marque UTF-8 initiale couvrent ?galement la lecture de `[public]`.

V?rifi? sur appareil en ARM64 et ARMv7. Le journal doit contenir les trois
contr?les PASS (m?tadonn?es, affectation et r?ouverture), sans FAIL.
