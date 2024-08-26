from sympy import symbols, integrate as sympy_integrate, sympify

def integrate(expression, variable):
    x = symbols(variable)
    expr = sympify(expression)
    print(f"Integrating: {expr} with respect to {x}")  # Debugging line
    integral = sympy_integrate(expr, x)
    print(f"Result: {integral}")  # Debugging line
    return str(integral)
