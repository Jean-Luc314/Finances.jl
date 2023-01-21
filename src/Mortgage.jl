# COMBAK: Write tests
# COMBAK: Add functionality to return mortgage schedule as a dataframe
# COMBAK: Control print of nominal
# COMBAK: Add stochastic simulation of house prices
# COMBAK: Add rent. Mortgage is profitable when interest - lost investment income / term / d < rent - ΔHouse Price / term / d
# ⇒ term * d * ( interest - rent ) < Lost Investment Income - ΔHouse Price + Fees
# COMBAK: Write an interest object, include rate interval
# COMBAK: Consider writing a cashflow object. It would include a currency and interest rate. There would be a time vector and arbitrary transaction vectors that would be summed (negatives implicit). A PV and plot methods could be written
"""
### Mortgage(price :: Union{Nominal, Real}, deposit :: Real, rate :: Real, term :: Real, frequency :: Symbol = :monthly, stampduty :: Bool = true)
Create a `Mortgage` object

**arguments**
- price :: Union{Nominal, Real}; House price
- deposit :: Real; Percentage deposit paid e.g., 0.1 = 10%
- rate :: Real; Annual percentage rate of interest charged on the loan e.g., 0.0597 = 5.97%
- term :: Real; Term of the mortgage in years e.g. 25 = 25 years
- frequency :: Symbol = :monthly; rate of mortgage repayments :monthly or :annually
- stampduty :: Bool = true; Not yet implemented
----------------
### example
```
Mortgage(150000, 0.1, 0.0597, 25)

c = Currency(:£, Dict(:£ => 1, :WON => 1516.67))
price = Nominal(150000, c)
Mortgage(price, 0.1, 0.0597, 25)
```
"""
struct Mortgage
    price :: Nominal
    deposit :: Real
    rate :: Real
    term :: Real
    frequency :: Symbol
    stampduty :: Bool
    function Mortgage(price :: Union{Nominal, <:Real}, deposit :: Real, rate :: Real, term :: Real, frequency :: Symbol = :monthly, stampduty :: Bool = true)
        # Parse Types
        price = Nominal(price)
        # Validate ranges
        validate(:($deposit < 0), :deposit)
        validate(:($(get_val(price)) < 0), :price)
        validate(:($term < 0), :term)
        valid_freqs = [:monthly, :annually]
        if frequency ∉ valid_freqs error("$frequency ∉ $valid_freqs") end
        # Initiate Mortgage object
        new(price, deposit, rate, term, frequency, stampduty)
    end
end
export Mortgages

"""
### get_price(m :: Mortgage) :: Real
Get the house price from a `Mortgage` object

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
get_price(m)
```
"""
get_price(m :: Mortgage) :: Real = m.price.m
export get_price

"""
### get_currency(m :: Mortgage) :: Symbol 
Get the house price currency from a `Mortgage` object

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
get_currency(m)
```
"""
get_currency(m :: Mortgage) :: Currency = m.price.p
export get_currency

"""
### get_deposit(m :: Mortgage) :: Real
Get the deposit on the house from a `Mortgage` object

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
get_deposit(m)
```
"""
get_deposit(m :: Mortgage) :: Real = m.deposit
export get_deposit

"""
### get_loan(m :: Mortgage) :: Real
Calculate the loan value at t = 0 on the house from a `Mortgage` object

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
get_loan(m)
```
"""
get_loan(m :: Mortgage) :: Real = get_price(m) * (1 - get_deposit(m))
export get_loan

"""
### get_frequency(m :: Mortgage) :: Symbol
Get the frequency of loan repayments from a `Mortgage` object

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
get_frequency(m)
```
"""
get_frequency(m :: Mortgage) :: Symbol = m.frequency
export get_frequency

"""
### get_frequency_num(m :: Mortgage) :: Integer
Get the number of loan repayments per annum from a `Mortgage` object

I.e., :monthly => 12, :annually => 1

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
get_frequency_num(m)
```
"""
get_frequency_num(m :: Mortgage) :: Integer = Dict(:monthly => 12, :annually => 1)[get_frequency(m)]
export get_frequency_num

"""
### get_term(m :: Mortgage) :: Real
Get the `term`, in years, from a `Mortgage` object

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
get_term(m)
```
"""
get_term(m :: Mortgage) :: Real = m.term
export get_term

