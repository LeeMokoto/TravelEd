import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;
import 'package:wonders/logic/data/itinerary_data.dart';
import 'package:wonders/logic/data/place_data.dart';
import 'package:wonders/logic/data/trip_data.dart';

/// Generates itineraries with Claude. The model returns *structured JSON* via a
/// forced tool call, which is what lets the app render the result as a designed
/// screen rather than a text blob.
///
/// The API key is provided at build time:
///   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
/// When the key is absent (or any call fails) the methods return null and the
/// caller falls back to [SampleItinerary].
class ItineraryService {
  static const String _endpoint = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-6';
  static const String _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const Duration _timeout = Duration(seconds: 60);

  bool get hasApiKey => _apiKey.isNotEmpty;

  static const List<String> _kinds = ['sight', 'food', 'stay', 'transit'];

  /// Generate a full itinerary for [trip]. Returns null on missing key, network
  /// failure, or an unparseable response.
  Future<Itinerary?> generate(Trip trip, List<Place> places, {required int dayCount, int nowMs = 0}) async {
    if (!hasApiKey) return null;
    final tool = _itineraryTool();
    final prompt = _buildPrompt(trip, places, dayCount);
    final input = await _callTool(tool, prompt);
    if (input == null) return null;
    try {
      final days = (input['days'] as List)
          .whereType<Map>()
          .map((m) => ItineraryDay.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      if (days.isEmpty) return null;
      return Itinerary(tripId: trip.id, days: days, generatedAtMs: nowMs);
    } catch (e) {
      dev.log('Itinerary parse failed: $e');
      return null;
    }
  }

  /// Regenerate a single day (the "Regenerate day with AI" action). Returns null
  /// on failure so the caller can fall back.
  Future<ItineraryDay?> regenerateDay(Trip trip, ItineraryDay current, List<Place> places) async {
    if (!hasApiKey) return null;
    final tool = _dayTool();
    final prompt = _buildDayPrompt(trip, current, places);
    final input = await _callTool(tool, prompt);
    if (input == null) return null;
    try {
      return ItineraryDay.fromJson(input);
    } catch (e) {
      dev.log('Day parse failed: $e');
      return null;
    }
  }

  /// POST to the Messages API forcing [tool], and return the tool_use input map.
  Future<Map<String, dynamic>?> _callTool(Map<String, dynamic> tool, String prompt) async {
    final body = jsonEncode({
      'model': _model,
      'max_tokens': 8000,
      'tools': [tool],
      'tool_choice': {'type': 'tool', 'name': tool['name']},
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    });
    try {
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: const {
              'content-type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': '2023-06-01',
              // Allow the call from a web build too.
              'anthropic-dangerous-direct-browser-access': 'true',
            },
            body: body,
          )
          .timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        dev.log('Anthropic call failed (${res.statusCode}): ${res.body}');
        return null;
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = decoded['content'] as List?;
      final toolUse = content?.whereType<Map>().firstWhere(
            (b) => b['type'] == 'tool_use',
            orElse: () => const {},
          );
      final input = toolUse?['input'];
      if (input is Map) return Map<String, dynamic>.from(input);
      return null;
    } catch (e) {
      dev.log('Anthropic request error: $e');
      return null;
    }
  }

  // --- Prompts ---------------------------------------------------------------

  String _buildPrompt(Trip trip, List<Place> places, int dayCount) {
    final b = StringBuffer()
      ..writeln('You are planning a $dayCount-day trip titled "${trip.title}".')
      ..writeln('Design a realistic, well-paced day-by-day itinerary.')
      ..writeln('Group the saved places below into days, add a few sensible extra '
          'stops (meals, a notable sight) where it helps the flow, give each a '
          'plausible time, and write a short, useful one-line note per activity.')
      ..writeln('Keep each activity\'s kind to one of: ${_kinds.join(', ')}.')
      ..writeln('When a saved place includes coordinates, carry its lat/lng through.')
      ..writeln('Return exactly $dayCount day(s).')
      ..writeln()
      ..writeln('Saved places (JSON):')
      ..writeln(jsonEncode(places.map(_placeForPrompt).toList()));
    return b.toString();
  }

  String _buildDayPrompt(Trip trip, ItineraryDay current, List<Place> places) {
    final b = StringBuffer()
      ..writeln('Re-plan day ${current.day} of the trip "${trip.title}".')
      ..writeln('Keep the same area ("${current.area}") and roughly the same set '
          'of places, but offer a fresh ordering, timing, and notes.')
      ..writeln('Keep each activity\'s kind to one of: ${_kinds.join(', ')}.')
      ..writeln()
      ..writeln('Current day (JSON):')
      ..writeln(jsonEncode(current.toJson()))
      ..writeln()
      ..writeln('Saved places available (JSON):')
      ..writeln(jsonEncode(places.map(_placeForPrompt).toList()));
    return b.toString();
  }

  Map<String, dynamic> _placeForPrompt(Place p) => {
        'name': p.name,
        'country': p.country,
        'kind': p.kind.name,
        if (p.note.isNotEmpty) 'note': p.note,
        if (p.hasLocation) 'lat': p.lat,
        if (p.hasLocation) 'lng': p.lng,
      };

  // --- Tool schemas ----------------------------------------------------------

  Map<String, dynamic> get _activitySchema => {
        'type': 'object',
        'properties': {
          'time': {'type': 'string', 'description': '24h time label, eg. 09:30'},
          'kind': {'type': 'string', 'enum': _kinds},
          'name': {'type': 'string'},
          'note': {'type': 'string', 'description': 'one short, useful line'},
          'lat': {'type': 'number'},
          'lng': {'type': 'number'},
        },
        'required': ['time', 'kind', 'name', 'note'],
      };

  Map<String, dynamic> get _daySchema => {
        'type': 'object',
        'properties': {
          'day': {'type': 'integer', 'description': '1-based day number'},
          'area': {'type': 'string', 'description': 'area or theme of the day'},
          'activities': {'type': 'array', 'items': _activitySchema},
        },
        'required': ['day', 'area', 'activities'],
      };

  Map<String, dynamic> _itineraryTool() => {
        'name': 'emit_itinerary',
        'description': 'Return the structured day-by-day itinerary.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'days': {'type': 'array', 'items': _daySchema},
          },
          'required': ['days'],
        },
      };

  Map<String, dynamic> _dayTool() => {
        'name': 'emit_day',
        'description': 'Return a single re-planned itinerary day.',
        'input_schema': _daySchema,
      };
}
