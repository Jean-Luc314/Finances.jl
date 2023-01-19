# COMBAK: format() does not work as intended for large numers (scientific notation)
"""
### format(prefix :: String = "", suffix :: String = "", digits :: Integer = 2, scale :: Real = 1, delim :: String = ",") :: Function
Return a function that formats a `Real` number according to the options set
    
I.e., f = format(...) returns f(x::Real)::String

**arguments**
- prefix :: String = "";
- suffix :: String = "";
- digits :: Integer = 1; Control rounding
- scale :: Real = 1; Multiple, the return function's input, by a factor. E.g., 100 for percentages
- delim :: String = ","; Separator every three digits e.g. 1000 => 1,000 
----------------
### example
```
format_percent = format("", "%", 2, 100, "")
format_percent(0.20743)
```
"""
function format(prefix :: String = "", suffix :: String = "", digits :: Integer = 2, scale :: Real = 1, delim :: String = ",") :: Function
    int_round(x, r) = r ? Int(x) : x
    x -> prefix * replace(string(int_round(round(x * scale, digits = digits), digits == 0)), r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => delim) * suffix
end
"""
### format(c :: Currency, digits = 2, prepend_cur :: Bool = true) :: Function
Return a function that formats a `Real` number according to the options set
    
I.e., f = format(...) returns f(x::Real)::String

**arguments**
- c :: Currency = "";
- digits :: Integer = 2; Control rounding
- prepend_cur :: Bool = true; Prepend vs append the currency symbol 
----------------
### example
```
format_pound = format(Currency(:£))
format_pound(20343.20743)
```
"""
function format(c :: Currency, digits = 2, prepend_cur :: Bool = true) :: Function
    cur = string(get_cur(c))
    if prepend_cur
        format(cur, "", digits, 1, ",")
    else
        format("", cur, digits, 1, ",")
    end
end
export format