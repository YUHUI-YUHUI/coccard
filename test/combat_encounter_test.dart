import 'package:flutter_test/flutter_test.dart';
import 'package:coc_character/app/data/combat_encounter.dart';

void main() {
  // -----------------------------------------------------------------------
  // 1. CombatEncounter creation defaults
  // -----------------------------------------------------------------------
  test('CombatEncounter creation defaults: currentRound=1, status=ongoing',
      () {
    final encounter = CombatEncounter(
      id: 'enc-1',
      name: 'Test Encounter',
      createdAt: DateTime(2026, 6, 21),
    );

    expect(encounter.currentRound, 1);
    expect(encounter.status, CombatStatus.ongoing);
    expect(encounter.combatants, isEmpty);
    expect(encounter.currentTurnIndex, 0);
    expect(encounter.finishedAt, isNull);
    expect(encounter.totalRounds, 1);
  });

  // -----------------------------------------------------------------------
  // 2. Combatant HP=0 → isAlive=false, isUnconscious=true
  // -----------------------------------------------------------------------
  test('Combatant HP=0 without dying/dead status → isUnconscious=true', () {
    final combatant = Combatant(
      id: 'c1',
      name: 'NPC Guard',
      type: CombatantType.npc,
      dex: 60,
      maxHp: 12,
      currentHp: 0,
      statuses: [],
    );

    expect(combatant.isAlive, false);
    expect(combatant.isUnconscious, true);
    expect(combatant.isDying, false);
  });

  // -----------------------------------------------------------------------
  // 3. Combatant HP=0 + dying status → isDying=true
  // -----------------------------------------------------------------------
  test('Combatant HP=0 with dying status → isDying=true', () {
    final combatant = Combatant(
      id: 'c2',
      name: 'Investigator',
      type: CombatantType.playerCharacter,
      dex: 55,
      maxHp: 10,
      currentHp: 0,
      statuses: [CombatantStatus.dying],
    );

    expect(combatant.isAlive, false);
    expect(combatant.isUnconscious, false);
    expect(combatant.isDying, true);
  });

  // -----------------------------------------------------------------------
  // 4. Sort by DEX descending
  // -----------------------------------------------------------------------
  test('Combatants sort by DEX descending', () {
    final combatants = [
      Combatant(
          id: 'c1', name: 'Slow', type: CombatantType.npc, dex: 30, maxHp: 10, currentHp: 10),
      Combatant(
          id: 'c2', name: 'Fast', type: CombatantType.playerCharacter, dex: 85, maxHp: 12, currentHp: 12),
      Combatant(
          id: 'c3', name: 'Medium', type: CombatantType.npc, dex: 55, maxHp: 8, currentHp: 8),
    ];

    combatants.sort((a, b) => b.dex.compareTo(a.dex));

    expect(combatants.map((c) => c.name), ['Fast', 'Medium', 'Slow']);
    expect(combatants.map((c) => c.dex), [85, 55, 30]);
  });

  // -----------------------------------------------------------------------
  // 5. Full JSON round-trip serialization
  // -----------------------------------------------------------------------
  test('Full JSON round-trip serialization', () {
    final encounter = CombatEncounter(
      id: 'enc-rt',
      name: 'Round-trip Test',
      combatants: [
        Combatant(
          id: 'c1',
          name: 'Alice',
          type: CombatantType.playerCharacter,
          characterId: 'char-alice',
          dex: 70,
          maxHp: 14,
          currentHp: 10,
          statuses: [CombatantStatus.frightened],
          damageTaken: 4,
          notes: 'Lost 4 SAN',
        ),
      ],
      currentRound: 3,
      currentTurnIndex: 1,
      status: CombatStatus.ongoing,
      createdAt: DateTime(2026, 6, 21, 10, 30),
      finishedAt: null,
    );

    final json = encounter.toJson();
    final restored = CombatEncounter.fromJson(json);

    expect(restored.id, encounter.id);
    expect(restored.name, encounter.name);
    expect(restored.currentRound, 3);
    expect(restored.currentTurnIndex, 1);
    expect(restored.status, CombatStatus.ongoing);
    expect(restored.createdAt, encounter.createdAt);
    expect(restored.finishedAt, isNull);
    expect(restored.combatants.length, 1);

    final c = restored.combatants.first;
    expect(c.id, 'c1');
    expect(c.name, 'Alice');
    expect(c.type, CombatantType.playerCharacter);
    expect(c.characterId, 'char-alice');
    expect(c.dex, 70);
    expect(c.maxHp, 14);
    expect(c.currentHp, 10);
    expect(c.statuses, [CombatantStatus.frightened]);
    expect(c.damageTaken, 4);
    expect(c.notes, 'Lost 4 SAN');
  });

  // -----------------------------------------------------------------------
  // 6. Missing JSON fields get defaults (old data compatibility)
  // -----------------------------------------------------------------------
  test('Missing JSON fields get defaults for backward compatibility', () {
    final json = <String, dynamic>{
      'id': 'enc-old',
      'name': 'Legacy Encounter',
      'createdAt': '2025-01-01T00:00:00.000',
      // currentRound, currentTurnIndex, status, combatants all missing
    };

    final encounter = CombatEncounter.fromJson(json);

    expect(encounter.id, 'enc-old');
    expect(encounter.name, 'Legacy Encounter');
    expect(encounter.currentRound, 1);
    expect(encounter.currentTurnIndex, 0);
    expect(encounter.status, CombatStatus.ongoing);
    expect(encounter.combatants, isEmpty);
    expect(encounter.finishedAt, isNull);

    // Also test Combatant with minimal JSON
    final combatantJson = <String, dynamic>{
      'id': 'c-old',
      'name': 'Old NPC',
    };

    final combatant = Combatant.fromJson(combatantJson);
    expect(combatant.type, CombatantType.npc); // default
    expect(combatant.dex, 0);
    expect(combatant.maxHp, 0);
    expect(combatant.currentHp, 0);
    expect(combatant.statuses, isEmpty);
    expect(combatant.damageTaken, 0);
    expect(combatant.notes, isNull);
  });

  // -----------------------------------------------------------------------
  // 7. totalDamageDealt calculation
  // -----------------------------------------------------------------------
  test('totalDamageDealt sums damageTaken across all combatants', () {
    final encounter = CombatEncounter(
      id: 'enc-dmg',
      name: 'Damage Test',
      combatants: [
        Combatant(
            id: 'c1',
            name: 'A',
            type: CombatantType.playerCharacter,
            dex: 50,
            maxHp: 12,
            currentHp: 8,
            damageTaken: 4),
        Combatant(
            id: 'c2',
            name: 'B',
            type: CombatantType.npc,
            dex: 40,
            maxHp: 10,
            currentHp: 0,
            damageTaken: 10),
        Combatant(
            id: 'c3',
            name: 'C',
            type: CombatantType.npc,
            dex: 60,
            maxHp: 6,
            currentHp: 6,
            damageTaken: 0),
      ],
      createdAt: DateTime(2026, 6, 21),
    );

    expect(encounter.totalDamageDealt, 14); // 4 + 10 + 0
  });
}
