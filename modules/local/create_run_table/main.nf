process CREATE_RUN_TABLE {
    publishDir "${params.outdir}" , mode: 'copy'
    label 'process_low'
    container "community.wave.seqera.io/library/pip_pandas:9cf85c2568d5b002"

    input:
    tuple path(assembly_table), path(resistance_table)

    output:
    path("run_table.tsv"), emit: run_table

    script:
    """
    merge_tables.py \\
        --assembly_summary $assembly_table \\
        --resistance_summary $resistance_table \\
        --output_table run_table.tsv
    """
}
