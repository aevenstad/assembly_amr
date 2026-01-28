process MLST {
    publishDir "${params.outdir}/${meta.id}/mlst", mode: 'copy'
    containerOptions {
        params.mlst_db ? "-B ${params.mlst_db}" : ''
    }
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/mlst:2.23.0--hdfd78af_0'
        : 'biocontainers/mlst:2.23.0--hdfd78af_0'}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def datadirOpt = params.mlst_db ? "--datadir \"${params.mlst_db}/pubmlst\"" : ''
    def blastdbOpt = params.mlst_db ? "--blastdb \"${params.mlst_db}/blast/mlst.fa\"" : ''

    """
    mlst \\
        ${args} \\
        --threads ${task.cpus} \\
        ${datadirOpt} \\
        ${blastdbOpt} \\
        ${fasta} \\
        > ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mlst: \$( echo \$(mlst --version 2>&1) | sed 's/mlst //' )
    END_VERSIONS
    """
}
