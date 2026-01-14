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
