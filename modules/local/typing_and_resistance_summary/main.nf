process TYPING_AND_RESISTANCE_TABLE {
    publishDir "${params.outdir}/${meta_id}", mode: 'copy'
    tag "$meta_id"
    label 'process_low'

    input:
    tuple val(meta_id), path(mlst_results), \
                        path(rmlst_results), \
                        path(kleborate_results), \
                        path(amrfinder_results), \
                        path(plasmidfinder_results)
    
    output:
    tuple val(meta_id), path("*summary.tsv"), emit: summary
    
    script:
    def prefix = task.ext.prefix ?: "${meta_id}"
    """
    # Get MLST species and ST
    ST=\$(cut -f3 $mlst_results)
    MLST_SPECIES=\$(cut -f2 $mlst_results)

    # Get rMLST results
    support=\$(grep "Support:" $rmlst_results | sed 's/Support://')
    species=\$(grep "Taxon:" $rmlst_results | sed 's/Taxon://')
    rMLST_SPECIES=\$(echo -e "\$species (\$support)")

    # Get Kleborate results
    if [[ -f kleborate_skipped.txt ]]; then
        KLEBORATE_SPECIES="NA"
        KLEBORATE_MATCH="NA"
        KLEBORATE_QC="NA"
        OMP_MUTATIONS="NA"
        COL_MUTATIONS="NA"
    else
        cat $kleborate_results | datamash transpose | perl -pe 's/ /_/g' | sed 's/.*__//' > kleborate_long.txt
        KLEBORATE_SPECIES=\$(grep -w "species" kleborate_long.txt | cut -f2)
        KLEBORATE_MATCH=\$(grep -w "species_match" kleborate_long.txt | cut -f2)
        KLEBORATE_QC=\$(grep -w "QC_warnings" kleborate_long.txt | cut -f2)
        OMP_MUTATIONS=\$(grep -w "Omp_mutations" kleborate_long.txt | cut -f2)
        COL_MUTATIONS=\$(grep -w "Col_mutations" kleborate_long.txt | cut -f2)

    fi

    # Get AMRFinderPlus results
    extract_resistance_genes() {
        local drug_class="\$1"
        awk -F'\\t' -v class="\$drug_class" '\$11 == class && \$16 > 90 && \$17 > 90 {print \$6, "(" \$16, \$17 ")"}' "$amrfinder_results" | tr '\\n' ' '
    }

    AMINOGLYCOSIDE=\$(extract_resistance_genes "AMINOGLYCOSIDE")
    AMINOGLYCOSIDE_QUINOLONE=\$(extract_resistance_genes "AMINOGLYCOSIDE/QUINOLONE")
    BETALACTAM=\$(extract_resistance_genes "BETA-LACTAM")
    BLEOMYCIN=\$(extract_resistance_genes "BLEOMYCIN")
    COLISTIN=\$(extract_resistance_genes "COLISTIN")
    FLUOROQUINOLONE=\$(extract_resistance_genes "FLUOROQUINOLONE")
    FOSFOMYCIN=\$(extract_resistance_genes "FOSFOMYCIN")
    GLYCOPEPTIDE=\$(extract_resistance_genes "GLYCOPEPTIDE")
    LINCOSAMIDE=\$(extract_resistance_genes "LINCOSAMIDE")
    LINCOSAMIDE_MACROLIDE=\$(extract_resistance_genes "LINCOSAMIDE/MACROLIDE")
    LINCOSAMIDE_MACROLIDE_STREPTOGRAMIN=\$(extract_resistance_genes "LINCOSAMIDE/MACROLIDE/STREPTOGRAMIN")
    LINCOSAMIDE_STREPTOGRAMIN=\$(extract_resistance_genes "LINCOSAMIDE/STREPTOGRAMIN")
    MACROLIDE=\$(extract_resistance_genes "MACROLIDE")
    MACROLIDE_STREPTOGRAMIN=\$(extract_resistance_genes "MACROLIDE/STREPTOGRAMIN")
    PHENICOL=\$(extract_resistance_genes "PHENICOL")
    PHENICOL_OXAZOLIDINONE=\$(extract_resistance_genes "PHENICOL/OXAZOLIDINONE")
    PHENICOL_QUINOLONE=\$(extract_resistance_genes "PHENICOL/QUINOLONE")
    QUATERNARY_AMMONIUM=\$(extract_resistance_genes "QUATERNARY AMMONIUM")
    QUINOLONE=\$(extract_resistance_genes "QUINOLONE")
    TETRACYCLINE=\$(extract_resistance_genes "TETRACYCLINE")
    SULFONAMIDE=\$(extract_resistance_genes "SULFONAMIDE")
    RIFAMYCIN=\$(extract_resistance_genes "RIFAMYCIN")
    STREPTOTHRICIN=\$(extract_resistance_genes "STREPTOTHRICIN")
    SULFONAMIDE=\$(extract_resistance_genes "SULFONAMIDE")
    TETRACYCLINE_=\$(extract_resistance_genes "TETRACYCLINE")
    TRIMETHOPRIM=\$(extract_resistance_genes "TRIMETHOPRIM")



    # Get PlasmidFinder results
    if [[ \$(wc -l < $plasmidfinder_results) -eq 1 ]]; then
        PLASMIDS="NA"
    else
        # Get the plasmid ID and identity
        plasmid_id=\$(cut -f2 $plasmidfinder_results | grep -v "Plasmid")
        identity=\$(cut -f3 $plasmidfinder_results | grep -v "Identity")
        PLASMIDS=\$(paste <(echo "\$plasmid_id") <(echo "\$identity") | awk '{printf "%s (%s) | ", \$1, \$2}' | sed 's/ | \$//')
    fi

    # Write summary table
    echo -e "Sample\t${meta_id}" > ${prefix}_summary.tsv
    echo -e "Species pubMLST\t\${MLST_SPECIES}" >> ${prefix}_summary.tsv
    echo -e "MLST\t\${ST}" >> ${prefix}_summary.tsv
    echo -e "Species rMLST\t\${rMLST_SPECIES}" >> ${prefix}_summary.tsv
    echo -e "Species Kleborate\t\${KLEBORATE_SPECIES}" >> ${prefix}_summary.tsv
    echo -e "Kleborate QC warnings\t\${KLEBORATE_QC}" >> ${prefix}_summary.tsv
    echo -e "Kleborate species match\t\${KLEBORATE_MATCH}" >> ${prefix}_summary.tsv
    echo -e "Kleborate Omp mutations\t\${OMP_MUTATIONS}" >> ${prefix}_summary.tsv
    echo -e "Kleborate Col mutations\t\${COL_MUTATIONS}" >> ${prefix}_summary.tsv
    echo -e "Plasmids\t\${PLASMIDS}" >> ${prefix}_summary.tsv
    echo -e "AMINOGLYCOSIDE\t\${AMINOGLYCOSIDE}" >> ${prefix}_summary.tsv
    echo -e "AMINOGLYCOSIDE/QUINOLONE\t\${AMINOGLYCOSIDE_QUINOLONE}" >> ${prefix}_summary.tsv
    echo -e "BETA-LACTAM\t\${BETALACTAM}" >> ${prefix}_summary.tsv
    echo -e "BLEOMYCIN\t\${BLEOMYCIN}" >> ${prefix}_summary.tsv
    echo -e "COLISTIN\t\${COLISTIN}" >> ${prefix}_summary.tsv
    echo -e "FLUOROQUINOLONE\t\${FLUOROQUINOLONE}" >> ${prefix}_summary.tsv
    echo -e "FOSFOMYCIN\t\${FOSFOMYCIN}" >> ${prefix}_summary.tsv
    echo -e "GLYCOPEPTIDE\t\${GLYCOPEPTIDE}" >> ${prefix}_summary.tsv
    echo -e "LINCOSAMIDE\t\${LINCOSAMIDE}" >> ${prefix}_summary.tsv
    echo -e "LINCOSAMIDE/MACROLIDE\t\${LINCOSAMIDE_MACROLIDE}" >> ${prefix}_summary.tsv
    echo -e "LINCOSAMIDE/MACROLIDE/STREPTOGRAMIN\t\${LINCOSAMIDE_MACROLIDE_STREPTOGRAMIN}" >> ${prefix}_summary.tsv
    echo -e "LINCOSAMIDE/STREPTOGRAMIN\t\${LINCOSAMIDE_STREPTOGRAMIN}" >> ${prefix}_summary.tsv
    echo -e "MACROLIDE\t\${MACROLIDE}" >> ${prefix}_summary.tsv
    echo -e "MACROLIDE/STREPTOGRAMIN\t\${MACROLIDE_STREPTOGRAMIN}" >> ${prefix}_summary.tsv
    echo -e "PHENICOL\t\${PHENICOL}" >> ${prefix}_summary.tsv
    echo -e "PHENICOL/OXAZOLIDINONE\t\${PHENICOL_OXAZOLIDINONE}" >> ${prefix}_summary.tsv
    echo -e "PHENICOL/QUINOLONE\t\${PHENICOL_QUINOLONE}" >> ${prefix}_summary.tsv
    echo -e "QUATERNARY AMMONIUM\t\${QUATERNARY_AMMONIUM}" >> ${prefix}_summary.tsv
    echo -e "QUINOLONE\t\${QUINOLONE}" >> ${prefix}_summary.tsv
    echo -e "TETRACYCLINE\t\${TETRACYCLINE}" >> ${prefix}_summary.tsv
    echo -e "SULFONAMIDE\t\${SULFONAMIDE}" >> ${prefix}_summary.tsv
    echo -e "RIFAMYCIN\t\${RIFAMYCIN}" >> ${prefix}_summary.tsv
    echo -e "STREPTOTHRICIN\t\${STREPTOTHRICIN}" >> ${prefix}_summary.tsv
    echo -e "SULFONAMIDE\t\${SULFONAMIDE}" >> ${prefix}_summary.tsv
    echo -e "TETRACYCLINE_\t\${TETRACYCLINE_}" >> ${prefix}_summary.tsv
    echo -e "TRIMETHOPRIM\t\${TRIMETHOPRIM}" >> ${prefix}_summary.tsv

    # Transpose to wide format
    cat ${prefix}_summary.tsv | datamash transpose > ${prefix}_summary_wide.tsv
    rm ${prefix}_summary.tsv
    mv ${prefix}_summary_wide.tsv ${prefix}_summary.tsv
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

process TYPING_AND_RESISTANCE_TABLE_PY {
    publishDir "${params.outdir}/${meta_id}", mode: 'copy'
    tag "$meta_id"
    label 'process_low'
    container "/bigdata/Jessin/Softwares/containers/pip_pandas_b119e1f6a52aae23.sif"

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
    shortread_resistance_summary.py \\
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