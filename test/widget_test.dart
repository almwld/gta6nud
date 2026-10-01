import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/main.dart';

void main() {
  testWidgets('GTA6 app boots', (tester) async {
    await tester.pumpWidget(const GTA6App());
    expect(find.byType(GTA6App), findsOneWidget);
  });
}
