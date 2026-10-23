import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:unicart_app/widgets/retailer_channel_selector.dart";

void main() {
  // Regression test for the blank-lobby bug: a Row that stretches its children
  // inside a scrolling list has unbounded height and threw a layout error,
  // which left the whole lobby body blank in release builds.
  testWidgets("RetailerChannelSelector lays out inside a scrolling list", (
    tester,
  ) async {
    // Wide surface: the test font is much wider than the real one, so a phone
    // width would report harmless text overflow unrelated to this bug.
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              RetailerChannelSelector(
                selected: "temu",
                onSelected: (value) => picked = value,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("Temu"), findsOneWidget);
    expect(find.text("SHEIN"), findsOneWidget);

    await tester.tap(find.text("SHEIN"));
    await tester.pump();
    expect(picked, "shein");
  });
}
