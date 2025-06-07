
using MutableNamedTuples

recursive_namedtuple(x::Any) = x
recursive_namedtuple(d::Dict) = MutableNamedTuple(; Dict(k => recursive_namedtuple(v) for (k, v) in d)...)

"""
    init_model(parameters, initial_conditions, T, typeInt = Int64, typeFloat = Float64)

Initializes the model with given parameters and initial conditions.

Parameters:
- `parameters`: A dictionary containing the model parameters.
- initial_conditions: A dictionary containing the initial conditions.
- T (integer): The time horizon of the model.
- typeInt: (optional, default: Int64): The data type to be used for integer values.
- typeFloat: (optional, default: Float64): The data type to be used for floating-point values.

Returns:
- model::AbstractModel: The initialized model.

"""
function init_model(parameters::Dict{String, Any}, initial_conditions::Dict{String, Any}, T, typeInt::DataType = Int64, typeFloat::DataType = Float64)

    # properties
    properties = Bit.init_properties(parameters, T; typeInt = typeInt, typeFloat = typeFloat)

    # firms
    firms, _ = Bit.init_firms(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # workers, and update firms vacancies
    workers_act, workers_inact, V_i_new, _, _ = Bit.init_workers(parameters, initial_conditions, firms; typeInt = typeInt, typeFloat = typeFloat)
    firms.V_i .= V_i_new

    # bank
    bank, _ = Bit.init_bank(parameters, initial_conditions, firms; typeInt = typeInt, typeFloat = typeFloat)

    # central bank
    central_bank, _ = Bit.init_central_bank(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # government
    government, _ = Bit.init_government(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # rest of the world
    rotw, _ = Bit.init_rotw(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # aggregates
    agg, _ = Bit.init_aggregates(parameters, initial_conditions, T; typeInt = typeInt, typeFloat = typeFloat)

    # model
    model = Model(workers_act, workers_inact, firms, bank, central_bank, government, rotw, agg, properties)

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
