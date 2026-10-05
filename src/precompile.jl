using PrecompileTools

@setup_workload let
    parameters = Bit.AUSTRIA2010Q1.parameters
    parameters["n_banks"] = 1  # Set number of banks to 1 for testing purposes
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
    @compile_workload let
        model = Bit.Model(parameters, initial_conditions)
        Bit.step!(model)
    end
end
