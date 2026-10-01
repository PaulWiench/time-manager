import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/session_fix.dart';
import 'package:time_manager/widgets/session_fix_sheet.dart';

/// The message line's exact words, as the additions handoff §5.3/§5.4 has them.
void main() {
  DateTime t(int h, int m) => DateTime(2026, 9, 22, h, m);
  final start = SessionFix.startEarlier(currentStart: t(8, 12), workWindowStartMinutes: 7 * 60);
  final checkIn = SessionFix.checkInAt(lastCheckOut: t(12, 30), now: t(13, 5));
  String say(SessionFix fix, DateTime v, {double net = 2.47}) =>
      sessionFixMessage(fix, v, todayNetHours: net).text;

  test('started earlier', () {
    expect(say(start, t(7, 45)), 'Adds 0:27 · today becomes 2:55 so far');
    expect(say(start, t(7, 0)), 'Adds 1:12 · earliest allowed start');
    expect(say(start, t(8, 12)), 'Pick a time before 08:12 to move the start earlier.');
    expect(say(start, t(6, 40)), 'Your work window starts at 07:00. Pick 07:00 or later.');
  });

  test('check in at', () {
    expect(say(checkIn, t(12, 58)), 'Break 0:28 · tracking resumes from 12:58');
    expect(say(checkIn, t(12, 38)), startsWith('This break is 0:08.'));
    expect(say(checkIn, t(13, 20)), "That's in the future. The latest is now, 13:05.");
    expect(say(checkIn, t(12, 20)),
        'You checked out at 12:30. To change that, edit the earlier session in History.');
    expect(say(checkIn, t(12, 30)), 'No break · the session that ended at 12:30 continues');
  });
}
