//
// This file holds several functions specific to the workflows/wgbs.nf workflow
//

import nextflow.Nextflow

class WorkflowWgbs {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
        if (!params.input) {
            Nextflow.error("Please provide an input samplesheet to the pipeline e.g. '--input samplesheet.csv'")
        }
    }

    //
    // Generate methods description for MultiQC
    //
    public static String methodsDescriptionText(workflow, mqc_methods_description) {
        def meta = [:]
        meta.workflow = workflow
        def methods_text = """
        ## Methods

        Data was processed using ${workflow.manifest.name} v${workflow.manifest.version}.

        """
        return methods_text
    }

    //
    // Generate workflow summary for MultiQC
    //
    public static String paramsSummaryMultiqc(workflow, summary_params) {
        def summary_section = ''
        def yaml_file_text  = "id: '${workflow.manifest.name.replace('/','-')}-summary'\n"
        yaml_file_text     += "description: ' - this information is collected when the pipeline is started.'\n"
        yaml_file_text     += "section_name: '${workflow.manifest.name} Workflow Summary'\n"
        yaml_file_text     += "section_href: 'https://github.com/${workflow.manifest.name}'\n"
        yaml_file_text     += "plot_type: 'html'\n"
        yaml_file_text     += "data: |\n"
        yaml_file_text     += "    <dl class=\"dl-horizontal\">\n"
        
        for (group in summary_params.keySet()) {
            yaml_file_text += "        <dt>${group}</dt><dd><samp>${summary_params.get(group) ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>\n"
        }
        yaml_file_text += "    </dl>\n"

        return yaml_file_text
    }
}