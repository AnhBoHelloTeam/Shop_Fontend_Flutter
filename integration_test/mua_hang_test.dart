import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shop_frontend/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_frontend/test_helpers/excel_logger.dart'; // 👈 Thêm dòng này

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🧪 TEST: mua hàng thành công', () {
    testWidgets('TC - Mua nhiều sản phẩm rồi kiểm tra giỏ hàng', (tester) async {
      final logger = ExcelLogger(); // 👈 Khởi tạo logger
      int step = 1;

      try {
        SharedPreferences.setMockInitialValues({});
        app.main();
        await tester.pumpAndSettle();
        logger.logStep(step++, 'Mở app', 'Pass', '');

        print('➡️ B1: Đăng nhập');
        await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
        await tester.enterText(find.byKey(Key('passwordField')), '123456');
        await tester.tap(find.byKey(Key('loginButton')));
        await tester.pumpAndSettle(Duration(seconds: 4));
        logger.logStep(step++, 'Đăng nhập', 'Pass', '');

        for (int i = 0; i < 2; i++) {
          final chiTietButton = find.descendant(
            of: find.byKey(Key('productCard_$i')),
            matching: find.widgetWithText(TextButton, 'Chi tiết'),
          );
          expect(chiTietButton, findsOneWidget);
          await tester.tap(chiTietButton);
          await tester.pumpAndSettle(Duration(seconds: 3));
          logger.logStep(step++, 'Xem chi tiết sản phẩm $i', 'Pass', '');

          final addToCartButton = find.widgetWithText(ElevatedButton, '🛒 Thêm vào giỏ hàng');
          expect(addToCartButton, findsOneWidget);
          await tester.tap(addToCartButton);
          await tester.pumpAndSettle(Duration(seconds: 2));
          logger.logStep(step++, 'Thêm sản phẩm $i vào giỏ', 'Pass', '');

          final backButton = find.byKey(Key('backButton'));
          expect(backButton, findsOneWidget);
          await tester.tap(backButton);
          await tester.pumpAndSettle(Duration(seconds: 2));
          logger.logStep(step++, 'Quay lại danh sách', 'Pass', '');
        }

        final cartIconButton = find.byKey(Key('cartIconButton'));
        expect(cartIconButton, findsOneWidget);
        await tester.tap(cartIconButton);
        await tester.pumpAndSettle(Duration(seconds: 3));
        logger.logStep(step++, 'Mở giỏ hàng', 'Pass', '');

        final checkoutButton = find.byKey(Key('checkoutButton'));
        expect(checkoutButton, findsOneWidget);
        await tester.tap(checkoutButton);
        await tester.pumpAndSettle(Duration(seconds: 5));
        logger.logStep(step++, 'Bấm "Mua hàng"', 'Pass', '');

        final confirmCheckoutButton = find.byKey(Key('confirmCheckoutButton'));
        expect(confirmCheckoutButton, findsOneWidget);
        await tester.tap(confirmCheckoutButton);
        await tester.pumpAndSettle(Duration(seconds: 5));
        logger.logStep(step++, 'Xác nhận mua hàng', 'Pass', '');

        expect(find.textContaining("Tổng tiền:"), findsWidgets);
        expect(find.textContaining("Trạng thái:"), findsWidgets);
        expect(find.byType(ListTile), findsWidgets);
        logger.logStep(step++, 'Kiểm tra đơn hàng đã mua', 'Pass', '');

        expect(find.text("Lịch sử đơn hàng"), findsOneWidget);
        expect(find.textContaining("Ngày đặt:"), findsWidgets);
        logger.logStep(step++, 'Trang lịch sử đơn hàng', 'Pass', '');

        await Future.delayed(Duration(seconds: 3));
        logger.logStep(step++, 'Tạm dừng xem kết quả', 'Pass', '');

        print('✅ Test hoàn tất 🎉');
        logger.logStep(step++, 'Kết thúc test', 'Pass', '');
      } catch (e) {
        logger.logStep(step++, 'Lỗi xảy ra', 'Fail', e.toString());
        print('❌ Lỗi: $e');
      } finally {
        await logger.saveExcel(); // 👈 Ghi file Excel
      }
    });
  });
}
