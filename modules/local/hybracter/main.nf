process HYBRACTER {
    publishDir "${params.outdir}/hybracter/${meta.id}", mode: 'copy'
    containerOptions "-B ${params.hybracter_config}"
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container '/bigdata/Jessin/Softwares/containers/hybracter_0.11.0.sif'

    input:
    tuple val(meta), path(longreads), path(shortreads_1), path(shortreads_2)

    output:
    tuple val(meta), path("FINAL_OUTPUT")                                   , emit: final_output
    tuple val(meta), path("benchmarks")                                     , emit: benchmarks
    tuple val(meta), path("completeness")                                   , emit: completeness
    tuple val(meta), path("flags")                                          , emit: flags
    tuple val(meta), path("processing")                                     , emit: processing
    tuple val(meta), path("stderr")                                         , emit: stderr
    tuple val(meta), path("supplementary_results")                          , emit: supplementary_results
    tuple val(meta), path("versions")                                       , emit: hybracter_versions 
    path "processing/qc/fastp/*.json"                                       , emit: fastp_json
    path "versions.yml"                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: '--auto'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def config = task.ext.config ?: "${params.hybracter_config}"
    def cacheDir = task.workDir ? task.workDir.toAbsolutePath().toString() + "/.cache" : "/tmp/.cache"

    """
    export XDG_CACHE_HOME=$cacheDir
    hybracter hybrid-single \\
        -l $longreads \\
        -1 $shortreads_1 \\
        -2 $shortreads_2 \\
        --sample $prefix \\
        --output ./ \\
        --configfile $config \\
        --threads $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hybracter: \$(echo \$(hybracter version) 2>&1 | grep hybracter | cut -f'3' -d ' ')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch FINAL_OUTPUT/complete/${prefix}_final.fasta
    touch FINAL_OUTPUT/complete/${prefix}_plasmid.fasta
    touch versions.yml
    """
}