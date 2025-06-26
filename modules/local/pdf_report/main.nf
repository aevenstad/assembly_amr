process WRITE_PDF_REPORT {
    publishDir "/pdf_report", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'

    container /bigdata/Jessin/Softwares/containers/pdf_report_0.1.0.sif

    input: val(meta), path(quast_out), path(bbmap_out), path(mlst_out), path(rmlst_out), path(kleborate_out), path(amrfinder_out), path(plasmidfinder_out), path(lrefinder_out)
    path "assets/genome_size.csv"
    path "assets/kleborate_columns.txt"
    path (sw_versions)
    path (db_versions)

    output:
    tuple val(meta), path("${meta.id}.pdf")  , emit: pdf_report
    // tuple val(meta), path("${meta.id}.tex") , emit: tex

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''
    
    """
    Rscript -e "rmarkdown::render\('pdf_report.Rmd', 
        output_file = '${prefix}.pdf', 
        params = list(
            prefix = '${prefix}',
            quast_out = '${quast_out}',
            bbmap_out = '${bbmap_out}',
            mlst_out = '${mlst_out}',
            rmlst_out = '${rmlst_out}',
            kleborate_out = '${kleborate_out}',
            amrfinder_out = '${amrfinder_out}',
            plasmidfinder_out = '${plasmidfinder_out}',
            lrefinder_out = '${lrefinder_out}',
            genome_size_csv = 'assets/genome_size.csv',
            kleborate_columns_txt = 'assets/kleborate_columns.txt',
            sw_versions = ${sw_versions},
            db_versions = ${db_versions}
        ))"
    """
}