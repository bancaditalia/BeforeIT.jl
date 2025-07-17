
abstract type AbstractData <: AbstractObject end

# Define the Data struct
Bit.@object struct Data(Object) <: AbstractData
    collection_time::Vector{Bit.typeInt}
    nominal_gdp::Vector{Bit.typeFloat}
    real_gdp::Vector{Bit.typeFloat}
    nominal_gva::Vector{Bit.typeFloat}
    real_gva::Vector{Bit.typeFloat}
    nominal_household_consumption::Vector{Bit.typeFloat}
    real_household_consumption::Vector{Bit.typeFloat}
    nominal_government_consumption::Vector{Bit.typeFloat}
    real_government_consumption::Vector{Bit.typeFloat}
    nominal_capitalformation::Vector{Bit.typeFloat}
    real_capitalformation::Vector{Bit.typeFloat}
    nominal_fixed_capitalformation::Vector{Bit.typeFloat}
    real_fixed_capitalformation::Vector{Bit.typeFloat}
    nominal_fixed_capitalformation_dwellings::Vector{Bit.typeFloat}
    real_fixed_capitalformation_dwellings::Vector{Bit.typeFloat}
    nominal_exports::Vector{Bit.typeFloat}
    real_exports::Vector{Bit.typeFloat}
    nominal_imports::Vector{Bit.typeFloat}
    real_imports::Vector{Bit.typeFloat}
    operating_surplus::Vector{Bit.typeFloat}
    compensation_employees::Vector{Bit.typeFloat}
    wages::Vector{Bit.typeFloat}
    taxes_production::Vector{Bit.typeFloat}
    gdp_deflator_growth_ea::Vector{Bit.typeFloat}
    real_gdp_ea::Vector{Bit.typeFloat}
    euribor::Vector{Bit.typeFloat}
    nominal_sector_gva::Vector{Vector{Bit.typeFloat}}
    real_sector_gva::Vector{Vector{Bit.typeFloat}}
end

# Define the DataVector struct
struct DataVector{D<:AbstractData}
    vector::Vector{D}
end
DataVector(model::AbstractModel) = DataVector([model.data])
DataVector(model_vec::Vector{<:AbstractModel}) = DataVector([model.data for model in model_vec])

# Define the getproperty function for the DataVector struct
# This function allows for the extraction of fields from the Data struct
# by using the dot syntax, e.g., data_vector.nominal_gdp
function Base.getproperty(dv::DataVector, name::Symbol)
    if name in fieldnames(Bit.Data)
        # If the field name exists in the `a` struct, extract it from all elements
        return hcat([getproperty(d, name) for d in dv.vector]...)
    else
        # Fallback to default behavior for other fields
        return getfield(dv, name)
    end
end
Base.getindex(dv::DataVector, i::Int) = Base.getindex(getfield(dv, :vector), i)
Base.length(dv::DataVector) = Base.length(getfield(dv, :vector))
Base.iterate(dv::DataVector) = Base.iterate(getfield(dv, :vector))
Base.iterate(dv::DataVector, state) = Base.iterate(getfield(dv, :vector), state)

"""
    update_data!(m)

Update the data in the model `m` with the current state of the model. Returns
the updated model `m`.

If one wants to track more data of the model of what is provided by default, one needs to
extend all the pipeline for data tracking, which involves to

1. Create a new model struct inheriting from `Bit.Model` with `Bit.@object`
1. Create a new data struct (e.g. `ExtendedData`) inheriting from `Bit.Data` with `Bit.@object`
2. Implement a new function `ExtendedData()` which just allocates empty containers for the
   data tracking
3. Extend `update_data!` by extending its components (`allocate_new_data!`, `update_data_init!`
   and `update_data_step!`)

Note that you can use @invoke in point 3. to use the standard functions so that you don't need
to copy-paste the default functions, for example:

```julia
function Bit.update_data_step!(m::NewModel)
    @invoke Bit.update_data_step!(m::AbstractModel)
    # your new data tracking operations...
end
```
"""
function update_data!(m::AbstractModel)
    allocate_new_data!(m)
    t = length(m.data.collection_time)
    t == 1 && return update_data_init!(m)
    return update_data_step!(m)
end

Data() = Data(typeInt[], [typeFloat[] for _ in 1:25]..., Vector{typeFloat}[], Vector{typeFloat}[])

function allocate_new_data!(m::AbstractModel)
    d = m.data
    for f in fieldnames(typeof(d))[1:26]
        push!(getfield(d, f), 0.0)
    end
    push!(d.nominal_sector_gva, zeros(m.prop.G))
    push!(d.real_sector_gva, zeros(m.prop.G))
end

