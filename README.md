<img width="2172" height="724" alt="Unreal Tournament" src="https://github.com/Andiweli/UT99-Android/blob/master/images/unreal-header.jpg" />

# Unreal Tournament (UT99) pour Android

Portage non officiel d'Unreal Tournament (1999) sur Android, à partir du port
d'[Andiweli/UT99-Android](https://github.com/Andiweli/UT99-Android). Ce fork
ajoute la traduction française, l'installation des données GOTY officielles, la
prise en charge des fichiers OldUnreal 469 et un menu pensé pour la manette.

<p align="left">
  <a href="https://github.com/tib-kpl/UT99-Android/releases/latest"><b>TÉLÉCHARGER</b></a>
  &nbsp;|&nbsp;
  <a href="CHANGELOG.md">Historique des versions</a>
  &nbsp;|&nbsp;
  <a href="docs/GOTY_COMPATIBILITY.md">Compatibilité GOTY / OldUnreal</a>
  &nbsp;|&nbsp;
  <a href="docs/CONSOLE_MENU.md">Menu console</a>
</p>

![OS](https://img.shields.io/badge/Android-4.1%20%C3%A0%2016-green)
![Architecture](https://img.shields.io/badge/ABI-armeabi--v7a%20%2F%20arm64--v8a-orange.svg)
![Controller](https://img.shields.io/badge/Contr%C3%B4les-Manette%20%2F%20Tactile%20%2F%20Clavier-blueviolet)
![Multiplayer](https://img.shields.io/badge/Multijoueur-LAN%20%2B%20Internet%20(436)-blueviolet)
![AI](https://img.shields.io/badge/AI-assisted%20coding-6e7781)

> [!NOTE]
> **English summary.** Unofficial Android port of Unreal Tournament (1999), forked from
> Andiweli/UT99-Android. This fork adds the French localization, an in-app installer for the
> official GOTY data (GOTY disc + latest OldUnreal patch, data files only), Android-side fixes for
> OldUnreal 469 data, an in-game Android settings screen and a controller-first console menu.
> Each [release](https://github.com/tib-kpl/UT99-Android/releases/latest) ships two signed APKs:
> `console-menu` and `classic-menu`. No game data is included.

> [!IMPORTANT]
> Aucune donnée du jeu n'est incluse. Il faut une copie légale d'Unreal Tournament.
> Ce projet n'est ni officiel ni approuvé par Epic Games. Unreal Tournament,
> Unreal Engine et les marques associées appartiennent à Epic Games.

---

## ▣ Captures

<img width="1920" height="1080" alt="ut99-0" src="https://github.com/user-attachments/assets/e7b74300-e685-47fb-82f8-4a81405855e2" />
<img width="1920" height="1080" alt="ut99-1" src="https://github.com/user-attachments/assets/81ffadd5-bf30-4444-ab3b-698c4e56430f" />
<img width="1920" height="1080" alt="ut99-2" src="https://github.com/user-attachments/assets/516263cf-caba-44e3-95f4-4b0852e79780" />

---

## ◈ Deux variantes, un seul moteur

Chaque release contient deux APK signés, construits depuis la même branche
`master` :

| APK | Menu |
|---|---|
| `…-console-menu-release.apk` | Menu console/téléphone : grandes options, navigation à la croix, aperçus de cartes, champs adaptés au clavier Android. Recommandé à la manette. |
| `…-classic-menu-release.apk` | Menu UT99 d'origine (fenêtres UWindow). |

Les deux partagent le même moteur natif, les mêmes correctifs et les mêmes
données. Installer une variante remplace l'autre en conservant les données et
les réglages.

---

## ◈ Fonctionnalités

**Données du jeu**
- **Installation GOTY officielle depuis l'app** : téléchargement du disque GOTY
  (miroirs OldUnreal ou archive.org, somme MD5 vérifiée) et du dernier patch
  OldUnreal. Seuls les fichiers de données sont gardés : aucun `.exe` ni `.dll`.
- Choix de la langue à l'installation : anglais, français, allemand, espagnol,
  italien, néerlandais, portugais, russe, chinois, grec. Les voix localisées
  du disque (français, espagnol, italien) sont conservées pour la langue choisie.
- Import de ses propres fichiers (dossier ou ZIP), versions v400 ou 469.
- Stockage au choix : mémoire interne, carte microSD ou **n'importe quel
  dossier**. Un dossier qui contient déjà un jeu valide peut être utilisé sur
  place, sans copie.

**Réglages Android en jeu** (rouage en haut à droite)
- Manette tactile : « Automatique (sans manette physique) », « Toujours
  afficher » ou « Masquer » ; opacité réglable de 20 à 100 % ; modification et
  réinitialisation de la disposition.
- Langue du jeu (redémarrage automatique).
- Emplacement des données du jeu.

**Commandes**
- Manettes Android (Xbox, consoles portables AYN, Retroid, OUYA…).
- Manette tactile *RetroTouch* pour jouer sans manette.
- Clavier et souris (testé sur Chromebook).

**Multijoueur**
- Parties LAN et parties Internet via le navigateur de serveurs.
- Le client annonce la version réseau 436 : il rejoint les serveurs 432 et 436
  (et les serveurs 469 qui acceptent les clients 436).
- Rejoindre par adresse IP, téléchargement des paquets manquants depuis le
  serveur.

**Localisation**
- Le jeu passe en français quand l'app est en français (langue du téléphone, ou
  langue par application sous Android 13+), avec la traduction officielle
  (`.frt`). Textes UTF-8 des fichiers 469 correctement décodés.

**Compatibilité OldUnreal 469**
- Le moteur Android est une base v400 qui charge aussi les paquets système 469f.
  Les correctifs (chargement de cartes, sons d'interface, paramètres de script
  récents, réseau…) sont détaillés dans
  [docs/GOTY_COMPATIBILITY.md](docs/GOTY_COMPATIBILITY.md).

> [!NOTE]
> Limites connues : certains mods et protections de serveurs (anti-triche, mods
> récents) ne fonctionnent pas ; les serveurs qui exigent 469 restent
> inaccessibles ; certains déclencheurs et événements de cartes peuvent encore
> mal se lancer. Le rendu utilise OpenGL ES (pas de Vulkan).

---

## ◎ Installation

1. Téléchargez et installez l'APK de votre choix depuis
   [la dernière release](https://github.com/tib-kpl/UT99-Android/releases/latest).
2. Lancez **Unreal Tournament**.
3. Si aucune donnée n'est trouvée, l'écran d'installation propose :
   - **Télécharger et installer GOTY (OldUnreal)** : choix de la langue et de
     l'emplacement, puis téléchargement du disque GOTY (environ 650 Mo) et du
     patch OldUnreal ;
   - **Choisir mon dossier UT99** ou **Importer une archive ZIP** pour vos
     propres fichiers. Si le dossier choisi contient déjà un jeu valide,
     **Utiliser ce dossier** le garde sur place, sans copie.
4. Le jeu démarre automatiquement une fois les données en place.

Dossiers requis pour un import manuel :

```text
UnrealTournament/
├── System/
├── Maps/
├── Textures/
├── Sounds/
└── Music/
```

Les dossiers peuvent être à la racine choisie ou dans un unique dossier
Unreal Tournament.

---

## ◇ Disposition par défaut de la manette

| Commande | Action |
|---|---|
| Stick gauche | Avancer / reculer / pas de côté |
| Stick droit | Regarder / tourner |
| Gâchette gauche | Tir secondaire |
| Gâchette droite | Tir principal |
| Bouton épaule gauche | Arme précédente |
| Bouton épaule droit | Arme suivante |
| A / bouton de droite | Sauter |
| B / bouton du bas / OUYA O | S'accroupir |
| Y / bouton de gauche / OUYA U | Marcher |
| X / bouton du haut / OUYA Y | Saluer |
| Croix directionnelle | Navigation dans les menus / en jeu selon le contexte |
| Start | Pause / menu |
| Back | Retour / annuler selon le contexte |

> [!NOTE]
> Les noms des boutons varient selon les manettes. Les commandes se
> réassignent dans le menu des contrôles du jeu.

---

## ◈ Compilation

Prérequis : JDK 17, Android SDK 35, NDK 23.2.8568313, CMake 3.22.1.
Le projet utilise Android Gradle Plugin 8.6.1 et Gradle 8.7.

```text
./gradlew assembleNormalRelease assembleClassicRelease
python tools/check_menu_variants.py
```

`normal` produit le menu console et `classic` le menu UT99 d'origine.
`tools/check_menu_variants.py` vérifie que les deux APK partagent les mêmes
bibliothèques natives, ressources, assets et manifeste. Le menu console
(`UT99ConsoleMenu.u`) se recompile avec `tools/build_console_menu.ps1` et un
UCC v400. Voir aussi [BUILD-FLAVORS.md](BUILD-FLAVORS.md).

| | |
|---|---|
| Identifiant | `com.ast.ut99` |
| SDK minimum | 16 (Android 4.1) |
| SDK cible | 35 |
| ABI | armeabi-v7a, arm64-v8a |
| Rendu | OpenGL ES |

Chaque commit sur `master` est compilé par GitHub Actions, qui signe les deux
APK et publie une release.

---

## ▣ Crédits

- Port Android d'origine : [Andiweli/UT99-Android](https://github.com/Andiweli/UT99-Android)
  ([soutenir Andiweli via PayPal](https://paypal.me/andiweli)).
- [OldUnreal](https://www.oldunreal.com/) pour le patch 469 et l'hébergement
  des données GOTY.
- La communauté de préservation et de portage d'Unreal Engine 1.

---

## ◎ Mentions légales

Unreal Tournament, Unreal Engine et les noms, ressources et marques associés
sont la propriété d'Epic Games. Ce dépôt n'inclut **aucune** donnée commerciale
du jeu ; une copie légale d'Unreal Tournament est nécessaire. Ce projet n'est ni
officiel ni approuvé par Epic Games. Usage non commercial uniquement.
