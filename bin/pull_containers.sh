#!/bin/bash

# List of container images
containers=(
    "https://depot.galaxyproject.org/singularity/ncbi-amrfinderplus:4.0.19--hf69ffd2_0"
    "https://depot.galaxyproject.org/singularity/bakta:1.10.4--pyhdfd78af_0"
    "https://depot.galaxyproject.org/singularity/fastp:0.23.4--h5f740d0_0"
    "https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0"
    "docker://quay.io/gbouras13/hybracter:0.11.0"
    "https://depot.galaxyproject.org/singularity/kleborate:3.1.2--pyhdfd78af_0"
    "https://depot.galaxyproject.org/singularity/mlst:2.23.0--hdfd78af_0"
    "https://depot.galaxyproject.org/singularity/nanostat:1.6.0--pyhdfd78af_0"
    "https://depot.galaxyproject.org/singularity/plasmidfinder:2.1.6--py310hdfd78af_1"
    "https://depot.galaxyproject.org/singularity/quast:5.2.0--py39pl5321heaaa4ec_4"
    "https://depot.galaxyproject.org/singularity/shovill:1.1.0--0"
)

# Set container directory argument
container_dir=$1

echo ""
echo "Installing Singularity Containers in:            ${container_dir}"
echo ""


# Check if any containers is already available in the container directory
for container in "${containers[@]}"; do
    container_name=$(basename $container)
    if [ -f $container_dir/$container_name ]; then
        echo "Container $container_name already exists in $container_dir"
    else
        echo "Pulling container $container_name"
        singularity pull $container_dir/$container_name $container
    fi
done