"""
### get_stampduty(m :: Mortgage) :: Bool
Get the `stampduty` from a `Mortgage` object

`stampduty` has not yet been implemented into any `Mortgage` methods

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
get_stampduty(m)
```
"""
get_stampduty(m :: Mortgage) :: Bool = m.stampduty
export get_stampduty

"""
### get_rate(m :: Mortgage) :: Real
Get the annual `rate` from a `Mortgage` object

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
get_rate(m)
```
"""
get_rate(m :: Mortgage) :: Real = m.rate

"""
### get_rate(m :: Mortgage, d :: Real = 1) :: Real
Get the geometric `rate` from a `Mortgage` object, over time interval [0, 1 / d]

E.g., d = 12 corresponds to monthly interest

`get_rate(m, d) = (1 + m.rate) ^ (1 / d) - 1`

**arguments**
- m :: Mortgage;
- d :: Real;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
get_rate(m, 12)
```
"""
get_rate(m :: Mortgage, d :: Real) :: Real = (1 + get_rate(m)) ^ (1 / d) - 1
export get_rate

"""
### calc_repayment(m :: Mortgage) :: Real
Calculate the loan repayment amount, which will occur `get_frequency_num(m)` times per annum

`calc_repayment()` solves the PV Equation:

d = Repayment frequency e.g., :monthly => 12
a^(d)_<n> = aₙ 
    = PV annuity in arrears, paid dthly with discount rate `get_rate(m)`
    = (1 - (1 + get_rate(m)) ^ -get_term(m)) / (d * get_rate(m, d))
P = dthly repayment
Loan = PV Payments = d * P * aₙ

I.e., P = calc_repayment(m) = get_loan(m) / d / aₙ

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
calc_repayment(m)
```
"""
function calc_repayment(m :: Mortgage) :: Real
    d = get_frequency_num(m)
    # Solve Loan = PV Payments = d * P * a^(d)_<n>
    # Giving P = Loan / d / aₙ
    aₙ = (1 - (1 + get_rate(m)) ^ -get_term(m)) / (d * get_rate(m, d))
    get_loan(m) / d / aₙ
end
export calc_repayment

