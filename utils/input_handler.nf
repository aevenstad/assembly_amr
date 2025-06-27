def handleInput(samplesheet) {
    if (params.from_fasta) {
        // Handle FASTA input
        def ch_final_fasta = samplesheet.map { row ->
            tuple([id: row.sample], file(row.fasta))
        }
        def ch_trimmed = Channel.empty()
        return [ch_final_fasta, ch_trimmed]
    } else if (params.assembly_type == 'short') {
        // Handle short-read assembly
        SHORTREAD_ASSEMBLY(samplesheet)
        def ch_final_fasta = SHORTREAD_ASSEMBLY.out.ch_final_fasta
        def ch_trimmed = SHORTREAD_ASSEMBLY.out.ch_shortread_trimmed
        return [ch_final_fasta, ch_trimmed]
    } else if (params.assembly_type == 'hybrid' || params.assembly_type == 'long') {
        // Handle long-read or hybrid assembly
        LONGREAD_ASSEMBLY(samplesheet)
        def ch_final_fasta = LONGREAD_ASSEMBLY.out.ch_final_fasta
        def ch_trimmed = params.assembly_type == 'long' ?
            LONGREAD_ASSEMBLY.out.ch_trimmed_longreads :
            LONGREAD_ASSEMBLY.out.ch_trimmed_shortreads
        return [ch_final_fasta, ch_trimmed]
    } else {
        error "Invalid assembly type: ${params.assembly_type}"
    }
}