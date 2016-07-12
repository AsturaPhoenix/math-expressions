part of math_expressions;

/**
 * Any Expression supports basic mathematical operations like
 * addition, subtraction, multiplication, division, power and negate.
 *
 * Furthermore, any expression can be differentiated with respect to
 * a given variable. Also expressions know how to simplify themselves.
 *
 * There are different classes of expressions:
 *
 * * Literals (see [Literal])
 *
 *     * Number Literals (see [Number])
 *     * Variable Literals (see [Variable])
 *     * Vector Literals (see [Vector])
 *     * Interval Literals (see [IntervalLiteral])
 * * Operators (support auto-wrapping of parameters into Literals)
 *
 *     * Unary Operators (see [UnaryOperator])
 *     * Binary Operators (see [BinaryOperator])
 * * Functions (see [MathFunction])
 *
 *     * Pre-defined Functions (see [DefaultFunction])
 *     * Composite Functions (see [CompositeFunction])
 *     * Custom Functions (see [CustomFunction])
 *
 * Pre-defined functions are [Exponential], [Log], [Ln], nth-[Root], [Sqrt],
 * [Abs], [Ceil], [Floor], [Sgn], [Sin], [Cos] and [Tan].
 */
abstract class Expression {

  // Basic operations.
  /// Add operator. Creates a [Plus] expression.
  Expression operator+(Expression exp) => new Plus(this, exp);
  /// Subtract operator. Creates a [Minus] expression.
  Expression operator-(Expression exp) => new Minus(this, exp);
  /// Multiply operator. Creates a [Times] expression.
  Expression operator*(Expression exp) => new Times(this, exp);
  /// Divide operator. Creates a [Divide] expression.
  Expression operator/(Expression exp) => new Divide(this, exp);
  /// Modulo operator. Creates a [Modulo] expression.
  Expression operator%(Expression exp) => new Modulo(this, exp);
  /// Power operator. Creates a [Power] expression.
  Expression operator^(Expression exp) => new Power(this, exp);
  /// Unary minus operator. Creates a [UnaryMinus] expression.
  Expression operator-() => new UnaryMinus(this);

  /**
   * Derives this expression with respect to the given variable.
   */
  Expression derive(String toVar);
  // TODO: Return simplified version of derivation. This might not be possible
  //       with the current model. Probably needs some kind of evaluator
  //       construct.

  /**
   * Returns a simplified version of this expression.
   * Subclasses should overwrite this method, if applicable.
   */
  Expression simplify() => this;
  // TODO: Return maximally simplified version of expression. This might not be
  //       possible with the current model, see above.

  bool get isConstant;
  getConstantValue([EvaluationType type = EvaluationType.REAL]) =>
    evaluate(type, null);

  /**
   * Evaluates this expression according to given type and context.
   */
  evaluate(EvaluationType type, ContextModel context);

  /**
   * Returns a string version of this expression.
   * Subclasses should override this method. The output should be kept
   * compatible with the [Parser].
   */
  String toString();

  /**
   * Converts the given argument to a valid expression.
   *
   * Returns the argument, if it is already an expression.
   * Else wraps the argument in a [Number] or [Variable] Literal.
   *
   * Throws ArgumentError, if given arg is not an Expression, num oder String.
   *
   * __Note__:
   * Does not handle negative numbers, will treat them as positives!
   */
  Expression _toExpression(var arg) {
    if (arg is Expression) {
      return arg;
    }

    if (arg is num) {
      // can not handle negative numbers - use parser for this case!
      return new Number(arg);
    }

    if (arg is String) {
      return new Variable(arg);
    }

    throw new ArgumentError('${arg} is not a valid expression!');
  }

  /**
   * Returns true, if the given expression is a constant literal and its value
   * matches the given value.
   */
  bool _isNumber(Expression exp, [num value = 0]) {
    // Check for literal.
    if (exp.isConstant) {
      return exp.getConstantValue() == value;
    }

    return false;
  }
}

/**
 * A binary operator takes two expressions and performs an operation on them.
 */
abstract class BinaryOperator extends Expression {
  Expression first, second;

  /**
   * Creates a [BinaryOperation] from two given arguments.
   *
   * If an argument is not an expression, it will be wrapped in an appropriate
   * literal.
   *
   *  * A (positive) number will be encapsulated in a [Number] Literal,
   *  * A string will be encapsulated in a [Variable] Literal.
   */
  BinaryOperator(first, second) {
    this.first = _toExpression(first);
    this.second = _toExpression(second);
  }

