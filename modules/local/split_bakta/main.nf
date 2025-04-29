process SPLIT_BAKTA {
    publishDir "${params.outdir}/${meta.id}/bakta", mode: 'copy'
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.9.0--h9ee0642_0' :
        'biocontainers/seqkit:2.9.0--h9ee0642_0' }"
    
    input:
    tuple val(meta), path(bakta_gff), path(bakta_fasta)

    output:
    tuple val(meta), path("${meta.id}*.gff3"), emit : bakta_split

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Get gff header
    head -n7 $bakta_gff > gff_header.txt

    # Get contig identifiers
    contigs=\$(grep -E "^>" $bakta_gff | sed 's/>//g')

    # Get fasta file from gff
    seqkit split -s 1 $bakta_fasta

    # Rename split fasta files based on header
    for file in ${bakta_fasta}.split/*; do 
        new_name=\$(grep -o ">\\S*" \$file | sed 's/>//g')
        mv \$file ${prefix}_\${new_name}.fasta
    done

    # Split gff file into separate files for each contig
    for contig in \$contigs; do
        gff_file="\${contig}.gff3"
        awk -v contig="\$contig" '\$1 == contig' $bakta_gff > \$gff_file
	    grep "##sequence-region \${contig}" $bakta_gff > \${contig}_annot_header.txt
	    cat gff_header.txt \${contig}_annot_header.txt \$gff_file ${prefix}_\${contig}.fasta > ${prefix}_\${gff_file}
    done
    """
}