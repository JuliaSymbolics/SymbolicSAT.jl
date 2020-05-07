module SymbolicSAT

using SymbolicUtils
using SymbolicUtils: Sym, Term, operation, arguments, Symbolic
using Z3

export Constraints, cond

## Booleans

import Base: ==, !=, <=, >=, <, >, &, |, xor

# binary ops that return Bool
for (f, Domain) in [(==) => Number, (!=) => Number,
                    (<=) => Real,   (>=) => Real,
                    (< ) => Real,   (> ) => Real,
                    (& ) => Bool,   (| ) => Bool,
                    xor => Bool]
    @eval begin
        promote_symtype(::$(typeof(f)), ::Type{<:$Domain}, ::Type{<:$Domain}) = Bool
        (::$(typeof(f)))(a::Symbolic{<:$Domain}, b::$Domain) = term($f, a, b, type=Bool)
        (::$(typeof(f)))(a::Symbolic{<:$Domain}, b::Symbolic{<:$Domain}) = term($f, a, b, type=Bool)
        (::$(typeof(f)))(a::$Domain, b::Symbolic{<:$Domain}) = term($f, [a, b], type=Bool)
    end
end

Base.:!(s::Symbolic{Bool}) = Term{Bool}(!, [s])
Base.:~(s::Symbolic{Bool}) = Term{Bool}(~, [s])

cond(_if, _then, _else) = Term{Union{symtype(_then), symtype(_else)}}(cond, Any[_if, _then, _else])

# Symutils -> Z3

export issatisfiable

to_z3(x, ctx) = x
to_z3(x::Symbolic, ctx) = error("could not convert $x to a z3 expression restrict types of variables to Real or its subtypes")
function to_z3(term::Term, ctx)
    op = operation(term)
    args = arguments(term)

    # weird special case
    if length(args) == 1 && (op == (!) || op == (~))
        not(to_z3(args[1], ctx))
    else
        op(map(x->to_z3(x, ctx), args)...)
    end
end

for (jlt, z3t) in [Integer => :int, Real => :real]
    @eval to_z3(x::Sym{<:$jlt}, ctx) = $(Symbol(z3t, "_const"))(ctx, String(nameof(x)))
end

struct Constraints
    constraints::Vector
    solver::Z3.Solver
    context::Z3.Context

    function Constraints(cs::Vector, solvertype="QF_NRA")
        ctx = Context()
        s = Solver(ctx, solvertype)

        for c in cs
            add(s, to_z3(c, ctx))
        end

        new(cs, s, ctx)
    end
end


function Base.show(io::IO, c::Constraints)
    cs = c.constraints
    println("Constraints:")
    for i in 1:length(cs)
        print(io, "  ")
        print(io, cs[i])
        i != length(cs) && println(io, " ∧")
    end
end

function issatisfiable(expr::Symbolic{Bool}, cs::Constraints)
    Z3.push(cs.solver)
    add(cs.solver, to_z3(expr, cs.context))
    res = check(cs.solver)
    Z3.pop(cs.solver,1)
    res == Z3.sat
end

issatisfiable(expr::Bool, Constraints) = expr

end # module
