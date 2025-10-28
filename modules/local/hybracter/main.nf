process HYBRACTER_HYBRID {
    publishDir "${params.outdir}", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container '/bigdata/Jessin/Softwares/containers/hybracter_0.11.0.sif'

    input:
    tuple val(meta), path(longreads), path(shortreads_1), path(shortreads_2)

    output:
    tuple val(meta), path("${meta.id}/hybracter/FINAL_OUTPUT")                                   , emit: final_output
    tuple val(meta), path("${meta.id}/hybracter/benchmarks")                                     , emit: benchmarks
    tuple val(meta), path("${meta.id}/hybracter/completeness")                                   , emit: completeness
    tuple val(meta), path("${meta.id}/hybracter/flags")                                          , emit: flags
    tuple val(meta), path("${meta.id}/hybracter/processing")                                     , emit: processing
    tuple val(meta), path("${meta.id}/hybracter/stderr")                                         , emit: stderr
    tuple val(meta), path("${meta.id}/hybracter/supplementary_results")                          , emit: supplementary_results
    tuple val(meta), path("${meta.id}/hybracter/versions")                                       , emit: hybracter_versions
    path "${meta.id}/hybracter/processing/qc/fastp/*.json"                                       , optional: true, emit: fastp_json
    path "${meta.id}/hybracter/versions.yml"                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: '--chromosome 2000000'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cacheDir = task.workDir ? task.workDir.toAbsolutePath().toString() + "/.cache" : "/tmp/.cache"

    """
    export XDG_CACHE_HOME=$cacheDir
    hybracter hybrid-single \\
        -l $longreads \\
        -1 $shortreads_1 \\
        -2 $shortreads_2 \\
        --sample $prefix \\
        --output $prefix/hybracter \\
        --threads $task.cpus \\
        $args

    # Copy *_final.fasta so that both complete and incomplete assemblies can be used for input channel
    if [ -f "${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_final.fasta" ]; then
        cp "${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_final.fasta" "${prefix}/hybracter/FINAL_OUTPUT/${prefix}_final.fasta"
    elif [ -f "${prefix}/hybracter/FINAL_OUTPUT/incomplete/${prefix}_final.fasta" ]; then
        cp "${prefix}/hybracter/FINAL_OUTPUT/incomplete/${prefix}_final.fasta" "${prefix}/hybracter/FINAL_OUTPUT/${prefix}_final.fasta"
    else
        echo "Error! No *_final.fasta found"
    fi

    # Rename hybracter_summary.tsv
    if [ -f "${prefix}/hybracter/FINAL_OUTPUT/hybracter_summary.tsv" ]; then
        mv "${prefix}/hybracter/FINAL_OUTPUT/hybracter_summary.tsv" "${prefix}/hybracter/FINAL_OUTPUT/${prefix}_hybracter_summary.tsv"
    fi


    cat <<-END_VERSIONS > ${prefix}/hybracter/versions.yml
    "${task.process}":
        hybracter: \$(echo \$(hybracter version) 2>&1 | grep hybracter | cut -f'3' -d ' ')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_final.fasta
    touch ${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_plasmid.fasta
    touch ${prefix}/hybracter/versions.yml
    """
}

process HYBRACTER_LONG {
    publishDir "${params.outdir}", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container '/bigdata/Jessin/Softwares/containers/hybracter_0.11.0.sif'

    input:
    tuple val(meta), path(longreads)

    output:
    tuple val(meta), path("${meta.id}/hybracter/FINAL_OUTPUT")                                   , emit: final_output
    tuple val(meta), path("${meta.id}/hybracter/benchmarks")                                     , emit: benchmarks
    tuple val(meta), path("${meta.id}/hybracter/completeness")                                   , emit: completeness
    tuple val(meta), path("${meta.id}/hybracter/flags")                                          , emit: flags
    tuple val(meta), path("${meta.id}/hybracter/processing")                                     , emit: processing
    tuple val(meta), path("${meta.id}/hybracter/stderr")                                         , emit: stderr
    tuple val(meta), path("${meta.id}/hybracter/supplementary_results")                          , emit: supplementary_results
    tuple val(meta), path("${meta.id}/hybracter/versions")                                       , emit: hybracter_versions
    path "${meta.id}/hybracter/processing/qc/fastp/*.json"                                       , optional: true, emit: fastp_json
    path "${meta.id}/hybracter/versions.yml"                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: '--auto'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cacheDir = task.workDir ? task.workDir.toAbsolutePath().toString() + "/.cache" : "/tmp/.cache"

    """
    export XDG_CACHE_HOME=$cacheDir
    hybracter long-single \\
        -l $longreads \\
        --sample $prefix \\
        --output $prefix/hybracter \\
        --threads $task.cpus \\
        $args


    # Copy *_final.fasta so that both complete and incomplete assemblies can be used for input channel
    if [ -f "${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_final.fasta" ]; then
        cp "${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_final.fasta" "${prefix}/hybracter/FINAL_OUTPUT/${prefix}_final.fasta"
    elif [ -f "${prefix}/hybracter/FINAL_OUTPUT/incomplete/${prefix}_final.fasta" ]; then
        cp "${prefix}/hybracter/FINAL_OUTPUT/incomplete/${prefix}_final.fasta" "${prefix}/hybracter/FINAL_OUTPUT/${prefix}_final.fasta"
    else
        echo "Error! No *_final.fasta found"
    fi

    # Rename hybracter_summary.tsv
    if [ -f "${prefix}/hybracter/FINAL_OUTPUT/hybracter_summary.tsv" ]; then
        mv "${prefix}/hybracter/FINAL_OUTPUT/hybracter_summary.tsv" "${prefix}/hybracter/FINAL_OUTPUT/${prefix}_hybracter_summary.tsv"
    fi


    cat <<-END_VERSIONS > ${prefix}/hybracter/versions.yml
    "${task.process}":
        hybracter: \$(echo \$(hybracter version) 2>&1 | grep hybracter | cut -f'3' -d ' ')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_final.fasta
    touch ${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_plasmid.fasta
    touch ${prefix}/hybracter/versions.yml
    """
}
