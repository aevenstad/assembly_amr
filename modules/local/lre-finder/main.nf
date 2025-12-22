process LRE_FINDER {
    publishDir "${params.outdir}/${meta.id}/lre-finder", mode: 'copy'
    tag "${meta.id}"

    container 'docker://andreeve867/lrefinder:latest'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.txt"), optional: true, emit: txt
    tuple val(meta), path("*.res"), optional: true
    tuple val(meta), path("*.pos"), optional: true
    tuple val(meta), path("*.fsa"), optional: true
    tuple val(meta), path("*.aln"), optional: true
    tuple val(meta), path("*.gz"), optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: '-ID 90 -1t1 -cge -matrix'
    """

    if [[ -f "${reads}[0]" && -f "${reads}[1]" ]]; then
        LRE-Finder.py \\
        -ipe ${reads}[0] ${reads}[1] \\
        -o ./${prefix} \\
        -t_db /lre-finder/elmDB/elm \\
        ${args} |\\
        html2text > LRE-Finder_out.txt

    else
        LRE-Finder.py \\
        -i ${reads} \\
        -o ./${prefix} \\
        -t_db /lre-finder/elmDB/elm \\
        ${args} |\\
        html2text > LRE-Finder_out.txt
    fi

    {
    echo '\\"${task.process}\\":'
    echo '    LRE-Finder: '\$(grep "VERSION =" /opt/bin/LRE-Finder.py | cut -d"\\"" -f2)
    } > versions.yml
    """
}
