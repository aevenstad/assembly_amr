process RMLST {
    publishDir "${params.outdir}/${meta.id}/rmlst", mode: 'copy'
    tag "${meta.id}"
    label 'process_low'
    maxForks 4

    // Retry on network-related failure
    errorStrategy { task.exitStatus in (1 + 2 + 3 + 7 + 28) ? 'retry' : 'finish' }
    maxRetries 3

    container 'docker://andreeve867/rmlst:latest'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}_rmlst.txt"), emit: rmlst
    tuple val(meta), path("${meta.id}_species.txt"), emit: species
    tuple val(meta), path("${meta.id}_species_list.txt"), optional: true, emit: species_list
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def fastaOption = fasta ? "--file ${fasta}" : ''

    """
    python3 /opt/rMLST/species_api_upload.py ${fastaOption} > ${prefix}_rmlst.txt

    grep "Taxon:" ${prefix}_rmlst.txt |\\
    sed 's/Taxon://;;s/ /_/' |\\
    awk 'NR==1{print \$1}' \\
    > ${prefix}_species.txt

    species_number=\$(grep -c "Taxon:" ${prefix}_rmlst.txt)
    if [ "\$species_number" -gt 1 ]; then
        grep "Taxon:" ${prefix}_rmlst.txt |\\
        sed 's/Taxon://;;s/ /_/' \\
        > ${prefix}_species_list.txt
    fi


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        PubMLST rMLST: https://pubmlst.org/species-id
    END_VERSIONS
    """
}
