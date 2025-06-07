#!/bin/bash

# Run Julia formatter
julia --project -e 'using JuliaFormatter; format(".")'
git add -u