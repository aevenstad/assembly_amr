process KLEBORATE {
    publishDir "${params.outdir}/${meta.id}/kleborate", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'


    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kleborate:3.1.2--pyhdfd78af_0' :
        'biocontainers/kleborate:3.1.2--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fastas)

    output:
    tuple val(meta), path("*.txt")  , emit: txt
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '-p kpsc'
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    kleborate \\
    $args \\
    --outdir ./ \\
    --assemblies $fastas

    kleborate_version=\$(kleborate --version 2>&1 | grep "Kleborate v" | sed 's/Kleborate v//;')
    echo "Kleborate version: \$kleborate_version"
    echo '"'"${task.process}"'":' > versions.yml
    echo "    kleborate: \$kleborate_version" >> versions.yml
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.results.txt

    cat <<-END_VERSIONS > versions_test.yml
    "${task.process}":
        kleborate: \$(kleborate --version 2>&1 | sed 's/Kleborate v//;')
    END_VERSIONS
    """
}
