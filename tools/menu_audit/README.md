# Essai des raccourcis des mods

`ExtraBindingsAudit` est un mutateur de diagnostic, exclu de l'APK.
Compiler ce dossier comme package `UT99MenuAudit` avec UCC v400, en ajoutant
`EditPackages=UT99MenuAudit` après `UT99ConsoleMenu` dans la configuration
de compilation isolée. Le package du menu et ses dépendances doivent être
présents dans ce même environnement.

Dans une installation de test avec RelicsBindings et ses fichiers `.int` et
`.frt`, lancer :

```
DM-Oblivion?game=Botpack.DeathMatchPlus?mutator=UT99MenuAudit.ExtraBindingsAudit?MinPlayers=0
```

Le scénario vérifie les métadonnées, la découverte du fournisseur, la ligne
dans Commandes, l'affectation de J à `mutate tossrelic`, puis sa relecture
après fermeture et réouverture du menu, sans ligne dupliquée. Il restaure
ensuite l'affectation initiale de J. Attendre le message
`EXTRA_BINDINGS restored temporary J binding` avant de fermer l'application.
Utiliser uniquement une configuration de test : une interruption avant la
restauration laisse la touche temporairement modifiée. Les fichiers GOTY
avec marque UTF-8 initiale couvrent également la lecture de `[public]`.

Vérifié sur appareil en ARM64 et ARMv7. Le journal doit contenir les trois
contrôles PASS (métadonnées, affectation et réouverture), sans FAIL.
