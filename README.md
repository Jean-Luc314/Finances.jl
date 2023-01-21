# Finances

This small package offers the following objects:

| Object    |   Description                                                                                                                                   |
|-----------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| Mortgages |   Store financial imformation regarding a Mortgage. Methods available to project / visualise cashflows                                          |
| Nominal   |   An object to describe value and currency, with securely defined exchange rates. Methods exist to manipulate e.g., convert between currencies  |
| Currency  |   Define valid currenciesand exchange rates                                                                                                     |

```julia
sinusoid = (1 .+ sin.(range(-π / 2, stop = 3π / 2, length = 150))) ./ 2
m = Mortgage(500000, 0.1, 0.0597, 25)
animate(m, :rate, (1 .+ 5 .* sinusoid) ./ 100, "ExampleAnimations/Mortgage_against_rate.gif")
```

![Animation of Mortgage against rate](https://raw.githubusercontent.com/Jean-Luc314/Finances.jl/main/ExampleAnimations/Mortgage_against_rate.gif)

```julia
animate(m, :term, 5 .+ 20 .* sinusoid, "ExampleAnimations/Mortgage_against_Term.gif")
```

![Animation of Mortgage against Term](https://raw.githubusercontent.com/Jean-Luc314/Finances.jl/main/ExampleAnimations/Mortgage_against_Term.gif)

[![Build Status](https://github.com/Jean-Luc314/Finances.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Jean-Luc314/Finances.jl/actions/workflows/CI.yml?query=branch%3Amain)