function update_data_init!(m::AbstractModel)
    d, p = m.data, m.prop

    tot_Y_h = sum(m.w_act.Y_h) + sum(m.w_inact.Y_h) + sum(m.firms.Y_h) + m.bank.Y_h
    d.nominal_gdp[1] =
        sum(m.firms.Y_i .* (1 .- 1 ./ m.firms.beta_i)) +
        tot_Y_h * p.psi / (1 / p.tau_VAT + 1) +
        p.tau_G * m.gov.C_G +
        tot_Y_h * p.psi_H / (1 / p.tau_CF + 1) +
        p.tau_EXPORT * m.rotw.C_E
    d.real_gdp[1] = d.nominal_gdp[1]
    d.nominal_gva[1] = sum(m.firms.Y_i .* ((1 .- m.firms.tau_Y_i) .- 1 ./ m.firms.beta_i))
    d.real_gva[1] = d.nominal_gva[1]
    d.nominal_household_consumption[1] = tot_Y_h * p.psi
    d.real_household_consumption[1] = d.nominal_household_consumption[1]
    d.nominal_government_consumption[1] = (1 + p.tau_G) * m.gov.C_G
    d.real_government_consumption[1] = d.nominal_government_consumption[1]
    d.nominal_capitalformation[1] = sum(m.firms.Y_i .* m.firms.delta_i ./ m.firms.kappa_i) + tot_Y_h * p.psi_H
    d.real_capitalformation[1] = d.nominal_capitalformation[1]
    d.nominal_fixed_capitalformation[1] = d.nominal_capitalformation[1]
    d.real_fixed_capitalformation[1] = d.nominal_capitalformation[1]
    d.nominal_fixed_capitalformation_dwellings[1] = tot_Y_h * p.psi_H
    d.real_fixed_capitalformation_dwellings[1] = d.nominal_fixed_capitalformation_dwellings[1]
    d.nominal_exports[1] = (1 + p.tau_EXPORT) * m.rotw.C_E
    d.real_exports[1] = d.nominal_exports[1]
    d.nominal_imports[1] = m.rotw.Y_I
    d.real_imports[1] = d.nominal_imports[1]
    d.operating_surplus[1] = sum(
        m.firms.Y_i .* (1 .- ((1 + p.tau_SIF) .* m.firms.w_bar_i ./ m.firms.alpha_bar_i + 1 ./ m.firms.beta_i)) .-
        m.firms.tau_K_i .* m.firms.Y_i .- m.firms.tau_Y_i .* m.firms.Y_i,
    )
    d.compensation_employees[1] = (1 + p.tau_SIF) * sum(m.firms.w_bar_i .* m.firms.N_i)
    d.wages[1] = sum(m.firms.w_bar_i .* m.firms.N_i)
    d.taxes_production[1] = sum(m.firms.tau_K_i .* m.firms.Y_i)

    for g in 1:(p.G)
        d.nominal_sector_gva[1][g] = sum(
            m.firms.Y_i[m.firms.G_i .== g] .*
            ((1 .- m.firms.tau_Y_i[m.firms.G_i .== g]) .- 1 ./ m.firms.beta_i[m.firms.G_i .== g]),
        )
    end

    d.real_sector_gva[1][:] = d.nominal_sector_gva[1][:]
    d.euribor[1] = m.cb.r_bar
    d.gdp_deflator_growth_ea[1] = m.rotw.pi_EA
    d.real_gdp_ea[1] = m.rotw.Y_EA
    d.collection_time[1] = 1
    return m
end

