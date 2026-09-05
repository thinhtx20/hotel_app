import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/shared/widgets/sticky_header.dart';

/// Dải ghim phải giao đúng `contentHeight` cho con lúc đã dính hẳn lên đỉnh.
///
/// Viền dưới của dải là `BoxDecoration.border` — nó chiếm chỗ thật trong layout,
/// nên nếu extent không cộng thêm 1px thì con chỉ nhận `contentHeight - 1` và
/// tràn đúng 1px. Lỗi chỉ lộ ra lúc đã ghim (`minExtent`), nên phải cuộn qua
/// khối phía trên rồi mới đo — test không cuộn sẽ luôn xanh.
///
/// Đo thẳng chiều cao con thay vì bắt lỗi tràn: sliver ghim cắt phần thừa nên
/// `tester.takeException()` không nhận được cảnh báo tràn của `RenderFlex`.
void main() {
  // Giống thanh lọc thật: ô tìm kiếm + khoảng đệm + hàng tab.
  const searchHeight = 46.0;
  const gap = 12.0;
  const tabsHeight = 38.0;
  const contentHeight = searchHeight + gap + tabsHeight;

  Widget buildHarness({double topInset = 0}) {
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            // Khối cuộn qua để dải ghim dính lên đỉnh.
            const SliverToBoxAdapter(child: SizedBox(height: 300)),
            SliverStickyHeader(
              contentHeight: contentHeight,
              topInset: topInset,
              child: const Column(
                children: [
                  SizedBox(height: searchHeight),
                  SizedBox(height: gap),
                  SizedBox(height: tabsHeight),
                ],
              ),
            ),
            SliverList.builder(
              itemCount: 20,
              itemBuilder: (_, _) => const SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  /// Cuộn quá khối phía trên để dải ghim co về đúng `minExtent`.
  Future<double> pinnedChildHeight(
    WidgetTester tester, {
    double topInset = 0,
  }) async {
    await tester.pumpWidget(buildHarness(topInset: topInset));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    return tester.renderObject<RenderBox>(find.byType(Column)).size.height;
  }

  testWidgets('con nhận đủ contentHeight lúc đã dính — màn có app bar',
      (tester) async {
    expect(await pinnedChildHeight(tester), contentHeight);
  });

  testWidgets('con nhận đủ contentHeight lúc đã dính — màn tự chừa status bar',
      (tester) async {
    expect(await pinnedChildHeight(tester, topInset: 24), contentHeight);
  });

  testWidgets('extent lúc ghim chừa chỗ cho cả status bar lẫn đường kẻ',
      (tester) async {
    await tester.pumpWidget(buildHarness(topInset: 24));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final header = tester.renderObject<RenderSliver>(
      find.byType(SliverStickyHeader),
    );
    expect(header.geometry!.paintExtent, 24 + contentHeight + 1);
  });
}
