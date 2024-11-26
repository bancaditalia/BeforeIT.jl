
using PrecompileTools

@setup_workload let
    parameters = BeforeIT.AUSTRIA2010Q1.parameters
    initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions
    T = 1
    @compile_workload let
        model = BeforeIT.init_model(parameters, initial_conditions, T)
	data = BeforeIT.init_data(model);
	BeforeIT.run_one_epoch!(model)
	BeforeIT.update_data!(data, model)
    end
end
