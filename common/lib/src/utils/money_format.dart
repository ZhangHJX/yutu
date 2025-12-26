enum MoneyType { int, decimal }

String formatMoney(num? money, MoneyType type) {
  if (money == null) {
    return type == MoneyType.int ? '0' : '.00';
  }
  final moneyString = money.toString();
  final moneyList = moneyString.split('.');
  final integer = moneyList[0];
  final decimal = moneyList.length > 1 ? '.${moneyList[1].padRight(2, '0')}' : '.00';
  return type == MoneyType.int ? integer : decimal;
}
