# COMBAK: Add functionality to return mortgage schedule as a dataframe
# COMBAK: Handle a Nominal(m :: Vector{<:Real}, p :: Currency). Use broadcasting
# COMBAK: Add ==(c₁ :: Currency, c₂ :: Currency)
# COMBAK: Add ==(m₁ :: Nominal, m₂ :: Nominal), update convert() documentation example
# COMBAK: Add *(m :: Nominal, x :: Real) & *(x :: Real, m :: Nominal)
# COMBAK: Add *(m :: Nominal, x :: Percent) & *(x :: Percent, m :: Nominal)
# COMBAK: Add +(m :: Nominal, n :: Nominal), must check currencies match
# COMBAK: Use Val() on format(Percent()) ?
"""
### Currency(p :: Symbol)
### Currency(p :: Symbol, conversions :: Dict{Symbol, Real})
Creates a Currency object

`Currency(p, conversions)` can store user-defined convertion factors

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
### format(currency :: Currency) :: Function
Return a function that, when called, returns the integer component of a number, prepended by its currency, and comma deliminated

The function returned will round down its `Real` input.
    
**arguments**
- currency :: Currency;
----------------
### example
```
format_pound = format(Currency(:£))
format_pound(2345603)
format_pound(2345603.01)
format_pound(2345603.06)
```
"""
format(currency :: Currency) :: Function = x -> string(currency.p) * replace(string(Int(floor(x))), r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => ",")

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

struct Mortgage
    price :: Nominal
    deposit :: Percent
    rate :: Percent
    term :: Real
    frequency :: Symbol
    stampduty :: Bool
    function Mortgage(price, deposit, rate, term, frequency = :monthly, stampduty = true)
        # Parse Types
        price = Nominal(price)
        deposit = Percent(deposit)
        rate = Percent(rate)
        # Validate ranges
        validate(:($(price.m) < 0), :price)
        validate(:($term < 0), :term)
        valid_freqs = [:monthly, :annually]
        if frequency ∉ valid_freqs error("$frequency ∉ $valid_freqs") end
        # Initiate Mortgage object, Parse types
        new(price, deposit, rate, term, frequency, stampduty)
    end
end
export Mortgages

get_price(m :: Mortgage) = m.price.m
export get_price
get_currency(m :: Mortgage) = m.price.p
get_deposit(m :: Mortgage) = m.deposit.p
get_loan(m :: Mortgage) = get_price(m) * (1 - get_deposit(m))
get_frequency(m :: Mortgage) = m.frequency
get_frequency_num(m :: Mortgage) = Dict(:monthly => 12, :annually => 1)[get_frequency(m)]
get_term(m :: Mortgage) = m.term
get_stampduty(m :: Mortgage) = m.stampduty
# Interest rate over 1/d time period
get_rate(m :: Mortgage, d :: Real = 1) = (1 + m.rate.p) ^ (1 / d) - 1
function payment(m :: Mortgage)
    d = get_frequency_num(m)
    # Solve Loan = PV Payments = d * P * a^(d)_<n>
    # Giving P = Loan / d / aₙ
    aₙ = (1 - (1 + get_rate(m)) ^ -get_term(m)) / (d * get_rate(m, d))
    get_loan(m) / d / aₙ
