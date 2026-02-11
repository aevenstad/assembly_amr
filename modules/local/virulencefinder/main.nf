process VIRULENCEFINDER {
    publishDir "${params.outdir}/${meta.id}", mode: 'copy'
    tag "${meta.id}"

    container '/bigdata/Jessin/Softwares/containers/virulencefinder_3.2.0.sif'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("virulencefinder/*.json")     , emit: json
    tuple val(meta), path("virulencefinder/*.tsv")      , emit: tsv
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    python -m virulencefinder \\
    --inputfasta $fasta \\
    --databases virulence_ent,virulence_entfm_entls \\
    --outputPath virulencefinder

    # Rename json output file
    mv virulencefinder/data.json virulencefinder/${prefix}.json

    # Convert json to tsv
    virulencefinder_json2tsv.py virulencefinder/${prefix}.json virulencefinder/${prefix}_virulencefinder.tsv

    {
    echo '\\"${task.process}\\":'
    echo '    VirulenceFinder: '\$(python -m virulencefinder -v)
    } > versions.yml
    """
}
