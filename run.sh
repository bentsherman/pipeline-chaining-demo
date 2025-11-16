#!/usr/bin/env bash

export NXF_SYNTAX_PARSER=v2
export NXF_CMD="../../nextflow-io/nextflow/launch.sh"

set -ex

$NXF_CMD -q run fetchngs -profile test \
    | tee results/output-fetchngs.json | jq

cat results/output-fetchngs.json \
    | $NXF_CMD -q run fetchngs-rnaseq --strandedness auto \
    | tee results/output-fetchngs-rnaseq.json | jq

cat results/output-fetchngs-rnaseq.json \
    | $NXF_CMD -q run rnaseq -profile test \
    | tee results/output-rnaseq.json | jq
