classdef variable < handle
    properties
        dim
        idx
        val
        fun
        linop
        pairing
        subvars
    end
    
    methods
        function h = variable(dim)
            h.dim = dim;
            h.pairing = {};
            h.linop = {};
            h.fun = prost.function.zero();
            h.subvars = {};
        end
    end
end
