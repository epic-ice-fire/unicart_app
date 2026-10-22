class UniCartSchool {
  final String id;
  final String name;
  final String shortName;
  final String emailDomain;
  final String logoUrl;

  /// Bundled logo (works offline, no CORS/hotlink problems). Falls back to
  /// [logoUrl] and then a generic icon if the asset is missing.
  final String? logoAsset;

  const UniCartSchool({
    required this.id,
    required this.name,
    required this.shortName,
    required this.emailDomain,
    required this.logoUrl,
    this.logoAsset,
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
      logoUrl: "",
      logoAsset: "assets/images/schools/augustine.png",
    ),
    UniCartSchool(
      id: "babcock",
      name: "Babcock University",
      shortName: "Babcock",
      emailDomain: "babcock.edu.ng",
      logoUrl: "",
      logoAsset: "assets/images/schools/babcock.png",
    ),
  ];

  static UniCartSchool byId(String? id) {
    return all.firstWhere(
      (school) => school.id == id,
      orElse: () => all.first,
    );
  }
}
