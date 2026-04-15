class Character {
  int id;
  String name;
  String player;
  String occupation;
  int? selectedOccId;
  String age;
  String gender;
  String residence;
  String birthplace;

  int str, con, siz, dex, app, int_, pow, edu;

  int currentHp, maxHp;
  int currentMp, maxMp;
  int sanity, maxSanity;
  int luck;
  int move;
  int build;
  String damageBonus;

  int creditMin;
  int creditMax;
  int occupationPoint;
  int interestPoint;

  String backstory;
  String notes;

  int cash;
  int spending;
  int assets;

  String? avatarUrl;

  List<CharacterWeapon> weapons;
  Map<String, int> skills;
  int luckDice;

  Character({
    this.id = 0,
    this.name = '',
    this.player = '',
    this.occupation = '',
    this.selectedOccId,
    this.age = '',
    this.gender = '',
    this.residence = '',
    this.birthplace = '',
    this.str = 0,
    this.con = 0,
    this.siz = 0,
    this.dex = 0,
    this.app = 0,
    this.int_ = 0,
    this.pow = 0,
    this.edu = 0,
    this.currentHp = 0,
    this.maxHp = 0,
    this.currentMp = 0,
    this.maxMp = 0,
    this.sanity = 0,
    this.maxSanity = 0,
    this.luck = 0,
    this.move = 0,
    this.build = 0,
    this.damageBonus = '0',
    this.creditMin = 0,
    this.creditMax = 0,
    this.occupationPoint = 0,
    this.interestPoint = 0,
    this.backstory = '',
    this.notes = '',
    this.cash = 0,
    this.spending = 0,
    this.assets = 0,
    this.avatarUrl,
    List<CharacterWeapon>? weapons,
    Map<String, int>? skills,
    this.luckDice = 3,
  })  : weapons = weapons ?? [],
        skills = skills ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'player': player,
      'occupation': occupation,
      'selectedOccId': selectedOccId,
      'age': age,
      'gender': gender,
      'residence': residence,
      'birthplace': birthplace,
      'str': str,
      'con': con,
      'siz': siz,
      'dex': dex,
      'app': app,
      'int': int_,
      'pow': pow,
      'edu': edu,
      'currentHp': currentHp,
      'maxHp': maxHp,
      'currentMp': currentMp,
      'maxMp': maxMp,
      'sanity': sanity,
      'maxSanity': maxSanity,
      'luck': luck,
      'move': move,
      'build': build,
      'damageBonus': damageBonus,
      'creditMin': creditMin,
      'creditMax': creditMax,
      'occupationPoint': occupationPoint,
      'interestPoint': interestPoint,
      'backstory': backstory,
      'notes': notes,
      'cash': cash,
      'spending': spending,
      'assets': assets,
      'avatarUrl': avatarUrl,
      'weapons': weapons.map((w) => w.toJson()).toList(),
      'skills': skills,
      'luckDice': luckDice,
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      player: json['player'] ?? '',
      occupation: json['occupation'] ?? '',
      selectedOccId: json['selectedOccId'],
      age: json['age'] ?? '',
      gender: json['gender'] ?? '',
      residence: json['residence'] ?? '',
      birthplace: json['birthplace'] ?? '',
      str: json['str'] ?? 0,
      con: json['con'] ?? 0,
      siz: json['siz'] ?? 0,
      dex: json['dex'] ?? 0,
      app: json['app'] ?? 0,
      int_: json['int'] ?? 0,
      pow: json['pow'] ?? 0,
      edu: json['edu'] ?? 0,
      currentHp: json['currentHp'] ?? 0,
      maxHp: json['maxHp'] ?? 0,
      currentMp: json['currentMp'] ?? 0,
      maxMp: json['maxMp'] ?? 0,
      sanity: json['sanity'] ?? 0,
      maxSanity: json['maxSanity'] ?? 0,
      luck: json['luck'] ?? 0,
      move: json['move'] ?? 0,
      build: json['build'] ?? 0,
      damageBonus: json['damageBonus'] ?? '0',
      creditMin: json['creditMin'] ?? 0,
      creditMax: json['creditMax'] ?? 0,
      occupationPoint: json['occupationPoint'] ?? 0,
      interestPoint: json['interestPoint'] ?? 0,
      backstory: json['backstory'] ?? '',
      notes: json['notes'] ?? '',
      cash: json['cash'] ?? 0,
      spending: json['spending'] ?? 0,
      assets: json['assets'] ?? 0,
      avatarUrl: json['avatarUrl'],
      luckDice: json['luckDice'] ?? 3,
      weapons: (json['weapons'] as List<dynamic>?)
              ?.map((w) => CharacterWeapon.fromJson(w))
              .toList() ??
          [],
      skills: (json['skills'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
    );
  }
}

class CharacterWeapon {
  String name;
  int skill;
  String damage;
  String range;
  String attacks;
  String ammo;
  String malfunction;

  CharacterWeapon({
    this.name = '',
    this.skill = 25,
    this.damage = '',
    this.range = '',
    this.attacks = '1',
    this.ammo = '—',
    this.malfunction = '—',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'skill': skill,
        'damage': damage,
        'range': range,
        'attacks': attacks,
        'ammo': ammo,
        'malfunction': malfunction,
      };

  factory CharacterWeapon.fromJson(Map<String, dynamic> json) {
    return CharacterWeapon(
      name: json['name'] ?? '',
      skill: json['skill'] ?? 25,
      damage: json['damage'] ?? '',
      range: json['range'] ?? '',
      attacks: json['attacks'] ?? '1',
      ammo: json['ammo'] ?? '—',
      malfunction: json['malfunction'] ?? '—',
    );
  }
}
