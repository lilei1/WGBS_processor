process COVERAGE_FILTER {
    tag "$meta.id"
    label 'process_single'
    
    conda "conda-forge::python=3.9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    tuple val(meta), path(coverage)

    output:
    tuple val(meta), path("*.filtered.cov"), emit: filtered
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    #!/usr/bin/env python3
    
    import gzip
    
    def filter_coverage(input_file, output_file, min_cov=${params.min_coverage}):
        opener = gzip.open if input_file.endswith('.gz') else open
        
        with opener(input_file, 'rt') as fin, open(output_file, 'w') as fout:
            for line in fin:
                fields = line.strip().split('\\t')
                if len(fields) >= 6:
                    coverage = int(fields[4]) + int(fields[5])  # methylated + unmethylated
                    if coverage >= min_cov:
                        fout.write(line)
    
    filter_coverage('${coverage}', '${prefix}.filtered.cov')
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}