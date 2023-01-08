# COMBAK: may be able to improve validate() as a macro
"""
### validate(expression :: Union{Expr, Symbol}, vars :: Union{Expr, Symbol}...)
Validate an expression and on error return a useful / custom message to the user

Caution: `expression` will be evaluated in Global Scope via eval() 

I.e., if `validate()` is called within a function, where variables within `expression` are in Global Scope as well as function scope, then the Global values will be evaluated.

**arguments**
- expression :: Union{Expr, Symbol}; expression to be evalueted (to Boolean). On false evaluation, expression is printed within the error() call
- vars :: Union{Expr, Symbol}...; Additional information to return within error call, if expression evaluates to false
----------------
### example
```
p = 1.5
p_max = 1
validate(:(\$p > \$p_max), :(p = \$p), :(p_max = \$p_max))
```
"""
validate(expression :: Union{Expr, Symbol}, vars :: Union{Expr, Symbol}...) = eval(expression) ? error(string(expression) * "\nVars:\n" * join(string.(vars), "\n")) : nothing

"""
### validate(expression :: Union{Expr, Symbol}, vars :: Union{Expr, Symbol}...)
Validate an expression and on error return a useful / custom message to the user

Caution: `expression` will be evaluated in Global Scope via eval() 

I.e., if `validate()` is called within a function, where variables within `expression` are in Global Scope as well as function scope, then the Global values will be evaluated.

**arguments**
- expression :: Union{Expr, Symbol}; expression to be evalueted (to Boolean). On false evaluation, expression is printed within the error() call
----------------
### example
```
p = 1.5
p_max = 1
validate(:(\$p > \$p_max))
```
"""
validate(expression :: Union{Expr, Symbol}) = eval(expression) ? error(string(expression)) : nothing