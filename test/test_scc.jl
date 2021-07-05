using Test
using Mimi

include("../src/compute_scc.jl")

m = getpage("RCP4.5 & SSP2", true, true, true)
run(m)
uds = [undiscount_scc(m, 2020), undiscount_scc(m, 2040), undiscount_scc(m, 2075)]
uds_compare = [0.8765, 0.5279, 0.2162] # From Excel PAGE-ICE
@test uds ≈ uds_compare rtol=1e-4

function checksccs(sccs, scccomp)
    sccobs = [quantile(sccs, [.05, .25, .5, .75, .95]); mean(sccs)]
    sccerror = abs.((sccobs - scccomp) ./ [10, 1, 1, 1, 10, 1])
    sccsd = std(sccs) / sqrt(100_000)
    @test all(sccerror .< 3*sccsd) # average off by < 3x SD
end

m = getpage("RCP4.5 & SSP2", true, true, true)
sccs = compute_scc_mcs(m, 100_000, year=2020)

m = getpage("RCP8.5 & SSP5", true, true, true)
sccs = compute_scc_mcs(m, 100_000, year=2020)

m = getpage("RCP4.5 & SSP2", true, true, false)
sccs = compute_scc_mcs(m, 1000, year=2020)

m = getpage("RCP8.5 & SSP5", true, true, false)
sccs = compute_scc_mcs(m, 100_000, year=2020)
