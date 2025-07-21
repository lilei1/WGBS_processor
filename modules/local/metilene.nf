process METILENE {
    tag "$condition"
    label 'process_medium'
    
    conda "bioconda::metilene=0.2.8"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metilene:0.2.8--h516909a_0' :
        'quay.io/biocontainers/metilene:0.2.8--h516909a_0' }"

    input:
    tuple val(condition), path(coverage_files)

    output:
    tuple val(condition), path("*.dmr.txt"), emit: dmr
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${condition}"
    def min_cpgs = params.metilene_min_cpgs ?: 10
    def max_dist = params.metilene_max_dist ?: 300
    
    """
    # Prepare input for metilene
    metilene_input.pl --in1 ${coverage_files[0]} --in2 ${coverage_files[1]} --out metilene_input.txt
    
    # Run metilene
    metilene \\
        $args \\
        -a ${condition}_group1 \\
        -b ${condition}_group2 \\
        -d $max_dist \\
        -c $min_cpgs \\
        metilene_input.txt > ${prefix}.dmr.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metilene: \$(metilene --version 2>&1 | head -n1 | sed 's/metilene version //')
    END_VERSIONS
    """
}