import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class ParsedLocationLink {
  final Uri uri;
  final double? latitude;
  final double? longitude;

  const ParsedLocationLink({
    required this.uri,
    required this.latitude,
    required this.longitude,
  });
}

class LocationLinkService {
  LocationLinkService._();
  static final LocationLinkService instance = LocationLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  Future<void> init({
    required void Function(ParsedLocationLink parsed) onLocationLink,
  }) async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial, onLocationLink);
      }
    } catch (e) {
      debugPrint('Deep link init error: $e');
    }

    _linkSub?.cancel();
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri, onLocationLink),
      onError: (error) {
        debugPrint('Deep link stream error: $error');
      },
    );
  }

  void dispose() {
    _linkSub?.cancel();
    _linkSub = null;
  }

  void _handleUri(
      Uri uri, void Function(ParsedLocationLink parsed) onLocationLink) {
    final parsed = _tryParseLocation(uri);
    if (parsed != null) {
      onLocationLink(parsed);
    }
  }

  ParsedLocationLink? _tryParseLocation(Uri uri) {
    final s = uri.toString();

    // geo:lat,lng
    if (uri.scheme == 'geo') {
      final geoPart = s.replaceFirst('geo:', '').split('?').first;
      final coords = _parsePair(geoPart);
      if (coords != null) {
        return ParsedLocationLink(
          uri: uri,
          latitude: coords.$1,
          longitude: coords.$2,
        );
      }
      return ParsedLocationLink(uri: uri, latitude: null, longitude: null);
    }

    // google.navigation:q=lat,lng
    if (uri.scheme == 'google.navigation') {
      final q = uri.queryParameters['q'];
      final coords = q != null ? _parsePair(q) : null;
      return ParsedLocationLink(
        uri: uri,
        latitude: coords?.$1,
        longitude: coords?.$2,
      );
    }

    // Google Maps links
    final host = uri.host.toLowerCase();
    final isMapsHost = host == 'maps.google.com' ||
        host == 'www.google.com' ||
        host == 'maps.app.goo.gl';

    if (!isMapsHost) return null;

    final q = uri.queryParameters['q'] ??
        uri.queryParameters['query'] ??
        uri.queryParameters['ll'] ??
        uri.queryParameters['daddr'] ??
        uri.queryParameters['saddr'];

    final coords = q != null ? _parsePair(q) : null;
    return ParsedLocationLink(
      uri: uri,
      latitude: coords?.$1,
      longitude: coords?.$2,
    );
  }

  (double, double)? _parsePair(String input) {
    final match =
        RegExp(r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)').firstMatch(input);
    if (match == null) return null;

    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;

    return (lat, lng);
  }
}
