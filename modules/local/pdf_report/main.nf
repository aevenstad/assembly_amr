process WRITE_PDF_REPORT {
    publishDir "${params.outdir}/pdf_report", mode: 'copy'
    tag "$meta_id"
    label 'process_medium'

    container 'docker://andreeve867/pdf_report:latest'

    input:
    tuple val(meta_id),
        path(quast),
        path(bbmap),
        path(mlst),
        path(rmlst),
        path(kleborate),
        path(amrfinder),
        path(plasmidfinder),
        path(lrefinder),
        path(genome_size),
        path(kleborate_columns),
        path(rscript),
        path(versions),
        path(kres_logo)
    output:
    tuple val(meta_id), path("${meta_id}_report.pdf")  , emit: pdf
    // tuple val(meta), path("${meta.id}.tex") , emit: tex

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta_id}"


    """
    Rscript -e "rmarkdown::render(input = '${rscript}', output_file='${meta_id}_report.pdf', params=list(
        sample_id='${prefix}',
        quast_out='${quast}',
        bbmap_out='${bbmap}',
        mlst_out='${mlst}',
        rmlst_out='${rmlst}',
        kleborate_out='${kleborate}',
        amrfinder_out='${amrfinder}',
        plasmidfinder_out='${plasmidfinder}',
        lrefinder_out='${lrefinder}',
        genome_size='${genome_size}',
        kleborate_columns='${kleborate_columns}',
        versions='${versions}',
        kres_logo='${kres_logo}'
        ))"
    """
}
