class UniCartSchool {
  final String id;
  final String name;
  final String shortName;
  final String emailDomain;
  final String logoUrl;

  const UniCartSchool({
    required this.id,
    required this.name,
    required this.shortName,
    required this.emailDomain,
    required this.logoUrl,
  });

  static const List<UniCartSchool> all = [
    UniCartSchool(
      id: "pau",
      name: "Pan-Atlantic University",
      shortName: "PAU",
      emailDomain: "pau.edu.ng",
      logoUrl: "https://www.google.com/s2/favicons?domain=pau.edu.ng&sz=128",
    ),
    UniCartSchool(
      id: "augustine",
      name: "Augustine University",
      shortName: "Augustine",
      emailDomain: "augustineuniversity.edu.ng",
      logoUrl: "https://augustineuniversity.edu.ng/images/NAME.png",
    ),
    UniCartSchool(
      id: "babcock",
      name: "Babcock University",
      shortName: "Babcock",
      emailDomain: "babcock.edu.ng",
      logoUrl: "https://legacy.babcock.edu.ng/assets/images/admin/BU_Logo.png",
    ),
  ];

  static UniCartSchool byId(String? id) {
    return all.firstWhere(
      (school) => school.id == id,
      orElse: () => all.first,
    );
  }
}
