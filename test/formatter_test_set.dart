part of math_expressions_test;

/**
 * Contains a test set for testing the formatter
 */
class FormatterTests extends TestSet {

  get name => 'Formatter Tests';

  get testFunctions => {
    'Pretty format': prettyFormatTest
  };

  @override
  void initTests(){}

  final Expression
    nonCommutativeAssociativity = new Minus(1, new Plus(2, 3)),
    unaryNegs = new Parser().parse('-4 + (-(4 - (-5))) * (-sin(-x))'),
    abs = new Abs(new Variable('x')),
    ln = new Ln(new Number(6));

  void prettyFormatTest() {
    expect(Formatter.pretty.format(nonCommutativeAssociativity),
      '1 − (2 + 3)');
    expect(Formatter.pretty.format(unaryNegs),
      '-4 + (-(4 − (-5))) × (-sin(-x))');
    expect(Formatter.pretty.format(abs), '|x|');
    expect(Formatter.pretty.format(ln), 'ln(6)');
  }
}
