  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:integration_test/integration_test.dart';
  import 'package:shop_frontend/main.dart' as app;
  import 'package:shared_preferences/shared_preferences.dart';

  void main() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    group('🧪 TEST: mua hàng thành công', () {

      testWidgets('TC - Mua nhiều sản phẩm rồi kiểm tra giỏ hàng', (tester) async {
        print('🟢 Bắt đầu test mua nhiều sản phẩm');

        SharedPreferences.setMockInitialValues({});
        app.main();
        await tester.pumpAndSettle();

        print('➡️ B1: Đăng nhập');
        await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
        await tester.enterText(find.byKey(Key('passwordField')), '123456');
        await tester.tap(find.byKey(Key('loginButton')));
        await tester.pumpAndSettle(Duration(seconds: 3));

        for (int i = 0; i < 2; i++) {
          print('➡️ B$i: Chi tiết sản phẩm productCard_$i');
          final chiTietButton = find.descendant(
            of: find.byKey(Key('productCard_$i')),
            matching: find.widgetWithText(TextButton, 'Chi tiết'),
          );
          expect(chiTietButton, findsOneWidget);
          await tester.tap(chiTietButton);
          await tester.pumpAndSettle(Duration(seconds: 3));

          print('🛒 Thêm vào giỏ hàng sản phẩm $i');
          final addToCartButton = find.widgetWithText(ElevatedButton, '🛒 Thêm vào giỏ hàng');
          expect(addToCartButton, findsOneWidget);
          await tester.tap(addToCartButton);
          await tester.pumpAndSettle(Duration(seconds: 2));

          print('↩️ Quay lại danh sách sản phẩm');
          final backButton = find.byKey(Key('backButton'));
          expect(backButton, findsOneWidget);
          await tester.tap(backButton);
          await tester.pumpAndSettle(Duration(seconds: 2));
        }

        print('🛒 Vào giỏ hàng');
        final cartIconButton = find.byKey(Key('cartIconButton'));
        expect(cartIconButton, findsOneWidget);
        await tester.tap(cartIconButton);
        await tester.pumpAndSettle(Duration(seconds: 3));

        // print('✅ Kiểm tra có ít nhất 2 sản phẩm trong giỏ');
        // final cartItems = find.byType(ListTile);
        // expect(cartItems, findsNWidgets(2));

              print('🛍️ Bấm nút "Mua hàng"');
        final checkoutButton = find.byKey(Key('checkoutButton'));
        expect(checkoutButton, findsOneWidget);
        await tester.tap(checkoutButton);
        await tester.pumpAndSettle(Duration(seconds: 4));
        
        print('🛍️ Bấm nút "Mua hàng"');
        final confirmCheckoutButton = find.byKey(Key('confirmCheckoutButton'));
        expect(confirmCheckoutButton, findsOneWidget);
        await tester.tap(confirmCheckoutButton);
        await tester.pumpAndSettle(Duration(seconds: 4));

      expect(find.textContaining("Tổng tiền:"), findsWidgets);
        expect(find.textContaining("Trạng thái:"), findsWidgets);
        expect(find.byType(ListTile), findsWidgets);

        print('📜 Kiểm tra đã chuyển sang trang Lịch sử đơn hàng');
  expect(find.text("Lịch sử đơn hàng"), findsOneWidget); // AppBar
  expect(find.textContaining("Ngày đặt:"), findsWidgets); // Có đơn hàng

  print('⏳ Tạm dừng 5 giây để xem danh sách đơn hàng');
  await Future.delayed(Duration(seconds: 3)); // 👈 Dừng lại 5 giây ở trang này

  print('✅ Test hoàn tất toàn bộ quy trình mua hàng 🎉');



        print('✅ Test hoàn tất toàn bộ quy trình mua hàng 🎉');


        print('✅ TC hoàn tất 🎉');
      });

    });
  }
