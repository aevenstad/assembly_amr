#!/bin/bash

# List of definition files
definitions=(
    "../singularity/lre-finder_v1.0.0.def"
    "../singularity/rMLST.def"
)

# Set container directory argument
container_dir=$1

echo ""
echo "Building Singularity Containers in:            ${container_dir}"
echo ""

# Check if any containers is already available in the container directory
for definition in "${definitions[@]}"; do
    container_name=$(basename $definition)
    container_name=${container_name%.def}.sif
    if [ -f $container_dir/$container_name ]; then
        echo "Container $container_name already exists in $container_dir"
    else
        echo "Building container $container_name"
        singularity build $container_dir/$container_name $definition
    fi
done
