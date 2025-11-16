#!/usr/bin/env nextflow

nextflow.preview.types = true

params {
    // List of SRA/ENA/GEO/DDBJ identifiers to download their associated metadata and FastQ files
    input: List<String>
}

workflow {
    main:
    ids = channel.fromList(params.input)
    samples = SRA(ids)

    publish:
    samples = samples
}

output {

    // List of FASTQ samples with optional MD5 checksums
    samples: Channel<Map> {
        path { sample ->
            sample.fastq_1 >> 'fastq/'
            sample.fastq_2 >> 'fastq/'
            sample.md5_1 >> 'fastq/md5/'
            sample.md5_2 >> 'fastq/md5/'
        }
        index {
            path 'samples-fetchngs.json'
        }
    }
}


workflow SRA {
    take:
    ids: Channel<String>

    emit:
    samples: Channel<Map> = FETCH(ids)
}


process FETCH {
    tag "$id"

    input:
    id: String

    output:
    [
        id      : id,
        fastq_1 : file('*_1.fastq'),
        fastq_2 : file('*_2.fastq'),
        md5_1   : file('*_1.fastq.md5'),
        md5_2   : file('*_2.fastq.md5')
    ]

    topic:
    tuple(task.process, 'aspera_cli', '4.14.0') >> 'versions'

    script:
    """
    echo ascp ${id}_1.fastq
    echo md5sum -c ${id}_1.fastq.md5
    echo ascp ${id}_2.fastq
    echo md5sum -c ${id}_2.fastq.md5

    touch ${id}_1.fastq
    touch ${id}_2.fastq
    touch ${id}_1.fastq.md5
    touch ${id}_2.fastq.md5
    """
}
