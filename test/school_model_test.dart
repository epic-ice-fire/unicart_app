import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:unicart_app/models/school.dart";

void main() {
  test("byId falls back to PAU for null and unknown ids", () {
    expect(UniCartSchool.byId(null).id, "pau");
    expect(UniCartSchool.byId("not-a-school").id, "pau");
  });

  test("byId returns the matching campus", () {
    expect(UniCartSchool.byId("babcock").shortName, "Babcock");
    expect(UniCartSchool.byId("augustine").shortName, "Augustine");
    expect(UniCartSchool.byId("veritas").shortName, "Veritas");
  });

  test("every bundled school logo file exists", () {
    for (final school in UniCartSchool.all) {
      final asset = school.logoAsset;
      if (asset == null) continue;
      expect(
        File(asset).existsSync(),
        isTrue,
        reason: "${school.id} logo is missing at $asset",
      );
    }
  });
}
