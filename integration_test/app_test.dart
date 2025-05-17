import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Test đăng nhập', () {
    // 🧪 Trường hợp 1: Để trống email và mật khẩu
    testWidgets('1. Để trống email và mật khẩu', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final loginButton = find.byKey(Key('loginButton'));
      await tester.tap(loginButton); // Bấm nút Đăng nhập khi chưa nhập gì
      await tester.pumpAndSettle(Duration(seconds: 5));

      // ✅ Kỳ vọng hiện thông báo lỗi vì thiếu thông tin
      expect(find.text('❌ Vui lòng nhập đầy đủ thông tin!'), findsOneWidget);
    });

    // 🧪 Trường hợp 2. Để trống Email
    testWidgets('2. Để trống Email', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 4));

      // ✅ Kỳ vọng backend trả về thông báo email không hợp lệ
      expect(find.textContaining('❌ Vui lòng nhập đầy đủ thông tin!'), findsOneWidget);
    });

    // 🧪 Trường hợp 3: Để trống mật khẩu
    testWidgets('3. Trống mật khẩu', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('emailField')), 'user@exam');
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 4));

      // ✅ Kỳ vọng backend trả về thông báo email không hợp lệ
      expect(find.textContaining('❌ Vui lòng nhập đầy đủ thông tin!'), findsOneWidget);
    });

    // 🧪 Trường hợp 4: Email sai định dạng
    testWidgets('4. Sai định dạng email', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key('emailField')), 'user@exam'); // Email không hợp lệ
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 4));

      // ✅ Kỳ vọng backend trả về thông báo email không hợp lệ
      expect(find.textContaining('Email không hợp lệ'), findsOneWidget);
    });

    // 🧪 Trường hợp 5: Mật khẩu không đủ 6 kí tự
    testWidgets('5. Mật khẩu không đủ 6 kí tự', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key('emailField')), 'user@exam.com');
      await tester.enterText(find.byKey(Key('passwordField')), '123');
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // ✅ Kỳ vọng backend trả về thông báo email không hợp lệ
      expect(find.textContaining('Mật khẩu phải có ít nhất 6 ký tự'), findsOneWidget);
    });

    // 🧪 Trường hợp 6: Tài khoản không tồn tại
    testWidgets('6. Tài khoản không tồn tại', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('emailField')), 'nonexistent@example.com'); // Email chưa đăng ký
      await tester.enterText(find.byKey(Key('passwordField')), '123456');
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 4)); // Đợi phản hồi từ server

      // ✅ Kỳ vọng thông báo tài khoản không tồn tại
      expect(find.text('❌ Tài khoản không tồn tại'), findsOneWidget);
    });

    // 🧪 Trường hợp 7: Sai mật khẩu
    testWidgets('7. Sai mật khẩu', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com'); // Email đúng
      await tester.enterText(find.byKey(Key('passwordField')), '12345999');     // Mật khẩu sai
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 4)); // Đợi phản hồi từ server

      // ✅ Kỳ vọng hiển thị lỗi sai mật khẩu
      expect(find.text('❌ Sai mật khẩu, Vui lòng kiểm tra lại'), findsOneWidget);
    });

    // 🧪 Trường hợp 8: Email chứa khoảng trắng giữa
    testWidgets('8. Email chứa khoảng trắng', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('emailField')), 'user@example .com'); 
      await tester.enterText(find.byKey(Key('passwordField')), '123456'); 
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 4)); // Đợi phản hồi từ server

      // ✅ Kỳ vọng hiển thị lỗi sai mật khẩu
      expect(find.text('❌ Email và mật khẩu không được chứa khoảng trắng ở giữa'), findsOneWidget);
    });

    // 🧪 Trường hợp 9: Mật khẩu có chứa khoảng trắng giữa
    testWidgets('9. Mật khẩu có chứa khoảng trắng giữa', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('emailField')), 'user@example.com'); 
      await tester.enterText(find.byKey(Key('passwordField')), '123 456');   
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 4)); // Đợi phản hồi từ server

      // ✅ Kỳ vọng hiển thị lỗi sai mật khẩu
      expect(find.text('❌ Sai mật khẩu, Vui lòng kiểm tra lại'), findsOneWidget);
    });

    // 🧪 Trường hợp 10: Đăng nhập thành công
    testWidgets('10. Đăng nhập thành công', (tester) async {
      SharedPreferences.setMockInitialValues({}); // Reset bộ nhớ SharedPreferences

      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('emailField')), 'admin@example.com'); // Tài khoản đúng
      await tester.enterText(find.byKey(Key('passwordField')), '123456');         // Mật khẩu đúng
      await tester.tap(find.byKey(Key('loginButton')));



      // ✅ Kỳ vọng hiển thị thông báo thành công
      expect(find.text('🎉 Đăng nhập thành công!'), findsOneWidget);

      // ✅ Kiểm tra SharedPreferences đã lưu token và trạng thái đăng nhập
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn');
      final token = prefs.getString('authToken');

      expect(isLoggedIn, isTrue); // Đã đăng nhập
      expect(token != null && token!.isNotEmpty, true); // Token được lưu
    });
  });
}
