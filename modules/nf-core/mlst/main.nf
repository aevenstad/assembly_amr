process MLST {
    publishDir "${params.outdir}/${meta.id}/mlst", mode: 'copy'
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mlst:2.23.0--hdfd78af_0' :
        'biocontainers/mlst:2.23.0--hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    tuple val(meta), env(ST), emit: sequence_type
    tuple val(meta), env(MLST_SPECIES), emit: mlst_species
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mlst \\
        $args \\
        --threads $task.cpus \\
        $fasta \\
        > ${prefix}_mlst.tsv

    ST=\$(cut -f3 ${prefix}_mlst.tsv)
    MLST_SPECIES=\$(cut -f2 ${prefix}_mlst.tsv)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mlst: \$( echo \$(mlst --version 2>&1) | sed 's/mlst //' )
    END_VERSIONS
    """

}
