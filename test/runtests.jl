using Finances
using Test

@testset "Finances.jl" begin
    @test Finances.get_price(Finances.Mortgage(100000, 0.1, 0.0597, 25)) == 100000
end
