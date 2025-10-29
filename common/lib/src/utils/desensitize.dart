class Desensitization {
  Desensitization._();

  static String maskData(
    String data, {
    int startVisible = 0,
    int endVisible = 0,
    String? insertSpace,
  }) {
    if (data.isEmpty) {
      return '';
    }
    final int length = data.length;
    final int visibleLength = startVisible + endVisible;
    if (visibleLength >= length) {
      return data;
    }
    final String maskedPart = '*' * (length - visibleLength);
    return data.substring(0, startVisible) +
        (insertSpace ?? '') +
        maskedPart +
        (insertSpace ?? '') +
        data.substring(length - endVisible);
  }

  // 姓名脱敏
  static String maskName(String name) {
    if (name.length <= 1) {
      return name;
    }
    return maskData(name, startVisible: 1, endVisible: 1);
  }

  // 身份证号脱敏
  static String maskIdCard(String idCard) {
    return maskData(idCard, startVisible: 6, endVisible: 4);
  }

  // 手机号脱敏
  static String maskPhone(String mobilePhone, {String? insertSpace}) {
    return maskData(mobilePhone, startVisible: 3, endVisible: 4, insertSpace: insertSpace);
  }

  // 邮箱脱敏，保留用户名的第一个字符和@及后面的域名部分
  static String maskEmail(String email) {
    final int atIndex = email.indexOf('@');
    if (atIndex <= 1) {
      return email;
    }
    final String username = email.substring(0, atIndex);
    final String domain = email.substring(atIndex);
    final String maskedUsername = maskData(username, startVisible: 1);
    return maskedUsername + domain;
  }
}
