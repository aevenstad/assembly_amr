process PLASMID_FASTA {
    publishDir "${params.outdir}/${meta.id}/plasmids", mode: 'copy'
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.9.0--h9ee0642_0' :
        'biocontainers/seqkit:2.9.0--h9ee0642_0' }"
    
    input:
    tuple val(meta), path(plasmid_fasta), path(plasmid_stats)

    output:
    tuple val(meta), path("circular/${meta.id}*.fasta"), optional: true
    tuple val(meta), path("linear/${meta.id}*.fasta"), optional: true
    tuple val(meta), path("unknown/${meta.id}*.fasta"), optional: true

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p circular
    mkdir -p linear
    mkdir -p unknown

    seqkit split -s 1 $plasmid_fasta

    # Rename split fasta files based on header
    for file in ${plasmid_fasta}.split/*; do 
        plasmid_name=\$(grep -o "plasmid00\\w*" \$file)
        if [ -z "\$plasmid_name" ]; then
            echo "No plasmid name found in \$file"
            mv \$file unknown/${prefix}_unknown.fasta
        else
            circular=\$(grep \$plasmid_name $plasmid_stats | cut -f 5)
            if [ "\$circular" == "True" ]; then
                mv \$file circular/${prefix}_\${plasmid_name}.fasta
            else
                mv \$file linear/${prefix}_\${plasmid_name}.fasta
            fi
        fi
    done
    """
}
