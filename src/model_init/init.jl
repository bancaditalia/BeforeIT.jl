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
    banks = Bit.Banks(parameters, initial_conditions)

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

    return Model((workers_act, workers_inact, firms, banks, central_bank, government, rotw, agg, properties, data))
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

    # obtain total income by summing contributions from firm owners, workers and all bank owners
    tot_Y_h = sum(model.firms.Y_h) + sum(model.w_act.Y_h) + sum(model.w_inact.Y_h) + sum(model.banks.Y_h)

    # update K_h and D_h in all agent types using total income
    model.firms.K_h .= model.firms.K_h / tot_Y_h
    model.firms.D_h .= model.firms.D_h / tot_Y_h
    model.w_act.K_h .= model.w_act.K_h / tot_Y_h
    model.w_act.D_h .= model.w_act.D_h / tot_Y_h
    model.w_inact.K_h .= model.w_inact.K_h / tot_Y_h
    model.w_inact.D_h .= model.w_inact.D_h / tot_Y_h
    model.banks.K_h .= model.banks.K_h / tot_Y_h
    model.banks.D_h .= model.banks.D_h / tot_Y_h

    # get total deposits and update each bank's balance sheet
    for bank_id in eachbank(model)
        D_h = typeFloat[f.D_h for f in model.banks.firms[bank_id]]
        D_h_act = typeFloat[w.D_h for w in model.banks.w_act[bank_id]]
        D_h_inact = typeFloat[w.D_h for w in model.banks.w_inact[bank_id]]
        tot_D_h = sum(D_h) + sum(D_h_act) + sum(D_h_inact) + model.banks.D_h[bank_id]
        model.banks.D_k[bank_id] += tot_D_h
    end
    return
end
