process PLASMID_FASTA {
    publishDir "${params.outdir}/${meta.id}/plasmids", mode: 'copy'
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.9.0--h9ee0642_0' :
        'biocontainers/seqkit:2.9.0--h9ee0642_0' }"
    
    input:
    tuple val(meta), path(plasmid_fasta)

    output:
    tuple val(meta), path("${meta.id}*.fasta"), emit : plasmids

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    seqkit split -s 1 $plasmid_fasta

    # Rename split fasta files based on header
    for file in ${plasmid_fasta}.split/*; do 
        new_name=\$(grep -o ">\\S*" \$file | sed 's/>//g')
        mv \$file ${prefix}_\${new_name}.fasta
    done
    """
}