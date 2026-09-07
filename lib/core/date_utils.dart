/// Strips the time-of-day component, keeping only the calendar date.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Formats a date as `YYYY-MM-DD`, independent of locale — safe for use in
/// route paths / storage keys.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
