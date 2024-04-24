@defcomp SLRDamages begin
    country = Index()

    y_year = Parameter(index=[time], unit="year")
    y_year_0 = Parameter(unit="year")

    # incoming parameters from SeaLevelRise
    s_sealevel = Parameter(index=[time], unit="m")

    pop_population = Parameter(index=[time, country], unit="million person")

    # incoming parameters to calculate consumption per capita after Costs
    cons_percap_consumption = Parameter(index=[time, country], unit="\$/person")
    cons_percap_consumption_0 = Parameter(index=[country], unit="\$/person")
    tct_per_cap_totalcostspercap = Parameter(index=[time,country], unit="\$/person")
    act_percap_adaptationcosts = Parameter(index=[time, country], unit="\$/person")

    # component parameters
    save_savingsrate = Parameter(unit="%", default=15.00) # pp33 PAGE09 documentation, "savings rate".

    alpha_noadapt = Parameter(index=[country])
    beta_noadapt = Parameter(index=[country])
    alpha_optimal = Parameter(index=[country])
    beta_optimal = Parameter(index=[country])
    saf_slradaptfrac = Parameter(index=[time, country])

    # component variables
    cons_percap_aftercosts = Variable(index=[time, country], unit="\$/person")
    gdp_percap_aftercosts = Variable(index=[time, country], unit="\$/person")

    d_slr = Variable(index=[time, country], unit="\$")
    d_percap_slr = Variable(index=[time, country], unit="\$/person")

    rcons_per_cap_SLRRemainConsumption = Variable(index=[time, country], unit="\$/person")
    rgdp_per_cap_SLRRemainGDP = Variable(index=[time, country], unit="\$/person")


    function run_timestep(p, v, d, t)
        slrmm = p.s_sealevel * 1000
        damage_noadapt = p.alpha_noadapt * slrmm + p.beta_noadapt * slrmm^2
        damage_optimal = p.alpha_optimal * slrmm + p.beta_optimal * slrmm^2

        v.d_slr[t, :] = damage_noadapt * (1 - p.saf_slradaptfrac) + damage_optimal * p.saf_slradaptfrac
        v.d_percap_slr[t, :] = v.d_slr[t, :] / (p.pop_population[t, :] * 1e6)

        for cc in d.country
            v.cons_percap_aftercosts[t, cc] = p.cons_percap_consumption[t, cc] - p.tct_per_cap_totalcostspercap[t, cc] - p.act_percap_adaptationcosts[t, cc]

            if (v.cons_percap_aftercosts[t, cc] < 0.01 * p.cons_percap_consumption_0[1])
                v.cons_percap_aftercosts[t, cc] = 0.01 * p.cons_percap_consumption_0[1]
            end

            v.gdp_percap_aftercosts[t,cc] = v.cons_percap_aftercosts[t, cc] / (1 - p.save_savingsrate / 100)

            v.rcons_per_cap_SLRRemainConsumption[t,cc] = v.cons_percap_aftercosts[t,cc] - v.d_percap_slr[t, cc]
            v.rgdp_per_cap_SLRRemainGDP[t,cc] = v.rcons_per_cap_SLRRemainConsumption[t,cc] / (1 - p.save_savingsrate / 100)
        end
    end
end


# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.
function addslrdamages(model::Model)
    SLRDamagescomp = add_comp!(model, SLRDamages)

    SLRDamagescomp[:alpha_noadapt] = readcountrydata_im(model, "damages/slremul.csv", :adm0, :bs, nothing, "alpha.damage.noadapt", values -> 0.)
    SLRDamagescomp[:beta_noadapt] = readcountrydata_im(model, "damages/slremul.csv", :adm0, :bs, nothing, "beta.damage.noadapt", values -> 0.)
    SLRDamagescomp[:alpha_optimal] = readcountrydata_im(model, "damages/slremul.csv", :adm0, :bs, nothing, "alpha.damage.optimal", values -> 0.)
    SLRDamagescomp[:beta_optimal] = readcountrydata_im(model, "damages/slremul.csv", :adm0, :bs, nothing, "beta.damage.optimal", values -> 0.)
    SLRDamagescomp[:saf_slradaptfrac] = Matrix(0.5, dim_count(model, :time), dim_count(model, :country))

    return SLRDamagescomp
end
