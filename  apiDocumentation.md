Documentation API — AutoConnect
Version 1.0
1. Présentation

L'API AutoConnect est une API RESTful permettant la communication entre :

Application Mobile Passager
Application Mobile Chauffeur
Dashboard Administrateur
Dashboard Gare
Services de Paiement
Services GPS
Assistant Vocal IA
2. Informations Générales
URL de base
Développement
http://localhost:3000/api/v1
Production
https://api.autoconnect.gn/api/v1
Format des données

Toutes les requêtes et réponses utilisent :

Content-Type: application/json
3. Authentification
JWT Authentication

Toutes les routes protégées utilisent :

Authorization: Bearer <token>
4. Structure Standard des Réponses
Succès
{
  "success": true,
  "message": "Opération réussie",
  "data": {}
}
Erreur
{
  "success": false,
  "message": "Erreur",
  "error": "Description de l'erreur"
}
5. Module Authentification
Inscription
POST
/auth/register
Body
{
  "nom": "Ousmane Diallo",
  "telephone": "+224620000000",
  "motDePasse": "Password123",
  "role": "PASSAGER"
}
Réponse
{
  "success": true,
  "token": "jwt_token"
}
Connexion
POST
/auth/login
Body
{
  "telephone": "+224620000000",
  "motDePasse": "Password123"
}
Déconnexion
POST
/auth/logout
Rafraîchir le Token
POST
/auth/refresh
6. Module Utilisateurs
Profil utilisateur
GET
/users/profile
Modifier profil
PUT
/users/profile
Body
{
  "nom": "Nouveau Nom"
}
7. Module Chauffeurs
Créer un chauffeur
POST
/drivers
Body
{
  "numeroPermis": "GN-123456",
  "experience": 5
}
Liste des chauffeurs
GET
/drivers
Détails chauffeur
GET
/drivers/:id
Activer disponibilité
PATCH
/drivers/:id/availability
Body
{
  "available": true
}
8. Module Véhicules
Ajouter un véhicule
POST
/vehicles
Body
{
  "marque": "Toyota",
  "modele": "Corolla",
  "immatriculation": "RC-1234-GN",
  "capacite": 7
}
Liste véhicules
GET
/vehicles
Véhicules proches
GET
/vehicles/nearby
Paramètres
?latitude=11.318&longitude=-12.283
9. Module Réservations
Créer une réservation
POST
/bookings
Body
{
  "vehicleId": 12,
  "departure": "Conakry",
  "destination": "Labé",
  "places": 2
}
Liste des réservations
GET
/bookings
Détails réservation
GET
/bookings/:id
Annuler réservation
PATCH
/bookings/:id/cancel
États possibles
PENDING
CONFIRMED
PAID
BOARDING
IN_PROGRESS
COMPLETED
CANCELLED
DISPUTE
10. Module Paiements
Paiement Mobile Money
POST
/payments/mobile-money
Body
{
  "bookingId": 1,
  "operator": "ORANGE",
  "telephone": "+224620000000",
  "montant": 100000
}
Vérifier un paiement
GET
/payments/:id/status
Remboursement
POST
/payments/refund
Body
{
  "bookingId": 1,
  "motif": "Annulation chauffeur"
}
11. Module Wallet
Consulter portefeuille
GET
/wallet
Réponse
{
  "balance": 500000,
  "pendingBalance": 100000,
  "withdrawableBalance": 400000
}
Historique portefeuille
GET
/wallet/history
Retrait
POST
/wallet/withdraw
Body
{
  "montant": 200000,
  "operateur": "MTN"
}
12. Module Escrow
Bloquer fonds
POST
/escrow/hold
Libérer fonds
POST
/escrow/release
13. Module QR Code
Générer QR
POST
/qr/generate
Réponse
{
  "qrCode": "base64..."
}
Vérifier QR
POST
/qr/verify
Body
{
  "bookingId": 1,
  "qrData": "encryptedData"
}
14. Module OTP
Générer OTP
POST
/otp/generate
Vérifier OTP
POST
/otp/verify
Body
{
  "bookingId": 1,
  "otp": "1234"
}
15. Module GPS
Mettre à jour position
POST
/gps/update
Body
{
  "latitude": 11.318,
  "longitude": -12.283
}
Position d'un véhicule
GET
/gps/vehicle/:vehicleId
Historique GPS
GET
/gps/history/:vehicleId
16. Module Notifications
Notifications utilisateur
GET
/notifications
Marquer comme lu
PATCH
/notifications/:id/read
17. Module Litiges
Créer un litige
POST
/disputes
Body
{
  "bookingId": 1,
  "description": "Le chauffeur n'est jamais venu."
}
Liste des litiges
GET
/disputes
Résoudre un litige
PATCH
/disputes/:id/resolve
18. Module Assistant Vocal
Traitement vocal
POST
/voice/process
Body
{
  "audio": "base64_audio",
  "langue": "PULAR"
}
Réponse
{
  "intent": "RESERVER_TRAJET",
  "destination": "Labé"
}
Speech-to-Text
POST
/voice/stt
Text-to-Speech
POST
/voice/tts
19. Module Fret
Ajouter une marchandise
POST
/freight
Body
{
  "poids": 50,
  "destination": "Labé",
  "description": "Sacs de riz"
}
Calcul tarifaire
POST
/freight/calculate
Génération ticket
POST
/freight/ticket
20. Module Administrateur
Tableau de bord
GET
/admin/dashboard
Réponse
{
  "users": 5000,
  "drivers": 1200,
  "bookings": 30000,
  "revenue": 250000000
}
Vérifier un chauffeur
PATCH
/admin/drivers/:id/verify
Suspendre un utilisateur
PATCH
/admin/users/:id/suspend
21. WebSocket (Temps Réel)
URL
wss://api.autoconnect.gn/socket
Événements
Réservation créée
{
  "event": "booking_created"
}
Chauffeur arrivé
{
  "event": "driver_arrived"
}
Début trajet
{
  "event": "trip_started"
}
Fin trajet
{
  "event": "trip_completed"
}
Mise à jour GPS
{
  "event": "gps_updated"
}
Wallet mis à jour
{
  "event": "wallet_updated"
}
22. Documentation Swagger

L’API doit être documentée automatiquement avec Swagger.

URL
/api/docs

Exemple NestJS :

const config = new DocumentBuilder()
  .setTitle('AutoConnect API')
  .setDescription('Documentation officielle AutoConnect')
  .setVersion('1.0')
  .addBearerAuth()
  .build();
23. Versionnement

Toutes les routes doivent être versionnées :

/api/v1

Évolution future :

/api/v2
/api/v3
24. Sécurité

Mesures obligatoires :

JWT Authentication
Refresh Tokens
bcrypt
HTTPS/TLS
Validation DTO
Rate Limiting
Protection CSRF (Dashboard)
Journalisation des actions sensibles
Vérification QR + OTP + GPS avant validation d'un trajet
25. Conclusion

Cette documentation API couvre les principaux modules d’AutoConnect :

Authentification
Utilisateurs
Chauffeurs
Véhicules
Réservations
Paiements
Wallet
Escrow
QR Code
OTP
GPS
Notifications
Litiges
Assistant Vocal
Fret
Administration
Temps Réel (WebSocket)

Elle constitue une base solide pour implémenter le backend avec NestJS, PostgreSQL, Redis et Socket.io, tout en restant évolutive pour les futures versions de la plateforme.