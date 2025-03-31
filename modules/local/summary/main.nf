process SAMPLE_SUMMARY {
    publishDir "${params.outdir}/summary", mode: 'copy'
    tag "$meta_id"
    label 'process_low'

    input:
    tuple val(meta_id), path(quast_results), \
                        path(bbmap_results), \
                        path(mlst_results), \
                        path(rmlst_results), \
                        path(kleborate_results), \
                        path(amrfinderplus_results), \
                        path(plasmidfinder_results)
    
    output:
    tuple val(meta_id), path("*summary.tsv"), emit: summary
    
    script:
    def prefix = task.ext.prefix ?: "${meta_id}"
    """
    # Get QUAST stats
    N_CONTIGS=\$(grep '# contigs (>= 0 bp)' $quast_results | cut -f2)
    N50=\$(grep 'N50' $quast_results | cut -f2)
    LENGTH=\$(grep 'Total length (>= 0 bp)' $quast_results | cut -f2)

    # Get BBMap coverage
    COVERAGE=\$(grep "Average coverage:" $bbmap_results | rev | cut -f1 | rev)

    # Get MLST species and ST
    ST=\$(cut -f3 $mlst_results)
    MLST_SPECIES=\$(cut -f2 $mlst_results)

    # Get rMLST results
    support=\$(grep "Support:" $rmlst_results | sed 's/Support://')
    species=\$(grep "Taxon:" $rmlst_results | sed 's/Taxon://')
    rMLST_SPECIES=\$(echo -e "\$species (\$support)")

    # Get Kleborate results
    if [[ -f $kleborate_results/kleborate_skipped.txt ]]; then
        KLEBORATE_SPECIES="NA"
        OMP_MUTATIONS="NA"
        COL_MUTATIONS="NA"
    else
        cat $kleborate_results/klebsiella_pneumo_complex_output.txt | datamash transpose | perl -pe 's/ /_/g' | sed 's/.*__//' > kleborate_long.txt
        KLEBORATE_SPECIES=\$(grep -w "species" kleborate_long.txt | cut -f2)
        KLEBORATE_MATCH=\$(grep -w "species_match" kleborate_long.txt | cut -f2)
        KLEBORATE_QC=\$(grep -w "QC_warnings" kleborate_long.txt | cut -f2)
        OMP_MUTATIONS=\$(grep -w "Omp_mutations" kleborate_long.txt | cut -f2)
        COL_MUTATIONS=\$(grep -w "Col_mutations" kleborate_long.txt | cut -f2)

    fi

    # Get PlasmidFinder results
    plasmid_id=\$(cut -f2 $plasmidfinder_results | grep -v "Plasmid")
    identity=\$(cut -f3 $plasmidfinder_results | grep -v "Identity")
    PLASMIDS=\$(paste <(echo "\$plasmid_id") <(echo "\$identity") | awk '{printf "%s (%s) | ", \$1, \$2}' | sed 's/ | \$//')

    # Write summary table
    echo -e "Metric\tValue" > ${prefix}_summary.tsv
    echo -e "Sample\t${meta_id}" >> ${prefix}_summary.tsv
    echo -e "No. contigs\t\${N_CONTIGS}" >> ${prefix}_summary.tsv
    echo -e "N50\t\${N50}" >> ${prefix}_summary.tsv
    echo -e "Length\t\${LENGTH}" >> ${prefix}_summary.tsv
    echo -e "Coverage\t\${COVERAGE}" >> ${prefix}_summary.tsv
    echo -e "Species pubMLST\t\${MLST_SPECIES}" >> ${prefix}_summary.tsv
    echo -e "MLST\t\${ST}" >> ${prefix}_summary.tsv
    echo -e "Species rMLST\t\${rMLST_SPECIES}" >> ${prefix}_summary.tsv
    echo -e "Species Kleborate\t\${KLEBORATE_SPECIES}" >> ${prefix}_summary.tsv
    echo -e "Kleborate Omp mutations\t\${OMP_MUTATIONS}" >> ${prefix}_summary.tsv
    echo -e "Kleborate Col mutations\t\${COL_MUTATIONS}" >> ${prefix}_summary.tsv
    echo -e "Plasmids\t\${PLASMIDS}" >> ${prefix}_summary.tsv
   """                        
}