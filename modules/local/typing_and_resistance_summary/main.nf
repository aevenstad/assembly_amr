process TYPING_AND_RESISTANCE_TABLE {
    publishDir "${params.outdir}/${meta_id}", mode: 'copy'
    tag "$meta_id"
    label 'process_low'
    container "community.wave.seqera.io/library/pip_pandas:9cf85c2568d5b002"

    input:
    tuple val(meta_id), path(mlst_results), \
                        path(rmlst_results), \
                        path(kleborate_results), \
                        path(amrfinder_results), \
                        path(plasmidfinder_results)
    path(mlst_species_translation)
    path(amrfinderplus_classes)

    output:
    tuple val(meta_id), path("${meta_id}_resistance_table.tsv"), emit: summary

    script:
    def prefix = task.ext.prefix ?: "${meta_id}"
    """
    resistance_summary.py \\
        $mlst_results \\
        $mlst_species_translation \\
        $rmlst_results \\
        $kleborate_results \\
        $amrfinder_results \\
        $amrfinderplus_classes \\
        $plasmidfinder_results \\
        $prefix \\
        ${prefix}_resistance_table.tsv
    """
}

process PER_CONTIG_RESISTANCE_SUMMARY {
    publishDir "${params.outdir}/${meta_id}", mode: 'copy'
    tag "$meta_id"
    label 'process_low'
    container "/bigdata/Jessin/Softwares/containers/pip_pandas_b119e1f6a52aae23.sif"

    input:
    tuple val(meta_id), path(amrfinder_results), \
                        path(plasmidfinder_results)
    path(amrfinderplus_classes)

    output:
    tuple val(meta_id), path("${meta_id}_per_contig_resistance_table.tsv"), emit: summary

    script:
    def prefix = task.ext.prefix ?: "${meta_id}"
    """
    per_contig_resistance.py \\
        $plasmidfinder_results \\
        $amrfinder_results \\
        $amrfinderplus_classes \\
        ${prefix}_per_contig_resistance_table.tsv
    """
}

process MERGE_TYPING_AND_RESISTANCE_TABLES {
    publishDir "${params.outdir}", mode: 'copy'
    label 'process_low'

    input:
    path(resistance_summaries)

    output:
    path("resistance_summary.tsv"), emit: summary

    script:
    """
    # Get header from the first file
    head -n 1 \$(ls $resistance_summaries | head -n 1) > resistance_summary.tsv

    # Append rows from all summaries
    for file in $resistance_summaries; do
        tail -n +2 \$file >> resistance_summary.tsv
    done
    """
}

