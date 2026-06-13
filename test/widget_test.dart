// This is a basic Flutter widget test for Fauji Fitness.
import 'package:flutter_test/flutter_test.dart';
import 'package:fauji_fitness/main.dart';

void main() {
  testWidgets('App shows branding or loading status on splash', (WidgetTester tester) async {
    // 1. App ko build karein aur pehla frame trigger karein.
    await tester.pumpWidget(const MyApp());

    // 2. Verify karein ke aapka premium branding text screen par mojood hai ya nahi.
    // Splash screen par hamara text 'FAUJI FITNESS' hai.
    expect(find.text('FAUJI FITNESS'), findsAtLeastNWidgets(1));

    // 3. Check karein ke splash screen par loading indicator ya status text dikh raha hai.
    expect(find.text('Loading...'), findsOneWidget);
  });
}