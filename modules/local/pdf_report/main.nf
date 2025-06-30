process WRITE_PDF_REPORT {
    publishDir "pdf_report", mode: 'copy'
    tag "$meta_id"
    label 'process_medium'

    container '/bigdata/Jessin/Softwares/containers/pdf_report.sif'

    input: 
    tuple val(meta_id), path(quast), path(bbmap), path(mlst), path(rmlst), path(kleborate), path(amrfinder), path(plasmidfinder), path(lrefinder)
    path(versions)
    path(genome_size)
    path(kleborate_columns)
    
    output:
    tuple val(meta_id), path("${meta_id}.pdf")  , emit: pdf_report
    // tuple val(meta), path("${meta.id}.tex") , emit: tex

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta_id}"

    """
    echo "prefix: ${prefix}"
    echo "quast: ${quast}"
    echo "bbmap: ${bbmap}"
    echo "mlst: ${mlst}"
    echo "rmlst: ${rmlst}"
    echo "kleborate: ${kleborate}"
    echo "amrfinder: ${amrfinder}"
    echo "plasmidfinder: ${plasmidfinder}"
    echo "lrefinder: ${lrefinder}"
    echo "genome_size: ${genome_size}"
    echo "kleborate_columns: ${kleborate_columns}"
    echo "versions: ${versions}"
    """
}