#!/usr/bin/env nextflow

if (params.help) {
	    log.info"""
	    ==============================================
	    LRGASP CHALLENAGE 3 BENCHMARKING PIPELINE
	    Author(s): Tianyuan Liu
        Genomics of Gene Expression Lab
	    ==============================================
	    Usage:
	    Run the pipeline with default parameters:
	    nextflow run main.nf -profile docker
	    Run with user parameters:
 	    nextflow run main.nf -profile docker --input {FASTA.file} --public_ref_dir {validation.reference.file} --participant_id {species.name} --assess_dir {benchmark.data.dir}  --results_dir {output.dir}
	    Mandatory arguments:
                --input                 FASTA file submitted by the participants
                --community_id          Name or OEB permanent ID for the benchmarking community
                --public_ref_dir        Directory with public reference genome and annotation files
                --participant_id        Name of the pipeline used for benchmarking
                --challenges_ids        list of challenges (performance evaluation methods) which are performed in the benchmark (Num. Isoforms detected/% Mapping to genome/% Multi-exonic isoforms/% Full Illumin support/SIRVs/)
                --assess_dir            directory where the performance metrics for other participants to be compared with the submitted one are found
	    Other options:
                --validation_results    The output directory where the results from validation step will be saved
                --assessment_results    The output directory where the results from the computed metrics step will be saved
                --outdir                The output directory where the consolidation of the benchmark will be saved
                --statsdir              The output directory with nextflow statistics
                --data_model_export_dir The output dir where json file with benchmarking data model contents will be saved
                --otherdir              The output directory where custom results will be saved (no directory inside)
	    Flags:
                --help                  Display this message
	    """

	exit 1
} else {

	log.info """\
         =========================================
         LRGASP CHALLENAGE 3 BENCHMARKING PIPELINE
         =========================================
         input file: ${params.input}
         community id: ${params.community_id}
         gold standard: ${params.goldstandard_dir}
         public reference directory: ${params.public_ref_dir}
         participant id: ${params.participant_id}
         challenges ids: ${params.challenges_ids}
         assess directory: ${params.assess_dir}
         consolidated benchmark results directory: ${params.outdir}
         validation result: ${params.validation_result}
         assessment results: ${params.assessment_results}
         data model export directory: ${params.data_model_export_dir}
         """
}

// input files
input_file = file(params.input)
ref_dir = file(params.public_ref_dir, type: 'dir' )
participant_id = params.participant_id
gold_standards_dir = file(params.goldstandard_dir)
challenges_ids = params.challenges_ids
benchmark_data = Channel.fromPath(params.assess_dir, type: 'dir' )
community_id = params.community_id

// output
validation_file = file(params.validation_result)
assessment_file = file(params.assessment_results)
aggregation_dir = Channel.fromPath(params.outdir, type: 'dir')
augmented_benchmark_data = file(params.data_model_export_dir)

// other
other_dir = file(params.otherdir, type: 'dir' )


process validation {
    tag "Validating input file format"
	publishDir "${validation_file.parent}", saveAs: { filename -> validation_file.name }, mode: 'copy'

    input:
    file input_file
    path ref_dir
    val challenges_ids
    val participant_id
    val community_id

    path gold_standard_dir

    output:
    val task.exitStatus into EXIT_STAT_VAL
    file 'validation.json' into validation_out

    script:
    """
    python /app/validation.py -i $input_file  -com $community_id -c $challenges_ids -p $participant_id -r $ref_dir -o validation.json --coverage $gold_standard_dir
    """
}

process compute_metrics {

	tag "Computing benchmark metrics for submitted data"
    publishDir "${assessment_file.parent}", saveAs: { filename -> assessment_file.name }, mode: 'copy'

    input:
    val file_validated from EXIT_STAT
    file input_file
    val challenges_ids
    path gold_standard_dir
    val participant_id
    val community_id
    path ref_dir

    output:
    val task.exitStatus into EXIT_STAT_COMP
	file 'assessment.json' into assessment_out

    when:
    file_validated == 0

	"""
	source activate sqanti_env
	python /app/sqanti3_lrgasp.challenge3.py $input_file $ref_dir $challenges_ids -c $gold_standard_dir --output assessment.json --com $community_id --participant_id $participant_id
    """
}


process consolidation {
	tag "Performing benchmark assessment and building plots"
	publishDir "${aggregation_dir.parent}", pattern: "aggregation_dir", saveAs: { filename -> aggregation_dir.name }, mode: 'copy'
	publishDir "${data_model_export_dir.parent}", pattern: "data_model_export.json", saveAs: { filename -> data_model_export_dir.name }, mode: 'copy'
	publishDir "${augmented_benchmark_data.parent}", pattern: "augmented_benchmark_data", saveAs: { filename -> augmented_benchmark_data.name }, mode: 'copy'

    input:
	path benchmark_data
	file assessment_out
	file validation_out

    output:
    path 'aggregation_dir', type: 'dir'
	path 'augmented_benchmark_data', type: 'dir'
	path 'data_model_export.json'

    """
    cp -Lpr $benchmark_data augmented_benchmark_data
	python /app/manage_assessment_data.py -b augmented_benchmark_data -p $assessment_out -o aggregation_dir
	python /app/merge_data_model_files.py -p $validation_out -m $assessment_out -a aggregation_dir -o data_model_export.json
    """
}

workflow.onComplete { 
	println ( workflow.success ? "LRGASP challenge 3 benchmarking finished!!!" : "Oops .. something went wrong" )
}

