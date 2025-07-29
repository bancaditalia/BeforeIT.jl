using PrecompileTools

@setup_workload let
    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
    @compile_workload let
        model = Bit.Model(parameters, initial_conditions)
        Bit.step!(model)
    end
end
