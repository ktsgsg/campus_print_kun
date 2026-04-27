/// F5 BIG-IP の `F5_ST` cookie を長寿命版へ作り変える。
///
/// 元 cookie のフォーマットが想定外なら例外を投げる
/// (Python版は `split("z")[3]` で IndexError になっていた)。
String genF5St(String f5st) {
  final parts = f5st.split('z');
  if (parts.length < 4) {
    throw FormatException('F5_ST cookie の形式が想定外です: $f5st');
  }
  final unixTime = parts[3];
  const admIdleTimeout = 3600;
  const admGuardTime = 100;
  const maxTimeout = 604800;
  const maxGuardTime = 600;
  return '${unixTime}c${admIdleTimeout}c${admGuardTime}c'
      '${unixTime}c${maxTimeout}c${maxGuardTime}c';
}
