process SHOVILL {
    publishDir "${params.outdir}", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/shovill:1.4.2--hdfd78af_0':
        'biocontainers/shovill:1.4.2--hdfd78af_0' }"
    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}/shovill/contigs.fa")                         , emit: contigs
    tuple val(meta), path("${meta.id}/shovill/shovill.corrections")                , emit: corrections
    tuple val(meta), path("${meta.id}/shovill/shovill.log")                        , emit: log
    tuple val(meta), path("${meta.id}/shovill/{skesa,spades,megahit,velvet}.fasta"), emit: raw_contigs
    tuple val(meta), path("${meta.id}/shovill/contigs.{fastg,gfa,LastGraph}")      , optional:true, emit: gfa
    path "${meta.id}/shovill/versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def memory = task.memory.toGiga()
    """
    shovill \\
        --R1 ${reads[0]} \\
        --R2 ${reads[1]} \\
        --depth 150 \\
        --minlen 200 \\
        --mincov 2 \\
        --cpus $task.cpus \\
        --ram $memory \\
        --outdir ./${prefix}/shovill \\
        --force

    cat <<-END_VERSIONS > ${prefix}/shovill/versions.yml
    "${task.process}":
        shovill: \$(echo \$(shovill --version 2>&1) | sed 's/^.*shovill //')
    END_VERSIONS
    """
}