end
function cashflow(m :: Mortgage)
    # Constant values
    d = get_frequency_num(m)
    P = payment(m)
    interval_rate = get_rate(m, d)
    # Initialise time vector
    t = collect(0:1//d:get_term(m))
    len = length(t)
    # Initialise vectors
    loan_outstanding = zeros(len)
    interest_payments = zeros(len)
    total_payments = zeros(len)
    loan_outstanding[1] = get_loan(m)
    # Through time, deduct payment from loan, add interest, repeat
    for j in 2:len
        interest = interval_rate * loan_outstanding[j - 1]
        capital_repaid = P - interest
        loan_outstanding[j] = loan_outstanding[j - 1] - capital_repaid
        interest_payments[j] = interest_payments[j - 1] + interest
        total_payments[j] = total_payments[j - 1] + P
    end
    (t, loan_outstanding, interest_payments, total_payments)
end
# Extract totals as at time T, default T = Term
function cumulate(m :: Mortgage, metric :: Symbol, T :: Union{Real, Nothing} = nothing)
    valid_metrics = [:payments, :interest, :interest_ratio]
    if metric ∉ valid_metrics error("$metric ∉ $valid_metrics") end
    if T === nothing T = get_term(m) end
    t, _, interest_payments, total_payments = cashflow(m)
    index = sum(t .<= T)
    Dict(
        :payments => total_payments,
        :interest => interest_payments,
        :interest_ratio => interest_payments ./ total_payments
        )[metric][index]
end
function tick_tuple(lims, n, func :: Function)
    Δ = (lims[2] - lims[1]) / n
    yticks = lims[1]:Δ:lims[2]
    yticklabels = func.(yticks)
    (yticks, yticklabels)
end
function plot(m :: Mortgage, xlims = :auto, ylims = :auto, nyticks = 6, title = "Mortgage Repayment Schedule", xlabel = "Time (Years)")
    t, loan_outstanding, interest_payments, total_payments = cashflow(m)
    # Plot schedules
    p = plot(t, loan_outstanding, label = "Loan Outstanding", xlims = xlims, ylims = ylims)
    plot!(t, interest_payments, label = "Cumulative Interest")
    plot!(t, total_payments, label = "Total Payments")
    # Add Original Price
    plot!(t, [m.price.m for x in t], ls = :dot, label = "Original Price")
    # Format yticks
    if ylims == :auto ylims = (0, maximum(maximum.([loan_outstanding, interest_payments, total_payments]))) end
    yticks!(tick_tuple(ylims, nyticks, format(get_currency(m))))
    # Additional features
    plot!(legend = :topleft)
    format_percent = format(Percent())
    title!(title * "\nrate = " * format_percent(get_rate(m)) * ", deposit = " * format_percent(get_deposit(m)))
    xlabel!(xlabel)
    p
end
function simulate(m :: Mortgage, variable :: Symbol, values, filename, fps = 15, xlims = :auto, ylims = :auto, nyticks = 6, title = "Mortgage Repayment Schedule", xlabel = "Time (Years)")
    valid_vars = [:price, :deposit, :rate, :term]
    if variable ∉ valid_vars error("$variable ∉ $valid_vars") end
    mortgages = Dict(
        :price => p -> Mortgage(p, get_deposit(m), get_rate(m), get_term(m), get_frequency(m), get_stampduty(m)),
        :deposit => d -> Mortgage(get_price(m), d, get_rate(m), get_term(m), get_frequency(m), get_stampduty(m)),
        :rate => r -> Mortgage(get_price(m), get_deposit(m), r, get_term(m), get_frequency(m), get_stampduty(m)),
        :term => t -> Mortgage(get_price(m), get_deposit(m), get_rate(m), t, get_frequency(m), get_stampduty(m))
    )[variable].(values)
    cashflows = cashflow.(mortgages)
    total_payments = [c[4] for c ∈ cashflows]
    terms = [t[1] for t ∈ cashflows]
    if ylims == :auto ylims = (minimum(minimum.(total_payments)), maximum(maximum.(total_payments))) end
    if variable == :term xlims = (minimum(minimum.(terms)), maximum(maximum.(terms))) end
    anim = @animate for mortgage ∈ mortgages plot(mortgage, xlims, ylims, nyticks, title, xlabel) end
    gif(anim, filename, fps = fps)
end


# Control print of nominal
# Add stochastic simulation of house prices
# Add rent. Mortgage is profitable when interest - lost investment income / term / d < rent - ΔHouse Price / term / d
# ⇒ term * d * ( interest - rent ) < Lost Investment Income - ΔHouse Price + Fees