initialise_time(term :: Real, d :: Integer) = collect(0:1//d:term)
initialise_time(term :: Real, d :: Real) = collect(0:1/d:term)

"""
### cashflow(m :: Mortgage) :: NTuple{4, Vector{<:Real}}
Calculate a projected cashflow for the Mortgage repayments of `m`

`cashflow(m)` returns a Tuple of giving vectors of:

1. Time
2. Outstanding loan value
3. Cumulative interest payments
4. Total payments

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
cashflow(m)
```
"""
function cashflow(m :: Mortgage) :: NTuple{4, Vector{<:Real}}
    # Constant values
    d = get_frequency_num(m)
    P = calc_repayment(m)
    interval_rate = get_rate(m, d)
    term = get_term(m)
    # Initialise time vector
    t = initialise_time(term, d)
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
export cashflow

"""
### project(m :: Mortgage, metric :: Symbol, T :: Union{Real, Nothing} = nothing) :: Real
Extract totals as at time T, default T = Term

**arguments**
- m :: Mortgage;
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
cashflow(m)
```
"""
function project(m :: Mortgage, metric :: Symbol, t :: Union{Real, Nothing} = nothing) :: Real
    valid_metrics = [:loan, :interest, :payments]
    if metric ∉ valid_metrics error("$metric ∉ $valid_metrics") end
    if t === nothing t = get_term(m) end
    time, loan_outstanding, interest_payments, total_payments = cashflow(m)
    index = sum(time .<= t)
    Dict(
        :loan => loan_outstanding,
        :interest => interest_payments,
        :payments => total_payments
        )[metric][index]
end
export project
"""
### tick_tuple(lims, n, format_func :: Function)
Return `ticks` and `ticklables` for the `Plots` `xticks!` and `yticks!`

Provide `format_func` to control the formatting of the tick labels

**arguments**
- lims; two-element tuple, giving the lower and upper limit of the ticks
- n; number of ticks
- format_func :: Function; Single argument function to format the ticks
----------------
### example
```
tick_tuple([0, 10], 5, x -> "£" * string(x))
```
"""
function tick_tuple(lims, n, format_func :: Function)
    Δ = (lims[2] - lims[1]) / (n - 1)
    yticks = lims[1]:Δ:lims[2]
    yticklabels = format_func.(yticks)
    (yticks, yticklabels)
end
"""
### plot(m :: Mortgage, xlims = :auto, ylims = :auto, nyticks = 6, title = "Mortgage Repayment Schedule", xlabel = "Time (Years)")
Plot the cashflow projection of a `Mortgage` object

The plot will illustrate:
    `Loan Outstanding`
    `Cumulative Interest`
    `Total Payments`

**arguments**
- m :: Mortgage; A `Mortgage` object
- xlims; Two-element `Vector`, giving lower and upper limits of x-axis. Defaults to `:auto`
- ylims; Two-element `Vector`, giving lower and upper limits of y-axis. Defaults to `:auto`
- nyticks; Number of y-ticks
- title; Title of plot
- xlabel; x-axis label
----------------
### example
```
m = Mortgage(150000, 0.1, 0.0597, 25)
plot(m :: Mortgage)
```
"""
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
    format_percent = format("", "%", 2, 100, "")
    title!(title * "\nrate = " * format_percent(get_rate(m)) * ", deposit = " * format_percent(get_deposit(m)))
    xlabel!(xlabel)
    p
end
export plot
"""
### animate(m :: Mortgage, variable :: Symbol, values, filename, fps = 15, xlims = :auto, ylims = :auto, nyticks = 6, title = "Mortgage Repayment Schedule", xlabel = "Time (Years)")
Create an animation of `Mortgage` repayment schedules, where one of the parameters is allowed to vary

The animation combine plots of:
    `Loan Outstanding`
    `Cumulative Interest`
    `Total Payments`

`variable` determines which parameter is 

**arguments**
- m :: Mortgage; A `Mortgage` object
- variable :: Symbol; Variable to animate over. Allowed values `[:price, :deposit, :rate, :term]`
- values; Values of `variable` to plot within the animation
- filename; Location of animation save
- fps; Frames per second
- xlims; Two-element `Vector`, giving lower and upper limits of x-axis. Defaults to `:auto`
- ylims; Two-element `Vector`, giving lower and upper limits of y-axis. Defaults to `:auto`
- nyticks; Number of y-ticks
- title; Title of plot
- xlabel; x-axis label
----------------
### example
```
sinusoid = (1 .+ sin.(range(-π / 2, stop = 3π / 2, length = 150))) ./ 2
m = Mortgage(500000, 0.1, 0.0597, 25)
animate(m, :rate, (1 .+ 5 .* sinusoid) ./ 100, "ExampleAnimations/Mortgage_against_rate.gif")
animate(m, :term, 5 .+ 20 .* sinusoid, "ExampleAnimations/Mortgage_against_Term.gif")
```
"""
function animate(m :: Mortgage, variable :: Symbol, values, filename, fps = 15, xlims = :auto, ylims = :auto, nyticks = 6, title = "Mortgage Repayment Schedule", xlabel = "Time (Years)")
    valid_vars = [:price, :deposit, :rate, :term]
    if variable ∉ valid_vars error("$variable ∉ $valid_vars") end
    # Lookup `variable` in a dictionary of functions
        # The function create a Mortgage given a value from `values`
    # Broadcast into `values` i.e., produce a vector of `Mortgage`, where the appropriate `variable` varies in value
    mortgages = Dict(
        :price      => p -> Mortgage(p,                 get_deposit(m), get_rate(m),    get_term(m),        get_frequency(m), get_stampduty(m)),
        :deposit    => d -> Mortgage(get_price(m),      d,              get_rate(m),    get_term(m),        get_frequency(m), get_stampduty(m)),
        :rate       => r -> Mortgage(get_price(m),      get_deposit(m), r,              get_term(m),        get_frequency(m), get_stampduty(m)),
        :term       => t -> Mortgage(get_price(m),      get_deposit(m), get_rate(m),    t,                  get_frequency(m), get_stampduty(m))
    )[variable].(values)
    # Broadcast `cashflow` across the Vector{`Mortgage`}
    cashflows = cashflow.(mortgages)
    # Fix y-limits to their maximum range
    total_payments = [c[4] for c ∈ cashflows]
    terms = [t[1] for t ∈ cashflows]
    if ylims == :auto ylims = (minimum(minimum.(total_payments)), maximum(maximum.(total_payments))) end
    # If `term` varies, fix x-limits to their maximum range
    if variable == :term xlims = (minimum(minimum.(terms)), maximum(maximum.(terms))) end
    # Produce animation
    anim = @animate for mortgage ∈ mortgages plot(mortgage, xlims, ylims, nyticks, title, xlabel) end
    gif(anim, filename, fps = fps)
end
export animate