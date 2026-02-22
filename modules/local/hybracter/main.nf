process HYBRACTER {
    publishDir "${params.outdir}", mode: 'copy'
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container '/bigdata/Jessin/Softwares/containers/hybracter_0.11.0.sif'

    input:
    tuple val(meta),
        path(longreads),
        path(shortreads_1),
        path(shortreads_2),
        path(minchromsize)

    output:
    tuple val(meta), path("${meta.id}/hybracter/FINAL_OUTPUT"), emit: final_output
    tuple val(meta), path("${meta.id}/hybracter/processing"),   emit: processing
    tuple val(meta), path("${meta.id}/hybracter/versions"),     emit: hybracter_versions
    path "${meta.id}/hybracter/processing/qc/fastp/*.json",     optional: true, emit: fastp_json
    path "${meta.id}/hybracter/versions.yml",                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: '--subsample_depth 250'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cacheDir = task.workDir
        ? task.workDir.toAbsolutePath().toString() + "/.cache"
        : "/tmp/.cache"

    """
    # Use minimum chromosome limit if genus is in table
    min_chrom_size=\$(cat $minchromsize)

    chromosome_size=""
    extra_params_flye=""

    if [[ "\$min_chrom_size" == "NA" ]]; then
        chromosome_size="--auto"
        extra_params_flye=""
        genome_size=""
        asm_coverage=""
    else
        chromosome_size="-c \$min_chrom_size"
        extra_params_flye="--extra_params_flye "
        genome_size="--genome-size \$min_chrom_size"
        asm_coverage=" --asm-coverage 50"
    fi

    username=\$(whoami)
    export XDG_CACHE_HOME=${cacheDir}_\${username}

    # Decide hybracter mode
    if [[ -f "${shortreads_1}" && -f "${shortreads_2}" ]]; then

        hybracter hybrid-single \\
            -l ${longreads} \\
            -1 ${shortreads_1} \\
            -2 ${shortreads_2} \\
            --sample ${prefix} \\
            --output ${prefix}/hybracter \\
            --threads ${task.cpus} \\
            \${chromosome_size} \\
            \${extra_params_flye}\"\${genome_size}\${asm_coverage}\" \\
            ${args}

    else

        hybracter long-single \\
            -l ${longreads} \\
            --sample ${prefix} \\
            --output ${prefix}/hybracter \\
            --threads ${task.cpus} \\
            \${chromosome_size} \\
            \${extra_params_flye} \\
            ${args}
    fi

    # Normalize final fasta location
    if [ -f "${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_final.fasta" ]; then
        cp "${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_final.fasta" \
           "${prefix}/hybracter/FINAL_OUTPUT/${prefix}_final.fasta"
    elif [ -f "${prefix}/hybracter/FINAL_OUTPUT/incomplete/${prefix}_final.fasta" ]; then
        cp "${prefix}/hybracter/FINAL_OUTPUT/incomplete/${prefix}_final.fasta" \
           "${prefix}/hybracter/FINAL_OUTPUT/${prefix}_final.fasta"
    else
        echo "ERROR: No *_final.fasta found" >&2
        exit 1
    fi

    # Rename summary
    if [ -f "${prefix}/hybracter/FINAL_OUTPUT/hybracter_summary.tsv" ]; then
        mv "${prefix}/hybracter/FINAL_OUTPUT/hybracter_summary.tsv" \
           "${prefix}/hybracter/FINAL_OUTPUT/${prefix}_hybracter_summary.tsv"
    fi

    # Rename Plassembler summary
    if [ -f "${prefix}/hybracter/processing/plassembler/${prefix}/plassembler_summary.tsv" ]; then
        mv "${prefix}/hybracter/processing/plassembler/${prefix}/plassembler_summary.tsv" \
            "${prefix}/hybracter/processing/plassembler/${prefix}/${prefix}_plassembler_summary.tsv"
    fi

    # Versions
    cat <<-END_VERSIONS > ${prefix}/hybracter/versions.yml
    "${task.process}":
        hybracter: \$(hybracter version 2>&1 | grep hybracter | cut -f3 -d' ')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: meta.id
    """
    mkdir -p ${prefix}/hybracter/FINAL_OUTPUT/complete
    touch ${prefix}/hybracter/FINAL_OUTPUT/complete/${prefix}_final.fasta
    touch ${prefix}/hybracter/versions.yml
    """
}