  /**
   * Creates a new [BinaryOperation] from two given expressions.
   */
  BinaryOperator.raw(this.first, this.second);

  String get opString;

  @override
  bool get isConstant => first.isConstant && second.isConstant;

  _evaluate(var a, var b);
  Expression _dynamicSimplify(Expression s1, Expression s2);

  @override
  Expression simplify() {
    final Expression
      s1 = first.simplify(),
      s2 = second.simplify();
    if (s1.isConstant && s2.isConstant) {
      return new Number(_evaluate(
        s1.evaluate(EvaluationType.REAL, null),
        s2.evaluate(EvaluationType.REAL, null)));
    }

    return _dynamicSimplify(s1, s2);
  }

  @override
  evaluate(EvaluationType type, ContextModel context) =>
    _evaluate(first.evaluate(type, context), second.evaluate(type, context));

  @override
  bool operator ==(o) => o is BinaryOperator &&
    o.opString == opString &&
    o.first == first &&
    o.second == second;
  @override
  int get hashCode => hash3(opString, first, second);

  @override
  String toString() => '($first $opString $second)';
}

/**
 * Commutative operators do not rely on order.
 */
abstract class CommutativeOperator extends BinaryOperator {
  CommutativeOperator(first, second): super(first, second);

  @override
  bool operator ==(o) => o is CommutativeOperator &&
    o.opString == opString &&
    (o.first == first && o.second == second ||
      o.first == second && o.second == first);
  @override
  int get hashCode {
    int h1 = first.hashCode, h2 = second.hashCode;
    return h1 < h2? hash3(opString, h1, h2) : hash3(opString, h2, h1);
  }
}

/**
 * A unary operator takes one argument and performs an operation on it.
 */
abstract class UnaryOperator extends Expression {
  Expression exp;

  /**
   * Creates a [UnaryOperation] from the given argument.
   *
   * If the argument is not an expression, it will be wrapped in an appropriate
   * literal.
   *
   * * A (positive) number will be encapsulated in a [Number] Literal,
   * * A string will be encapsulated in a [Variable] Literal.
   */
  UnaryOperator(exp) {
    this.exp = _toExpression(exp);
  }

  /**
   * Creates a [UnaryOperation] from the given expression.
   */
  UnaryOperator.raw(this.exp);

  String get opString;

  @override
  bool get isConstant => exp.isConstant;

  @override
  bool operator ==(o) => o is UnaryOperator &&
    o.opString == opString &&
    o.exp == exp;
  @override
  int get hashCode => hash2(opString, exp);

  @override
  String toString() => '($opString$exp)';
}

/**
 * The unary minus negates its argument.
 */
class UnaryMinus extends UnaryOperator {

  /**
   * Creates a new unary minus operation on the given expression.
   *
   * For example, to create -1:
   *     one = new Number(1);
   *     minus_one = new UnaryMinus(one);
   *
   * or just:
   *     minus_one = new UnaryMinus(1);
   */
  UnaryMinus(exp): super(exp);

  @override
  String get opString => '-';

  Expression derive(String toVar) => new UnaryMinus(exp.derive(toVar));

  /**
   * Possible simplifications:
   *
   * 1. -(-a) = a
   * 2. -0 = 0
   */
  Expression simplify() {
    Expression simplifiedOp = exp.simplify();

    // double minus
    if (simplifiedOp is UnaryMinus) {
      return simplifiedOp.exp;
    }

    // operand == 0
    if (_isNumber(simplifiedOp, 0)) {
        return simplifiedOp;
    }

    // nothing to do..
    return new UnaryMinus(simplifiedOp);
  }

  evaluate(EvaluationType type, ContextModel context) {
    return -(exp.evaluate(type, context));
  }
}

/**
 * The plus operator performs an addition.
 */
class Plus extends CommutativeOperator {

  /**
   * Creates an addition operation on the given expressions.
   *
   * For example, to create x + 4:
   *     addition = new Plus('x', 4);
   *
   * or:
   *     addition = new Variable('x') + new Number(4);
   */
  Plus(first, second): super(first, second);

  @override
  String get opString => '+';

  Expression derive(String toVar) => new Plus(first.derive(toVar),
                                              second.derive(toVar));

