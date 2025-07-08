
## Computing derivatives with respect to properties of the model

# Here, we will show how derivatives with respect to each property
# of the model can be computed through the use of DualNumbers.jl

# First, we need to set through Preferences.jl that we want to
# use dual numbers inside the model so that to be able to use
# automatic differentiation:
using Preferences
set_preferences!(
	"BeforeIT", 
	"typeInt" => "DualNumbers.Dual{Int}",
	"typeFloat" => "DualNumbers.Dual{Float64}"
)

# then we can just create a model and now the model will contain
# those types instead of standard integers and floats:
import BeforeIT as Bit
using Random

parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

model = Bit.Model(parameters, initial_conditions);
model.prop.tau_FIRM # this is a dual number now

# then we can just use `Bit.derivative` to compute the derivative
# of stepping the model for `T` steps with respect to a variable
# of choice. The derivatives are attached to each field of the
# model object:
T = 1;
Random.seed!(42);
model = Bit.Model(parameters, initial_conditions);
model = Bit.derivative(model, :(prop.tau_FIRM), T);

# Let's say we want to find the effect of changing that taxation
# parameter on the Firms comsumption:
C = sum(model.firms.C_d_h);
C.epsilon

# this tells for instance that changing by 0.1 that taxation parameter 
# negatively affects the Firms consumption budget by -58.87.
# We can check if the result matches the effect computed numerically:
Random.seed!(42);
model = Bit.Model(parameters, initial_conditions);
model.prop.tau_FIRM += 0.01;
Bit.step!(model);
sum(model.firms.C_d_h) - C

# In this case, it does.
