process AMRFINDERPLUS_RUN {
    publishDir "${params.outdir}/${meta.id}/amrfinderplus", mode: 'copy'
    containerOptions "-B ${params.amrfinderplus_db}"
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ncbi-amrfinderplus:4.2.7--hf69ffd2_0':
        'biocontainers/ncbi-amrfinderplus:4.2.7--hf69ffd2_0' }"

    input:
    tuple val(meta), path(species), path(fasta)
    path valid_species_list

    output:
    tuple val(meta), path("${prefix}.tsv")          , emit: report
    tuple val(meta), path("${prefix}-mutations.tsv"), emit: mutation_report, optional: true
    path "AMRFinder.log"                            , emit: log
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '--plus --ident_min 0.6 --coverage_min 0.6'
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Set organism name (E.coli must be changed to "Escherichia")
    organism=\$(cat $species | sed 's/ /_/g')
    if [[ "\$organism" == Escherichia* ]]; then
        organism="Escherichia"
    fi
    
    
    # Check if organism is a valid AMRFinder option
    if grep -Fqx "\$organism" "$valid_species_list"; then
        amrfinder \\
            --nucleotide $fasta \\
            --organism \$organism \\
            $args \\
            --database ${params.amrfinderplus_db} \\
            --threads 1 > ${prefix}.tsv \\
            2> AMRFinder.log

    else
        # Run AMRFinder without organism option
        amrfinder \\
            --nucleotide $fasta \\
            $args \\
            --database ${params.amrfinderplus_db} \\
            --threads 1 > ${prefix}.tsv \\
            2> AMRFinder.log
    fi


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        amrfinderplus: \$(amrfinder --version)
        amrfinderplus-database: \$(echo \$(echo \$(amrfinder --database ${params.amrfinderplus_db} --database_version 2> stdout) | rev | cut -f 1 -d ' ' | rev))
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        amrfinderplus: \$(amrfinder --version)
        amrfinderplus-database: stub_version
    END_VERSIONS
    """
}
