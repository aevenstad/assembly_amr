process KLEBORATE {
    publishDir "${params.outdir}", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'


    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kleborate:3.1.2--pyhdfd78af_0' :
        'biocontainers/kleborate:3.1.2--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(species), path(fastas)

    output:
    tuple val(meta), path("${meta.id}/kleborate/*.txt"), emit: txt
    tuple val(meta), env(KLEBORATE_SPECIES), emit: kleborate_species
    tuple val(meta), env(OMP_MUTATIONS), emit: kleborate_omp
    tuple val(meta), env(COL_MUTATIONS), emit: kleborate_col
    path "${meta.id}/kleborate/versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '-p kpsc'
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    species_content=\$(cat $species)
    echo "Species file content: \$species_content"

    if [[ "\$species_content" == *"Klebsiella"* ]]; then
        kleborate \\
        $args \\
        --outdir $prefix/kleborate \\
        --assemblies $fastas

        # Create variables for summary
        KLEBORATE_SPECIES=\$(tail -n1 $prefix/kleborate/klebsiella_pneumo_complex_output.txt | cut -f2)
        OMP_MUTATIONS=\$(awk -F'\t' -v col="klebsiella_pneumo_complex__amr__Omp_mutations" \\
            'NR==1 {for (i=1; i<=NF; i++) if ($i == col) c=i} c {print $c}' \\
            F="\t" kleborate/klebsiella_pneumo_complex_output.txt | tail -n1)
        COL_MUTATIONS=\$(awk -F'\t' -v col="klebsiella_pneumo_complex__amr__Col_mutations" \\
            'NR==1 {for (i=1; i<=NF; i++) if ($i == col) c=i} c {print $c}' \\
            F="\t" kleborate/klebsiella_pneumo_complex_output.txt | tail -n1)        

    else
        echo "Skipping Kleborate..."
        mkdir -p $prefix/kleborate
        echo "Kleborate skipped for \$species_content" > ${prefix}/kleborate/kleborate_skipped.txt
        KLEBORATE_SPECIES="NA"
        OMP_MUTATIONS="NA"
        COL_MUTATIONS="NA"
    fi

    kleborate_version=\$(kleborate --version 2>&1 | grep "Kleborate v" | sed 's/Kleborate v//;')
    echo "Kleborate version: \$kleborate_version"
    echo '"'"${task.process}"'":' > ${prefix}/kleborate/versions.yml
    echo "    kleborate: \$kleborate_version" >> ${prefix}/kleborate/versions.yml
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.results.txt

    cat <<-END_VERSIONS > ${prefix}/kleborate/versions_test.yml
    "${task.process}":
        kleborate: \$(kleborate --version 2>&1 | sed 's/Kleborate v//;')
    END_VERSIONS
    """
}
