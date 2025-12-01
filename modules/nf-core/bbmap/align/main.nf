process BBMAP_ALIGN {
    publishDir "${params.outdir}/${meta.id}/bbmap", mode: 'copy'
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/mulled-v2-008daec56b7aaf3f162d7866758142b9f889d690:e8a286b2e789c091bac0a57302cdc78aa0112353-0'
        : 'biocontainers/mulled-v2-008daec56b7aaf3f162d7866758142b9f889d690:e8a286b2e789c091bac0a57302cdc78aa0112353-0'}"

    input:
    tuple val(meta), path(fastq), path(ref)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("${meta.id}_bbmap_statistics.txt"), emit: txt
    tuple val(meta), path("${meta.id}_bbmap_covstats.txt"), emit: covstats

    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    input = meta.single_end ? "in=${fastq}" : "in=${fastq[0]} in2=${fastq[1]}"

    // Set the db variable to reflect the three possible types of reference input: 1) directory
    // named 'ref', 2) directory named something else (containing a 'ref' subdir) or 3) a sequence
    // file in fasta format
    if (ref.isDirectory()) {
        if (ref ==~ /(.\/)?ref\/?/) {
            db = ''
        }
        else {
            db = "path=${ref}"
        }
    }
    else {
        db = "ref=${ref}"
    }

    """
    bbmap.sh \\
        ${db} \\
        ${input} \\
        out=${prefix}.bam \\
        covstats=${prefix}_bbmap_covstats.txt \\
        threads=${task.cpus} \\
        -Xmx${task.memory.toGiga()}g \\
        1>${prefix}_bbmap_statistics.txt 2>&1


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bbmap: \$(bbversion.sh | grep -v "Duplicate cpuset")
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam
    touch ${prefix}.bbmap.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bbmap: \$(bbversion.sh | grep -v "Duplicate cpuset")
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
    END_VERSIONS
    """
}
