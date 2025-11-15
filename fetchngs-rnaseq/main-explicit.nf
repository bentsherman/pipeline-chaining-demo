
params {
    samples: String // List<FastqPair>
    strandedness: String
}

// record FastqPair {
//     id: String
//     fastq_1: Path
//     fastq_2: Path
// }

workflow {
    main:
    samples = file(params.samples)
        .splitJson()
        .collect { sample ->
            sample + [strandedness: params.strandedness]
        }

    publish:
    samples = samples
}

output {
    samples { // List<Sample>
        index { path 'samples.json' }
    }
}

// record Sample {
//     sample: String
//     fastq_1: Path
//     fastq_2: Path
//     strandedness: String
// }
