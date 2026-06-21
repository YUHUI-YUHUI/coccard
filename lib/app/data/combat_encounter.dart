import 'dart:math';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum CombatStatus { ongoing, finished }

enum CombatantType { playerCharacter, npc }

enum CombatantStatus { unconscious, dying, fled, frightened, temporaryMadness, dead }

// ---------------------------------------------------------------------------
// Combatant
// ---------------------------------------------------------------------------

class Combatant {
  Combatant({
    required this.id,
    required this.name,
    required this.type,
    this.characterId,
    required this.dex,
    required this.maxHp,
    required this.currentHp,
    List<CombatantStatus>? statuses,
    this.damageTaken = 0,
    this.notes,
  }) : statuses = statuses ?? [];

  final String id;
  final String name;
  final CombatantType type;
  final String? characterId;
  final int dex;
  final int maxHp;
  int currentHp;
  final List<CombatantStatus> statuses;
  int damageTaken;
  String? notes;

  // ---- Getters ----

  bool get isAlive => currentHp > 0;

  bool get isUnconscious =>
      currentHp == 0 &&
      !statuses.contains(CombatantStatus.dying) &&
      !statuses.contains(CombatantStatus.dead);

  bool get isDying =>
      currentHp == 0 && statuses.contains(CombatantStatus.dying);

  // ---- Factory helpers ----

  static String generateId() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  // ---- JSON ----

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'characterId': characterId,
        'dex': dex,
        'maxHp': maxHp,
        'currentHp': currentHp,
        'statuses': statuses.map((s) => s.name).toList(),
        'damageTaken': damageTaken,
        'notes': notes,
      };

  factory Combatant.fromJson(Map<String, dynamic> json) => Combatant(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: CombatantType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CombatantType.npc,
        ),
        characterId: json['characterId'] as String?,
        dex: json['dex'] as int? ?? 0,
        maxHp: json['maxHp'] as int? ?? 0,
        currentHp: json['currentHp'] as int? ?? 0,
        statuses: (json['statuses'] as List<dynamic>?)
                ?.map((s) => CombatantStatus.values.firstWhere(
                      (e) => e.name == s,
                      orElse: () => CombatantStatus.unconscious,
                    ))
                .toList() ??
            [],
        damageTaken: json['damageTaken'] as int? ?? 0,
        notes: json['notes'] as String?,
      );
}

// ---------------------------------------------------------------------------
// CombatEncounter
// ---------------------------------------------------------------------------

class CombatEncounter {
  CombatEncounter({
    required this.id,
    required this.name,
    List<Combatant>? combatants,
    this.currentRound = 1,
    this.currentTurnIndex = 0,
    this.status = CombatStatus.ongoing,
    required this.createdAt,
    this.finishedAt,
  }) : combatants = combatants ?? [];

  final String id;
  final String name;
  final List<Combatant> combatants;
  int currentRound;
  int currentTurnIndex;
  CombatStatus status;
  final DateTime createdAt;
  DateTime? finishedAt;

  // ---- Getters ----

  /// Synonym for currentRound (alias kept for API consistency).
  int get totalRounds => currentRound;

  /// Sum of damageTaken across all combatants.
  int get totalDamageDealt =>
      combatants.fold<int>(0, (sum, c) => sum + c.damageTaken);

  // ---- JSON ----

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'combatants': combatants.map((c) => c.toJson()).toList(),
        'currentRound': currentRound,
        'currentTurnIndex': currentTurnIndex,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
      };

  factory CombatEncounter.fromJson(Map<String, dynamic> json) =>
      CombatEncounter(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        combatants: (json['combatants'] as List<dynamic>?)
                ?.map((c) => Combatant.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        currentRound: json['currentRound'] as int? ?? 1,
        currentTurnIndex: json['currentTurnIndex'] as int? ?? 0,
        status: CombatStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CombatStatus.ongoing,
        ),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        finishedAt: json['finishedAt'] != null
            ? DateTime.parse(json['finishedAt'] as String)
            : null,
      );
}
