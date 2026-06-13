# Documentation du projet

## 1. Presentation generale

Cette application est une plateforme de gestion des frais academiques developpee en Flutter.
Elle permet de gerer:

- les etudiants
- les frais academiques
- les paiements
- les recus PDF
- les tableaux de bord selon le role de l utilisateur

La base de donnees principale est locale avec SQLite, et l application peut fonctionner sur mobile, desktop et web.

## 2. Architecture fonctionnelle

L application se compose de plusieurs espaces selon le role:

- espace Etudiant
- espace Tresorerie
- espace Administrateur Budget
- espace Direction Generale

Au demarrage:

1. l application initialise la base de donnees
2. elle affiche un ecran de chargement
3. elle demande ensuite une connexion
4. apres authentification, elle redirige vers l interface du role

## 3. Comptes de connexion par defaut

Les comptes ci-dessous sont les comptes de test presentes dans la base locale.

### Administrateur general

- Email: `admin@univ.local`
- Mot de passe: `admin123`
- Role: `dg`
- Interface: Direction Generale

### Administrateur budget

- Email: `budget@univ.local`
- Mot de passe: `budget123`
- Role: `budget_admin`
- Interface: Budget

### Tresorerie / Comptable

- Email: `tresorerie@univ.local`
- Mot de passe: `comptable123`
- Role: `accountant`
- Interface: Tresorerie

### Etudiants de demonstration

- Email: `alice@univ.local`
- Mot de passe: `etudiant123`
- Role: `student`

- Email: `david@univ.local`
- Mot de passe: `etudiant123`
- Role: `student`

## 4. Roles et permissions

### 4.1 Etudiant

L etudiant peut:

- consulter ses frais
- consulter ses paiements
- effectuer un paiement
- telecharger un recu PDF
- voir sa situation academique et financiere

### 4.2 Tresorerie

Le role `accountant` permet de:

- voir les etudiants
- gerer les frais
- suivre les paiements
- verifier les situations financieres
- generer ou consulter les donnees de suivi

### 4.3 Administrateur budget

Le role `budget_admin` permet de:

- gerer les etudiants
- gerer les frais
- suivre les promotions et les niveaux
- voir les tableaux de synthese budgetaire

### 4.4 Direction Generale

Le role `dg` permet de:

- consulter les statistiques globales
- voir les promotions
- suivre les paiements et les impayes
- acceder a une vue de pilotage generale

## 5. Creation d un compte etudiant

Les etudiants ne se connectent pas directement avec un compte cree librement par n importe qui.
Le processus normal est le suivant:

1. L administration cree d abord une preinscription etudiant.
2. L etudiant ouvre la page d inscription.
3. Il saisit exactement le nom complet enregistre par l administration.
4. L application verifie que le nom existe et que l inscription n a pas encore ete validee.
5. L etudiant ajoute ensuite:
   - son adresse email
   - son mot de passe
6. Le compte est active.

### Points importants

- Le nom complet doit correspondre exactement a ce qui est enregistre.
- Si l email est deja utilise, l inscription est refusee.
- Une fois valide, l etudiant peut se connecter avec son email et son mot de passe.

## 6. Connexion

L ecran de connexion demande:

- email
- mot de passe

Apres connexion:

- si le role est `student`, l application ouvre l interface etudiant
- si le role est `accountant`, elle ouvre l espace tresorerie
- si le role est `budget_admin`, elle ouvre l espace budget
- si le role est `dg`, elle ouvre l espace direction

## 7. Paiement des frais

Le paiement Mobile Money utilise Shwary.

### Fonctionnement

1. L etudiant saisit son numero Mobile Money.
2. L application normalise le numero au format RDC.
3. Elle envoie une demande de paiement a Shwary.
4. Shwary retourne souvent un statut `pending` au debut.
5. Ce statut signifie que la transaction est creee et en attente de validation.

### Important

- Un statut `pending` n est pas un echec.
- Le paiement peut etre considere comme initie avec succes.
- La validation finale peut arriver ensuite selon le traitement Shwary.

## 8. Mode de stockage

L application utilise:

- SQLite local pour les donnees internes
- une configuration web compatible avec `sqflite_common_ffi_web`

Les donnees de demonstration sont ajoutees automatiquement au premier lancement.

## 9. Fichiers importants

- `lib/main.dart`: point d entree de l application
- `lib/database/app_database.dart`: base de donnees et donnees de demonstration
- `lib/models/user.dart`: roles et mapping des utilisateurs
- `lib/services/payment_api_service.dart`: orchestration du paiement
- `lib/services/shwary_service.dart`: appel Shwary
- `lib/services/shwary_config.dart`: configuration Shwary
- `lib/screens/auth/login_screen.dart`: ecran de connexion
- `lib/screens/auth/register_screen.dart`: inscription etudiant
- `lib/screens/student/student_home.dart`: tableau de bord etudiant
- `lib/screens/accountant/accountant_home.dart`: tresorerie
- `lib/screens/budget/budget_admin_home.dart`: budget
- `lib/screens/direction/dg_home.dart`: direction generale

## 10. Lancement du projet

### Sur mobile Android

```bash
flutter run
```

### Pour generer la version web

```bash
flutter build web --release
```

## 11. Notes pour la personne qui reprend le projet

- Ne pas ajouter le dossier `build/` dans GitHub.
- Les identifiants de test sont en base locale.
- Le paiement Shwary doit etre teste avec un numero Mobile Money RDC valide.
- Si un compte marchand est modifie, mettre a jour la configuration `ShwaryConfig`.

## 12. Recommandations

- Garder cette documentation a jour si un role change.
- Si la base de donnees seed change, actualiser les identifiants de test.
- Ne pas partager publiquement les cles marchandes Shwary.
