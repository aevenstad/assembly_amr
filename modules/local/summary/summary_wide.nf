process WRITE_SUMMARY {
    publishDir "${params.outdir}/${meta_id}/summary", mode: 'copy'
    tag "$meta_id"
    label 'process_low'

    input:
    tuple val(meta_id), \
            val(N_CONTIGS), \
            val(N50), \
            val(LENGTH), \
            val(COVERAGE), \
            val(MLST_SPECIES), \
            val(ST), \
            val(rMLST_SPECIES), \
            val(KLEBORATE_SPECIES), \
            val(OMP_MUTATIONS), \
            val(COL_MUTATIONS), \
            val(PLASMIDS)

    output:
    tuple val(meta_id), path("*summary.tsv"), emit: summary

    script:
    def prefix = task.ext.prefix ?: "${meta_id}"
    """
    echo -e "Sample\tNo. contigs\tN50\tLength\tCoverage\tSpecies pubMLST\tMLST\tSpecies rMLST\tSpecies Kleborate\tKleborate Omp mutations\tKleborate Col mutations\tPlasmids" > ${prefix}_summary.tsv
    echo -e "${meta_id}\t${N_CONTIGS}\t${N50}\t${LENGTH}\t${COVERAGE}\t${MLST_SPECIES}\t${ST}\t${rMLST_SPECIES}\t${KLEBORATE_SPECIES}\t${OMP_MUTATIONS}\t${COL_MUTATIONS}\t${PLASMIDS}" >> ${prefix}_summary.tsv
    """
}