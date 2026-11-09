import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/today/domain/models/today_dashboard_summary.dart';
import 'package:tapittrip/features/today/presentation/widgets/today_weather_card.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/widgets/trip_card.dart';
import 'package:tapittrip/features/weather/data/weather_repository.dart';
import 'package:tapittrip/features/weather/domain/models/daily_forecast.dart';
import 'package:tapittrip/features/weather/domain/models/trip_weather.dart';
import 'package:tapittrip/features/weather/domain/models/weather_condition.dart';
import 'package:tapittrip/features/weather/presentation/providers/weather_provider.dart';
import 'package:tapittrip/features/weather/presentation/widgets/trip_weather_view.dart';

class FakeWeatherApiClient extends ApiClient {
  FakeWeatherApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return getResponse;
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  group('Weather Models', () {
    test('WeatherCondition parses from JSON correctly', () {
      final json = {
        'temperature_c': 28.5,
        'temperature_f': 83.3,
        'feels_like_c': 31.0,
        'feels_like_f': 87.8,
        'condition': 'Partly Cloudy',
        'icon': 'partly_cloudy',
        'humidity': 72,
        'wind_kph': 14.5,
        'precipitation_probability': 15,
        'advisory': 'Warm and partly cloudy in Taguig. Ideal for outdoor walking.',
      };

      final condition = WeatherCondition.fromJson(json);

      expect(condition.temperatureC, 28.5);
      expect(condition.temperatureF, 83.3);
      expect(condition.tempString, '29°C');
      expect(condition.tempDualString, '29°C (83°F)');
      expect(condition.condition, 'Partly Cloudy');
      expect(condition.humidity, 72);
      expect(condition.precipitationProbability, 15);
      expect(condition.weatherIcon, Icons.cloud_queue_rounded);
    });

    test('DailyForecast parses from JSON correctly', () {
      final json = {
        'date': '2026-11-10',
        'day_name': 'Tue',
        'temp_max_c': 32.0,
        'temp_min_c': 24.0,
        'temp_max_f': 89.6,
        'temp_min_f': 75.2,
        'condition': 'Rain',
        'icon': 'rain',
        'precipitation_probability': 65,
      };

      final forecast = DailyForecast.fromJson(json);

      expect(forecast.date, '2026-11-10');
      expect(forecast.dayName, 'Tue');
      expect(forecast.rangeString, '24° / 32°C');
      expect(forecast.precipitationProbability, 65);
      expect(forecast.weatherIcon, Icons.water_drop_outlined);
    });

    test('TripWeather parses complete forecast structure', () {
      final json = {
        'destination': 'Taguig',
        'latitude': 14.55,
        'longitude': 121.05,
        'timezone': 'Asia/Manila',
        'current': {
          'temperature_c': 27.0,
          'temperature_f': 80.6,
          'condition': 'Sunny',
          'icon': 'sunny',
          'humidity': 65,
          'wind_kph': 10.0,
          'precipitation_probability': 5,
          'advisory': 'Sunny skies',
        },
        'forecast': [
          {
            'date': '2026-11-09',
            'day_name': 'Mon',
            'temp_max_c': 31.0,
            'temp_min_c': 23.0,
            'temp_max_f': 87.8,
            'temp_min_f': 73.4,
            'condition': 'Sunny',
            'icon': 'sunny',
            'precipitation_probability': 5,
          },
        ],
        'provider_attribution': 'Weather data provided by Open-Meteo',
      };

      final tripWeather = TripWeather.fromJson(json);

      expect(tripWeather.destination, 'Taguig');
      expect(tripWeather.latitude, 14.55);
      expect(tripWeather.current.condition, 'Sunny');
      expect(tripWeather.forecast.length, 1);
      expect(tripWeather.providerAttribution, contains('Open-Meteo'));
    });
  });

