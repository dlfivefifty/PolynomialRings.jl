# PolynomialRings

[![Build Status](https://travis-ci.org/tkluck/PolynomialRings.jl.svg?branch=master)](https://travis-ci.org/tkluck/PolynomialRings.jl)

[![Coverage Status](https://coveralls.io/repos/tkluck/PolynomialRings.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tkluck/PolynomialRings.jl?branch=master)

[![codecov.io](http://codecov.io/github/tkluck/PolynomialRings.jl/coverage.svg?branch=master)](http://codecov.io/github/tkluck/PolynomialRings.jl?branch=master)

A library for arithmetic and algebra with multi-variable polynomials.

## Usage

```julia
using PolynomialRings
R = @ring ℚ[x,y]

if (x+y)*(x-y) == x^2 - y^2
    println("Seems to work")
end
```

A few useful functions are `deg`, `red`, `expansion`, `groebner_basis`.

## Relation to `MultiVariatePolynomials.jl`

Julia already has an excellent offering for multi-variate polynomials in the
form of MultiVariatePolynomials.jl. What place does PolynomialRings take?

The most important design difference is that in the latter, we choose to make
variable names (for example `x` and `y`) part of the type specification, as
opposed to part of the data structure.  We feel this is necessary for type
stability. For example, the expression `(x+y)*x` has exponents of type
`Tuple{Int,Int}`, whereas the expression `(x+y)*z` has exponents of type
`Tuple{Int,Int,Int}`. This is true even though *in both cases*, the arguments
to `*` have exponents of type `Tuple{Int,Int}` and `Tuple{Int}` respectively.
This means that the return type can only be inferred if the variable names are
part of the type.

In doing so, this is a nice exercise for Julia's type system. In practice, this
seems to add non-negligibly to compilation times, but not to run times.

## Relation to `Singular.jl`

Eventually, we hope to be an easy-to-deploy alternative to Singular.jl.

A pure Julia library will likely never match the brute computing power that
Singular brings to the table. However, Julia's high-level constructs may allow
the user to make certain routine optimizations with much more ease.

As a speculative example, consider the following. In Julia, an invocation such
as

```julia
@coefficient(f*g, x^10*y^10)
```

could conceivably notice that the first argument is a product. It could then
only compute the requested coefficient of the product, skipping the computation
whose result will be discarded.

## Maturity

Currently, this library should be considered alpha quality.

## Design goals

### First-class support for different expansions of the same object

We hope to make it exceedingly easy to regard, for example, a matrix of
polynomials as a polynomial with matrix coefficients. Or to regard a
polynomial in five variables with coefficients in ℚ as a two-variable
polynomial with coefficients in the ring of three-variable polynomials
over ℚ.

This makes the signature of some functions a bit different than usual.
For example, a function call like

    coefficient(x^3 + x^2*y + y, y)

is ambiguous: should the result be `1` or `x^2+1`? Most other CAS base
their decision on the parent object for the polynomial: these two results
are what one gets if it is, respectively, `ℚ[x,y]` or `ℚ[x][y]`.

We make a different choice: the variables relative to which one wants to
take the expansion, need to be passed explicitly:

    julia> coefficient(x^3 + x^2*y + y, (1,), :y)
    x^2 + 1
    julia> coefficient(x^3 + x^2*y + y, (0,1), :x, :y)
    1

At first glance, this may seem more cumbersome than usual. However, in a
situation where one switches perspective regularly, the alternative is much
harder to work with. This is because it is not obvious from the name of a
variable `x` which parent object it belongs to.

Moreover, in practice, this choice does not sacrifice convenience at all,
because the following macro is provided:

    julia> @coefficient(x^2 + x^2*y + y, y)
    x^2 + 1
    julia> @coefficient(x^2 + x^2*y + y, x^0 * y)
    1

We (intend to) have similar 'relative' versions of functions such as
`expansion()`, `leading_term()` and `deg()`.

### User-friendly support for pools of indeterminate variables

It should be easy to generate a vector such as "two instances of the most
general polynomial of degree two":

    [c1*x^2 + c2*x + c3, c4*x^2 + c5*x + c6 ]

We make this possible by supporting polynomial rings with an unbounded
number of variables and a sparse representation of the exponents.

### Speed

For elementary operations, we aim to get within the typical factor 2 for
julia-vs-C when compared to Singular. At this point, this library has
comparable performance to Singular on at least one simple benchmark:

    $ julia <<JULIA
    using PolynomialRings; using Singular
    R = @ring ℤ[d,e,f]
    S,g,h,i = Singular.SingularPolynomialRing(Singular.SingularZZ, ["g","h","i"])
    (d+e+f)^4; (g+h+i)^4 # compile all julia code
    @time (d+e+f)^200
    @time (g+h+i)^200
    prod(d+e+f for _=1:5); prod(g+h+i for _=1:5) # compile all julia code
    @time prod(d+e+f for _=1:200)
    @time prod(g+h+i for _=1:200)
    JULIA
      0.151427 seconds (1.51 M allocations: 40.430 MiB, 20.68% gc time)
      0.879622 seconds (13.50 M allocations: 319.072 MiB, 2.00% gc time)
      1.584750 seconds (31.07 M allocations: 896.958 MiB, 29.18% gc time)
      1.030947 seconds (14.87 M allocations: 373.402 MiB, 1.99% gc time)


Note: the Singular code has some non-trivial Julia-overhead (as can be seen
from the allocations), so this comparison isn't quite fair.

### Use elementary Julia types wherever possible

For example, for any function operating on free finitely generated modules, the
module elements should just be represented by `AbstractArray{<:Polynomial}` or
`Dict{K,<:Polynomial}`. Polynomial coefficients can be any `Number`, any
`Array` (for expansions in a module), or any `Matrix` (for a polynomial ring
with matrix coefficients).
