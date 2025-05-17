import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shop_frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Kiểm thử đăng ký', () {
    Future<void> goToRegisterScreen(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final registerTextButton = find.byKey(Key('registerButton'));
      await tester.tap(registerTextButton);
      await tester.pumpAndSettle();
    }

    // 🧪 1. Để trống tất cả các trường
    testWidgets('1. Để trống tất cả các trường', (tester) async {
      await goToRegisterScreen(tester);

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Kiểm tra thông báo lỗi cho các trường bắt buộc
      expect(find.text('❗Vui lòng điền đầy đủ thông tin'), findsOneWidget);
      tester.printToConsole('❗Vui lòng điền đầy đủ thông tin');
    });

    // 🧪 2. Để trống họ tên
    testWidgets('2. Họ tên để trống', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), '');
      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123456');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');
      await tester.enterText(find.byKey(Key('addressField')), 'Da Nang');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Vui lòng nhập họ tên'), findsOneWidget);
      tester.printToConsole('❗Vui lòng điền đầy đủ thông tin');
    });

    // 🧪 3. Để trống Email
    testWidgets('3. Email để trống', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'Nhan');
      await tester.enterText(find.byKey(Key('emailField')), '');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123456');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');
      await tester.enterText(find.byKey(Key('addressField')), 'Da Nang');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Vui lòng nhập email'), findsOneWidget);
      tester.printToConsole('❗Vui lòng điền đầy đủ thông tin');
    });

    // 🧪 4. Để trống Mật khẩu
    testWidgets('4. Mật khẩu để trống', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'Nhan');
      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123456');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');
      await tester.enterText(find.byKey(Key('addressField')), 'Da Nang');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Vui lòng nhập mật khẩu'), findsOneWidget);
      tester.printToConsole('❗Vui lòng điền đầy đủ thông tin');
    });

    // 🧪 5. Để trống Mật khẩu xác nhận
    testWidgets('5. Xác nhận MK để trống', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'Nhan');
      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');
      await tester.enterText(find.byKey(Key('addressField')), 'Da Nang');
      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Vui lòng xác nhận mật khẩu'), findsOneWidget);
      tester.printToConsole('❗Vui lòng điền đầy đủ thông tin');
    });

    // 🧪 6. Chưa điền số điện thoại
    testWidgets('6.SDT để trống', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'Nhan');
      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123456');
      await tester.enterText(find.byKey(Key('phoneField')), '');
      await tester.enterText(find.byKey(Key('addressField')), 'Da Nang');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));
      expect(find.text('❗Vui lòng nhập số điện thoại'), findsOneWidget);
      tester.printToConsole('❗Vui lòng điền đầy đủ thông tin');
    });

    // 🧪 7. Chưa điền Địa chỉ
    testWidgets('7. Dịa chỉ để trống', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'Nhan');
      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123456');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');
      await tester.enterText(find.byKey(Key('addressField')), '');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Vui lòng nhập địa chỉ'), findsOneWidget);
      tester.printToConsole('❗Vui lòng điền đầy đủ thông tin');
    });

    // 🧪 8. Nhập email sai định dạng
    testWidgets('8. Nhập email sai định dạng', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'Nhan');
      await tester.enterText(find.byKey(Key('emailField')), 'user@example');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123456');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');
      await tester.enterText(find.byKey(Key('addressField')), 'HCM');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Email không hợp lệ'), findsOneWidget);
      tester.printToConsole('❗Email không hợp lệ');
    });

    // 🧪 9. Nhập email có khoảng trống giữa
    testWidgets('9. Nhập email có khoảng trống', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'Nhan');
      await tester.enterText(find.byKey(Key('emailField')), 'user @example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123456');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');
      await tester.enterText(find.byKey(Key('addressField')), 'HCM');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Email không được chứa khoảng trống'), findsOneWidget);
      tester.printToConsole('❗Email có khoảng trống hợp lệ');
    });

    // 🧪 10. Mật khẩu quá ngắn
    testWidgets('10. Mật khẩu quá ngắn', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'demo');
      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');
      await tester.enterText(find.byKey(Key('addressField')), 'HCM');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Mật khẩu ít nhất 6 ký tự'), findsOneWidget);
      tester.printToConsole('❗Mật khẩu ít nhất 6 ký tự');
    });

    // 🧪 11. Mật khẩu và xác nhận mật khẩu không khớp
    testWidgets('11. Mật khẩu và xác nhận mật khẩu không khớp', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'demo');
      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '654321');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');
      await tester.enterText(find.byKey(Key('addressField')), 'HCM');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Mật khẩu không khớp'), findsOneWidget);
      tester.printToConsole('❗Mật khẩut không khớp');
    });

    // 🧪 12. Mật khẩu có khoảng trống
    testWidgets('12. Mật khẩu có khoảng trống', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'demo');
      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123 456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123 456');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');  
      await tester.enterText(find.byKey(Key('addressField')), 'HCM');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Mật khẩu không được chứa khoảng trống'), findsOneWidget);
      tester.printToConsole('❗Mật khẩu có khoảng trống hợp lệ');
    });

    // 🧪 13. Nhập số điện thoại không hợp lệ
    testWidgets('13. Nhập số điện thoại không hợp lệ', (tester) async {
      await goToRegisterScreen(tester);
      await tester.enterText(find.byKey(Key('nameField')), 'demo');
      await tester.enterText(find.byKey(Key('emailField')), 'test@example.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123456');
      await tester.enterText(find.byKey(Key('phoneField')), '12345');
      await tester.enterText(find.byKey(Key('addressField')), 'HCM');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('❗Số điện thoại không hợp lệ'), findsOneWidget);
      tester.printToConsole('❗Số điện thoại không hợp lệ');
    });

    // 🧪 14. Đăng ký thành công
    testWidgets('14. Đăng ký thành công', (tester) async {
      await goToRegisterScreen(tester);

      final uniqueEmail = 'test${DateTime.now().millisecondsSinceEpoch}@example.com';
      await tester.enterText(find.byKey(Key('nameField')), 'demo');
      await tester.enterText(find.byKey(Key('emailField')), uniqueEmail);
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.enterText(find.byKey(Key('confirmPasswordField')), '123456');
      await tester.enterText(find.byKey(Key('phoneField')), '0123456789');
      await tester.enterText(find.byKey(Key('addressField')), 'HCM');

      final registerButton = find.byKey(Key('registerButton'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(find.text('✅ Đăng ký thành công!'), findsOneWidget);
    });
  });
}
