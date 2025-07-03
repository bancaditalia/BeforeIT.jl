
import BeforeIT as Bit
using MAT, Test

dir = @__DIR__

parameters = Bit.STEADY_STATE2010Q1.parameters
initial_conditions = Bit.STEADY_STATE2010Q1.initial_conditions
model = Bit.Model(parameters, initial_conditions, 1)

properties = model.prop

H_act = Int(properties.H_act)
H_inact = Int(properties.H_inact)
I = properties.I
H = H_act + H_inact
H_W = H_act - I - 1

@test all(model.w_act.O_h .!= -1)
@test all(model.w_inact.O_h .== -1)

@test sum(model.firms.C_d_h) == 0.0
@test isapprox(sum(model.firms.Pi_i), 16805.143545982424, atol = 1e-7)
@test isapprox(sum(model.firms.D_i), 54049.00000000002, atol = 1e-7)
@test isapprox(sum(model.firms.Y_i), 134635.75553779324, atol = 1e-7)
@test isapprox(sum(model.firms.N_i), 3866.0, atol = 1e-7)
