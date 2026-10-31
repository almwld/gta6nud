import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/main.dart';

void main() {
  testWidgets('GTA6 app boots into the local GLB workspace', (tester) async {
    await tester.pumpWidget(const GTA6App());

    expect(find.byType(GTA6App), findsOneWidget);
    expect(find.text('مساحة المجسمات ثلاثية الأبعاد'), findsOneWidget);
    expect(find.text('اختيار ملف GLB'), findsOneWidget);
    expect(find.text('SPEED+'), findsNothing);
    expect(find.text('SPEED-'), findsNothing);
    expect(find.text('Walk'), findsNothing);
    expect(find.text('Run'), findsNothing);
  });
}
