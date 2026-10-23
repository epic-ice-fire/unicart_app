import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:unicart_app/widgets/unicart_ui.dart";

void main() {
  testWidgets("UniCartStatusPill shows its category and label", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: UniCartStatusPill(
              label: "Paid & locked",
              category: "Payment",
              color: Colors.green,
              icon: Icons.lock_rounded,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text("Payment"), findsOneWidget);
    expect(find.text("Paid & locked"), findsOneWidget);
  });
}
