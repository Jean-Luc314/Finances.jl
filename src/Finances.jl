module Finances

using Plots
import Plots: plot

include("validate.jl")
include("Nominal.jl")
include("format.jl")
include("Mortgage.jl")

end # Module
