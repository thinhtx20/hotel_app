import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/shared/widgets/keyboard_dismisser.dart';

/// Dựng một app giống cấu hình thật: KeyboardDismisser gắn ở MaterialApp.builder.
Widget _app({required Widget body}) {
  return MaterialApp(
    builder: (context, child) =>
        KeyboardDismisser(child: child ?? const SizedBox.shrink()),
    home: Scaffold(body: body),
  );
}

void main() {
  testWidgets('Chạm vùng trống ngoài ô nhập liệu thì bỏ focus (ẩn bàn phím)',
      (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _app(
        body: Column(
          children: [
            TextField(focusNode: focusNode),
            const SizedBox(height: 200, key: Key('blank')),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    // Chạm vào vùng trống: không widget nào nhận tap, lớp bọc phải xử lý.
    await tester.tapAt(tester.getCenter(find.byKey(const Key('blank'))));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('Chạm vào nút bấm: nút vẫn chạy và bàn phím vẫn đóng',
      (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var tapped = false;

    await tester.pumpWidget(
      _app(
        body: Column(
          children: [
            TextField(focusNode: focusNode),
            ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Lưu'));
    await tester.pump();
    expect(tapped, isTrue, reason: 'Lớp bọc không được nuốt tap của nút');
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('Chạm vào chính ô nhập liệu thì giữ nguyên focus', (tester) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      _app(
        body: Column(
          children: [
            TextField(focusNode: first, decoration: const InputDecoration(labelText: 'A')),
            TextField(focusNode: second, decoration: const InputDecoration(labelText: 'B')),
          ],
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextField, 'A'));
    await tester.pump();
    expect(first.hasFocus, isTrue);

    // Chạm lại vào chính ô đó: không được nhấp nháy bàn phím.
    await tester.tap(find.widgetWithText(TextField, 'A'));
    await tester.pump();
    expect(first.hasFocus, isTrue);

    // Chuyển sang ô khác: focus chuyển, bàn phím vẫn mở.
    await tester.tap(find.widgetWithText(TextField, 'B'));
    await tester.pump();
    expect(second.hasFocus, isTrue);
    expect(first.hasFocus, isFalse);
  });

  testWidgets('Kéo cuộn danh sách thì bỏ focus (ẩn bàn phím)', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _app(
        body: ListView(
          children: [
            TextField(focusNode: focusNode),
            for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('$i')),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('Ô nhập liệu trong bottom sheet cũng ẩn bàn phím khi chạm ra ngoài',
      (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _app(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => SizedBox(
                  height: 300,
                  child: Column(
                    children: [
                      TextField(focusNode: focusNode),
                      const Expanded(child: SizedBox(key: Key('sheet-blank'))),
                    ],
                  ),
                ),
              ),
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tapAt(tester.getCenter(find.byKey(const Key('sheet-blank'))));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });
}
