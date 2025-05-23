process QUAST {
    publishDir "${params.outdir}", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/quast:5.2.0--py39pl5321heaaa4ec_4' :
        'biocontainers/quast:5.2.0--py39pl5321heaaa4ec_4' }"

    input:
    tuple val(meta), path(fasta)

    output:
    path "${meta.id}/quast/*", emit: results
    tuple val(meta), path("${meta.id}/quast/report.tsv"), emit: tsv
    tuple val(meta), path("${meta.id}/quast/contigs_reports/all_alignments_transcriptome.tsv"), optional: true, emit: transcriptome
    tuple val(meta), path("${meta.id}/quast/contigs_reports/misassemblies_report.tsv"), optional: true, emit: misassemblies
    tuple val(meta), path("${meta.id}/quast/contigs_reports/unaligned_report.tsv"), optional: true, emit: unaligned
    path "${meta.id}/quast/versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args   ?: ''
    prefix        = task.ext.prefix ?: "${meta.id}"
    def assembly = fasta           ?  "$fasta"       : ''
    """
    quast.py \\
        --output-dir ${prefix}/quast \\
        $assembly \\
        --threads $task.cpus \\
        $args

    ln -s ${prefix}/quast/report.tsv ${prefix}.tsv
    [ -f ${prefix}/quast/contigs_reports/all_alignments_transcriptome.tsv ] && ln -s 4_quast/contigs_reports/all_alignments_transcriptome.tsv ${prefix}_transcriptome.tsv
    [ -f ${prefix}/quast/contigs_reports/misassemblies_report.tsv ] && ln -s 4_quast/contigs_reports/misassemblies_report.tsv ${prefix}_misassemblies.tsv
    [ -f ${prefix}/quast/contigs_reports/unaligned_report.tsv ] && ln -s 4_quast/contigs_reports/unaligned_report.tsv ${prefix}_unaligned.tsv

    cat <<-END_VERSIONS > ${prefix}/quast/versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/^.*QUAST v//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def _args      = task.ext.args   ?: ''
    prefix        = task.ext.prefix ?: "${meta.id}"
    def _assembly = fasta           ? "$fasta" : ''

    """
    mkdir -p $prefix
    touch $prefix/report.tsv
    touch $prefix/report.html
    touch $prefix/report.pdf
    touch $prefix/quast.log
    touch $prefix/transposed_report.txt
    touch $prefix/transposed_report.tex
    touch $prefix/icarus.html
    touch $prefix/report.tex
    touch $prefix/report.txt

    mkdir -p $prefix/basic_stats
    touch $prefix/basic_stats/cumulative_plot.pdf
    touch $prefix/basic_stats/Nx_plot.pdf
    touch $prefix/basic_stats/genome_GC_content_plot.pdf
    touch $prefix/basic_stats/GC_content_plot.pdf

    mkdir -p $prefix/icarus_viewers
    touch $prefix/icarus_viewers/contig_size_viewer.html

    ln -s $prefix/report.tsv ${prefix}.tsv

    if [ $fasta ]; then
        touch $prefix/basic_stats/NGx_plot.pdf
        touch $prefix/basic_stats/gc.icarus.txt

        mkdir -p $prefix/aligned_stats
        touch $prefix/aligned_stats/NAx_plot.pdf
        touch $prefix/aligned_stats/NGAx_plot.pdf
        touch $prefix/aligned_stats/cumulative_plot.pdf

        mkdir -p $prefix/contigs_reports
        touch $prefix/contigs_reports/all_alignments_transcriptome.tsv
        touch $prefix/contigs_reports/contigs_report_transcriptome.mis_contigs.info
        touch $prefix/contigs_reports/contigs_report_transcriptome.stderr
        touch $prefix/contigs_reports/contigs_report_transcriptome.stdout
        touch $prefix/contigs_reports/contigs_report_transcriptome.unaligned.info
        mkdir -p $prefix/contigs_reports/minimap_output
        touch $prefix/contigs_reports/minimap_output/transcriptome.coords
        touch $prefix/contigs_reports/minimap_output/transcriptome.coords.filtered
        touch $prefix/contigs_reports/minimap_output/transcriptome.coords_tmp
        touch $prefix/contigs_reports/minimap_output/transcriptome.sf
        touch $prefix/contigs_reports/minimap_output/transcriptome.unaligned
        touch $prefix/contigs_reports/minimap_output/transcriptome.used_snps
        touch $prefix/contigs_reports/misassemblies_frcurve_plot.pdf
        touch $prefix/contigs_reports/misassemblies_plot.pdf
        touch $prefix/contigs_reports/misassemblies_report.tex
        touch $prefix/contigs_reports/misassemblies_report.tsv
        touch $prefix/contigs_reports/misassemblies_report.txt
        touch $prefix/contigs_reports/transcriptome.mis_contigs.fa
        touch $prefix/contigs_reports/transposed_report_misassemblies.tex
        touch $prefix/contigs_reports/transposed_report_misassemblies.tsv
        touch $prefix/contigs_reports/transposed_report_misassemblies.txt
        touch $prefix/contigs_reports/unaligned_report.tex
        touch $prefix/contigs_reports/unaligned_report.tsv
        touch $prefix/contigs_reports/unaligned_report.txt

        mkdir -p $prefix/genome_stats
        touch $prefix/genome_stats/genome_info.txt
        touch $prefix/genome_stats/transcriptome_gaps.txt
        touch $prefix/icarus_viewers/alignment_viewer.html

        ln -sf ${prefix}/contigs_reports/misassemblies_report.tsv ${prefix}_misassemblies.tsv
        ln -sf ${prefix}/contigs_reports/unaligned_report.tsv ${prefix}_unaligned.tsv
        ln -sf ${prefix}/contigs_reports/all_alignments_transcriptome.tsv ${prefix}_transcriptome.tsv

    fi

    if ([ $fasta ] && [ $gff ]); then
        touch $prefix/genome_stats/features_cumulative_plot.pdf
        touch $prefix/genome_stats/features_frcurve_plot.pdf
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/^.*QUAST v//; s/ .*\$//')
    END_VERSIONS
    """
}