  /**
   * Possible simplifications:
   *
   * 1. a + 0 = a
   * 2. 0 + a = a
   * 3. a + -(b) = a - b
   */
  @override
  Expression _dynamicSimplify(Expression s1, Expression s2) {

    if (_isNumber(s1, 0)) {
      return s2;
    }

    if (_isNumber(s2, 0)) {
      return s1;
    }

    if (s2 is UnaryMinus) {
      return s1 - s2.exp; // a + -(b) = a - b
    }

    return new Plus(s1, s2);
    //TODO -a + b = b - a
    //TODO -a - b = - (a+b)
  }

  @override
  _evaluate(var a, var b) {
    return a + b;
  }
}

/**
 * The minus operator performs a subtraction.
 */
class Minus extends BinaryOperator {

  /**
   * Creates a subtaction operation on the given expressions.
   *
   * For example, to create 5 - x:
   *     subtraction = new Minus(5, 'x');
   *
   * or:
   *     subtraction = new Number(5) - new Variable('x');
   */
  Minus(first, second): super(first, second);

  @override
  String get opString => '-';

  Expression derive(String toVar) => new Minus(first.derive(toVar),
                                               second.derive(toVar));

  /**
   * Possible simplifications:
   *
   * 1. a - 0 = a
   * 2. 0 - a = - a
   * 3. a - -(b) = a + b
   */
  @override
  Expression _dynamicSimplify(Expression s1, Expression s2) {
    if (_isNumber(s2, 0)) {
      return s1;
    }

    if (_isNumber(s1, 0)) {
      return -s2;
    }

    if (s2 is UnaryMinus) {
      return s1 + s2.exp; // a - -(b) = a + b
    }

    return new Minus(s1, s2);
    //TODO -a + b = b - a
    //TODO -a - b = - (a + b)
  }

  @override
  _evaluate(var a, var b) {
    return a - b;
  }
}

/**
 * The times operator performs a multiplication.
 */
class Times extends CommutativeOperator {

  /**
   * Creates a product operation on the given expressions.
   *
   * For example, to create 7 * x:
   *     product = new Times(7, 'x');
   *
   * or:
   *     product = new Number(7) * new Variable('x');
   */
  Times(first, second): super(first, second);

  @override
  String get opString => '*';

  Expression derive(String toVar) => new Plus(
    new Times(first, second.derive(toVar)),
    new Times(first.derive(toVar), second));

  /**
   * Possible simplifications:
   *
   * 1. -a * b = - (a * b)
   * 2. a * -b = - (a * b)
   * 3. -a * -b = a * b
   * 4. a * 0 = 0
   * 5. 0 * a = 0
   * 6. a * 1 = a
   * 7. 1 * a = a
   */
  @override
  Expression _dynamicSimplify(Expression s1, Expression s2) {
    Expression tempResult;

    bool negative = false;
    if (s1 is UnaryMinus) {
      s1 = (s1 as UnaryMinus).exp;
      negative = !negative;
    }

    if (s2 is UnaryMinus) {
      s2 = (s2 as UnaryMinus).exp;
      negative = !negative;
    }

    if (_isNumber(s1, 0)) {
      return s1; // = 0
    }

    if (_isNumber(s1, 1)) {
      tempResult = s2;
    }

    if (_isNumber(s2, 0)) {
      return s2; // = 0
    }

    if (_isNumber(s2, 1)) {
      tempResult = s1;
    }

    // If temp result is not set, we return a multiplication
    if (tempResult == null) {
      tempResult = new Times(s1, s2);
      return negative ? -tempResult : tempResult;
    }

    // Otherwise we return the only constant and just check for sign before
    return negative ? new UnaryMinus(tempResult) : tempResult;
  }

  @override
  _evaluate(a, b) => a * b;

  evaluate(EvaluationType type, ContextModel context) {
    var firstEval = first.evaluate(type, context);
    var secondEval = second.evaluate(type, context);

    if (type == EvaluationType.VECTOR) {
      if (secondEval is! double) {
        return firstEval.multiply(secondEval);
      }
    }

    return firstEval * secondEval;
  }
}

/**
 * The divide operator performs a division.
 */
class Divide extends BinaryOperator {

  /**
   * Creates a division operation on the given expressions.
   *
   * For example, to create x/(y+2):
   *     div = new Divide('x', new Plus('y', 2));
   *
   * or:
   *     div = new Variable('x') / (new Variable('y') + new Number(2));
   */
  Divide(dividend, divisor): super(dividend, divisor);

  @override
  String get opString => '/';

  Expression derive(String toVar) => ((first.derive(toVar) * second)
                                    - (first * second.derive(toVar)))
                                    / (second * second);

