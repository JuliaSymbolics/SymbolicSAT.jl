# SymbolicSAT

**WARNING: This package is experimental! Use it only to find bugs.**

This package extends [SymbolicUtils](https://juliasymbolics.github.io/SymbolicUtils.jl/) expression simplification with a theorem prover.

It is a wrapper around [a wrapper](https://github.com/ahumenberger/Z3.jl) to [The Z3 Theorem Prover](https://github.com/Z3Prover/z3/wiki).

Usage:

0. `using SymbolicUtils, SymbolicSAT`
1. Construct a `Constraints([cs...])` where `cs` are boolean expressions
2. Pass it as the second argument to `simplify`

```julia
julia> using SymbolicUtils, SymbolicSAT

julia> @syms a::Real b::Real
(a, b)

julia> constraints = Constraints([a^2 + b^2 < 4])
Constraints:
  ((a ^ 2) + (b ^ 2)) < 4

julia> simplify((a < 2) & (b < 2), Constraints([a^2 + b^2 < 4]))
true
```

Thanks to the author of [Z3.jl](https://github.com/ahumenberger/Z3.jl) for the Julia bindings and answering my questions!
