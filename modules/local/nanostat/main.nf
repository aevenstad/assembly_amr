process NANOSTAT_RAW {
    publishDir "${params.outdir}/nanostat/${meta.id}", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanostat:1.6.0--pyhdfd78af_0' :
        'biocontainers/nanostat:1.6.0--pyhdfd78af_0' }"


    input:
    tuple val(meta), path(longreads)

    output:
    path "*_raw_NanoStats.txt"                 , emit: nanostat_raw
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    NanoStat \\
        --fastq $longreads \\
        --name "${prefix}_raw_NanoStats.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanostat: \$(NanoStat --version | sed -e "s/nanostat, version //g")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_raw_NanoStats.txt
    touch versions.yml
    """
}

process NANOSTAT_TRIMMED {
    publishDir "${params.outdir}/nanostat/${meta.id}", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanostat:1.6.0--pyhdfd78af_0' :
        'biocontainers/nanostat:1.6.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(trimmed_longreads)

    output:
    path "*_trimmed_NanoStats.txt"                     , emit: nanostat_trimmed

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    NanoStat \\
        --fastq $trimmed_longreads \\
        --name "${prefix}_trimmed_NanoStats.txt"
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_trimmed_NanoStats.txt
    """
}