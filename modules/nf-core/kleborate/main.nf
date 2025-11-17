process KLEBORATE {
    publishDir "${params.outdir}", mode: 'copy'
    tag "${meta.id}"
    label 'process_medium'


    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/kleborate:3.1.2--pyhdfd78af_0'
        : 'biocontainers/kleborate:3.1.2--pyhdfd78af_0'}"

    input:
    tuple val(meta), path(species), path(fastas)

    output:
    tuple val(meta), path("${meta.id}/kleborate"), optional: true, emit: results
    tuple val(meta), path("${meta.id}/kleborate/*.txt"), optional: true, emit: txt
    path "${meta.id}/kleborate/versions.yml", optional: true, emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '-p kpsc'
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    species_content=\$(awk '{print \$2}' ${species})

    if [[ "\$species_content" == *"Klebsiella"* ]]; then
        kleborate \\
        ${args} \\
        --outdir ${prefix}/kleborate \\
        --assemblies ${fastas}

        kleborate_version=\$(kleborate --version 2>&1 | grep "Kleborate v" | sed 's/Kleborate v//;')
        echo "Kleborate version: \$kleborate_version"
        echo '"'"${task.process}"'":' > ${prefix}/kleborate/versions.yml
        echo "    kleborate: \$kleborate_version" >> ${prefix}/kleborate/versions.yml
    else
        echo "Skipping Kleborate..."
        echo "Kleborate skipped for \$species_content"
    fi
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.results.txt

    cat <<-END_VERSIONS > ${prefix}/kleborate/versions_test.yml
    "${task.process}":
        kleborate: \$(kleborate --version 2>&1 | sed 's/Kleborate v//;')
    END_VERSIONS
    """
}
