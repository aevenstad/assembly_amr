process AMRFINDERPLUS_RUN {
    publishDir "${params.outdir}/amrfinderplus/${meta.id}", mode: 'copy'
    containerOptions "-B ${params.amrfinderplus_db}"
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ncbi-amrfinderplus:4.0.19--hf69ffd2_0':
        'biocontainers/ncbi-amrfinderplus:4.0.19--hf69ffd2_0' }"

    input:
    tuple val(meta), path(species), path(fasta)

    output:
    tuple val(meta), path("${prefix}.tsv")          , emit: report
    tuple val(meta), path("${prefix}-mutations.tsv"), emit: mutation_report, optional: true
    path "versions.yml"                             , emit: versions
    env VER                                         , emit: tool_version
    env DBVER                                       , emit: db_version

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '--plus --ident_min 0.6 --coverage_min 0.6'
    prefix = task.ext.prefix ?: "${meta.id}"
    fasta_name = fasta.getName().replace(".gz", "")
    """
    # Set organism name (E.coli must be changed to "Escherichia")
    organism=\$(cat $species)
    if [[ "\$organism" == Escherichia* ]]; then
        organism="Escherichia"
    elif [[ "\$organism" == Klebsiella* ]]; then
        organism="Klebsiella_pneumoniae"
    fi
    
    # Path to valid AMRFinder organism names
    valid_species_list="${projectDir}/assets/amrfinder_organism_list.txt"
    
    # Check if organism is a valid AMRFinder option
    if grep -Fqx "\$organism" "\$valid_species_list"; then
        amrfinder \\
            --nucleotide $fasta \\
            --organism \$organism \\
            $args \\
            --database ${params.amrfinderplus_db} \\
            --threads $task.cpus > ${prefix}.tsv

    else
        # Run AMRFinder without organism option
        amrfinder \\
            --nucleotide $fasta \\
            $args \\
            --database ${params.amrfinderplus_db} \\
            --threads ${task.cpus} > ${prefix}.tsv
    fi


    VER=\$(amrfinder --version)
    DBVER=\$(echo \$(amrfinder --database /mnt/db --database_version 2> stdout) | rev | cut -f 1 -d ' ' | rev)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        amrfinderplus: \$(amrfinder --version)
        amrfinderplus-database: \$(echo \$(echo \$(amrfinder --database /mnt/db --database_version 2> stdout) | rev | cut -f 1 -d ' ' | rev))
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tsv

    VER=\$(amrfinder --version)
    DBVER=stub_version

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        amrfinderplus: \$(amrfinder --version)
        amrfinderplus-database: stub_version
    END_VERSIONS
    """
}
