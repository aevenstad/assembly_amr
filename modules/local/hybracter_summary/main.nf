process HYBRACTER_SUMMARY {
    publishDir "${params.outdir}", mode: 'copy'
    label 'process_low'
    
    input:
    path(hybracter_results)

    output:
    path("hybracter_summary.tsv"), emit: summary
    
    script:
    """
    # Get header from the first file
    head -n 1 \$(ls $hybracter_results | head -n 1) > hybracter_summary.tsv

    # Append rows from all summaries
    for file in $hybracter_results; do
        tail -n +2 \$file >> hybracter_summary.tsv
    done
    """
}