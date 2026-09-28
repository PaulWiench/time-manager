/// When a day stops being provisional, and what an unfinished one is allowed
/// to do to the balance.
///
/// The old behaviour: `_deltaFor` returns `-targetHours` for any workday with
/// no committed work, and `checkIn` forces a recalculation. So checking in at
/// 08:43 wrote today as `0 + 0 - 7.9` and the headline balance dropped a full
/// day, then climbed back at each check-out. A morning of work read as a
/// catastrophe and a finished day read as normal — exactly backwards, since
/// the morning is the part that is still going to be fixed.
///
/// The rule instead: **a day that is still running is assumed to be heading for
/// its target.** It can only help the balance, never hurt it, until it is over.
///
/// Nothing here is persisted. `day_entries.balance_delta` stays exactly as
/// honest as it was — this decides only what is *displayed*, which is why
/// getting the judgement wrong on some odd evening costs nothing and is
/// corrected by the next midnight.
library;

import 'date_only.dart';
import 'midnight_cutoff.dart';

/// How long a gap outside working hours has to be before it reads as "gone
/// home" rather than "stepped out". Deliberately not [kBreakWindow] (two
/// hours, in tracking_state.dart): that one decides whether to *show* a break
/// timer and is a within-the-day question. This one decides whether the day is
/// over, and the work window is already doing most of that work.
const kEndOfDayIdle = Duration(hours: 1);

/// Whether [day] can be counted for what it actually was.
///
/// True when the calendar has moved past it, or when — with nothing running —
/// the clock is outside normal working hours and more than [idleWindow] has
/// passed since the last check-out.
///
/// The work window is what keeps a long lunch from ending the day: an idle hour
/// at 14:00 is inside it and settles nothing, the same hour at 19:00 is not.
bool dayIsFinished({
  required DateTime now,
  required DateTime day,
  required bool hasActiveSession,
  required DateTime? lastCheckOut,
  required TimeOfDayWindow workWindow,
  Duration idleWindow = kEndOfDayIdle,
}) {
  // Any day already in the past is finished, whatever happened on it. This is
  // also the only branch that can settle a day nobody ever checked in to.
  if (dateOnly(now).isAfter(dateOnly(day))) return true;

  // A future day has not started, let alone finished.
  if (dateOnly(now).isBefore(dateOnly(day))) return false;

  if (hasActiveSession) return false;
  if (lastCheckOut == null) return false;
  if (workWindow.contains(now)) return false;

  return now.difference(lastCheckOut) > idleWindow;
}

/// What [delta] is allowed to contribute to the running balance.
///
/// A finished day contributes what it earned, overtime or shortfall alike. An
/// unfinished one contributes only a surplus: pass the target at 16:30 and the
/// balance moves that minute, but stop short at 16:30 and nothing is deducted
/// until the day is actually over.
double todayContribution({required double delta, required bool finished}) {
  if (finished) return delta;
  return delta > 0 ? delta : 0;
}
