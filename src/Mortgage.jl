# COMBAK: Add functionality to return mortgage schedule as a dataframe
# COMBAK: Control print of nominal
# COMBAK: Add stochastic simulation of house prices
# COMBAK: Add rent. Mortgage is profitable when interest - lost investment income / term / d < rent - ΔHouse Price / term / d
# ⇒ term * d * ( interest - rent ) < Lost Investment Income - ΔHouse Price + Fees
struct Mortgage
    price :: Nominal
    deposit :: Real
    rate :: Real
    term :: Real
    frequency :: Symbol
    stampduty :: Bool
    function Mortgage(price, deposit, rate, term, frequency = :monthly, stampduty = true)
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

get_price(m :: Mortgage) = m.price.m
export get_price
get_currency(m :: Mortgage) = m.price.p
export get_currency
get_deposit(m :: Mortgage) = m.deposit.p
export get_deposit
get_loan(m :: Mortgage) = get_price(m) * (1 - get_deposit(m))
export get_loan
get_frequency(m :: Mortgage) = m.frequency
export get_frequency
get_frequency_num(m :: Mortgage) = Dict(:monthly => 12, :annually => 1)[get_frequency(m)]
export get_frequency_num
get_term(m :: Mortgage) = m.term
export get_term
get_stampduty(m :: Mortgage) = m.stampduty
export get_stampduty
# Interest rate over 1/d time unit
get_rate(m :: Mortgage, d :: Real = 1) = (1 + m.rate.p) ^ (1 / d) - 1
export get_rate
function payment(m :: Mortgage)
    d = get_frequency_num(m)
    # Solve Loan = PV Payments = d * P * a^(d)_<n>
    # Giving P = Loan / d / aₙ
    aₙ = (1 - (1 + get_rate(m)) ^ -get_term(m)) / (d * get_rate(m, d))
    get_loan(m) / d / aₙ
end
export payment
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
export cashflow
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
export cumulate
function tick_tuple(lims, n, format_func :: Function)
    Δ = (lims[2] - lims[1]) / n
    yticks = lims[1]:Δ:lims[2]
    yticklabels = format_func.(yticks)
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
    format_percent = format("", "%", 2, 100, "")
    title!(title * "\nrate = " * format_percent(get_rate(m)) * ", deposit = " * format_percent(get_deposit(m)))
    xlabel!(xlabel)
    p
end
export plot
function animate(m :: Mortgage, variable :: Symbol, values, filename, fps = 15, xlims = :auto, ylims = :auto, nyticks = 6, title = "Mortgage Repayment Schedule", xlabel = "Time (Years)")
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
export animate