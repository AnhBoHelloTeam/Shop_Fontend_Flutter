import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shop_frontend/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🧪 TEST: Giỏ hàng khi đăng nhập', () {
    
    // 🔹 TEST CASE 3: Đăng nhập thành công → vào giỏ hàng (chưa thêm gì)
    testWidgets('TC3 - Đăng nhập rồi vào giỏ hàng (chưa thêm sản phẩm)', (tester) async {
      print('🟢 TC3 Bắt đầu: Đăng nhập và kiểm tra giỏ hàng trống');

      SharedPreferences.setMockInitialValues({}); // Reset storage
      app.main();
      await tester.pumpAndSettle();

      print('➡️ B1: Nhập email & mật khẩu');
      await tester.enterText(find.byKey(Key('emailField')), 'admin@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');

      print('➡️ B2: Nhấn nút đăng nhập');
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      print('➡️ B3: Nhấn icon giỏ hàng');
      final cartIconButton = find.byKey(Key('cartIconButton'));
      expect(cartIconButton, findsOneWidget);
      await tester.tap(cartIconButton);
      await tester.pumpAndSettle(Duration(seconds: 3));

      print('✅ B4: Kiểm tra thông báo giỏ hàng trống');
      expect(find.textContaining('Chưa có sản phẩm nào trong giỏ'), findsOneWidget);

      print('✅ TC3 Hoàn tất 🎉');
    });

    // 🔹 TEST CASE 4: Đăng nhập → thêm sản phẩm → vào giỏ hàng
    testWidgets('TC4 - Đăng nhập, thêm sản phẩm, kiểm tra giỏ hàng', (tester) async {
      print('🟢 TC4 Bắt đầu: Đăng nhập và thêm sản phẩm vào giỏ');

      SharedPreferences.setMockInitialValues({});
      app.main();
      await tester.pumpAndSettle();

      print('➡️ B1: Nhập thông tin đăng nhập');
      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');

      print('➡️ B2: Nhấn nút đăng nhập');
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 4));

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
      await tester.pumpAndSettle(Duration(seconds: 3));
      print('✅ Đã thêm sản phẩm vào giỏ');

      print('➡️ B5: Quay lại và vào giỏ hàng');
      final backButton = find.byKey(Key('backButton'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle(Duration(seconds: 2));

      final cartIconButton = find.byKey(Key('cartIconButton'));
      expect(cartIconButton, findsOneWidget);
      await tester.tap(cartIconButton);
      await tester.pumpAndSettle(Duration(seconds: 3));

      print('✅ B6: Kiểm tra sản phẩm có trong giỏ');
      expect(find.byType(ListTile), findsWidgets);

      print('✅ TC4 Hoàn tất 🎉');
    });

  });
}
