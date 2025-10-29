class PassValueModel<A, B> {
  PassValueModel({this.first, this.second});

  final A? first;
  final B? second;

  PassValueModel<A, B> copyWith({A? first, B? second}) {
    return PassValueModel(first: first ?? this.first, second: second ?? this.second);
  }
}
