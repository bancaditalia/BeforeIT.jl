
abstract type AbstractWorkers end
abstract type AbstractFirms end
abstract type AbstractBank end
abstract type AbstractCentralBank end
abstract type AbstractGovernment end
abstract type AbstractRestOfTheWorld end

macro worker(T, I)
    quote
        Y_h::$T
        D_h::$T
        K_h::$T
        w_h::$T
        O_h::$I
        C_d_h::$T
        I_d_h::$T
        C_h::$T
        I_h::$T
    end
end
