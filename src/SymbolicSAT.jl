module SymbolicSAT

using SymbolicUtils
using SymbolicUtils: Sym, Term, operation, arguments, Symbolic, symtype
using Z3

export Constraints, issatisfiable, isprovable

# Symutils -> Z3

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
    Z3.pop(cs.solver,0)
    if res == Z3.sat
        return true
    elseif res == Z3.unsat
        return false
    elseif res == Z3.unknown
        return nothing
    end
end

function isprovable(expr, cs::Constraints)
    sat = issatisfiable(expr, cs)
    sat === true ? !issatisfiable(!expr, cs) : sat
end

issatisfiable(expr::Bool, Constraints) = expr

isbool(x) = symtype(x) == Bool

SymbolicUtils.default_rules(expr, c::Constraints) = RuleSet([
    @rule ~x::isbool => isprovable(~x, (@ctx)) === true ? true : ~x
])

end # module
