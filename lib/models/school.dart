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
      logoUrl: "https://images.weserv.nl/?url=www.google.com%2Fs2%2Ffavicons%3Fdomain%3Dpau.edu.ng%26sz%3D128",
    ),
    UniCartSchool(
      id: "augustine",
      name: "Augustine University",
      shortName: "Augustine",
      emailDomain: "augustineuniversity.edu.ng",
      logoUrl: "https://images.weserv.nl/?url=augustineuniversity.edu.ng%2Fimages%2FNAME.png",
    ),
    UniCartSchool(
      id: "babcock",
      name: "Babcock University",
      shortName: "Babcock",
      emailDomain: "babcock.edu.ng",
      logoUrl: "https://images.weserv.nl/?url=legacy.babcock.edu.ng%2Fassets%2Fimages%2Fadmin%2FBU_Logo.png",
    ),
  ];

  static UniCartSchool byId(String? id) {
    return all.firstWhere(
      (school) => school.id == id,
      orElse: () => all.first,
    );
  }
}
