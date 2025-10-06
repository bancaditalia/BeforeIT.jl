# # Working with Single Agents

# To support complex extensions of the base model,
# we implemented a way to retrieve single agents from containers
# of multiple instances having a SoA (Struct-Of-Arrays) layout under
# the hood.

# In practice, this allows to operate on agents as if they were single
# structs. Let's see how this unfolds with a concrete example. As usual,
# we create a model instance with
import BeforeIT as Bit

parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
model = Bit.Model(parameters, initial_conditions);

# Three containers in this model have multiple instances of agents:
# `model.firms`, `model.w_act`, `model.w_inact`. Each of them
# to be compatible with this approach contains IDs which correspond
# to single instances. IDs are `UInt` and are set internally.

# !!! note
#     One invariant of IDs one could rely on is that at initialization
#     IDs are mapped one-to-one to indices of the arrays. Though, if any
#     deletion happens this won't be true anymore.
id = 1
agent = model.w_act[id]

# Then we can access or modify attributes of the agent simply with
agent.Y_h

# and
agent.Y_h = 1.0

# Now, we will show how to add or remove agent instances from the model.
# Since agents are added by passing a `NamedTuple` of the fields we will use
# the fields of the agent we retrieved for ease of exposition
agentfields = Bit.getfields(agent)

# !!! note
#     Importantly, fields can be accessed as long as the agent is still inside the
#     model, and not after that. So, if you need those fields for something else
#     after removing an agent, retrieve the fields before removing it.
delete!(model.w_act, id)
push!(model.w_act, agentfields);

# We can also retrieve the id of the last agent added to the container with
id = Bit.lastid(model.w_act)

# Let's finally verify that the last agent has `Y_h` equal to `1.0` as it should be
agent = model.w_act[id]
agent.Y_h

# # A More Complex Example

# Let's now use this capability to extend the base model.

# When extending the BeforeIT models it is required to first create a new model
# type to use instead of the default model, we can do so by using
Bit.@object struct NewModel(Bit.Model) <: Bit.AbstractModel end

# Let's say that we want to add the posssibilty for workers to sign financial contracts to borrow
# money. At issuance, the worker’s deposit would increase by principal, and in time step `period` the
# `money_to_be_paid` should be paid by the debtor. In each time step a worker signs a new `ConsumerLoanContract`
# with a probability of 30% for a principal which is 20% of its `Y_h`, which should be repaid by a 10% margin
# 5 time steps later. A worker can have multiple `ConsumerLoanContracts`. A worker can only sign a new
# `ConsumerLoanContract` if the sum of `money_to_be_paid` is less than its `Y_h`.

# To perform this last operation efficiently, we first store the sum of `money_to_be_paid` as a new field
# for the workers with
Bit.@object mutable struct NewWorkers(Bit.Workers) <: Bit.AbstractWorkers
    sum_money_to_be_paid::Vector{Float64}
end

# Let’s introduce a new `ConsumerLoanContract` struct into the model. A worker could
# sign a `ConsumerLoanContract` and get a credit which would be repaid.

# To do so, we first define it with
struct ConsumerLoanContract
    principal::Float64
    money_to_be_paid::Float64
    period::Int32
    debtor::Bit.Agent{NewWorkers}
end

# and store a vector of contracts into the properties of the model
Bit.@object mutable struct NewProperties(Bit.Properties) <: Bit.AbstractProperties
    contracts::Vector{ConsumerLoanContract}
end

# We want that to happen before the search & matching process, to do so we could either specialize the
# `step!` function or the function we want to call immediately after this new process. For the
# matter of brevity, we will follow this second approach:
function Bit.search_and_matching_credit(firms::Bit.Firms, model::NewModel)
    sign_and_repay_contracts!(model.w_act, model)
    return @invoke Bit.search_and_matching_credit(firms::Bit.AbstractFirms, model::Bit.AbstractModel)
end

function sign_and_repay_contracts!(workers, model)
    for id in Bit.allids(workers)
        agent = workers[id]
        if rand() < 0.3 && agent.sum_money_to_be_paid <= agent.Y_h
            principal = 0.2 * agent.Y_h
            agent.Y_h += principal
            money_to_be_paid = 1.1 * principal
            period = model.agg.t + 5
            new_contract = ConsumerLoanContract(principal, money_to_be_paid, period, agent)
            push!(model.prop.contracts, new_contract)
            agent.sum_money_to_be_paid += money_to_be_paid
        end
    end
    repaid_contracts_indices = Int[]
    for (i, contract) in enumerate(model.prop.contracts)
        if contract.period == model.agg.t
            debtor = contract.debtor
            if debtor.Y_h <= contract.money_to_be_paid
                debtor.Y_h -= contract.money_to_be_paid
                debtor.sum_money_to_be_paid -= contract.money_to_be_paid
                push!(repaid_contracts_indices, i)
            end
        end
    end
    for i in repaid_contracts_indices
        contracts = model.prop.contracts
        contracts[i], contracts[end] = contracts[end], contracts[i]
        pop!(contracts)
    end
    return
end

# Now, we just create the new model
p, ic = Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions
firms = Bit.Firms(p, ic)
w_act, w_inact = Bit.Workers(p, ic)
cb = Bit.CentralBank(p, ic)
bank = Bit.Bank(p, ic)
gov = Bit.Government(p, ic)
rotw = Bit.RestOfTheWorld(p, ic)
agg = Bit.Aggregates(p, ic)
prop = Bit.Properties(p, ic)
data = Bit.Data()

w_act_new = NewWorkers(Bit.fields(w_act)..., zeros(length(w_act.Y_h)))
prop_new = NewProperties(Bit.fields(prop)..., ConsumerLoanContract[])

model = NewModel(w_act_new, w_inact, firms, bank, cb, gov, rotw, agg, prop_new, data)

# and evolve it
Bit.step!(model)
