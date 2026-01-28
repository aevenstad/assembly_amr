process LONGREAD_SUMMARY_TABLE {
    publishDir "${params.outdir}", mode: 'copy'
    label 'process_low'
    container "oras://community.wave.seqera.io/library/r-dplyr_r-openxlsx_r-purrr_r-readr_pruned:9c3c5e7a8434d04f"

    input:
        path(hybracter_per_contig)
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
            hybracter_per_contig='${hybracter_per_contig.join(" ")}',
            hybracter_summary='${hybracter_summary.join(" ")}',
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