  group('TodayWeatherCard Widget', () {
    testWidgets('renders current temperature and advisory tip', (tester) async {
      const summary = TodayDashboardSummary(
        trip: Trip(
          id: 'test-trip-1',
          ownerId: 'user-1',
          title: 'BGC Taguig',
          planningMode: PlanningMode.guided,
        ),
        tripStatus: 'active',
        metrics: DashboardMetrics(
          totalActivities: 3,
          completedActivities: 1,
          progressPercentage: 33,
        ),
        timezone: 'Asia/Manila',
        weather: WeatherCondition(
          temperatureC: 28.0,
          temperatureF: 82.4,
          condition: 'Partly Cloudy',
          icon: 'partly_cloudy',
          feelsLikeC: 30.0,
          feelsLikeF: 86.0,
          humidity: 70,
          windKph: 12.0,
          precipitationProbability: 20,
          advisory: 'Great day for exploring High Street.',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TodayWeatherCard(summary: summary),
          ),
        ),
      );

      expect(find.text('28°C'), findsOneWidget);
      expect(find.text('Partly Cloudy'), findsOneWidget);
      expect(find.textContaining('Great day for exploring High Street'), findsOneWidget);
      expect(find.textContaining('70%'), findsOneWidget);
    });
  });

  group('TripWeatherView Widget', () {
    testWidgets('renders forecast days and destination climate', (tester) async {
      const mockTripWeather = TripWeather(
        destination: 'Taguig, PH',
        latitude: 14.55,
        longitude: 121.05,
        timezone: 'Asia/Manila',
        current: WeatherCondition(
          temperatureC: 29.0,
          temperatureF: 84.2,
          condition: 'Sunny',
          icon: 'sunny',
          feelsLikeC: 32.0,
          feelsLikeF: 89.6,
          humidity: 65,
          windKph: 10.0,
          precipitationProbability: 10,
          advisory: 'Clear skies across Taguig.',
        ),
        forecast: [
          DailyForecast(
            date: '2026-11-09',
            dayName: 'Mon',
            tempMaxC: 32.0,
            tempMinC: 24.0,
            tempMaxF: 89.6,
            tempMinF: 75.2,
            condition: 'Sunny',
            icon: 'sunny',
            precipitationProbability: 10,
          ),
          DailyForecast(
            date: '2026-11-10',
            dayName: 'Tue',
            tempMaxC: 31.0,
            tempMinC: 23.0,
            tempMaxF: 87.8,
            tempMinF: 73.4,
            condition: 'Rain',
            icon: 'rain',
            precipitationProbability: 60,
          ),
        ],
        providerAttribution: 'Weather data provided by Open-Meteo',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripWeatherProvider('test-trip-1').overrideWith(
              (ref) => Future.value(mockTripWeather),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TripWeatherView(tripId: 'test-trip-1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Taguig, PH'), findsOneWidget);
      expect(find.text('29°C'), findsOneWidget);
      expect(find.text('Sunny'), findsWidgets);
      expect(find.text('Forecast for Trip Days'), findsOneWidget);
      expect(find.textContaining('Weather Backup Ideas'), findsWidgets);
      expect(find.textContaining('Open-Meteo'), findsOneWidget);
    });
  });

  group('LiveWeatherTripCard Widget', () {
    testWidgets('renders weather badge automatically when provider emits', (tester) async {
      const trip = Trip(
        id: 'trip-bgc-1',
        ownerId: 'user-1',
        title: 'BGC Taguig',
        destinationCountry: 'Taguig',
        planningMode: PlanningMode.guided,
        tripType: 'solo',
      );

      const mockWeather = TripWeather(
        destination: 'Taguig',
        latitude: 14.55,
        longitude: 121.05,
        timezone: 'Asia/Manila',
        current: WeatherCondition(
          temperatureC: 28.0,
          temperatureF: 82.4,
          condition: 'Clear Sky',
          icon: 'sunny',
          humidity: 60,
          windKph: 9.0,
          precipitationProbability: 0,
          advisory: 'Sunny weather in Taguig',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripWeatherProvider('trip-bgc-1').overrideWith(
              (ref) => Future.value(mockWeather),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LiveWeatherTripCard(trip: trip),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('BGC Taguig'), findsOneWidget);
      expect(find.text('Taguig'), findsOneWidget);
      expect(find.text('28°C'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
    });
  });

  group('WeatherRepository Unit Tests', () {
    test('parses unwrapped API response correctly without type error', () async {
      final fakeApi = FakeWeatherApiClient()
        ..getResponse = {
          'destination': 'Taguig',
          'latitude': 14.55,
          'longitude': 121.05,
          'timezone': 'Asia/Manila',
          'current': {
            'temperature_c': 28.0,
            'temperature_f': 82.4,
            'condition': 'Clear Sky',
            'icon': 'sunny',
            'humidity': 60,
            'wind_kph': 10.0,
            'precipitation_probability': 0,
            'advisory': 'Warm and pleasant.',
          },
          'forecast': [],
          'provider_attribution': 'Live Weather',
        };

      final repo = WeatherRepository(apiClient: fakeApi);
      final weather = await repo.fetchTripWeather('trip-bgc-1');

      expect(weather.destination, 'Taguig');
      expect(weather.current.temperatureC, 28.0);
      expect(weather.current.condition, 'Clear Sky');
    });

    test('parses nested data wrapped API response correctly', () async {
      final fakeApi = FakeWeatherApiClient()
        ..getResponse = {
          'data': {
            'destination': 'Tokyo',
            'latitude': 35.67,
            'longitude': 139.65,
            'timezone': 'Asia/Tokyo',
            'current': {
              'temperature_c': 18.0,
              'temperature_f': 64.4,
              'condition': 'Sunny',
              'icon': 'sunny',
              'humidity': 45,
              'wind_kph': 8.0,
              'precipitation_probability': 0,
              'advisory': 'Pleasant day.',
            },
            'forecast': [],
            'provider_attribution': 'Live Weather',
          },
        };

      final repo = WeatherRepository(apiClient: fakeApi);
      final weather = await repo.fetchTripWeather('trip-tokyo-1');

      expect(weather.destination, 'Tokyo');
      expect(weather.current.temperatureC, 18.0);
    });
  });
}
