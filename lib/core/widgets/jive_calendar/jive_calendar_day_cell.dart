import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

enum JiveHolidayCornerType { rest, work }

class JiveHolidayCornerMark {
  final JiveHolidayCornerType type;

  const JiveHolidayCornerMark(this.type);

  String get label => type == JiveHolidayCornerType.work ? '班' : '休';

  Color get foregroundColor => type == JiveHolidayCornerType.work
      ? Colors.orange.shade800
      : Colors.red.shade700;

  Color get backgroundColor => type == JiveHolidayCornerType.work
      ? Colors.orange.withValues(alpha: 0.18)
      : Colors.redAccent.withValues(alpha: 0.18);
}

class JiveCalendarDayCell extends StatelessWidget {
  final DateTime day;
  final CalendarStyle style;
  final Decoration decoration;
  final TextStyle textStyle;
  final String? lunarLabel;
  final bool showTodayLabel;
  final JiveHolidayCornerMark? holidayCornerMark;

  const JiveCalendarDayCell({
    super.key,
    required this.day,
    required this.style,
    required this.decoration,
    required this.textStyle,
    required this.lunarLabel,
    required this.showTodayLabel,
    required this.holidayCornerMark,
  });

  TextStyle _lunarTextStyle(TextStyle base) {
    final color = base.color?.withValues(alpha: 0.7) ?? Colors.grey.shade600;
    return base.copyWith(
      fontSize: 9,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = lunarLabel?.trim();
    final showLunar = label != null && label.isNotEmpty;
    final reserveRight = holidayCornerMark != null ? 10.0 : 2.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: style.cellMargin,
      padding: style.cellPadding,
      decoration: decoration,
      alignment: style.cellAlignment,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              // When holiday corner marks are shown, reserve space so they do
              // not visually collide with 2-digit day numbers on narrow cells.
              padding: EdgeInsets.fromLTRB(2, 2, reserveRight, 2),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // When the calendar shows 6 rows, the cell can be quite
                  // short. To prevent the lunar/term/festival label from
                  // overlapping with the day number, we allocate vertical
                  // slices and scale the text down if needed.
                  final showTodayEffective =
                      showTodayLabel && constraints.maxHeight >= 34;

                  Widget scaledText(String text, TextStyle style) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: style,
                      ),
                    );
                  }

                  final children = <Widget>[
                    if (showTodayEffective)
                      Expanded(
                        flex: 2,
                        child: scaledText(
                          '今日',
                          GoogleFonts.lato(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    Expanded(
                      flex: showLunar ? 3 : 5,
                      child: scaledText('${day.day}', textStyle),
                    ),
                    if (showLunar)
                      Expanded(
                        flex: 2,
                        child: scaledText(label, _lunarTextStyle(textStyle)),
                      ),
                  ];

                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: children,
                  );
                },
              ),
            ),
          ),
          if (holidayCornerMark != null)
            Positioned(
              top: 1,
              right: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: holidayCornerMark!.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  holidayCornerMark!.label,
                  style: GoogleFonts.lato(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: holidayCornerMark!.foregroundColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
