# Academic Fees App

Application Flutter/Dart de gestion et de paiement simule des frais academiques.

## Fonctionnalites

- Connexion locale avec deux roles : etudiant et comptable.
- Connexion locale avec trois roles : etudiant, comptable et administration.
- Base de donnees SQLite locale avec `sqflite`.
- Espace etudiant :
  - consultation du profil academique ;
  - suivi des frais factures, payes et restants ;
  - paiement en ligne simule avec choix de methode, numero et code de confirmation ;
  - historique des recus.
- Espace comptable :
  - tableau de bord des montants factures, encaisses et a recouvrer ;
  - liste des etudiants et soldes avec filtres en ordre / non en ordre ;
  - ajout de nouveaux frais ;
  - suivi des paiements recents.
- Espace administration :
  - creation des etudiants ;
  - modification et mise a jour des informations etudiantes ;
  - gestion des comptes etudiants reservee a l'administration.

## Comptes de demonstration

| Role | Email | Mot de passe |
| --- | --- | --- |
| Etudiant | `alice@univ.local` | `etudiant123` |
| Etudiant | `david@univ.local` | `etudiant123` |
| Comptable | `comptable@univ.local` | `comptable123` |
| Administration | `admin@univ.local` | `admin123` |

## Lancement

Installer les dependances :

```bash
flutter pub get
```

Lancer sur un emulateur Android ou un appareil mobile :

```bash
flutter run
```

Verifier le projet :

```bash
flutter analyze
flutter test
```

## Note technique

Le paiement en ligne est volontairement simule. Lorsqu'un etudiant choisit une methode, entre son numero et confirme le code affiche, l'application marque le frais comme paye, cree une reference `SIM-*`, masque le numero utilise, et enregistre le paiement dans SQLite local.
