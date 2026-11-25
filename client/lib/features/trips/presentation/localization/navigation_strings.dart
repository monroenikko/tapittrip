import 'package:flutter/widgets.dart';

class NavigationStrings {
  const NavigationStrings(this.locale);
  final Locale locale;
  bool get _fil => ['fil', 'tl'].contains(locale.languageCode);

  String get home => _fil ? 'Home' : 'Home';
  String get itinerary => _fil ? 'Itinerary' : 'Itinerary';
  String get bookings => _fil ? 'Mga booking' : 'Bookings';
  String get profile => _fil ? 'Profile' : 'Profile';
  String get chooseTrip => _fil ? 'Pumili ng biyahe' : 'Choose a trip';
  String get itineraryHelp => _fil
      ? 'Buksan ang itinerary ng biyahe para makita o idagdag ang mga aktibidad.'
      : 'Open a trip to view or plan its activities.';
  String get savedAccommodation =>
      _fil ? 'Naka-save na tutuluyan' : 'Saved accommodation';
  String get bookingsHelp => _fil
      ? 'Tingnan ang naka-save na tutuluyan sa bawat biyahe.'
      : 'View saved accommodation for each trip.';
  String get noTrips => _fil ? 'Wala pang biyahe' : 'No trips yet';
  String get noTripsHelp => _fil
      ? 'Magdagdag ng biyahe para maisaayos ang itinerary at tutuluyan. Opsyonal ang mga aktibidad.'
      : 'Add a trip to organize itineraries and accommodation. Activities are optional.';
  String get addTrip => _fil ? 'Magdagdag ng biyahe' : 'Add Trip';
  String get tripError =>
      _fil ? 'Hindi ma-load ang mga biyahe.' : 'Unable to load trips.';
  String get stayError => _fil
      ? 'Hindi ma-load ang tutuluyan sa biyaheng ito.'
      : 'Unable to load accommodation for this trip.';
  String get retry => _fil ? 'Subukang muli' : 'Retry';
  String get noStays => _fil
      ? 'Wala pang naka-save na tutuluyan.'
      : 'No accommodation saved yet.';
  String get manageStays =>
      _fil ? 'Buksan ang mga tutuluyan' : 'Manage accommodation';
  String get openItinerary => _fil ? 'Buksan ang itinerary' : 'Open itinerary';
  String get openStays => _fil
      ? 'Buksan ang mga detalye ng tutuluyan'
      : 'Open accommodation details';
}
