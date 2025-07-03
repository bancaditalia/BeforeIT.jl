
using PrecompileTools

@setup_workload let
    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
    T = 1
    @compile_workload let
        model = Bit.Model(parameters, initial_conditions, T)
	data = Bit.Data(model);
	Bit.step!(model)
	Bit.update_data!(data, model)
    end
end
