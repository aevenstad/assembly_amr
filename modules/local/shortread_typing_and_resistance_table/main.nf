process TYPING_AND_RESISTANCE_TABLE {
    publishDir "${params.outdir}/tables", mode: 'copy'
    tag "$meta_id"
    label 'process_low'
    container "community.wave.seqera.io/library/pip_pandas:9cf85c2568d5b002"

    input:
    tuple val(meta_id), path(mlst_results), \
                        path(rmlst_results), \
                        path(kleborate_results), \
                        path(amrfinder_results), \
                        path(plasmidfinder_results), \
                        path(lrefinder_results), \
                        path(virulencefinder_results)
    path(amrfinderplus_classes)

    output:
    tuple val(meta_id), path("${meta_id}_resistance_table.tsv"), emit: summary

    script:
    def prefix = task.ext.prefix ?: "${meta_id}"
    """
    resistance_summary.py \\
        $mlst_results \\
        $rmlst_results \\
        $kleborate_results \\
        $amrfinder_results \\
        $amrfinderplus_classes \\
        $plasmidfinder_results \\
        $lrefinder_results \\
        $virulencefinder_results \\
        $prefix \\
        ${prefix}_resistance_table.tsv
    """
}
