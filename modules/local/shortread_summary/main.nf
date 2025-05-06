process SHORTREAD_STATS {
    publishDir "${params.outdir}/${meta_id}", mode: 'copy'
    tag "$meta_id"
    label 'process_low'

    input:
    tuple val(meta_id), path(quast_results), \
                        path(bbmap_results)
    
    output:
    tuple val(meta_id), path("*assembly.tsv"), emit: summary
    
    script:
    def prefix = task.ext.prefix ?: "${meta_id}"
    """
    # Get QUAST stats
    N_CONTIGS=\$(grep '# contigs (>= 0 bp)' $quast_results | cut -f2)
    N50=\$(grep 'N50' $quast_results | cut -f2)
    LENGTH=\$(grep 'Total length (>= 0 bp)' $quast_results | cut -f2)

    # Get BBMap coverage
    COVERAGE=\$(grep "Average coverage:" $bbmap_results | rev | cut -f1 | rev)

    # Write summary table
    echo -e "Sample\tNo. contigs\tN50\tLength\tCoverage" > ${prefix}_assembly.tsv
    echo -e "${meta_id}\t\${N_CONTIGS}\t\${N50}\t\${LENGTH}\t\${COVERAGE}" >> ${prefix}_assembly.tsv
   """
}

process STATS_FROM_FASTA {
    publishDir "${params.outdir}/${meta_id}", mode: 'copy'
    tag "$meta_id"
    label 'process_low'

    input:
    tuple val(meta_id), path(quast_results)

    
    output:
    tuple val(meta_id), path("*assembly.tsv"), emit: summary
    
    script:
    def prefix = task.ext.prefix ?: "${meta_id}"
    """
    # Get QUAST stats
    N_CONTIGS=\$(grep '# contigs (>= 0 bp)' $quast_results | cut -f2)
    N50=\$(grep 'N50' $quast_results | cut -f2)
    LENGTH=\$(grep 'Total length (>= 0 bp)' $quast_results | cut -f2)

    # Write summary table
    echo -e "Sample\tNo. contigs\tN50\tLength" > ${prefix}_assembly.tsv
    echo -e "${meta_id}\t\${N_CONTIGS}\t\${N50}\t\${LENGTH}" >> ${prefix}_assembly.tsv
   """
}

process MERGE_SHORTREAD_STATS {
    publishDir "${params.outdir}", mode: 'copy'
    label 'process_low'

    input:
    path(assembly_summary)

    output:
    path("assembly_summary.tsv"), emit: summary

    script:
    """
    # Get header from the first file
    head -n 1 \$(ls $assembly_summary | head -n 1) > assembly_summary.tsv

    # Append rows from all summaries
    for file in $assembly_summary; do
        tail -n +2 \$file >> assembly_summary.tsv
    done
   """
}