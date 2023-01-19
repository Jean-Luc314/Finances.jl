# COMBAK: Handle a Nominal(m :: Vector{<:Real}, p :: Currency). Use broadcasting
# COMBAK: Add ==(c₁ :: Currency, c₂ :: Currency)
# COMBAK: Add ==(m₁ :: Nominal, m₂ :: Nominal), update convert() documentation example
# COMBAK: Add *(m :: Nominal, x :: Real) & *(x :: Real, m :: Nominal)
# COMBAK: Add *(m :: Nominal, x :: Percent) & *(x :: Percent, m :: Nominal)
# COMBAK: Add +(m :: Nominal, n :: Nominal), must check currencies match
"""
### Currency(p :: Symbol)
### Currency(p :: Symbol, conversions :: Dict{Symbol, Real})
Creates a Currency object

`Currency(p, conversions)` can store user-defined conversion factors

**arguments**
- p :: Symbol; currency symbol
- conversions :: Dict{Symbol, Real}; Currency conversion factors
----------------
### example
```
Currency(:£)
Currency(:WON, Dict(:£ => 1, :WON => 1516.67))
```
"""
struct Currency
    p :: Symbol
    conversions :: Dict{Symbol, <:Real}
    function Currency(p :: Symbol)
        conversions = Dict(p => 1)
        Currency(p, conversions)
    end
    function Currency(p :: Symbol, conversions :: Dict{Symbol, <:Real})
        if p ∉ keys(conversions) error("$p ∉ $(keys(conversions))") end
        new(p, conversions)
    end
end
export Currency

"""
### get_cur(c :: Currency) :: Symbol
Get currency Symbol from `c`

**arguments**
- c :: Currency
----------------
### example
```
c = Currency(:WON, Dict(:£ => 1, :WON => 1516.67))
get_cur(c)
```
"""
get_cur(c :: Currency) :: Symbol = c.p

"""
### get_conversions(c :: Currency) :: Dict{Symbol, <:Real}
Get currency conversion Dict from `c`

**arguments**
- c :: Currency
----------------
### example
```
c = Currency(:WON, Dict(:£ => 1, :WON => 1516.67))
get_conversions(c)
```
"""
get_conversions(c :: Currency) :: Dict{Symbol, <:Real} = c.conversions

"""
### convert(c :: Currency, to :: Symbol) :: Currency
Convert the currency `c` into currency `to`

Constraint: `to ∈ keys(get_conversions(c))`

Conversion factors are maintained

**arguments**
- c :: Currency;
- to :: Symbol;
----------------
### example
```
c = Currency(:WON, Dict(:£ => 1, :WON => 1516.67))
convert(c, :£)
```
"""
function convert(c :: Currency, to :: Symbol) :: Currency
    con_Dict = get_conversions(c)
    if to ∉ keys(con_Dict) error("$to ∉ $(keys(con_Dict))") end
    Currency(to, con_Dict)
end

"""
### Nominal(m :: Real, p :: Currency)
Create a `Nominal` from `m` and `p`

**arguments**
- m :: Real; monetary value
- p :: Currency; currency of monetary value
----------------
### example
```
Nominal(1000, Currency(:£))
```
"""
struct Nominal
    m :: Real
    p :: Currency
end

"""
### Nominal(m :: Real)
Create a `Nominal` from `m`

Default currency is `:£`

**arguments**
- m :: Real; monetary value
----------------
### example
```
Nominal(1000)
```
"""
Nominal(m :: Real) = Nominal(m, Currency(:£))
# Identity, useful for parsing arguments
Nominal(m :: Nominal) = m
export Nominal

"""
### get_val(m :: Nominal) :: Real
Get `Real` value from `m`

**arguments**
- m :: Nominal;
----------------
### example
```
m = Nominal(500000)
get_val(m)
```
"""
get_val(m :: Nominal) :: Real = m.m
export get_val

"""
### get_currency(m :: Nominal) :: Currency
Get currency object from `m`

**arguments**
- m :: Nominal;
----------------
### example
```
m = Nominal(500000)
get_currency(m)
```
"""
get_currency(m :: Nominal) :: Currency = m.p
export get_currency

"""
### get_conversions(m :: Nominal) :: Dict{Symbol, <:Real}
Get currency conversion Dict from `m`

**arguments**
- m :: Nominal
----------------
### example
```
c = Currency(:WON, Dict(:£ => 1, :WON => 1516.67))
m = Nominal(500000, c)
get_conversions(m)
```
"""
get_conversions(m :: Nominal) :: Dict{Symbol, <:Real} = get_conversions(m.p)
export get_conversions

"""
### convert(nom :: Nominal, to :: Currency) :: Nominal
Convert the currency of `m` to `to`

**arguments**
- m :: Nominal;
- to :: Currency;
----------------
### example
```
c = Currency(:£, Dict(:£ => 1, :WON => 1516.67))
m_£ = Nominal(500000, c)
m_WON = convert(m_£, :WON)
get_val(convert(m_WON, :£)) == get_val(m_£)
```
"""
convert(m :: Nominal, to :: Symbol) :: Nominal = Nominal(m.m / get_conversions(m.p)[m.p.p] * get_conversions(m.p)[to], convert(m.p, to))
export convert