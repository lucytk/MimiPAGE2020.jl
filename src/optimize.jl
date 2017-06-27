using Mimi
using OptiMimi
include("getpagefunction.jl")

# Create the model
m = Model()
setindex(m, :time, [2009, 2010, 2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200])
setindex(m, :region, ["EU", "USA", "OECD","USSR","China","SEAsia","Africa","LatAmerica"])

@defcomp AbatementScale begin
    region=Index()

    emissiongrowthfactor = Parameter(unit="% of normal growth")

    er_CO2emissionsgrowth = Parameter(index=[time,region],unit="%")
    er_CH4emissionsgrowth = Parameter(index=[time,region],unit="%")
    er_N2Oemissionsgrowth = Parameter(index=[time,region],unit="%")
    er_LGemissionsgrowth = Parameter(index=[time,region],unit="%")

    er_CO2emissionsgrowth_new = Variable(index=[time,region],unit="%")
    er_CH4emissionsgrowth_new = Variable(index=[time,region],unit="%")
    er_N2Oemissionsgrowth_new = Variable(index=[time,region],unit="%")
    er_LGemissionsgrowth_new = Variable(index=[time,region],unit="%")
end

function run_timestep(s::AbatementScale, tt::Int64)
    v = s.Variables
    p = s.Parameters
    d = s.Dimensions

    for rr in d.region
        v.er_CO2emissionsgrowth_new[tt, rr] = p.er_CO2emissionsgrowth[tt, rr] * p.emissiongrowthfactor / 100
        v.er_CH4emissionsgrowth_new[tt, rr] = p.er_CH4emissionsgrowth[tt, rr] * p.emissiongrowthfactor / 100
        v.er_N2Oemissionsgrowth_new[tt, rr] = p.er_N2Oemissionsgrowth[tt, rr] * p.emissiongrowthfactor / 100
        v.er_LGemissionsgrowth_new[tt, rr] = p.er_LGemissionsgrowth[tt, rr] * p.emissiongrowthfactor / 100
    end
end

addcomponent(m, AbatementScale)

buildpage(m)

connectparameter(m, :co2emissions, :er_CO2emissionsgrowth, :AbatementScale, :er_CO2emissionsgrowth_new)
connectparameter(m, :ch4emissions, :er_CH4emissionsgrowth, :AbatementScale, :er_CH4emissionsgrowth_new)
connectparameter(m, :n2oemissions, :er_N2Oemissionsgrowth, :AbatementScale, :er_N2Oemissionsgrowth_new)
connectparameter(m, :LGemissions, :er_LGemissionsgrowth, :AbatementScale, :er_LGemissionsgrowth_new)

# Initial value of q0propinit
setparameter(m, :AbatementScale, :emissiongrowthfactor, 90.)

initpage(m)
run(m)

bestpolicy(model::Model) = -model[:EquityWeighting, :te_totaleffect]

optprob = problem(m, [:AbatementScale], [:emissiongrowthfactor], [0.], [100.0], bestpolicy);
(maxf, maxx) = solution(optprob, () -> [90.])

# (-3.006562326528711e7,[0.0])

worstpolicy(model::Model) = model[:EquityWeighting, :te_totaleffect]

optprob = problem(m, [:AbatementScale], [:emissiongrowthfactor], [0.], [100.0], worstpolicy);
(maxf, maxx) = solution(optprob, () -> [90.])

# (2.1320245992205706e8,[100.0])

erfactors = convert(Vector{Float64}, linspace(0, 100, 100))
results = sensitivity(m, :AbatementScale, :emissiongrowthfactor, model -> model[:EquityWeighting, :te_totaleffect], erfactors)

using Plots
plotly()
plot(erfactors, results, xlab="Emissions Growth Factor (%)", ylab="Total Effect")
