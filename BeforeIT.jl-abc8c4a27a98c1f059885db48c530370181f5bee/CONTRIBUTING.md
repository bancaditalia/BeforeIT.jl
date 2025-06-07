# Contributing to BeforeIT.jl

To contribute to BeforeIT.jl, feel free to:

  * Submit modifications to the code or documentation via a pull request.
  * Identify bugs and offer suggestions in the issues section of the project's GitHub page.
  * Get in touch directly with one of the authors to disccuss ideas on possible applications and developments.

Thank you for your time!

## How to run tests

To make sure that the code is still working after you modify it, you can run all tests by executing `julia --project=. test/runtests.jl`.

## How to preview the documentation

To preview changes to the documentation, you can build it locally using the script in docs/make.jl.
This requires the Documenter package, which you can install by executing `import Pkg; Pkg.add("Documenter")` in a REPL session. Then, build the documentation by executing `julia --project=. docs/make.jl` from a terminal. This will buil the new documentation within the build/ sub directory.