  /**
   * Possible simplifications:
   *
   * 1. -a / b = - (a / b)
   * 2. a / -b = - (a / b)
   * 3. -a / -b = a / b
   * 5. 0 / a = 0
   * 6. a / 1 = a
   * 7. a / a = 1
   */
  @override
  Expression _dynamicSimplify(Expression s1, Expression s2) {
    Expression tempResult;

    bool negative = false;

    if (s1 is UnaryMinus) {
      s1 = (s1 as UnaryMinus).exp;
      negative = !negative;
    }

    if (s2 is UnaryMinus) {
      s2 = (s2 as UnaryMinus).exp;
      negative = !negative;
    }

    if (_isNumber(s1, 0)) {
      return s1; // = 0
    }

    if (_isNumber(s2, 1)) {
      tempResult = s1;
    } else if (s1 == s2) {
      tempResult = new Number(1);
    } else {
      tempResult = new Divide(s1, s2);
    }

    return negative ? new UnaryMinus(tempResult) : tempResult;
    // TODO cancel down/out? - needs equals on literals (and expressions?)!
  }

  /**
   * This method throws an [IntegerDivisionByZeroException],
   * if a divide by zero is encountered.
   */
  @override
  _evaluate(a, b) => a / b;

  evaluate(EvaluationType type, ContextModel context) {
    var firstEval = first.evaluate(type, context);
    var secondEval = second.evaluate(type, context);

    if (type == EvaluationType.VECTOR) {
      if (secondEval is! double) {
        return firstEval.divide(secondEval);
      }
    }

    return firstEval / secondEval;
  }
}

/**
 * The modulo operator performs a Euclidean modulo operation, as Dart performs
 * it. That is, a % b = a - floor(a / |b|) |b|. For positive integers, this is a
 * remainder.
 */
class Modulo extends BinaryOperator {

  /**
   * Creates a modulo operation on the given expressions.
   *
   * For example, to create x % (y+2):
   *     r = new Modulo('x', new Plus('y', 2));
   *
   * or:
   *     r = new Variable('x') % (new Variable('y') + new Number(2));
   */
  Modulo(dividend, divisor): super(dividend, divisor);

  @override
  String get opString => '%';

  Expression derive(String toVar) {
    final Abs a2 = new Abs(second);
    return first.derive(toVar) - new Floor(first / a2) * a2.derive(toVar);
  }

  /**
   * Possible simplifications:
   *
   * 1. a % -b = a % b
   * 2. 0 % a = 0
   */
  @override
  Expression _dynamicSimplify(Expression s1, Expression s2) {
    if (_isNumber(s1, 0)) {
      return s1; // = 0
    }

    if (s2 is UnaryMinus) {
      s2 = (s2 as UnaryMinus).exp;
    }

    return new Modulo(s1, s2);
  }

  @override
  _evaluate(a, b) => a % b;
}

/**
 * The power operator.
 */
class Power extends BinaryOperator {

  /**
   * Creates a power operation on the given expressions.
   *
   * For example, to create x^3:
   *     pow = new Power('x', 3);
   *
   * or:
   *     pow = new Variable('x') ^ new Number(3.0);
   */
  Power(x, exp): super(x, exp);

  @override
  bool get isConstant => false; // TODO transcendental?

  @override
  String get opString => '^';

  Expression derive(String toVar) => this.asE().derive(toVar);

  /**
   * Possible simplifications:
   *
   * 1. 0^x = 0
   * 2. 1^x = 1
   * 3. x^0 = 1
   * 4. x^1 = x
   */
  @override
  Expression _dynamicSimplify(Expression s1, Expression s2) {
    //TODO unboxing
    /*
    bool baseNegative = false, expNegative = false;

    // unbox unary minuses
    if (baseOp is UnaryMinus) {
      baseOp = baseOp.exp;
      baseNegative = !baseNegative;
    }
    if (exponentOp is UnaryMinus) {
      exponentOp = exponentOp.exp;
      expNegative = !expNegative;
    }
    */

    if (_isNumber(s1, 0)) {
      return s1; // 0^x = 0
    }

    if (_isNumber(s1, 1)) {
      return s1; // 1^x = 1
    }

    if (_isNumber(s2, 0)) {
      return new Number(1.0); // x^0 = 1
    }

    if (_isNumber(s2, 1)) {
      return s1; // x^1 = x
    }

    return new Power(s1, s2);
  }

