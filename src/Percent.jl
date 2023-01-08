# COMBAK: Delete Percent(), redesign format to have prefix, suffix, separator, digits args
"""
### Percent(p :: Real, p_min :: Real = -10, p_max :: Real = 10)
Create a `Percent` object

Use `p_min` and `p_max` to enforce range boundaries

**arguments**
- p :: Real; Value of percent variable
- p_min :: Real; Lower bound on acceptable values
- p_max :: Real; Upper bound on acceptable values
----------------
### example
```
Percent(0.1)
```
"""
struct Percent
    p :: Real
    # Choose to control the valid range
    function Percent(p :: Real, p_min :: Real = -10, p_max :: Real = 10)
        validate(:($p > $p_max), :p, :p_max)
        validate(:($p < $p_min), :p, :p_min)
        new(p)
    end
end

Percent(p :: Percent) = p
Percent() = Percent(0)

format(percent :: Percent, digits = 2) = x -> string(round(x * 100, digits = digits)) * "%"
export format