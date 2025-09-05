
## Working with Single Agents

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

id = UInt(1)
agent = model.w_act[id]

# !!! note
#   One invariant of IDs one could rely on is that at initialization
#   IDs are mapped one-to-one to indices of the arrays. Though, if any
#   deletion happens this won't be true anymore.

# Then we can access or modify attributes of the agent simply with

agent.Y_h

# and

agent.Y_h = 1.0

# Now, we will show how to add or remove agent instances from the model.
# Since agents are added by passing a `NamedTuple` of the fields we will use
# the fields of the agent we retrieved for ease of exposition

agentfields = Bit.getfields(agent)

# !!! note
#   Importantly, fields can be accessed as long as the agent is still inside the
#   model, and not after that. So, if you need those fields for something else
#   after removing an agent, retrieve the fields before removing it.

delete!(model.w_act, id)
push!(model.w_act, agentfields);

# We can also retrieve the id of the last agent added to the container with

id = Bit.lastid(model.w_act)

# Let's finally verify that the last agent has `Y_h` equal to `1.0` has it should be

agent = model.w_act[id]
agent.Y_h
