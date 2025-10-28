// lib/models/user_profile.dart
import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final int height;          // cm
  final int weight;          // kg
  final int shoulderWidth;   // cm
  final int waistline;       // cm
  final String fitPreference; // 'slim' | 'regular' | 'oversized'
  final List<String> colorBlacklist; // ["pink", "purple", ...]
  final bool hasMotorcycle;
  final String commuteMethod;       // 'public' | 'car' | 'walk'
  final Map<String, int> styleWeights; // { street: 34, outdoor: 33, office: 33 }
  final String gender;              // 'male' | 'female' | 'other'

  const UserProfile({
    required this.height,
    required this.weight,
    required this.shoulderWidth,
    required this.waistline,
    required this.fitPreference,
    required this.colorBlacklist,
    required this.hasMotorcycle,
    required this.commuteMethod,
    required this.styleWeights,
    required this.gender,
  });

  UserProfile copyWith({
    int? height,
    int? weight,
    int? shoulderWidth,
    int? waistline,
    String? fitPreference,
    List<String>? colorBlacklist,
    bool? hasMotorcycle,
    String? commuteMethod,
    Map<String, int>? styleWeights,
    String? gender,
  }) {
    return UserProfile(
      height: height ?? this.height,
      weight: weight ?? this.weight,
      shoulderWidth: shoulderWidth ?? this.shoulderWidth,
      waistline: waistline ?? this.waistline,
      fitPreference: fitPreference ?? this.fitPreference,
      colorBlacklist: colorBlacklist ?? List<String>.from(this.colorBlacklist),
      hasMotorcycle: hasMotorcycle ?? this.hasMotorcycle,
      commuteMethod: commuteMethod ?? this.commuteMethod,
      styleWeights: styleWeights ?? Map<String, int>.from(this.styleWeights),
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toJson() => {
        'height': height,
        'weight': weight,
        'shoulderWidth': shoulderWidth,
        'waistline': waistline,
        'fitPreference': fitPreference,
        'colorBlacklist': colorBlacklist,
        'hasMotorcycle': hasMotorcycle,
        'commuteMethod': commuteMethod,
        'styleWeights': styleWeights,
        'gender': gender,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        height: j['height'] ?? 0,
        weight: j['weight'] ?? 0,
        shoulderWidth: j['shoulderWidth'] ?? 0,
        waistline: j['waistline'] ?? 0,
        fitPreference: (j['fitPreference'] ?? 'regular') as String,
        colorBlacklist: (j['colorBlacklist'] as List?)?.cast<String>() ?? const [],
        hasMotorcycle: (j['hasMotorcycle'] ?? false) as bool,
        commuteMethod: (j['commuteMethod'] ?? 'public') as String,
        styleWeights:
            (j['styleWeights'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
                const {'street': 34, 'outdoor': 33, 'office': 33},
        gender: (j['gender'] ?? 'male') as String,
      );
}
