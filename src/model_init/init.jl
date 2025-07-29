
"""
    Model(parameters, initial_conditions)

Initializes the model with given parameters and initial conditions.

Parameters:
- `parameters`: A dictionary containing the model parameters.
- initial_conditions: A dictionary containing the initial conditions.

Returns:
- model::AbstractModel: The initialized model.
"""
function Model(parameters::Dict{String, Any}, initial_conditions::Dict{String, Any})

    # properties
    properties = Bit.Properties(parameters, initial_conditions)

    # firms
    firms = Bit.Firms(parameters, initial_conditions)

    # workers, and update firms vacancies
    workers_act, workers_inact = Bit.Workers(parameters, initial_conditions)

    # bank
    bank = Bit.Bank(parameters, initial_conditions)

    # central bank
    central_bank = Bit.CentralBank(parameters, initial_conditions)

    # government
    government = Bit.Government(parameters, initial_conditions)

    # rest of the world
    rotw = Bit.RestOfTheWorld(parameters, initial_conditions)

    # aggregates
    agg = Bit.Aggregates(parameters, initial_conditions)

    # data
    data = Bit.Data()

    return Model(workers_act, workers_inact, firms, bank, central_bank,
                 government, rotw, agg, properties, data)
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
    tot_Y_h = sum(model.firms.Y_h) + sum(model.w_act.Y_h) + sum(model.w_inact.Y_h) +
              model.bank.Y_h

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
    tot_D_h = sum(model.firms.D_h) + sum(model.w_act.D_h) + sum(model.w_inact.D_h) +
              model.bank.D_h
    model.bank.D_k += tot_D_h
end
