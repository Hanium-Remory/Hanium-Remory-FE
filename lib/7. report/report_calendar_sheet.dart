// 리포트를 날짜로 골라 오는 달력.
//
// 리포트가 있는 날에만 점을 찍는다. 점이 없는 날은 눌러도 아무 일이 없다 —
// 그날은 인형이 꺼져 있었거나 아직 배치가 돌지 않은 날이라, 열어봐야 빈
// 화면이다.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);

/// 달력을 띄우고 고른 날짜를 준다. 닫기만 하면 null.
Future<DateTime?> showReportCalendar(
  BuildContext context, {
  required Set<DateTime> markedDays,
  required DateTime focusedDay,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: _bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _ReportCalendar(markedDays: markedDays, focusedDay: focusedDay),
  );
}

class _ReportCalendar extends StatefulWidget {
  const _ReportCalendar({required this.markedDays, required this.focusedDay});

  /// 리포트가 있는 날들. 시각은 무시하고 날짜만 본다.
  final Set<DateTime> markedDays;
  final DateTime focusedDay;

  @override
  State<_ReportCalendar> createState() => _ReportCalendarState();
}

class _ReportCalendarState extends State<_ReportCalendar> {
  late DateTime _month = DateTime(
    widget.focusedDay.year,
    widget.focusedDay.month,
  );

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  Set<DateTime> get _marked => {
    for (final d in widget.markedDays) DateTime(d.year, d.month, d.day),
  };

  /// 그달 첫날 앞의 빈 칸 수. 일요일부터 시작하는 달력에 맞춘다.
  int get _leadingBlanks => DateTime(_month.year, _month.month).weekday % 7;

  int get _daysInMonth => DateTime(_month.year, _month.month + 1, 0).day;

  /// 앞으로는 이번 달을 넘지 않는다. 아직 오지 않은 날에는 리포트가 없다.
  bool get _canGoNext {
    final now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  @override
  Widget build(BuildContext context) {
    final marked = _marked;
    final today = DateTime.now();
    final cells = _leadingBlanks + _daysInMonth;
    final rows = (cells / 7).ceil();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE0D5C9),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                IconButton(
                  tooltip: '이전 달',
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left, color: _dark),
                ),
                Expanded(
                  child: Text(
                    '${_month.year}년 ${_month.month}월',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: _dark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '다음 달',
                  onPressed: _canGoNext
                      ? () => setState(
                          () => _month = DateTime(_month.year, _month.month + 1),
                        )
                      : null,
                  icon: const Icon(Icons.chevron_right, color: _dark),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                for (final w in _weekdays)
                  Expanded(
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: _muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            for (var row = 0; row < rows; row++)
              Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _buildCell(
                        row * 7 + col - _leadingBlanks + 1,
                        marked,
                        today,
                      ),
                    ),
                ],
              ),
            SizedBox(height: 10.h),
            Text(
              '점이 있는 날에 리포트가 있어요.',
              style: TextStyle(
                fontSize: 11.sp,
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int dayNumber, Set<DateTime> marked, DateTime today) {
    if (dayNumber < 1 || dayNumber > _daysInMonth) {
      return SizedBox(height: 42.h);
    }
    final day = DateTime(_month.year, _month.month, dayNumber);
    final hasReport = marked.contains(day);
    final isToday =
        day == DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: 42.h,
      child: InkWell(
        // 점이 없는 날은 열어봐야 빈 화면이라 아예 누르지 못하게 둔다.
        onTap: hasReport ? () => Navigator.pop(context, day) : null,
        borderRadius: BorderRadius.circular(99),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 13.sp,
                color: hasReport
                    ? _dark
                    : (isToday ? _muted : const Color(0xFFC9BCB1)),
                fontWeight: hasReport ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Container(
              width: 5.w,
              height: 5.w,
              decoration: BoxDecoration(
                color: hasReport ? _brown : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
