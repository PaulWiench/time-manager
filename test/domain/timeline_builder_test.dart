import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/timeline_builder.dart';

void main() {
  final day = DateTime(2026, 8, 10);

  test('single session with no gaps produces one work block', () {
    final blocks = buildDayTimeline(
      sessions: [
        TimelineInterval(start: day.add(const Duration(hours: 9)), end: day.add(const Duration(hours: 17))),
      ],
      syntheticBreaks: const [],
    );

    expect(blocks, hasLength(1));
    expect(blocks.single.type, TimelineBlockType.work);
  });

  test('a natural gap between two sessions becomes a real-break block', () {
    final blocks = buildDayTimeline(
      sessions: [
        TimelineInterval(start: day.add(const Duration(hours: 8)), end: day.add(const Duration(hours: 12))),
        TimelineInterval(start: day.add(const Duration(hours: 13)), end: day.add(const Duration(hours: 17))),
      ],
      syntheticBreaks: const [],
    );

    expect(blocks.map((b) => b.type), [
      TimelineBlockType.work,
      TimelineBlockType.realBreak,
      TimelineBlockType.work,
    ]);
    expect(blocks[1].duration, const Duration(hours: 1));
  });

  test('a synthetic break inside a gap splits it into real-break / synthetic / (no trailing gap)', () {
    final blocks = buildDayTimeline(
      sessions: [
        TimelineInterval(start: day.add(const Duration(hours: 8)), end: day.add(const Duration(hours: 12, minutes: 30))),
        TimelineInterval(start: day.add(const Duration(hours: 14)), end: day.add(const Duration(hours: 17))),
      ],
      syntheticBreaks: [
        TimelineSyntheticBreak(
          id: 'b1',
          start: day.add(const Duration(hours: 13, minutes: 30)),
          end: day.add(const Duration(hours: 14)),
        ),
      ],
    );

    expect(blocks.map((b) => b.type), [
      TimelineBlockType.work,
      TimelineBlockType.realBreak,
      TimelineBlockType.syntheticBreak,
      TimelineBlockType.work,
    ]);
    expect(blocks[2].id, 'b1');
  });

  test('a synthetic break placed with no adjoining gap yields no real-break block', () {
    final blocks = buildDayTimeline(
      sessions: [
        TimelineInterval(start: day.add(const Duration(hours: 8)), end: day.add(const Duration(hours: 17))),
      ],
      syntheticBreaks: [
        TimelineSyntheticBreak(
          id: 'b1',
          start: day.add(const Duration(hours: 12)),
          end: day.add(const Duration(hours: 12, minutes: 30)),
        ),
      ],
    );

    // The synthetic break's start (noon) falls inside the single session's
    // span, so it sorts between... nothing splits the session in this
    // model (the WorkSession row itself is never split) -- it simply sorts
    // by start time, landing after the session since starts are equal-or-
    // later isn't the case here (noon > 8am), so it appears after the
    // session with no gap.
    expect(blocks.map((b) => b.type), [
      TimelineBlockType.work,
      TimelineBlockType.syntheticBreak,
    ]);
  });

  test('empty input produces no blocks', () {
    expect(buildDayTimeline(sessions: const [], syntheticBreaks: const []), isEmpty);
  });
}
