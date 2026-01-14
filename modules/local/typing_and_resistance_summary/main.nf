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
                        path(lrefinder_results)
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
        $prefix \\
        ${prefix}_resistance_table.tsv
    """
}

process PER_CONTIG_RESISTANCE_SUMMARY {
    publishDir "${params.outdir}", mode: 'copy'
    label 'process_low'
    container "oras://community.wave.seqera.io/library/r-dplyr_r-openxlsx_r-purrr_r-readr_pruned:9c3c5e7a8434d04f"

    input:
        path(hybracter_summary)
        path(plassembler_summary)
        path(mlst_results)
        path(rmlst_results)
        path(amrfinder_results)
        path(plasmidfinder_results)
        path(kleborate_results)
        path(longread_summary_script)

    output:
    path("*.xlsx"), emit: summary

    script:
    """
    Rscript -e "rmarkdown::render(
        input = '${longread_summary_script}',
        output_format=NULL,
        params=list(
            hybracter_files='${hybracter_summary.join(" ")}',
            plassembler_files='${plassembler_summary.join(" ")}',
            mlst_files='${mlst_results.join(" ")}',
            rmlst_files='${rmlst_results.join(" ")}',
            kleborate_files='${kleborate_results.join(" ")}',
            amrfinder_files='${amrfinder_results.join(" ")}',
            plasmidfinder_files='${plasmidfinder_results.join(" ")}',
            output_file='${params.run_name}_summary_table.xlsx'
        )
    )"
    """
}

process MERGE_TYPING_AND_RESISTANCE_TABLES {
    publishDir "${params.outdir}/tables", mode: 'copy'
    label 'process_low'

    input:
    path(resistance_summaries)

    output:
    path("*_resistance_summary.tsv"), emit: summary

    script:
    """
    # Get header from the first file
    head -n 1 \$(ls $resistance_summaries | head -n 1) > ${params.run_name}_resistance_summary.tsv

    # Append rows from all summaries
    for file in $resistance_summaries; do
        tail -n +2 \$file >> ${params.run_name}_resistance_summary.tsv
    done
    """
}

