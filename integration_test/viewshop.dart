import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shop_frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🧪  giỏ hàng khi chưa đăng nhập', () {
    // 🔹 TEST CASE 1: Chưa đăng nhập, truy cập giỏ hàng trực tiếp
    testWidgets('TC1 - Truy cập giỏ hàng trực tiếp khi chưa đăng nhập', (tester) async {
      print('🟢 TC1 Bắt đầu: Vào giỏ hàng trực tiếp khi chưa đăng nhập');

      app.main();
      await tester.pumpAndSettle();

      print('➡️ B1: Nhấn nút "Xem sản phẩm"');
      final xemSanPhamButton = find.byKey(Key('goToHomeButton'));
      expect(xemSanPhamButton, findsOneWidget);
      await tester.tap(xemSanPhamButton);
      await tester.pumpAndSettle(Duration(seconds: 3));

      print('➡️ B2: Nhấn icon giỏ hàng');
      final cartIconButton = find.byKey(Key('cartIconButton'));
      expect(cartIconButton, findsOneWidget);
      await tester.tap(cartIconButton);
      await tester.pumpAndSettle(Duration(seconds: 3));

      print('✅ B3: Kiểm tra thông báo yêu cầu đăng nhập');
      expect(find.text('Vui lòng đăng nhập để sử dụng giỏ hàng!'), findsOneWidget);

      print('✅ TC1 Hoàn tất');
    });

    // 🔹 TEST CASE 2: Chưa đăng nhập, thêm sản phẩm rồi vào giỏ hàng
    testWidgets('TC2 - Thêm sản phẩm khi chưa đăng nhập rồi vào giỏ hàng', (tester) async {
      print('🟢 TC2 Bắt đầu: Thêm sản phẩm khi chưa đăng nhập rồi vào giỏ');

      app.main();
      await tester.pumpAndSettle();

      print('➡️ B1: Nhấn "Xem sản phẩm"');
      final xemSanPhamButton = find.byKey(Key('goToHomeButton'));
      expect(xemSanPhamButton, findsOneWidget);
      await tester.tap(xemSanPhamButton);
      await tester.pumpAndSettle(Duration(seconds: 3));

      print('➡️ B2: Cuộn để hiện sản phẩm');
      final scrollable = find.byType(Scrollable);
      expect(scrollable, findsWidgets);
      await tester.drag(scrollable.first, Offset(0, -400));
      await tester.pumpAndSettle(Duration(seconds: 3));
      await tester.drag(scrollable.first, Offset(0, -400));
      await tester.pumpAndSettle(Duration(seconds: 3));
      await tester.drag(scrollable.first, Offset(0, 1000));
      await tester.pumpAndSettle(Duration(seconds: 3));

      print('➡️ B3: Nhấn "Chi tiết" sản phẩm đầu tiên');
      final chiTietButton = find.descendant(
        of: find.byKey(Key('productCard_0')),
        matching: find.widgetWithText(TextButton, 'Chi tiết'),
      );
      expect(chiTietButton, findsOneWidget);
      await tester.tap(chiTietButton);
      await tester.pumpAndSettle(Duration(seconds: 4));

      print('➡️ B4: Nhấn "Thêm vào giỏ hàng"');
      final addToCartButton = find.widgetWithText(ElevatedButton, '🛒 Thêm vào giỏ hàng');
      expect(addToCartButton, findsOneWidget);
      await tester.tap(addToCartButton);
      await tester.pumpAndSettle(Duration(seconds: 6));
      tester.printToConsole('❗Bạn cần đăng nhập để thêm vào giỏ');

      print('➡️ B5: Quay lại danh sách sản phẩm');
      final backButton = find.byKey(Key('backButton'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle(Duration(seconds: 3));

      print('➡️ B6: Nhấn icon giỏ hàng');
      final cartIconButton = find.byKey(Key('cartIconButton'));
      expect(cartIconButton, findsOneWidget);
      await tester.tap(cartIconButton);
      await tester.pumpAndSettle(Duration(seconds: 4));

      print('✅ B7: Kiểm tra thông báo yêu cầu đăng nhập');
      expect(find.text('Vui lòng đăng nhập để sử dụng giỏ hàng!'), findsOneWidget);

      print('✅ TC2 Hoàn tất');
    });
  });
}
