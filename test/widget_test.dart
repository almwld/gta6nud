import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gta6hub/core/simulation_provider.dart';
import 'package:gta6hub/engine/body/body_manager.dart';
import 'package:gta6hub/main.dart';

void main() {
  testWidgets('GTA6 app boots with its runtime providers', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SimulationProvider()),
          ChangeNotifierProvider(create: (_) => BodyManager()),
        ],
        child: const GTA6App(),
      ),
    );
    await tester.pump();
    expect(find.byType(GTA6App), findsOneWidget);
  });
}
