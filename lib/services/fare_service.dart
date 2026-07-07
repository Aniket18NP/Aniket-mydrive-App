class FareService {
  double bikeFare(double distanceKm) {
    return 40 + (distanceKm * 15);
  }

  double economyFare(double distanceKm) {
    return 80 + (distanceKm * 25);
  }

  double suvFare(double distanceKm) {
    return 150 + (distanceKm * 40);
  }
}