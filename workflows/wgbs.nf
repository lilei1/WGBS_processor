/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { WorkflowWgbs } from '../lib/WorkflowWgbs.groovy'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Simple parameter validation without NfcoreSchema
def summary_params = [:]
summary_params.input = params.input
summary_params.outdir = params.outdir
summary_params.genome = params.genome

// Validate input parameters
WorkflowWgbs.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true )   : Channel.empty()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { FASTQC                     } from '../modules/nf-core/fastqc/main'
include { TRIMGALORE                 } from '../modules/nf-core/trimgalore/main'
include { BISMARK_ALIGN              } from '../modules/nf-core/bismark/align/main'
include { BISMARK_DEDUPLICATE        } from '../modules/nf-core/bismark/deduplicate/main'
include { BISMARK_METHYLATIONEXTRACTOR } from '../modules/nf-core/bismark/methylationextractor/main'
include { MULTIQC                    } from '../modules/nf-core/multiqc/main'

//
// MODULE: Local modules
//
include { COVERAGE_FILTER } from '../modules/local/coverage_filter'
include { METILENE        } from '../modules/local/metilene'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow WGBS {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // MODULE: Run Trim Galore
    //
    if (!params.skip_trimming) {
        TRIMGALORE (
            INPUT_CHECK.out.reads
        )
        ch_trimmed_reads = TRIMGALORE.out.reads
        ch_versions = ch_versions.mix(TRIMGALORE.out.versions.first())
    } else {
        ch_trimmed_reads = INPUT_CHECK.out.reads
    }

    //
    // MODULE: Run Bismark alignment
    //
    BISMARK_ALIGN (
        ch_trimmed_reads
    )
    ch_versions = ch_versions.mix(BISMARK_ALIGN.out.versions.first())

    //
    // MODULE: Run Bismark deduplication
    //
    if (!params.skip_deduplication) {
        BISMARK_DEDUPLICATE (
            BISMARK_ALIGN.out.bam
        )
        ch_bam = BISMARK_DEDUPLICATE.out.bam
        ch_versions = ch_versions.mix(BISMARK_DEDUPLICATE.out.versions.first())
    } else {
        ch_bam = BISMARK_ALIGN.out.bam
    }

    //
    // MODULE: Run Bismark methylation extractor
    //
    BISMARK_METHYLATIONEXTRACTOR (
        ch_bam
    )
    ch_versions = ch_versions.mix(BISMARK_METHYLATIONEXTRACTOR.out.versions.first())

    //
    // MODULE: Filter coverage files
    //
    COVERAGE_FILTER (
        BISMARK_METHYLATIONEXTRACTOR.out.coverage
    )
    ch_versions = ch_versions.mix(COVERAGE_FILTER.out.versions.first())

    //
    // MODULE: Run metilene for DMR detection
    //
    ch_metilene_input = COVERAGE_FILTER.out.filtered
        .map { meta, cov -> [meta.condition, cov] }
        .groupTuple()
        .filter { condition, files -> files.size() >= 2 }

    METILENE (
        ch_metilene_input
    )
    ch_versions = ch_versions.mix(METILENE.out.versions.first())

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowWgbs.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowWgbs.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
    
    if (!params.skip_trimming) {
        ch_multiqc_files = ch_multiqc_files.mix(TRIMGALORE.out.log.collect{it[1]}.ifEmpty([]))
    }
    
    ch_multiqc_files = ch_multiqc_files.mix(BISMARK_ALIGN.out.report.collect{it[1]}.ifEmpty([]))
    
    if (!params.skip_deduplication) {
        ch_multiqc_files = ch_multiqc_files.mix(BISMARK_DEDUPLICATE.out.report.collect{it[1]}.ifEmpty([]))
    }
    
    ch_multiqc_files = ch_multiqc_files.mix(BISMARK_METHYLATIONEXTRACTOR.out.report.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_versions.unique().collectFile(name: 'collated_versions.yml'))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}