  @override
  _evaluate(a, b) => Math.pow(a, b);

  @override
  evaluate(EvaluationType type, ContextModel context) {
    if (type == EvaluationType.REAL) {
      return Math.pow(first.evaluate(type, context), second.evaluate(type, context));
    }

    if (type == EvaluationType.INTERVAL) {
      // Expect base to be interval.
      Interval interval = first.evaluate(type, context);

      // Expect exponent to be a natural number.
      var exponent = second.evaluate(EvaluationType.REAL, context);

      if (exponent is double) {
        //print('Warning, expected natural exponent but is real. Interpreting as int: ${this}');
        exponent = exponent.toInt();
      }

      num evalMin, evalMax;
      // Distinction of cases depending on oddity of exponent.
      if (exponent.isOdd) {
        // [x, y]^n = [x^n, y^n] for n = odd
        evalMin = Math.pow(interval.min, exponent);
        evalMax = Math.pow(interval.max, exponent);
      } else {
        // [x, y]^n = [x^n, y^n] for x >= 0
        if (interval.min >= 0) {
          // Positive interval.
          evalMin = Math.pow(interval.min, exponent);
          evalMax = Math.pow(interval.max, exponent);
        }

        // [x, y]^n = [y^n, x^n] for y < 0
        if (interval.min >= 0) {
          // Positive interval.
          evalMin = Math.pow(interval.max, exponent);
          evalMax = Math.pow(interval.min, exponent);
        }

        // [x, y]^n = [0, max(x^n, y^n)] otherwise
        evalMin = 0;
        evalMax = Math.max( Math.pow(interval.min, exponent),
                            Math.pow(interval.min, exponent));
      }

      assert(evalMin <= evalMax);

      return new Interval(evalMin, evalMax);
    }

    throw new UnimplementedError('Evaluate Power with type ${type} not supported yet.');
  }

  String toString() => '($first^$second)';

  /**
   * Returns the exponential form of this operation.
   * E.g. x^4 = e^(4*ln(x))
   *
   * This method is used to determine the derivation of a power expression.
   */
  Expression asE() => new Exponential(second * new Ln(first));
}


/**
 * A literal can be a number, a constant or a variable.
 */
abstract class Literal extends Expression {
  var value;

  /**
   * Creates a literal. The optional paramter `value` can be used to specify
   * its value.
   */
  Literal([var this.value]);

  String toString() => value.toString();

  @override
  bool operator ==(o) => o is Literal && o.value == value;
  @override
  int get hashCode => value.hashCode;
}

/**
 * A number is a constant number literal.
 */
class Number extends Literal {
  /**
   * Creates a number literal with given value.
   * Always holds a double internally.
   */
  Number(num value): super(value.toDouble());

  bool get isConstant => true;

  evaluate(EvaluationType type, ContextModel context) {
    if (type == EvaluationType.REAL) {
      return value;
    }

    if (type == EvaluationType.INTERVAL) {
      // interpret number as interval
      IntervalLiteral intLit = new IntervalLiteral.fromSingle(this);
      return intLit.evaluate(type, context);
    }

    if (type == EvaluationType.VECTOR) {
      // interpret number as scalar
      return value;
    }

    throw new UnsupportedError('Number $this can not be interpreted as: ${type}');
  }

  Expression derive(String toVar) => new Number(0.0);
}

/**
 * A vector of arbitrary size.
 */
class Vector extends Literal {

  /// Convenience operator to access vector elements.
  Expression operator[](int i) => elements[i];

  /**
   * Creates a vector with the given element expressions.
   *
   * For example, to create a 3-dimensional vector:
   *     x = y = z = new Number(1);
   *     vec3 = new Vector([x, y, z]);
   */
  Vector(List<Expression> elements): super(elements);

  /// The elements of this vector.
  List<Expression> get elements => value;

  /// The length of this vector.
  int get length => elements.length;

  Expression derive(String toVar) {
    List<Expression> elementDerivatives = new List<Expression>(length);

    // Derive each element.
    for (int i = 0; i < length; i++) {
      elementDerivatives[i] = elements[i].derive(toVar);
    }

    return new Vector(elementDerivatives);
  }

  /**
   * Simplifies all elements of this vector.
   */
  Expression simplify() {
    List<Expression> simplifiedElements = new List<Expression>(length);

    // Simplify each element.
    for (int i = 0; i < length; i++) {
      simplifiedElements[i] = elements[i].simplify();
    }

    return new Vector(simplifiedElements);
  }

