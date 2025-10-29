/// 以指定字符串分割
///
/// [pattern] 分割字符串, 例如: '*** **** ****'
///
/// [delimiter] 输出字符串的分割符, 例如: ' '
///
/// 例如:
/// groupByPattern('12345678901', pattern: '*** **** ****') => '123 4567 8901'
/// groupByPattern('12345678901', pattern: '*** **** ****', delimiter: '-') => '123-4567-8901'
String groupByPattern(String? input, {required String pattern, String delimiter = ' '}) {
  if (input == null) {
    return '';
  }

  final segmentLengths = pattern.split(' ').map((s) => s.length).toList();

  final List<String> result = [];
  int index = 0;

  for (final length in segmentLengths) {
    if (index + length <= input.length) {
      result.add(input.substring(index, index + length));
      index += length;
    } else {
      break;
    }
  }

  if (index < input.length) {
    result.add(input.substring(index));
  }

  return result.join(delimiter);
}
