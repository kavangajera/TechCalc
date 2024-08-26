# differentiate.py
from sympy import symbols, diff, sympify

def differentiate(expression, variable):
    x = symbols(variable)
    expr = sympify(expression)
    derivative = diff(expr, x)
    return str(derivative)