  evaluate(EvaluationType type, ContextModel context) {
    if (type == EvaluationType.VECTOR) {
      EvaluationType elementType = EvaluationType.REAL;

      if (length == 1) {
        // Does not seem to be a vector, try to return REAL.
        return elements[0].evaluate(elementType, context);
      }

      // Interpret vector elements as REAL.
      if (length == 2) {
        double x,y;
        x = elements[0].evaluate(elementType, context);
        y = elements[1].evaluate(elementType, context);
        return new Vector2(x, y);
      }

      if (length == 3) {
        double x,y,z;
        x = elements[0].evaluate(elementType, context);
        y = elements[1].evaluate(elementType, context);
        z = elements[2].evaluate(elementType, context);
        return new Vector3(x, y, z);
      }

      if (length == 4) {
        double x,y,z,w;
        x = elements[0].evaluate(elementType, context);
        y = elements[1].evaluate(elementType, context);
        z = elements[2].evaluate(elementType, context);
        w = elements[3].evaluate(elementType, context);
        return new Vector4(x, y, z, w);
      }

      if (length > 4) {
        throw new UnimplementedError("Vector of arbitrary length (> 4) are not supported yet.");
      }
    }

    if (type == EvaluationType.REAL && length == 1) {
      // Interpret vector as real number.
      return elements[0].evaluate(type, context);
    }

    throw new UnsupportedError('Vector $this with length $length can not be interpreted as: $type');
  }

  bool get isConstant => elements.fold(true,
    (prev, elem) => prev && elem.isConstant);
}

/**
 * A variable is a named literal.
 */
class Variable extends Literal {
  String get name => value as String;

  /**
   * Creates a variable literal with given name.
   */
  Variable(String name): super(name);

  @override
  bool get isConstant => false;

  Expression derive(String toVar) => name == toVar ? new Number(1.0) : new Number(0.0);

  String toString() => '$name';

  evaluate(type, context) => context.getExpression(name).evaluate(type, context);
}

/**
 * A bound variable is an anonymous variable, e.g. a variable without name,
 * which is bound to an expression.
 */
//TODO This is only used for DefaultFunctions, might as well use an expression
//      directly then and remove some complexity.. leaving this in use right now,
//      since it might be useful some time - maybe for composite functions? (FL)
class BoundVariable extends Variable {
  /**
   * Creates an anonymous variable which is bound to the given expression.
   */
  BoundVariable(Expression expr): super('anon') {
    this.value = expr;
  }

  bool get isConstant => value.isConstant;

  // Anonymous, bound variable, derive content and unbox.
  Expression derive(String toVar) => value.derive(toVar); //TODO Needs boxing?

  // TODO Might need boxing in another variable?
  //      How to reassign anonymous variables to functions?
  Expression simplify() => value.simplify();

  evaluate(EvaluationType type, ContextModel context) =>
    value.evaluate(type, context);

  /// Put bound variable in curly brackets to make them distinguishable.
  String toString() => '{$value}';
}

/**
 * An interval literal.
 */
class IntervalLiteral extends Literal {
  Expression min, max;

  /**
   * Creates a new interval with given borders.
   */
  IntervalLiteral(Expression this.min, Expression this.max);

  /**
   * Creates a new interval with identical borders.
   */
  IntervalLiteral.fromSingle(Expression exp): this.min = exp, this.max = exp;

  Expression derive(String toVar) {
    // Can not derive this yet..
    // TODO Implement interval differentiation.
    throw new UnimplementedError('Interval differentiation not supported yet.');
  }

  Expression simplify() {
    return new IntervalLiteral(min.simplify(), max.simplify());
  }

  evaluate(EvaluationType type, ContextModel context) {
    // Interval borders should evaluate to real numbers..
    num minEval = min.evaluate(EvaluationType.REAL, context);
    num maxEval = max.evaluate(EvaluationType.REAL, context);

    if (type == EvaluationType.INTERVAL) {
      return new Interval(minEval, maxEval);
    }

    if (type == EvaluationType.REAL) {
      // If min == max, we can interpret an interval as real.
      //TODO But should we?
      if (minEval == maxEval) {
        return minEval;
      }
    }

    throw new UnsupportedError('Interval $this can not be interpreted as: ${type}');
  }

  @override
  String toString() => 'I[$min, $max]';
  @override
  bool get isConstant => min.isConstant && max.isConstant;
}
