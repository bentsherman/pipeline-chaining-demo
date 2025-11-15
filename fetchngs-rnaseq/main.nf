
samples = file(params.samples)
    .splitJson()
    .collect { sample ->
        sample + [strandedness: params.strandedness]
    }
