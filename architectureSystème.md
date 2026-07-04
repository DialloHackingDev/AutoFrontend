Architecture Système — Projet AutoConnect
1. Vue d’Ensemble

AutoConnect est une plateforme numérique de mobilité intelligente permettant de connecter :

Les passagers
Les chauffeurs
Les gares routières
Les administrateurs
Les services de paiement mobile
L’assistant vocal intelligent

L’architecture est conçue selon une approche modulaire, scalable, sécurisée et orientée services afin de supporter plusieurs milliers d’utilisateurs simultanés.

2. Architecture Générale
┌─────────────────────────────────────────────┐
│                 UTILISATEURS                │
├─────────────┬─────────────┬─────────────────┤
│ Passagers   │ Chauffeurs  │ Administrateurs │
└──────┬──────┴──────┬──────┴────────┬────────┘
       │             │               │
       ▼             ▼               ▼

┌─────────────────────────────────────────────┐
│      Applications Mobiles Flutter           │
└─────────────────────────────────────────────┘
                     │
                     ▼

┌─────────────────────────────────────────────┐
│             API Gateway NestJS              │
└─────────────────────────────────────────────┘
                     │
     ┌───────────────┼────────────────┐
     │               │                │
     ▼               ▼                ▼

┌──────────┐   ┌──────────┐   ┌──────────┐
│ Booking  │   │ Wallet   │   │ Payment  │
│ Service  │   │ Service  │   │ Service  │
└──────────┘   └──────────┘   └──────────┘

     │               │                │

     ▼               ▼                ▼

┌──────────┐   ┌──────────┐   ┌──────────┐
│ QR/OTP   │   │ GPS      │   │ Voice AI │
│ Service  │   │ Service  │   │ Service  │
└──────────┘   └──────────┘   └──────────┘

                     │
                     ▼

┌─────────────────────────────────────────────┐
│              PostgreSQL                     │
└─────────────────────────────────────────────┘

                     │
                     ▼

┌─────────────────────────────────────────────┐
│                  Redis                      │
└─────────────────────────────────────────────┘

                     │
                     ▼

┌─────────────────────────────────────────────┐
│               Socket.io                     │
└─────────────────────────────────────────────┘
3. Architecture Frontend
3.1 Application Passager
Technologie
Flutter
Fonctionnalités
Recherche de trajets
Réservation
Paiement
Suivi GPS
Historique
Assistant vocal
3.2 Application Chauffeur
Technologie
Flutter
Fonctionnalités
Gestion disponibilité
Validation QR
Validation OTP
Navigation GPS
Gestion revenus
Retrait d'argent
3.3 Dashboard Administrateur
Technologie
React.js
TypeScript
Fonctionnalités
Gestion utilisateurs
Gestion chauffeurs
Gestion paiements
Gestion litiges
Statistiques
4. Architecture Backend
Technologie Principale
NestJS

Pourquoi ?

Architecture modulaire
Sécurité élevée
Facilité de maintenance
Scalabilité
Structure des Modules
src/
│
├── auth
├── users
├── passengers
├── drivers
├── vehicles
├── stations
├── bookings
├── payments
├── wallet
├── withdrawals
├── escrow
├── qr
├── otp
├── gps
├── notifications
├── disputes
├── freight
├── analytics
├── voice-ai
└── admin
5. Architecture de Réservation
Flux de Réservation
Passager
    │
    ▼
Choix destination
    │
    ▼
Recherche véhicule
    │
    ▼
Réservation
    │
    ▼
Paiement
    │
    ▼
QR + OTP générés
    │
    ▼
Notification Chauffeur
6. Architecture de Validation du Trajet

AutoConnect utilise une validation hybride.

Technologies utilisées
QR Code

Permet d'identifier la réservation.

OTP

Permet de vérifier la présence réelle du passager.

GPS

Permet de vérifier que :

le passager est proche du chauffeur ;
le trajet est réellement effectué.
Workflow
Réservation
      │
      ▼
