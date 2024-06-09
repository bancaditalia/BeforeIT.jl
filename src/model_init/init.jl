using MutableNamedTuples
recursive_namedtuple(x::Any) = x
recursive_namedtuple(d::Dict) = MutableNamedTuple(; Dict(k => recursive_namedtuple(v) for (k, v) in d)...)

"""
    initialise_model(parameters, initial_conditions, T, typeInt = Int64, typeFloat = Float64)

Initializes the model with given parameters and initial conditions.

Parameters:
- `parameters`: A dictionary containing the model parameters.
- initial_conditions: A dictionary containing the initial conditions.
- T (integer): The time horizon of the model.
- typeInt: (optional, default: Int64): The data type to be used for integer values.
- typeFloat: (optional, default: Float64): The data type to be used for floating-point values.

Returns:
- model::Model: The initialized model.

"""
function initialise_model(parameters::Dict{String, Any}, initial_conditions::Dict{String, Any}, T, typeInt::DataType = Int64, typeFloat::DataType = Float64)

    # properties
    properties = BeforeIT.init_properties(parameters, T; typeInt = typeInt, typeFloat = typeFloat)

    # firms
    firms = BeforeIT.init_firms(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # workers, and update firms vacancies
    workers_act, workers_inact, V_i_new = BeforeIT.init_workers(parameters, initial_conditions, firms; typeInt = typeInt, typeFloat = typeFloat)
    firms.V_i = V_i_new

    # bank
    bank = BeforeIT.init_bank(parameters, initial_conditions, firms; typeInt = typeInt, typeFloat = typeFloat)

    # central bank
    central_bank = BeforeIT.init_central_bank(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # government
    government = BeforeIT.init_government(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # rest of the world
    rotw = BeforeIT.init_rotw(parameters, initial_conditions; typeInt = typeInt, typeFloat = typeFloat)

    # aggregates
    agg = BeforeIT.init_aggregates(parameters, initial_conditions, T; typeInt = typeInt, typeFloat = typeFloat)
    
    # obtain total income by summing contributions from firm owners, workers and bank owner

    tot_Y_h = sum(firms.Y_h) + sum(workers_act.Y_h) + sum(workers_inact.Y_h) + bank.Y_h

    # uptade K_h and D_h in all agent types
    firms.K_h .= firms.K_h / tot_Y_h 
    firms.D_h .= firms.D_h / tot_Y_h
    workers_act.K_h .= workers_act.K_h / tot_Y_h
    workers_act.D_h .= workers_act.D_h / tot_Y_h
    workers_inact.K_h .= workers_inact.K_h / tot_Y_h
    workers_inact.D_h .= workers_inact.D_h / tot_Y_h
    bank.K_h = bank.K_h / tot_Y_h
    bank.D_h = bank.D_h / tot_Y_h

    # get total deposits and update bank balance sheet
    tot_D_h = sum(firms.D_h) + sum(workers_act.D_h) + sum(workers_inact.D_h) + bank.D_h
    bank.D_k += tot_D_h

    # model
    model = Model(workers_act, workers_inact, firms, bank, central_bank, government, rotw, agg, properties)

    return model

end
