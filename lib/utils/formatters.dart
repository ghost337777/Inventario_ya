/// Da formato de pesos colombianos: 342500 -> $ 342.500
String formatoPesos(int valor) {
  final s = valor.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return '${valor < 0 ? '-' : ''}\$ $buffer';
}
