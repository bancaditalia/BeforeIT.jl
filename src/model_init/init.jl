
using MutableNamedTuples

recursive_namedtuple(x::Any) = x
recursive_namedtuple(d::Dict) = MutableNamedTuple(; Dict(k => recursive_namedtuple(v) for (k, v) in d)...)

"""
    Model(parameters, initial_conditions)

Initializes the model with given parameters and initial conditions.

Parameters:
- `parameters`: A dictionary containing the model parameters.
- initial_conditions: A dictionary containing the initial conditions.

Returns:
- model::AbstractModel: The initialized model.
"""
function Model(parameters::Dict{String, Any}, initial_conditions::Dict{String, Any}; typeInt::DataType = Int64, typeFloat::DataType = Float64)

    # properties
    properties = Bit.Properties(parameters; typeInt = typeInt, typeFloat = typeFloat)

    # firms
    firms = Bit.Firms(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # workers, and update firms vacancies
    workers_act, workers_inact = Bit.Workers(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # bank
    bank = Bit.Bank(parameters, initial_conditions, firms; typeInt = typeInt, typeFloat = typeFloat)

    # central bank
    central_bank = Bit.CentralBank(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # government
    government = Bit.Government(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # rest of the world
    rotw = Bit.RestOfTheWorld(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # aggregates
    agg = Bit.Aggregates(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # data
    data = Bit.Data(parameters)

    # model
    model = Model(workers_act, workers_inact, firms, bank, central_bank, government, rotw, agg, properties, data)

    return model
end

"""
    update_variables_with_totals!(model::AbstractModel)

Update the variables in the given `model` with some global quantities obtained from all agents.
This is the last step in the initialization process and it must be performed after all agents have been initialized.

# Arguments
- `model::AbstractModel`: The model object to update.

# Returns
- Nothing
"""
function update_variables_with_totals!(model::AbstractModel)

    # obtain total income by summing contributions from firm owners, workers and bank owner
    tot_Y_h = sum(model.firms.Y_h) + sum(model.w_act.Y_h) + sum(model.w_inact.Y_h) + model.bank.Y_h

    # uptade K_h and D_h in all agent types using total income  
    model.firms.K_h .= model.firms.K_h / tot_Y_h 
    model.firms.D_h .= model.firms.D_h / tot_Y_h
    model.w_act.K_h .= model.w_act.K_h / tot_Y_h
    model.w_act.D_h .= model.w_act.D_h / tot_Y_h
    model.w_inact.K_h .= model.w_inact.K_h / tot_Y_h
    model.w_inact.D_h .= model.w_inact.D_h / tot_Y_h
    model.bank.K_h = model.bank.K_h / tot_Y_h
    model.bank.D_h = model.bank.D_h / tot_Y_h

    # get total deposits and update bank balance sheet
    tot_D_h = sum(model.firms.D_h) + sum(model.w_act.D_h) + sum(model.w_inact.D_h) + model.bank.D_h
    model.bank.D_k += tot_D_h
end
