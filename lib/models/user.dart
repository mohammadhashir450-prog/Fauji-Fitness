enum Goal { lose, maintain, gain }
enum MembershipType { basic, trainer }
enum MemberCategory { male, female }

class UserProfile {
  final String id;
  String name;
  DateTime? dob;
  String sex; // 'male', 'female', 'other'
  double? heightCm;
  String? avatarUrl;
  Goal goal;
  MembershipType membershipType;
  MemberCategory? memberCategory;
  bool darkMode;
  String? trainerName;
  DateTime? registrationDate;

  UserProfile({
    required this.id,
    required this.name,
    this.dob,
    this.sex = 'male',
    this.heightCm,
    this.avatarUrl,
    this.goal = Goal.maintain,
    this.membershipType = MembershipType.basic,
    this.memberCategory,
    this.darkMode = true,
    this.trainerName,
    this.registrationDate,
  });

  double? get heightM => heightCm == null ? null : heightCm! / 100.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dob': dob?.toIso8601String(),
        'sex': sex,
        'heightCm': heightCm,
        'avatarUrl': avatarUrl,
        'goal': goal.name,
        'membershipType': membershipType.name,
        'memberCategory': memberCategory?.name,
        'darkMode': darkMode,
        'trainerName': trainerName,
        'registrationDate': registrationDate?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        dob: json['dob'] == null ? null : DateTime.parse(json['dob'] as String),
        sex: json['sex'] as String? ?? 'male',
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        avatarUrl: json['avatarUrl'] as String?,
        goal: Goal.values.firstWhere(
          (g) => g.name == (json['goal'] as String? ?? 'maintain'),
          orElse: () => Goal.maintain,
        ),
        membershipType: MembershipType.values.firstWhere(
          (m) => m.name == (json['membershipType'] as String? ?? 'basic'),
          orElse: () => MembershipType.basic,
        ),
        memberCategory: json['memberCategory'] == null
            ? null
            : MemberCategory.values.firstWhere(
                (m) => m.name == json['memberCategory'] as String,
                orElse: () => MemberCategory.male,
              ),
        darkMode: (json['darkMode'] as bool?) ?? true,
        trainerName: json['trainerName'] as String?,
        registrationDate: json['registrationDate'] == null ? null : DateTime.parse(json['registrationDate'] as String),
      );
}
