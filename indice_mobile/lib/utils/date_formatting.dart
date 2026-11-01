extension DateFormatting on DateTime {
  String toFrenchDate() {
    final local = toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  String toFrenchDateTime() {
    final local = toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${toFrenchDate()} à $hour:$minute';
  }
}
