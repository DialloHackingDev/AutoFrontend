/// Lieu proposé par la recherche (ville, quartier, gare…).
class Place {
  final String name;

  /// Contexte affiché sous le nom (région, ville…)
  final String subtitle;
  final double latitude;
  final double longitude;

  const Place({
    required this.name,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });
}

/// Principales villes de Guinée, intégrées à l'app pour que la recherche
/// propose des suggestions même sans connexion.
/// Coordonnées approximatives (centre-ville), suffisantes pour centrer la carte.
const List<Place> guineaPlaces = [
  // Conakry et ses communes
  Place(name: 'Conakry', subtitle: 'Conakry', latitude: 9.5370, longitude: -13.6773),
  Place(name: 'Kaloum', subtitle: 'Conakry', latitude: 9.5092, longitude: -13.7122),
  Place(name: 'Dixinn', subtitle: 'Conakry', latitude: 9.5450, longitude: -13.6800),
  Place(name: 'Matam', subtitle: 'Conakry', latitude: 9.5580, longitude: -13.6600),
  Place(name: 'Ratoma', subtitle: 'Conakry', latitude: 9.6190, longitude: -13.6250),
  Place(name: 'Matoto', subtitle: 'Conakry', latitude: 9.5870, longitude: -13.6100),
  Place(name: 'Bambéto', subtitle: 'Ratoma, Conakry', latitude: 9.6000, longitude: -13.6500),
  // Basse-Guinée
  Place(name: 'Coyah', subtitle: 'Kindia', latitude: 9.7090, longitude: -13.3840),
  Place(name: 'Dubréka', subtitle: 'Kindia', latitude: 9.7900, longitude: -13.5230),
  Place(name: 'Forécariah', subtitle: 'Kindia', latitude: 9.4300, longitude: -13.0880),
  Place(name: 'Kindia', subtitle: 'Kindia', latitude: 10.0570, longitude: -12.8650),
  Place(name: 'Télimélé', subtitle: 'Kindia', latitude: 10.9050, longitude: -13.0430),
  Place(name: 'Boké', subtitle: 'Boké', latitude: 10.9400, longitude: -14.2900),
  Place(name: 'Kamsar', subtitle: 'Boké', latitude: 10.6500, longitude: -14.6000),
  Place(name: 'Boffa', subtitle: 'Boké', latitude: 10.1800, longitude: -14.0390),
  Place(name: 'Fria', subtitle: 'Boké', latitude: 10.3670, longitude: -13.5830),
  Place(name: 'Gaoual', subtitle: 'Boké', latitude: 11.7540, longitude: -13.2000),
  Place(name: 'Koundara', subtitle: 'Boké', latitude: 12.4800, longitude: -13.3060),
  // Moyenne-Guinée
  Place(name: 'Mamou', subtitle: 'Mamou', latitude: 10.3750, longitude: -12.0910),
  Place(name: 'Dalaba', subtitle: 'Mamou', latitude: 10.6860, longitude: -12.2500),
  Place(name: 'Pita', subtitle: 'Mamou', latitude: 11.0590, longitude: -12.3960),
  Place(name: 'Labé', subtitle: 'Labé', latitude: 11.3180, longitude: -12.2830),
  Place(name: 'Lélouma', subtitle: 'Labé', latitude: 11.4300, longitude: -12.5000),
  Place(name: 'Mali', subtitle: 'Labé', latitude: 12.0800, longitude: -12.3000),
  Place(name: 'Koubia', subtitle: 'Labé', latitude: 11.5800, longitude: -11.8900),
  Place(name: 'Tougué', subtitle: 'Labé', latitude: 11.4460, longitude: -11.6640),
  // Haute-Guinée
  Place(name: 'Faranah', subtitle: 'Faranah', latitude: 10.0400, longitude: -10.7430),
  Place(name: 'Dabola', subtitle: 'Faranah', latitude: 10.7500, longitude: -11.1170),
  Place(name: 'Dinguiraye', subtitle: 'Faranah', latitude: 11.3000, longitude: -10.7170),
  Place(name: 'Kissidougou', subtitle: 'Faranah', latitude: 9.1850, longitude: -10.0990),
  Place(name: 'Kankan', subtitle: 'Kankan', latitude: 10.3850, longitude: -9.3060),
  Place(name: 'Kérouané', subtitle: 'Kankan', latitude: 9.2700, longitude: -9.0170),
  Place(name: 'Kouroussa', subtitle: 'Kankan', latitude: 10.6530, longitude: -9.8830),
  Place(name: 'Mandiana', subtitle: 'Kankan', latitude: 10.6170, longitude: -8.6830),
  Place(name: 'Siguiri', subtitle: 'Kankan', latitude: 11.4200, longitude: -9.1700),
  // Guinée forestière
  Place(name: 'Nzérékoré', subtitle: 'Nzérékoré', latitude: 7.7560, longitude: -8.8180),
  Place(name: 'Beyla', subtitle: 'Nzérékoré', latitude: 8.6870, longitude: -8.6570),
  Place(name: 'Guéckédou', subtitle: 'Nzérékoré', latitude: 8.5670, longitude: -10.1330),
  Place(name: 'Lola', subtitle: 'Nzérékoré', latitude: 7.8000, longitude: -8.5330),
  Place(name: 'Macenta', subtitle: 'Nzérékoré', latitude: 8.5430, longitude: -9.4720),
  Place(name: 'Yomou', subtitle: 'Nzérékoré', latitude: 7.5690, longitude: -9.2530),
];