Paiement
      │
      ▼
QR généré
      │
      ▼
OTP généré
      │
      ▼
Validation GPS
      │
      ▼
Trajet démarré
      │
      ▼
Trajet terminé
      │
      ▼
Double validation
7. Architecture Financière
Principe

Le paiement ne va jamais directement au chauffeur.

Flux Financier
Passager
    │
    ▼
Orange Money / MTN Money
    │
    ▼
Escrow AutoConnect
    │
    ▼
Wallet Chauffeur
    │
    ▼
Retrait
    │
    ▼
Commission Plateforme
8. Architecture Wallet

Chaque chauffeur possède un portefeuille numérique.

Structure
Wallet

id
driver_id
balance
pending_balance
withdrawable_balance
created_at
updated_at
Exemple

Paiement :

100 000 GNF

Après trajet :

withdrawable_balance = 100000

Lors du retrait :

commission = 10000
montant_final = 90000
9. Architecture Temps Réel
Technologie

Socket.io

Utilisations
Position GPS
Réservations instantanées
Notifications
Disponibilité des véhicules
Événements
booking_created

driver_arrived

trip_started

trip_completed

wallet_updated

driver_online

driver_offline
10. Architecture GPS
Fonctionnement
Téléphone Chauffeur
         │
         ▼
Service GPS
         │
         ▼
Backend
         │
         ▼
Base de données
         │
         ▼
Application Passager
11. Architecture IA Vocale
Objectif

Permettre l'utilisation de l'application par les personnes :

âgées ;
analphabètes ;
peu habituées à la technologie.
Langues
Français
Pular
Soussou
Malinké
Pipeline IA
Voix utilisateur
        │
        ▼
Speech To Text
        │
        ▼
Analyse intention
        │
        ▼
Backend AutoConnect
        │
        ▼
Réponse IA
        │
        ▼
Text To Speech
        │
        ▼
Voix générée
12. Architecture de Gestion du Fret
Modules
Gestion des marchandises
Poids
Type
Destination
Calcul tarifaire

Calcul automatique basé sur :

poids ;
distance ;
type de marchandise.
Ticket numérique
Génération PDF
Historique
13. Architecture de Sécurité
Authentification
JWT
Refresh Token
Chiffrement
bcrypt
Communication
HTTPS
TLS
Protection API
Guards NestJS
Validation DTO
Rate Limiting
14. Architecture Base de Données
SGBD

PostgreSQL

Tables Principales
users
passengers
drivers
vehicles
stations
bookings
payments
wallets
withdrawals
gps_logs
notifications
disputes
freight
15. Architecture Cache
Technologie

Redis

Utilisation
Sessions
OTP
Cache GPS
Notifications
Temps réel
16. Architecture Offline First

Très importante pour la Guinée.

Fonctionnalités
Consultation hors ligne
Synchronisation automatique
Cache local
Technologies
SQLite
Hive
17. Architecture de Déploiement
Internet
    │
    ▼
Nginx
    │
    ▼
NestJS
    │
 ┌──┼───────────────┐
 │  │               │
 ▼  ▼               ▼

Redis PostgreSQL Socket.io
18. Monitoring
Outils
Prometheus
Grafana
Sentry
Winston
19. Évolution Future

L’architecture est préparée pour évoluer vers :

Microservices
Kubernetes
Multi-pays
IA avancée
Big Data Analytics
20. Conclusion

L’architecture système d’AutoConnect repose sur une structure moderne utilisant :

Flutter pour les applications mobiles ;
React.js pour les tableaux de bord ;
NestJS pour les APIs ;
PostgreSQL pour les données ;
Redis pour les performances ;
Socket.io pour le temps réel ;
QR + OTP + GPS pour la validation des trajets ;
Wallet + Escrow pour la gestion financière ;
IA vocale multilingue pour l’accessibilité.

Cette architecture permet d’obtenir une plateforme robuste, sécurisée, évolutive et adaptée au contexte du transport en Guinée et en Afrique de l’Ouest.