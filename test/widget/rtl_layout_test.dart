// test/widget/rtl_layout_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RTL & Layout Widget Tests', () {
    testWidgets('Arabic locale renders with TextDirection.rtl correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("جمعياتي"),
              ),
              body: const Column(
                children: [
                  Text("تفاصيل الجمعية"),
                  Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text("نواف"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text("جمعياتي"), findsOneWidget);
      expect(find.text("تفاصيل الجمعية"), findsOneWidget);
      expect(find.text("نواف"), findsOneWidget);

      final directionalityFinder = find.byType(Directionality);
      expect(directionalityFinder, findsWidgets);

      final BuildContext context = tester.element(find.text("جمعياتي"));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('English locale renders with TextDirection.ltr correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("My Groups"),
              ),
              body: const Column(
                children: [
                  Text("Group Details"),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text("My Groups"), findsOneWidget);
      final BuildContext context = tester.element(find.text("My Groups"));
      expect(Directionality.of(context), TextDirection.ltr);
    });

    testWidgets('Responsive Row with flexible widgets avoids overflow in RTL',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640)); // small screen

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Row(
                children: [
                  const Icon(Icons.circle),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "اسم مستخدم طويل جداً قد يسبب تجاوزاً للشاشة في الأجهزة الصغيرة",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text("إجراء")),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify no RenderFlex overflow exception
      expect(tester.takeException(), isNull);
      expect(find.text("إجراء"), findsOneWidget);
    });
  });
}
