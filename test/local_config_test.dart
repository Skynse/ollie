import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/repositories/local/local_config.dart';

import 'helpers/test_database.dart';

void main() {
  tearDown(() async {
    await tearDownTestDatabase();
  });

  test('LocalConfig initializes and exposes repositories', () async {
    await setUpTestDatabase();
    await LocalConfig.init();

    expect(LocalConfig.createBoardRepository(), isNotNull);
    expect(LocalConfig.createSprintRepository(), isNotNull);
  });
}
