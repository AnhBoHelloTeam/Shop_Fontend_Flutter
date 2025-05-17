import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shop_frontend/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🧪 TEST: thêm sản phẩm', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    Future<void> loginAndGoToAddPage(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Đăng nhập
      await tester.enterText(find.byKey(Key('emailField')), 'admin@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Điều hướng đến thêm sản phẩm
      await tester.tap(find.byKey(Key('accountIconButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('addProductButton')));
      await tester.pumpAndSettle();
    }

    testWidgets('TC01 - Thêm sản phẩm thành công', (tester) async {
      print('🟢 TC01: Thêm sản phẩm thành công');
      await loginAndGoToAddPage(tester);

      await tester.enterText(find.byKey(Key('productNameField')), 'iPhone 15 Pro Max');
      await tester.enterText(find.byKey(Key('productPriceField')), '39990000');
      await tester.enterText(find.byKey(Key('productDescField')), 'Flagship 2024');
      await tester.enterText(find.byKey(Key('productCategoryField')), 'Điện thoại');
      await tester.enterText(find.byKey(Key('productStockField')), '50');
      await tester.enterText(find.byKey(Key('productImageField')), 'https://via.placeholder.com/150');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('addProductButton')));
      await tester.pumpAndSettle();

      await Future.delayed(Duration(seconds: 5));
    });

    testWidgets('TC02 - Thiếu tên sản phẩm', (tester) async {
      print('🔴 TC02: Thiếu tên sản phẩm');
      await loginAndGoToAddPage(tester);

      await tester.enterText(find.byKey(Key('productPriceField')), '1000000');
      await tester.enterText(find.byKey(Key('productDescField')), 'Mô tả');
      await tester.enterText(find.byKey(Key('productCategoryField')), 'Loa');
      await tester.enterText(find.byKey(Key('productStockField')), '10');
      await tester.enterText(find.byKey(Key('productImageField')), 'https://via.placeholder.com/150');

      await tester.tap(find.byKey(Key('addProductButton')));
      await tester.pumpAndSettle();

      await Future.delayed(Duration(seconds: 4));
      expect(find.textContaining('Vui lòng nhập Tên sản phẩm'), findsOneWidget);
    });

    testWidgets('TC03 - Thiếu giá sản phẩm', (tester) async {
      print('🔴 TC03: Thiếu giá');
      await loginAndGoToAddPage(tester);

      await tester.enterText(find.byKey(Key('productNameField')), 'Loa Bluetooth');
      await tester.enterText(find.byKey(Key('productDescField')), 'Mô tả sản phẩm');
      await tester.enterText(find.byKey(Key('productCategoryField')), 'Loa');
      await tester.enterText(find.byKey(Key('productStockField')), '5');
      await tester.enterText(find.byKey(Key('productImageField')), 'https://via.placeholder.com/150');

      await tester.tap(find.byKey(Key('addProductButton')));
      await tester.pumpAndSettle();

      await Future.delayed(Duration(seconds: 4));
      expect(find.textContaining('Vui lòng nhập Giá sản phẩm'), findsOneWidget);
    });

    testWidgets('TC04 - Giá âm', (tester) async {
      print('🔴 TC04: Giá âm');
      await loginAndGoToAddPage(tester);

      await tester.enterText(find.byKey(Key('productNameField')), 'Tai nghe');
      await tester.enterText(find.byKey(Key('productPriceField')), '-50000');
      await tester.enterText(find.byKey(Key('productDescField')), 'Tai nghe xịn');
      await tester.enterText(find.byKey(Key('productCategoryField')), 'Phụ kiện');
      await tester.enterText(find.byKey(Key('productStockField')), '10');
      await tester.enterText(find.byKey(Key('productImageField')), 'https://via.placeholder.com/150');

      await tester.tap(find.byKey(Key('addProductButton')));
      await tester.pumpAndSettle();

      await Future.delayed(Duration(seconds: 4));
      expect(find.textContaining('Giá trị không hợp lệ'), findsOneWidget);
    });

    testWidgets('TC05 - Thiếu mô tả sản phẩm', (tester) async {
      print('🔴 TC05: Thiếu mô tả');
      await loginAndGoToAddPage(tester);

      await tester.enterText(find.byKey(Key('productNameField')), 'MacBook Air');
      await tester.enterText(find.byKey(Key('productPriceField')), '28990000');
      // Bỏ mô tả
      await tester.enterText(find.byKey(Key('productCategoryField')), 'Laptop');
      await tester.enterText(find.byKey(Key('productStockField')), '8');
      await tester.enterText(find.byKey(Key('productImageField')), 'https://via.placeholder.com/150');

      await tester.tap(find.byKey(Key('addProductButton')));
      await tester.pumpAndSettle();

      await Future.delayed(Duration(seconds: 4));
      expect(find.textContaining('Vui lòng nhập Mô tả'), findsOneWidget);
    });

    testWidgets('TC06 - Thiếu ảnh sản phẩm', (tester) async {
  print('🔴 TC06: Thiếu ảnh sản phẩm');
  await loginAndGoToAddPage(tester);

  await tester.enterText(find.byKey(Key('productNameField')), 'Đồng hồ thông minh');
  await tester.enterText(find.byKey(Key('productPriceField')), '2500000');
  await tester.enterText(find.byKey(Key('productDescField')), 'Hỗ trợ đo nhịp tim');
  await tester.enterText(find.byKey(Key('productCategoryField')), 'Phụ kiện');
  await tester.enterText(find.byKey(Key('productStockField')), '15');
  // Bỏ ảnh sản phẩm

  await tester.tap(find.byKey(Key('addProductButton')));
  await tester.pumpAndSettle();
  await Future.delayed(Duration(seconds: 4));

  expect(find.textContaining('Vui lòng nhập Ảnh sản phẩm'), findsOneWidget);
});


  testWidgets('TC07 - Ảnh không hợp lệ', (tester) async {
  print('🔴 TC07: Ảnh không hợp lệ');
  await loginAndGoToAddPage(tester);

  await tester.enterText(find.byKey(Key('productNameField')), 'Camera');
  await tester.enterText(find.byKey(Key('productPriceField')), '5000000');
  await tester.enterText(find.byKey(Key('productDescField')), 'Quay 4K');
  await tester.enterText(find.byKey(Key('productCategoryField')), 'Camera');
  await tester.enterText(find.byKey(Key('productStockField')), '20');
  await tester.enterText(find.byKey(Key('productImageField')), 'file:/notvalidimage');

  await tester.tap(find.byKey(Key('addProductButton')));
  await tester.pumpAndSettle();
  await Future.delayed(Duration(seconds: 4));

  expect(find.textContaining('Đường dẫn ảnh không hợp lệ'), findsOneWidget);
});


testWidgets('TC08 - Tồn kho âm', (tester) async {
  print('🔴 TC08: Số lượng tồn kho âm');
  await loginAndGoToAddPage(tester);

  await tester.enterText(find.byKey(Key('productNameField')), 'Ổ cứng SSD');
  await tester.enterText(find.byKey(Key('productPriceField')), '1500000');
  await tester.enterText(find.byKey(Key('productDescField')), '512GB NVMe');
  await tester.enterText(find.byKey(Key('productCategoryField')), 'Lưu trữ');
  await tester.enterText(find.byKey(Key('productStockField')), '-3');
  await tester.enterText(find.byKey(Key('productImageField')), 'https://via.placeholder.com/150');

  await tester.tap(find.byKey(Key('addProductButton')));
  await tester.pumpAndSettle();
  await Future.delayed(Duration(seconds: 4));

  expect(find.textContaining('Số lượng không hợp lệ'), findsOneWidget);
});

  });
}
