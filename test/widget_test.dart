import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sametify/main.dart';

void main() {
  testWidgets('SametifyApp loads correctly smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SametifyApp(),
      ),
    );

    expect(find.text('Günaydın Samet'), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Ara'), findsOneWidget);
    expect(find.text('Kitaplığın'), findsOneWidget);
  });
}
