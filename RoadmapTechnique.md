Roadmap Technique — Projet AutoConnect
1. Présentation

La roadmap technique d’AutoConnect définit l’ordre de développement des différents composants du système afin de garantir :

Une mise sur le marché rapide (MVP)
Une réduction des risques techniques
Une meilleure gestion des coûts
Une architecture évolutive
Une montée en charge progressive
2. Vision Générale

Le projet sera développé en 3 grandes étapes :

Phase 1 : MVP (Minimum Viable Product)

Objectif : lancer une première version fonctionnelle.

Phase 2 : Version Professionnelle

Objectif : stabiliser et enrichir la plateforme.

Phase 3 : Plateforme Nationale

Objectif : déploiement à grande échelle.

3. Phase 0 — Analyse & Conception
Durée estimée

3 semaines

Objectifs
Analyse métier
Étude du marché
Architecture logicielle
Maquettes UI/UX
Base de données
UML
Livrables
Cahier des charges
Diagrammes UML
Architecture système
Documentation API
Maquettes Figma/Galileo
4. Phase 1 — Mise en Place de l’Environnement
Durée estimée

1 semaine

Configuration Git
autoconnect/
├── backend/
├── mobile-passager/
├── mobile-chauffeur/
├── admin-dashboard/
└── docs/
Outils
Outil	Usage
GitHub	Gestion du code
Docker	Conteneurisation
Postman	Test API
Swagger	Documentation
VS Code	Développement
5. Phase 2 — Développement Backend Core
Durée estimée

4 semaines

Technologie
NestJS
PostgreSQL
Modules à développer
Auth Module

Fonctionnalités :

Inscription
Connexion
JWT
Refresh Token
Users Module
Gestion utilisateurs
Profils
Drivers Module
Chauffeurs
Vérification identité
Vehicles Module
Gestion véhicules
Stations Module
Gestion gares
Bookings Module
Réservations
Annulations
Livrable

API REST fonctionnelle.

6. Phase 3 — Application Mobile Passager
Durée estimée

5 semaines

Technologie

Flutter

Écrans
Splash Screen
Connexion
Inscription
Accueil
Recherche trajet
Réservation
Paiement
Historique
Profil
Fonctionnalités
Réservation
Recherche
Géolocalisation
Livrable

Version MVP Passager.

7. Phase 4 — Application Mobile Chauffeur
Durée estimée

4 semaines

Fonctionnalités
Disponibilité
Réservations reçues
Validation QR
Validation OTP
Revenus
Retraits
Livrable

Application Chauffeur MVP.

8. Phase 5 — Intégration Temps Réel
Durée estimée

2 semaines

Technologie

Socket.io

Fonctionnalités
Réservation instantanée
Passager réserve
→ Chauffeur reçoit immédiatement
Mise à jour GPS
Chauffeur se déplace
→ Client voit le déplacement
Notifications temps réel
Départ imminent
Chauffeur arrivé
Fin du trajet
Livrable

Communication temps réel complète.

9. Phase 6 — Paiement Mobile Money
Durée estimée

3 semaines

Services
Orange Money
MTN Money
Fonctionnalités
Paiement
Client
   ↓
Mobile Money
   ↓
Escrow
Vérification
Paiement réussi
Paiement échoué
Remboursement
Annulation
Litige
Livrable

Système financier sécurisé.

10. Phase 7 — Wallet & Retraits
Durée estimée

2 semaines

Modules
Wallet
Solde
Historique
Withdrawals
Retraits
Commission
Calcul automatique
Exemple
Trajet = 100 000 GNF

Retrait :

Commission = 10 000

Montant chauffeur = 90 000
Livrable

Gestion financière complète.

11. Phase 8 — Validation QR + OTP + GPS
Durée estimée

3 semaines

QR Code
Génération
Scan
OTP
Génération
Vérification
GPS
Vérification proximité
Workflow
Réservation
    ↓
Paiement
    ↓
QR + OTP
    ↓
GPS valide
    ↓
Début trajet
Livrable

Système anti-fraude opérationnel.

12. Phase 9 — Dashboard Administrateur
Durée estimée

3 semaines

Technologie

React.js + TypeScript

Fonctionnalités
Gestion utilisateurs
Passagers
Chauffeurs
Gestion paiements
Historique
Commissions
Gestion litiges
Réclamations
Statistiques
Revenus
Réservations
Livrable

Back-office complet.

13. Phase 10 — Assistant Vocal IA
Durée estimée

6 semaines

Technologies
Whisper
Coqui TTS
Langues
Français
Pular
Soussou
Malinké
Fonctionnalités
Commandes vocales

Exemples :

"Je veux aller à Labé"

"Réserver une voiture"

"Où est mon chauffeur ?"
Réponses vocales
"Votre réservation est confirmée."
Livrable

Assistant vocal intégré.

14. Phase 11 — Gestion du Fret
Durée estimée

4 semaines

Fonctionnalités
Création marchandises
Calcul automatique
Ticket numérique
Historique
Livrable

Module fret complet.

15. Phase 12 — Sécurité Avancée
Durée estimée

2 semaines

Implémentation
HTTPS
Rate Limiting
Validation DTO
Logs
Monitoring
Outils
Prometheus
Grafana
Sentry
Livrable

Plateforme sécurisée.

16. Phase 13 — Tests
Durée estimée

3 semaines

Tests Backend
Unit Tests
Integration Tests
Tests Mobile
UI Tests
Functional Tests
Tests Utilisateurs
Chauffeurs
Passagers
Livrable

Version stable.

17. Phase 14 — Déploiement Production
Durée estimée

2 semaines

Infrastructure
Internet
    │
    ▼
Nginx
    │
    ▼
NestJS
    │
 ┌──┼──────────┐
 ▼  ▼          ▼

Redis PostgreSQL Socket.io
Outils
Docker
GitHub Actions
Ubuntu Server
Livrable

Plateforme en production.

18. Évolutions Futures
Version 2
Réservation de bus
Réservation de motos
Version 3
IA prédictive
Recommandation automatique
Version 4
Expansion régionale

Pays ciblés :

Guinée
Sénégal
Mali
Côte d'Ivoire
19. Estimation Globale
Phase	Durée
Analyse & conception	3 semaines
Backend Core	4 semaines
Mobile Passager	5 semaines
Mobile Chauffeur	4 semaines
Temps réel	2 semaines
Paiement	3 semaines
Wallet	2 semaines
QR/OTP/GPS	3 semaines
Dashboard	3 semaines
IA vocale	6 semaines
Fret	4 semaines
Sécurité	2 semaines
Tests	3 semaines
Déploiement	2 semaines
Total estimé

43 semaines (environ 10 mois) pour une plateforme complète de niveau professionnel.

20. Priorités de Développement
MVP Prioritaire
Authentification
Réservation
Paiement
Chauffeur
GPS
Wallet
Version Professionnelle
Dashboard
QR/OTP
IA Vocale
Fret
Version Nationale
Analytics avancés
Intelligence artificielle
Multi-villes
Multi-pays
Conclusion

La roadmap technique d’AutoConnect suit une approche progressive permettant de construire d’abord un MVP solide, puis d’ajouter les fonctionnalités avancées comme le wallet, la validation QR/OTP/GPS, l’assistant vocal multilingue et la gestion du fret. Cette stratégie réduit les risques, accélère le lancement et prépare la plateforme à une croissance nationale puis régionale.