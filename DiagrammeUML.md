Diagramme UML — Projet AutoConnect

Pour un projet de cette taille, le diagramme UML doit être composé de plusieurs diagrammes. Le plus important pour commencer est le Diagramme de Cas d'Utilisation (Use Case) et le Diagramme de Classes.

1. Diagramme de Cas d'Utilisation (Use Case)
                    +----------------------------------+
                    |         AutoConnect             |
                    +----------------------------------+

  Passager
      |
      |--------------------------+
      |                          |
      v                          v
+----------------+      +------------------+
| S'inscrire     |      | Se connecter     |
+----------------+      +------------------+

      |
      v
+--------------------------+
| Rechercher un trajet     |
+--------------------------+
      |
      v
+--------------------------+
| Réserver un trajet       |
+--------------------------+
      |
      v
+--------------------------+
| Payer le trajet          |
+--------------------------+
      |
      v
+--------------------------+
| Recevoir QR + OTP        |
+--------------------------+
      |
      v
+--------------------------+
| Suivre le véhicule GPS   |
+--------------------------+
      |
      v
+--------------------------+
| Confirmer le trajet      |
+--------------------------+

-----------------------------------------------------

 Chauffeur

      |
      v
+--------------------------+
| Se connecter             |
+--------------------------+
      |
      v
+--------------------------+
| Déclarer disponibilité   |
+--------------------------+
      |
      v
+--------------------------+
| Recevoir réservation     |
+--------------------------+
      |
      v
+--------------------------+
| Scanner QR               |
+--------------------------+
      |
      v
+--------------------------+
| Vérifier OTP             |
+--------------------------+
      |
      v
+--------------------------+
| Démarrer trajet          |
+--------------------------+
      |
      v
+--------------------------+
| Terminer trajet          |
+--------------------------+
      |
      v
+--------------------------+
| Demander retrait         |
+--------------------------+

-----------------------------------------------------

 Administrateur

      |
      +--------------------------+
      |                          |
      v                          v

+----------------------+   +----------------------+
| Gérer utilisateurs   |   | Gérer chauffeurs     |
+----------------------+   +----------------------+

+----------------------+
| Gérer paiements      |
+----------------------+

+----------------------+
| Gérer litiges        |
+----------------------+

+----------------------+
| Consulter statistiques|
+----------------------+

-----------------------------------------------------

 Agent de Gare

      |
      v

+----------------------+
| Gérer départs        |
+----------------------+

+----------------------+
| Gérer fret           |
+----------------------+

+----------------------+
| Vérifier chargement  |
+----------------------+

-----------------------------------------------------

 Assistant Vocal IA

      |
      v

+----------------------+
| Comprendre la voix   |
+----------------------+

+----------------------+
| Réserver vocalement  |
+----------------------+

+----------------------+
| Répondre vocalement  |
+----------------------+
2. Diagramme de Classes UML
+------------------------------------------------+
|                    User                        |
+------------------------------------------------+
| id : UUID                                      |
| nom : String                                   |
| téléphone : String                             |
| motDePasse : String                            |
| rôle : Role                                    |
| langue : Langue                               |
| crééLe : DateTime                             |
+------------------------------------------------+

                ▲
                |
      -----------------------
      |                     |
      |                     |

+----------------+    +----------------+
| Passager       |    | Chauffeur      |
+----------------+    +----------------+
| adresse        |    | permis         |
|                |    | note           |
+----------------+    +----------------+

                         |
                         | 1
                         |
                         | possède
                         |
                         *
+--------------------------------------+
|              Véhicule                |
+--------------------------------------+
| id                                   |
| immatriculation                      |
| type                                 |
| capacité                             |
| statut                               |
+--------------------------------------+

----------------------------------------------------

+--------------------------------------+
|             Réservation              |
+--------------------------------------+
| id                                   |
| départ                               |
| destination                          |
| prix                                 |
| statut                               |
| qrCode                               |
| otpCode                              |
| dateCréation                         |
+--------------------------------------+

Passager 1 ----- * Réservation

Chauffeur 1 ----- * Réservation

----------------------------------------------------

+--------------------------------------+
|               Paiement               |
+--------------------------------------+
| id                                   |
| montant                              |
| méthode                              |
| statut                               |
| transactionId                        |
+--------------------------------------+

Réservation 1 ----- 1 Paiement

----------------------------------------------------

+--------------------------------------+
|                Wallet                |
+--------------------------------------+
| id                                   |
| balance                              |
| pendingBalance                       |
| withdrawableBalance                  |
+--------------------------------------+

Chauffeur 1 ----- 1 Wallet

----------------------------------------------------

+--------------------------------------+
|              Retrait                 |
+--------------------------------------+
| id                                   |
| montant                              |
| commission                           |
| statut                               |
| date                                 |
+--------------------------------------+

Wallet 1 ----- * Retrait

----------------------------------------------------

+--------------------------------------+
|               Gare                   |
+--------------------------------------+
| id                                   |
| nom                                  |
| ville                                |
| adresse                              |
+--------------------------------------+

----------------------------------------------------

+--------------------------------------+
|                Fret                  |
+--------------------------------------+
| id                                   |
| poids                                |
| tarif                                |
| destination                          |
+--------------------------------------+

----------------------------------------------------

+--------------------------------------+
|              Notification            |
+--------------------------------------+
| id                                   |
| type                                 |
| message                              |
| lu                                   |
+--------------------------------------+

----------------------------------------------------

+--------------------------------------+
|                Litige                |
+--------------------------------------+
| id                                   |
| description                          |
| statut                               |
| date                                 |
+--------------------------------------+
3. Diagramme d'État (Réservation)
[PENDING]
     |
     v
[CONFIRMED]
     |
     v
[PAID]
     |
     v
[QR + OTP GENERATED]
     |
     v
[BOARDING]
     |
     v
[IN_PROGRESS]
     |
     v
[COMPLETED]
     |
     v
[FUNDS_RELEASED]
     |
     v
[WITHDRAWABLE]
États alternatifs
[PAID] ------------> [CANCELLED]

[BOARDING] --------> [DISPUTE]

[IN_PROGRESS] -----> [INCIDENT]
4. Diagramme de Séquence (Réservation + Paiement + Validation)
Passager
    |
    | Réserver
    v

Application Mobile
    |
    | API Booking
    v

Backend NestJS
    |
    | Vérifier disponibilité
    v

Base de données

-----------------------------

Backend
    |
    | Créer réservation
    |
    | Générer QR
    |
    | Générer OTP
    |
    | Paiement
    v

Service Paiement

-----------------------------

Paiement validé

    |
    v

Wallet Escrow

-----------------------------

Jour du voyage

Passager
    |
    | QR + OTP
    v

Chauffeur

    |
    | Validation GPS
    v

Backend

    |
    | Trajet démarré
    v

IN_PROGRESS

    |
    | Confirmation chauffeur
    | Confirmation passager
    v

COMPLETED

    |
    | Crédit Wallet Chauffeur
    v

Retrait Chauffeur

    |
    | Commission AutoConnect
    v

Mobile Money
Diagrammes UML à produire pour le dossier final
✅ Diagramme de Cas d’Utilisation
✅ Diagramme de Classes
✅ Diagramme de Séquence
✅ Diagramme d’État
⏳ Diagramme d’Activité
⏳ Diagramme de Déploiement
⏳ Diagramme d’Architecture Logicielle

Pour un dossier professionnel (université, client ou investisseur), je te recommande ensuite de réaliser ces diagrammes visuellement avec Draw.io (diagrams.net), StarUML ou Visual Paradigm.