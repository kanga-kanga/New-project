# 📘 Guide d'Utilisation - Gestion des Frais Académiques

Ce guide explique les étapes pour gérer les étudiants, les frais et les paiements dans l'application.

---

## 🔐 1. Comptes de Test par Défaut
Voici les identifiants pré-configurés pour tester les différents rôles :

| Rôle | Email | Mot de Passe |
| :--- | :--- | :--- |
| **Administrateur** | `admin@univ.local` | `admin123` |
| **Comptable** | `comptable@univ.local` | `comptable123` |
| **Étudiant (Exemple)** | `alice@univ.local` | `etudiant123` |

---

## 🛠️ 2. Actions de l'Administrateur
L'administrateur gère les inscriptions.

### Ajouter un Étudiant
1. Connectez-vous avec le compte **Administrateur**.
2. Sur l'écran principal, cliquez sur le bouton bleu **[+ Nouvel Étudiant]** en bas à droite.
3. Remplissez le formulaire :
   - Nom complet, Email, Mot de passe.
   - Matricule (ex: ETU-2026-005).
   - Filière et **Niveau** (important pour l'attribution des frais).
4. Cliquez sur **Enregistrer**. L'étudiant peut maintenant se connecter.

---

## 💰 3. Actions du Comptable
Le comptable gère les finances et la création des frais.

### Créer des Frais pour un Niveau
1. Connectez-vous avec le compte **Comptable**.
2. Cliquez sur le bouton **[Nouveau Frais]** en bas à droite.
3. Remplissez les informations :
   - **Niveau Concerné** : Sélectionnez par exemple *Licence 1*.
   - **Libellé** : Le nom du frais (ex: Tranche 1).
   - **Montant** : Le prix en USD.
   - **Échéance** : La date limite de paiement.
4. Cliquez sur **Générer les Frais**. Tous les étudiants du niveau sélectionné recevront ce frais dans leur espace personnel.

---

## 🎓 4. Actions de l'Étudiant
L'étudiant consulte et paie ses frais.

### Se Connecter et Payer
1. Connectez-vous avec un compte **Étudiant** (créé par l'admin).
2. Sur l'accueil, vous verrez :
   - Une barre de progression de vos paiements.
   - La liste des **Frais à payer**.
3. Cliquez sur un frais dans la liste pour initier le paiement.
4. Une simulation de paiement s'ouvre :
   - Choisissez une méthode (Mobile Money, Carte, etc.).
   - Saisissez un numéro de compte/téléphone fictif.
   - Validez.
5. Une fois le paiement réussi, le reçu est généré et le frais disparaît de la liste "à payer" pour aller dans l'**Historique**.

### Consulter les Reçus
- Allez dans la section **Historique des paiements**.
- Cliquez sur une transaction pour afficher et télécharger le reçu officiel.

---

## 📊 5. Suivi des Paiements (Admin & Comptable)
- **Admin** : Peut voir la liste des étudiants avec un indicateur visuel (Vert: en ordre, Rouge: retard de paiement).
- **Comptable** : Voit le total des recettes perçues et la liste chronologique de toutes les transactions effectuées sur l'application.
