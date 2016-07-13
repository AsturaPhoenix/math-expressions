part of math_expressions;

/**
 * The Formatter stringizes the given mathematical [Expression].
 *
 * Usage example:
 *     Formatter.pretty.format(new Parser().parse("(x^2 + cos(y)) / 3"));
 */
abstract class Formatter {
  static final Formatter pretty = new _PrettyFormatter();

  String format(Expression e);
}

class _PrettyFormatter extends InfixFormatter{
  _PrettyFormatter(): super(
    minus: ' − ',
    times: ' × ',
    divide: ' ÷ '
  );

  @override
  String formatFunction(final MathFunction e) => e is Abs?
    '|${format(e.arg)}|' : super.formatFunction(e);
}

class InfixFormatter extends Formatter{
  final String unaryMinus, plus, minus, times, divide, modulo, power;

  InfixFormatter({
    this.unaryMinus: '-',
    this.plus: ' + ',
    this.minus: ' - ',
    this.times: ' * ',
    this.divide: ' / ',
    this.modulo: ' % ',
    this.power: '^'});

  String formatUnaryMinus(final UnaryMinus e) {
    final String exp = format(e.exp);
    return unaryMinus + (e.exp is BinaryOperator? '($exp)' : exp);
  }

  String op(final BinaryOperator e) {
    if (e is Plus) return plus;
    if (e is Minus) return minus;
    if (e is Times) return times;
    if (e is Divide) return divide;
    if (e is Modulo) return modulo;
    if (e is Power) return power;
    return e.opString;
  }

  String fenceIfNecessary(final BinaryOperator parent, final Expression child) {
    final String childFmt = format(child);
    return child is BinaryOperator && child.precedence < parent.precedence ||
      child is UnaryMinus?
      '($childFmt)' : childFmt;
  }

  String formatBinaryOperator(final BinaryOperator e,
      final bool fenceUnaryMinus) {
    bool needsFence(final Expression child, final bool fenceTies) =>
      child is BinaryOperator && (child.precedence < e.precedence ||
        fenceTies && child.precedence == e.precedence);
    bool
      f1 = needsFence(e.first, false),
      f2 = needsFence(e.second, e is! CommutativeOperator);
    final String
      s1 = format(e.first, fenceUnaryMinus && !f1),
      s2 = format(e.second, !f2);

    return (f1? '($s1)' : s1) + op(e) + (f2? '($s2)' : s2);
  }

  String formatFunction(final MathFunction e) =>
    e is Ln? 'ln(${format(e.arg)})' :
    '${e.name}(${e.args.map(format).join(", ")})';

  String formatBoundVariable(final BoundVariable e) => format(e.value);

  String formatNumber(final Number e) => e.value.truncateToDouble() == e.value?
    e.value.toStringAsFixed(0) : e.value.toString();

  String formatDefault(final Expression e) => e.toString();

  @override
  String format(final Expression e, [final bool fenceUnaryMinus = false]) {
    if (e is UnaryMinus) {
      final String fmt = formatUnaryMinus(e);
      return fenceUnaryMinus? '($fmt)' : fmt;
    }
    if (e is BinaryOperator) return formatBinaryOperator(e, fenceUnaryMinus);
    if (e is MathFunction) return formatFunction(e);
    if (e is BoundVariable) return formatBoundVariable(e);
    if (e is Number) return formatNumber(e);
    return formatDefault(e);
  }
}
