Cahier des Charges Technique
Projet : AutoConnect
Version 1.0
1. Présentation du Projet
1.1 Nom du projet

AutoConnect

1.2 Contexte

Le transport interurbain et urbain en Guinée repose principalement sur un système informel où les passagers doivent se déplacer physiquement dans les gares routières pour trouver un véhicule disponible.

Cette situation entraîne :

des temps d'attente importants ;
un manque de visibilité sur les départs ;
des pertes financières pour les chauffeurs ;
des conflits fréquents liés aux réservations ;
une absence de traçabilité des trajets ;
une faible accessibilité pour les personnes âgées ou analphabètes.

AutoConnect vise à moderniser ce secteur grâce à une plateforme numérique intelligente.

2. Objectifs du Projet
2.1 Objectif principal

Développer une plateforme numérique permettant de connecter :

les passagers ;
les chauffeurs ;
les gares routières ;

afin d'améliorer l'organisation, la réservation et la gestion du transport routier en Guinée.

2.2 Objectifs spécifiques
Réduire les temps d'attente.
Faciliter la réservation des trajets.
Optimiser le remplissage des véhicules.
Sécuriser les transactions financières.
Moderniser les gares routières.
Intégrer une assistance vocale multilingue.
Rendre le système accessible aux personnes non alphabétisées.
Permettre la gestion intelligente du fret.
3. Périmètre du Projet

Le système comprendra :

Application mobile Passager
Recherche de trajets
Réservation
Paiement
Suivi GPS
Assistant vocal
Application mobile Chauffeur
Gestion des disponibilités
Réception des réservations
Validation des passagers
Gestion des revenus
Tableau de bord Gare
Gestion des départs
Gestion du fret
Statistiques
Tableau de bord Administrateur
Gestion des utilisateurs
Gestion financière
Gestion des litiges
Statistiques globales
Assistant Vocal Intelligent
Français
Pular
Soussou
Malinké
4. Acteurs du Système
Acteur	Description
Passager	Réserve et effectue un trajet
Chauffeur	Transporte les passagers
Agent de Gare	Organise les départs
Administrateur	Supervise la plateforme
Assistant Vocal IA	Assiste les utilisateurs
5. Architecture Générale
Frontend Mobile
Flutter
Dashboard Web
React.js
TypeScript
Backend
NestJS
Node.js
Base de données
PostgreSQL
Cache
Redis
Temps réel
Socket.io
Paiement
Orange Money
MTN Money
6. Fonctionnalités Fonctionnelles
6.1 Module Passager
Gestion du compte
Inscription
Connexion
Déconnexion
Réinitialisation mot de passe
Réservation
Choisir une destination
Voir les véhicules disponibles
Réserver une place
Annuler une réservation
Paiement
Orange Money
MTN Money
Wallet AutoConnect
Suivi du trajet
Visualisation GPS
Heure estimée d'arrivée
Position du véhicule
Historique
Réservations passées
Reçus de paiement
6.2 Module Chauffeur
Gestion du profil
Informations personnelles
Documents administratifs
Gestion des trajets
Déclarer sa disponibilité
Accepter les réservations
Démarrer un trajet
Terminer un trajet
Revenus
Consultation des revenus
Consultation des retraits
Wallet
Solde disponible
Solde en attente
Historique financier
6.3 Module Validation Intelligente

Pour limiter les fraudes, chaque trajet doit être validé par :

QR Code

Chaque réservation génère un QR unique.

OTP

Un code OTP unique est généré pour chaque réservation.

GPS

Le système vérifie la proximité réelle entre :

passager ;
chauffeur.
Double validation

Validation par :

chauffeur ;
passager.
7. Gestion Financière
Principe

Le paiement passe obligatoirement par AutoConnect.

Processus
Le client paie.
Les fonds sont placés dans un compte séquestre (Escrow).
Le trajet est validé.
Les fonds sont transférés dans le portefeuille du chauffeur.
Le chauffeur demande un retrait.
La commission de la plateforme est prélevée lors du retrait.
Exemple

Montant du trajet :

100 000 GNF

Commission :

10 %

Résultat :

Chauffeur : 90 000 GNF
Plateforme : 10 000 GNF
8. Gestion des Annulations
Cas	Action
Annulation chauffeur	Remboursement intégral
Annulation client > 2h avant départ	Remboursement intégral
Annulation tardive	Remboursement partiel
Absence client	Aucun remboursement
9. Assistant Vocal Intelligent
Objectif

Permettre aux utilisateurs ne sachant pas lire ou écrire d'utiliser la plateforme.

Langues
Français
Pular
Soussou
Malinké
Fonctionnalités
Réservation vocale
Consultation des trajets
Confirmation des réservations
Assistance utilisateur
Exemple

Assistant :

« Où souhaitez-vous aller ? »

Utilisateur :

« Labé »

Assistant :

« Trois véhicules sont disponibles pour Labé. Souhaitez-vous réserver ? »

10. Gestion du Fret
Fonctionnalités
Pesée numérique
Mesure automatique du poids
Calcul tarifaire
Prix basé sur le poids
Ticket numérique
Génération de reçu
Historique
Historique des marchandises
Maintenance préventive
Analyse des charges transportées
11. Base de Données

Principales entités :

Utilisateurs
Chauffeurs
Véhicules
Réservations
Paiements
Wallets
Retraits
Fret
Gares
Notifications
Litiges
12. Sécurité
Authentification
JWT
Refresh Token
Protection des mots de passe
bcrypt
Protection API
Validation DTO
Guards NestJS
Rate Limiting
Sécurité transport
HTTPS
SSL/TLS
13. Fonctionnement Hors Ligne

L'application doit fonctionner même avec une connexion limitée.

Fonctionnalités Offline
Consultation des données récentes
Synchronisation automatique
Cache local

Technologies :

SQLite
Hive
14. Notifications
Types
Push Notification
Confirmation réservation
Départ imminent
Paiement confirmé
SMS
OTP
Alertes critiques
Vocal
Assistance IA
15. Performance
Critère	Valeur
Temps réponse API	< 2 secondes
Disponibilité	99 %
Temps réservation	< 30 secondes
Validation OTP	< 5 secondes
16. Déploiement
Infrastructure
VPS Linux Ubuntu
Docker
Nginx
Monitoring
Grafana
Prometheus
Sentry
CI/CD
GitHub Actions
17. Livrables
Applications
Application mobile Passager
Application mobile Chauffeur
Dashboard Gare
Dashboard Administrateur
Backend
API REST
WebSocket
Documentation
Cahier des charges
UML
Documentation API
Documentation technique
18. Planning Prévisionnel
Phase	Durée
Analyse & conception	3 semaines
Backend	6 semaines
Application mobile	8 semaines
Paiement & Wallet	4 semaines
IA vocale	6 semaines
Dashboard	4 semaines
Tests & sécurité	3 semaines
Déploiement	2 semaines

Durée totale estimée : 6 à 8 mois pour une première version professionnelle.

19. Évolutions Futures
Paiement international
Réservation de bus
Réservation de motos-taxis
Intelligence artificielle prédictive
Analyse nationale du trafic
Extension vers d'autres pays d'Afrique de l'Ouest
20. Conclusion

AutoConnect est une plateforme de mobilité intelligente conçue pour répondre aux réalités du transport en Guinée. Grâce à la combinaison de la réservation numérique, du paiement sécurisé, de la validation QR/OTP/GPS, de la gestion du fret et d’un assistant vocal multilingue, le système vise à moderniser durablement le secteur du transport tout en restant accessible à tous les profils d’utilisateurs.