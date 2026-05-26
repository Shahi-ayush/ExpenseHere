import 'package:nepali_utils/nepali_utils.dart';

class NepaliDateService {
  /// Converts AD [DateTime] to BS [NepaliDateTime].
  NepaliDateTime convertADToBS(DateTime adDate) {
    return adDate.toNepaliDateTime();
  }

  /// Converts BS [NepaliDateTime] to AD [DateTime].
  DateTime convertBSToAD(NepaliDateTime bsDate) {
    return bsDate.toDateTime();
  }

  /// Formats AD [DateTime] into a BS string (Jestha 12, 2083).
  String formatBSDateLong(DateTime adDate) {
    return NepaliDateFormat('MMMM d, y').format(convertADToBS(adDate));
  }

  /// Formats AD [DateTime] into a BS string (2083-02-12).
  String formatBSDateShort(DateTime adDate) {
    return NepaliDateFormat('yyyy-MM-dd').format(convertADToBS(adDate));
  }

  /// Formats AD [DateTime] into a BS string (Jestha 12).
  String formatBSMonthDay(DateTime adDate) {
    return NepaliDateFormat('MMMM d').format(convertADToBS(adDate));
  }

  /// Formats AD [DateTime] into a BS string (Jestha 2083).
  String formatBSMonthYear(NepaliDateTime date) {
    return NepaliDateFormat('MMMM y').format(date);
  }

  /// Formats AD [DateTime] into a BS string (Jestha).
  String formatBSMonth(NepaliDateTime date) {
    return NepaliDateFormat('MMMM').format(date);
  }

  /// Formats AD [DateTime] into a BS Day (12).
  String formatBSDay(NepaliDateTime date) {
    return NepaliDateFormat('d').format(date);
  }

  /// Formats AD [DateTime] into a BS EEE (Sun).
  String formatBSWeekday(NepaliDateTime date) {
    return NepaliDateFormat('EEE').format(date);
  }

  /// Returns localized full BS weekday name.
  String formatBSWeekdayLong(NepaliDateTime date) {
    return NepaliDateFormat('EEEE').format(date);
  }

  /// Checks if a [NepaliDateTime] is valid.
  bool isValidBSDate(NepaliDateTime date) {
    return date.year >= 2000 && date.year <= 2099;
  }

  /// Checks if two AD dates fall in the same BS month.
  bool isSameBSMonth(DateTime d1, NepaliDateTime d2) {
    final b1 = convertADToBS(d1);
    return b1.year == d2.year && b1.month == d2.month;
  }

  /// Gets the start and end [DateTime] (AD) of a BS month.
  (DateTime, DateTime) getBSMonthRange(NepaliDateTime month) {
    final startBS = NepaliDateTime(month.year, month.month, 1);
    final days = getDaysInMonth(month.year, month.month);
    final endBS = NepaliDateTime(month.year, month.month, days);
    return (startBS.toDateTime(), endBS.toDateTime());
  }

  /// Returns the number of days in a Nepali month, with manual corrections for known library bugs.
  int getDaysInMonth(int year, int month) {
    // Manual overrides for known issues in nepali_utils/nepali_date_picker data tables
    final overrides = {
      '2084-2': 31,
      '2084-3': 32,
      '2084-4': 31,
      '2084-10': 30,
      '2084-12': 30,
      '2085-1': 31,
      '2085-5': 30,
      '2085-6': 31,
      '2085-11': 30,
      '2085-12': 30,
      '2086-1': 30,
      '2086-2': 32,
      '2086-3': 31,
    };

    final key = '$year-$month';
    if (overrides.containsKey(key)) {
      return overrides[key]!;
    }

    // Default to library value
    return NepaliDateTime(year, month, 1).totalDays;
  }

  /// Returns the adjusted start weekday (1-7) for a month, accounting for library day-count errors.
  int getStartWeekday(int year, int month) {
    int libraryWeekday = NepaliDateTime(year, month, 1).weekday; // 1 (Sun) to 7 (Sat)
    
    // We calculate the cumulative offset by comparing library day counts vs our overrides
    // for all months from the first error (2084-2) up to the requested month.
    int accumulatedOffset = 0;

    // Define the error map as corrections (Reality - Library)
    final corrections = {
      '2084-2': -1, // 31 - 32
      '2084-3': 1,  // 32 - 31
      '2084-4': -1, // 31 - 32
      '2084-10': 1, // 30 - 29
      '2084-12': -1, // 30 - 31
      '2085-1': 1,  // 31 - 30
      '2085-5': -1, // 30 - 31
      '2085-6': 1,  // 31 - 30
      '2085-11': 1, // 30 - 29
      '2085-12': -1, // 30 - 31
      '2086-1': -1, // 30 - 31
      '2086-2': 1,  // 32 - 31
      '2086-3': -1, // 31 - 32 (Correction for library drift)
    };

    // Iterate through years/months and accumulate the drift
    for (int y = 2084; y <= year; y++) {
      int startM = (y == 2084) ? 2 : 1;
      int endM = (y == year) ? month - 1 : 12;
      
      for (int m = startM; m <= endM; m++) {
        final key = '$y-$m';
        if (corrections.containsKey(key)) {
          accumulatedOffset += corrections[key]!;
        }
      }
    }

    int adjusted = (libraryWeekday + accumulatedOffset);
    
    // Normalize to 1-7 range
    while (adjusted < 1) {
      adjusted += 7;
    }
    while (adjusted > 7) {
      adjusted -= 7;
    }
    
    return adjusted;
  }
}
