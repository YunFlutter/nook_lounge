class MarketReportConstants {
  const MarketReportConstants._();

  // 유지보수 포인트:
  // 데이터소스/뷰/UI에서 동일 문자열을 재사용해
  // 오타로 인한 분기 불일치를 방지합니다.
  static const String duplicateReportErrorCode = 'duplicate_trade_report';
  static const String otherReasonLabel = '기타(직접 입력)';
  static const int customReasonMaxLength = 300;
}
