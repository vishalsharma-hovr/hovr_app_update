import 'package:flutter_test/flutter_test.dart';
import 'package:hovr_app_update/hovr_app_update.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('configure and promptIfUpdateRequired complete', (tester) async {
    await HovrAppUpdate.configure(
      const AppUpdateConfig(iosAppStoreId: '1585783552'),
    );

    await expectLater(
      HovrAppUpdate.promptIfUpdateRequired(serverVersion: ''),
      completes,
    );
  });
}
