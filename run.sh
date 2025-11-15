#!/usr/bin/env bash

export NXF_SYNTAX_PARSER=v2
export NXF_CMD="../../nextflow-io/nextflow/launch.sh"

set -x

$NXF_CMD -q run fetchngs -profile test -output-dir results/fetchngs > results/fetchngs/output.json

cat results/fetchngs/output.json | jq

$NXF_CMD -q run rnaseq -profile test --reads results/fetchngs/samples.json -output-dir results/rnaseq > results/rnaseq/output.json

cat results/rnaseq/output.json | jq
