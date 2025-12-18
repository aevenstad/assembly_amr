process RENAME_MLST {
    publishDir "${params.outdir}/${meta.id}/mlst", mode: 'copy'
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(mlst_out)
    path mlst_species_names

    output:
    tuple val(meta), path("*_renamed.tsv"),        emit: tsv
    tuple val(meta), path("*_species_name.txt"),   emit: species

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bash $mlst_species_names $mlst_out
    cut -f2 ${prefix}_renamed.tsv > ${prefix}_species_name.txt
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}_renamed.tsv
    touch ${prefix}_species_name.txt
    """
}