function update_data_step!(m::AbstractModel)
    d, p, t = m.data, m.prop, length(m.data.collection_time)
    tot_C_h = sum(m.w_act.C_h) + sum(m.w_inact.C_h) + sum(m.firms.C_h) + m.bank.C_h
    tot_I_h = sum(m.w_act.I_h) + sum(m.w_inact.I_h) + sum(m.firms.I_h) + m.bank.I_h

    d.nominal_gdp[t] =
        sum(m.firms.tau_Y_i .* m.firms.Y_i .* m.firms.P_i) +
        p.tau_VAT * tot_C_h +
        p.tau_CF * tot_I_h +
        p.tau_G * m.gov.C_j +
        p.tau_EXPORT * m.rotw.C_l +
        sum((1 .- m.firms.tau_Y_i) .* m.firms.P_i .* m.firms.Y_i) -
        sum(1 ./ m.firms.beta_i .* m.firms.P_bar_i .* m.firms.Y_i)
    d.real_gdp[t] =
        sum(m.firms.Y_i .* ((1 .- m.firms.tau_Y_i) - 1 ./ m.firms.beta_i)) +
        sum(m.firms.tau_Y_i .* m.firms.Y_i) +
        p.tau_VAT * tot_C_h / m.agg.P_bar_h +
        p.tau_CF * tot_I_h / m.agg.P_bar_CF_h +
        p.tau_G * m.gov.C_j / m.gov.P_j +
        p.tau_EXPORT * m.rotw.C_l / m.rotw.P_l
    d.nominal_gva[t] =
        sum((1 .- m.firms.tau_Y_i) .* m.firms.P_i .* m.firms.Y_i) -
        sum(1 ./ m.firms.beta_i .* m.firms.P_bar_i .* m.firms.Y_i)
    d.real_gva[t] = sum(m.firms.Y_i .* ((1 .- m.firms.tau_Y_i) - 1 ./ m.firms.beta_i))
    d.nominal_household_consumption[t] = (1 + p.tau_VAT) * tot_C_h
    d.real_household_consumption[t] = (1 + p.tau_VAT) * tot_C_h / m.agg.P_bar_h
    d.nominal_government_consumption[t] = (1 + p.tau_G) * m.gov.C_j
    d.real_government_consumption[t] = (1 + p.tau_G) * m.gov.C_j / m.gov.P_j
    d.nominal_capitalformation[t] =
        sum(m.firms.P_CF_i .* m.firms.I_i) +
        (1 + p.tau_CF) * tot_I_h +
        sum(m.firms.DS_i .* m.firms.P_i) +
        sum(m.firms.DM_i .* m.firms.P_bar_i - 1 ./ m.firms.beta_i .* m.firms.P_bar_i .* m.firms.Y_i)
    d.real_capitalformation[t] =
        sum(m.firms.I_i) +
        (1 + p.tau_CF) * tot_I_h / m.agg.P_bar_CF_h +
        sum(m.firms.DM_i .- m.firms.Y_i ./ m.firms.beta_i) +
        sum(m.firms.DS_i)
    d.nominal_fixed_capitalformation[t] = sum(m.firms.P_CF_i .* m.firms.I_i) + (1 + p.tau_CF) * tot_I_h
    d.real_fixed_capitalformation[t] = sum(m.firms.I_i) + (1 + p.tau_CF) * tot_I_h / m.agg.P_bar_CF_h
    d.nominal_fixed_capitalformation_dwellings[t] = (1 + p.tau_CF) * tot_I_h
    d.real_fixed_capitalformation_dwellings[t] = (1 + p.tau_CF) * tot_I_h / m.agg.P_bar_CF_h
    d.nominal_exports[t] = (1 + p.tau_EXPORT) * m.rotw.C_l
    d.real_exports[t] = (1 + p.tau_EXPORT) * m.rotw.C_l / m.rotw.P_l
    d.nominal_imports[t] = sum(m.rotw.P_m .* m.rotw.Q_m)
    d.real_imports[t] = sum(m.rotw.Q_m)
    d.operating_surplus[t] = sum(
        m.firms.P_i .* m.firms.Q_i + m.firms.P_i .* m.firms.DS_i -
        (1 + p.tau_SIF) .* m.firms.w_i .* m.firms.N_i .* m.agg.P_bar_HH -
        1 ./ m.firms.beta_i .* m.firms.P_bar_i .* m.firms.Y_i - m.firms.tau_Y_i .* m.firms.P_i .* m.firms.Y_i -
        m.firms.tau_K_i .* m.firms.P_i .* m.firms.Y_i,
    )
    d.compensation_employees[t] = (1 + p.tau_SIF) * sum(m.firms.w_i .* m.firms.N_i) * m.agg.P_bar_HH
    d.wages[t] = sum(m.firms.w_i .* m.firms.N_i) * m.agg.P_bar_HH
    d.taxes_production[t] = sum(m.firms.tau_K_i .* m.firms.Y_i .* m.firms.P_i)

    for g in 1:(p.G)
        g_i = m.firms.G_i .== g
        d.nominal_sector_gva[t][g] =
            sum((1 .- @view(m.firms.tau_Y_i[g_i])) .* @view(m.firms.P_i[g_i]) .* m.firms.Y_i[g_i]) - 
            sum(1.0 ./ @view(m.firms.beta_i[g_i]) .* @view(m.firms.P_bar_i[g_i]) .* @view(m.firms.Y_i[g_i]))
        d.real_sector_gva[t][g] = sum(@view(m.firms.Y_i[g_i]) .*
            ((1 .- @view(m.firms.tau_Y_i[g_i])) - 1.0 ./ @view(m.firms.beta_i[g_i])),
        )
    end

    d.euribor[t] = m.cb.r_bar
    d.gdp_deflator_growth_ea[t] = m.rotw.pi_EA
    d.real_gdp_ea[t] = m.rotw.Y_EA
    d.collection_time[t] = m.agg.t
    return m
end
