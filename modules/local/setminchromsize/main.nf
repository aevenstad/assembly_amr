process SETMINCHROMSIZE {
    publishDir "${params.outdir}/${meta.id}/minchromsize", mode: 'copy'
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(genus)
    path(genome_size_table)

    output:
    tuple val(meta), path("*_minchromsize.txt"), emit: txt

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    if grep -q "\$(cat $genus)" $genome_size_table; then
        grep "\$(cat $genus)" $genome_size_table |\\
            sort -nr -k2,2 |\\
            awk -F"," 'NR==1 {print \$2}' \\
            > ${prefix}_minchromsize.txt
    else
        echo "NA" > ${prefix}_minchromsize.txt
    fi
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}_minchromsize.txt
    """
}
