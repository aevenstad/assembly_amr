process MLST {
    publishDir "${params.outdir}/${meta.id}/mlst", mode: 'copy'
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mlst:2.23.0--hdfd78af_0' :
        'biocontainers/mlst:2.23.0--hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta), path(mlst_species_names)

    output:
    tuple val(meta), path("*_mlst.tsv"), emit: tsv
    tuple val(meta), path("*renamed.tsv"), emit: renamed_tsv
    path "log.txt"                   , emit: log
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

    # Rename species in MLST output
    bash $mlst_species_names ${prefix}_mlst.tsv 2> log.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mlst: \$( echo \$(mlst --version 2>&1) | sed 's/mlst //' )
    END_VERSIONS
    """

}
