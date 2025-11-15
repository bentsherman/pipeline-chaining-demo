#!/usr/bin/env nextflow

nextflow.preview.types = true

params {
    // The input read-pair files
    reads: List<Map>

    // The input transcriptome file
    transcriptome: Path

    // Directory containing multiqc configuration
    multiqc: Path = "${projectDir}/multiqc"
}

workflow {
    main:
    log.info """\
        R N A S E Q - N F   P I P E L I N E
        ===================================
        transcriptome: ${params.transcriptome}
        reads        : ${params.reads*.id}
        outdir       : ${workflow.outputDir}
    """.stripIndent()

    read_pairs_ch = channel.fromList(params.reads)
        .map { row ->
            tuple(row.id, file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true))
        }

    (samples_ch, index) = RNASEQ( read_pairs_ch, params.transcriptome )

    multiqc_files_ch = samples_ch
        .flatMap { _id, fastqc, quant -> [fastqc, quant] }
        .collect()

    multiqc_report = MULTIQC( multiqc_files_ch, params.multiqc )

    versions_ch = channel.topic('versions')
        .map { entry -> entry as Tuple<String,String,String> }
        .reduce([:]) { acc, entry ->
            def (process, name, version) = entry
            acc[process.tokenize(':').last()] = [
                (name): version
            ]
            return acc
        }

    publish:
    samples = samples_ch.map { id, fastqc, quant -> [id: id, fastqc: fastqc, quant: quant] }
    index = index
    multiqc_report = multiqc_report
    versions = versions_ch

    onComplete:
    log.info(
        workflow.success
            ? "\nDone! Open the following report in your browser --> ${workflow.outputDir}/multiqc_report.html\n"
            : "Oops .. something went wrong"
    )
}

output {
    samples: Channel<Map> {
        path { sample ->
            sample.fastqc >> "fastqc/${sample.id}"
            sample.quant >> "quant/${sample.id}"
        }
        index {
            path 'samples.json'
        }
    }

    index: Path {
        path '.'
    }

    multiqc_report: Path {
        path '.'
    }

    versions: Map<String,Map> {
        path '.'
        index {
            path 'versions.yml'
        }
    }
}


workflow RNASEQ {
    take:
    reads_ch        : Channel<Tuple<String,Path,Path>>
    transcriptome   : Path

    main:
    index = INDEX(transcriptome)            // Value<Path>
    fastqc_ch = FASTQC(reads_ch)            // Channel<Tuple<String,Path>>
    quant_ch = QUANT(reads_ch, index)       // Channel<Tuple<String,Path>>
    samples_ch = fastqc_ch.join(quant_ch)   // Channel<Tuple<String,Path,Path>>

    emit:
    samples : Channel<Tuple<String,Path,Path>> = samples_ch
    index   : Value<Path> = index
}


process FASTQC {
    tag "$id"

    input:
    (id, fastq_1, fastq_2): Tuple<String, Path, Path>

    output:
    tuple(id, file("fastqc_${id}_logs"))

    topic:
    tuple("${task.process}", 'fastqc', '0.12.1') >> 'versions'

    script:
    """
    echo fastqc.sh "${id}" "${fastq_1} ${fastq_2}"
    mkdir fastqc_${id}_logs
    """
}


process INDEX {
    tag "${transcriptome.simpleName}"

    input:
    transcriptome: Path

    output:
    file('index')

    topic:
    tuple("${task.process}", 'salmon', '1.10.3') >> 'versions'

    script:
    """
    echo salmon index --threads ${task.cpus} -t ${transcriptome} -i index
    touch index
    """
}


process MULTIQC {

    input:
    _logs   : Bag<Path>
    config  : Path

    output:
    file('multiqc_report.html')

    topic:
    tuple("${task.process}", 'multiqc', '1.27.1') >> 'versions'

    script:
    """
    echo cp ${config}/* .
    echo "custom_logo: \$PWD/nextflow_logo.png" >> multiqc_config.yaml
    echo multiqc -n multiqc_report.html .
    touch multiqc_report.html
    """
}


process QUANT {
    tag "$id"

    input:
    (id, fastq_1, fastq_2): Tuple<String, Path, Path>
    index: Path

    output:
    tuple(id, file("quant_${id}"))

    topic:
    tuple("${task.process}", 'salmon', '1.10.3') >> 'versions'

    script:
    """
    echo salmon quant --threads ${task.cpus} --libType=U -i ${index} -1 ${fastq_1} -2 ${fastq_2} -o quant_${id}
    mkdir quant_${id}
    """
}
