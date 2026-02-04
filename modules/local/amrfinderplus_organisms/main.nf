process AMRFINDERPLUS_ORGANISMS {
    publishDir "${params.outdir}", mode: 'copy'
    containerOptions "-B ${params.amrfinderplus_db}"
    label 'process_small'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ncbi-amrfinderplus:4.0.3--hf69ffd2_0':
        'biocontainers/ncbi-amrfinderplus:4.0.3--hf69ffd2_1' }"

    output:
    path "amrfinder_organism_list.txt"                            , emit: txt

    when:
    task.ext.when == null || task.ext.when

    script:
    """
        amrfinder \\
            --list_organisms \\
            --database ${params.amrfinderplus_db} \\
            | cut -d":" -f2 \\
            | sed 's/, /\\n/g' \\
            > amrfinder_organism_list.txt
    """

    stub:
    """
    touch amrfinder_organism_list.txt
    """
}
