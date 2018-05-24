#!/usr/bin/env nextflow

//  nextflow -c test_OAR.nf_config run test_OAR.nf --fastq2bam 0 --sampleID test_OAR --genomeID Homo_sapiens.GRCh37.dna.fasta -resume
// nextflow-0.29.0-RC1-all -c test_OAR.nf_config run test_OAR.nf --fastq2bam 0 --sampleID test_OAR --genomeID Homo_sapiens.GRCh37.dna.fasta -resume

if (params.fastq2bam == 0 && !params.help) {

	log.info ''
	log.info 'A U R E X O M E ~ MODE FASTQ2BAM'
	log.info ''



	 Channel
		.fromFilePairs("${params.resultDir}/bcl2fastq/*_{R1,R2}*.fastq.gz")
		.filter { it[0] != "Undetermined_S0_L001" }
		.filter { it[0] != "Undetermined_S0_L002" }
		.set {fastq_pairs_ch}


 process fastq2sortedbam {
	 	errorStrategy 'finish'
		echo true


		input:
		set pair_id, file(reads) from fastq_pairs_ch

		output:
		set val(sample_name), file("${bam_name}.bam") into bwa_mem_ch
		stdout fastq2sortedbamout

		shell:
		bam_name=pair_id+'_bwa'
		lastIndexOf = pair_id.lastIndexOf("_")
		sample_name = pair_id.substring(0, lastIndexOf)

		log.info ""
		log.info "bwa : mapping $pair_id"
		log.info ""

		'''
		!{params.binDir}/bwa mem !{params.genomeRef} !{reads} -B 4 -O 6 -E 1 -M | !{params.binDir}/samtools sort -O BAM -l 9 -T tmp_sort - | !{params.binDir}/samtools view -h -b -o !{bam_name}.bam -
		'''


	}

	fastq2sortedbamout.subscribe { print "$it" }

  //
	// /* group tuple
	//  * We create a new channel bam_list_group with bam files grouped by pair_id
	//  */
	// bwa_mem_ch
	// 	.groupTuple(size: params.nLane)
	// 	.set { bam_group_ch }
  //
  //
  //
	// process merge_bam {
	// 	errorStrategy 'finish'
	// 	publishDir "${params.resultDir}/bam/${sample_name}", mode: "copy", pattern: "*.flagstat"
	// 	maxForks params.maxJob
	// 	cpus params.nCpu
  //
	// 	input:
	// 	set val(sample_name), file(input_bams) from bam_group_ch
  //
	// 	output:
	// 	set val(sample_name), val(output_name), file("${output_name}.bam"), file("${output_name}.bai") into samtools_merge_ch
	// 	stdout merge_bamout
  //
  //
	// 	script:
	// 	output_name=sample_name+'_bwa_merged'
  //
	// 	outdir="${params.resultDir}/bam/${sample_name}"
	// 	result_Dir=file(outdir)
	// 	myDir = result_Dir.mkdir()
	// 	println myDir ? "Directory \"$outdir\" created successfully" : "Cannot create directory or already exist: \"$outdir\""
  //
	// 	log.info ""
	// 	log.info "samtools merge $sample_name"
	// 	log.info ""
  //
	// 	"""
	// 	samtools merge -@ ${task.cpus} ${output_name}.bam ${input_bams}
	// 	samtools index ${output_name}.bam ${output_name}.bai
	// 	samtools flagstat ${output_name}.bam > ${output_name}.flagstat
	// 	"""
	// }
  //
	// merge_bamout.subscribe { print "$it" }
  //
	// log.info ''
	// log.info 'CHECK GATK INDEX'
	// log.info ''
  //
  //
	// indexdict = params.refDir + "/" + params.genomeID - matcher[0][1] + "dict"
	// indexbit = params.refDir + "/" + params.genomeID - matcher[0][1] + "2bit"
  //
	// gatkcheck1 = file(indexdict)
	// gatkcheck2 = file(indexbit)
  //
	// genome = file(params.genomeRef)
	// genome_name = genome.name.take(genome.name.lastIndexOf('.'))
  //
  //
	// process mark_duplicates {
	// 	  errorStrategy 'finish'
  //
	// 	  // maxForks params.maxJob
	// 	  // cpus params.nCpu
  //
	// 		input:
	// 		set val(sample_name), val(input_name), file(input_bam), file(input_bam_index) from samtools_merge_ch
  //
	// 		output:
	// 		set val(sample_name), val(output_name), file("${output_name}.bam"), file("${output_name}.bai") into picard_md_ch
	// 		set val(sample_name), file("${output_name}.bam"), file("${output_name}.bai") into picard_md_bqsr2_ch
	// 		stdout mark_duplicatesout
  //
	// 		shell:
	// 		output_name=input_name+'_MD'
	// 		outdir="${params.resultDir}/bam/${sample_name}"
	// 		log.info ""
	// 		log.info "GATK MarkDuplicates ${input_bam}"
	// 		log.info ""
  //
	// 		"""
	// 		gatk-launch MarkDuplicates -I ${input_bam} -O ${output_name}.bam -M ${output_name}.metric --CREATE_INDEX true
	// 		"""
	// 	}
  //
	// 	mark_duplicatesout.subscribe { print "$it" }
  //
  //
	// 	process bqsr1 {
	//     errorStrategy 'finish'
	// 		echo true
	// 		// maxForks params.maxJob
	// 		// cpus params.nCpu
  //
	// 		input:
	// 		set val(sample_name), val(input_name), file(input_bam), file(input_bam_index) from picard_md_ch
  //
	// 		output:
	// 		set val(sample_name), val(output_name), file("${output_name}.bam"), file("${output_name}.bai") into gatk_bqsr1_bam_ch
	// 		set val(sample_name), val(input_name), file("${output_name}-recalibration_report.grp") into gatk_bqsr1_report_ch
	// 		stdout bqsr1out
  //
  //
	// 		shell:
	// 		output_name=input_name+'_BQSR'
	// 		outdir="${params.resultDir}/bam/${sample_name}"
	// 		log.info ""
	// 		log.info "GATK BaseRecalibrator 1 ${input_bam}"
	// 		log.info ""
  //
	// 		"""
	//     echo "BASE QUALITY RECALIBRATOR - 1/5: RECAL REPORT 1 ${input_bam}"
	// 		gatk-launch BaseRecalibrator -R ${params.genomeRef} -I ${input_bam} --known-sites ${params.dbsnpAll} -L ${params.targetBed} -O ${output_name}-recalibration_report.grp
  //
  //
	//     echo "BASE QUALITY RECALIBRATOR - 2/5: RECAL BASE 1 ${input_bam}"
	// 		gatk-launch ApplyBQSR -R ${params.genomeRef} -I ${input_bam} --bqsr-recal-file ${output_name}-recalibration_report.grp -O ${output_name}.bam
  //
  //
	// 		samtools index -@ ${task.cpus} ${output_name}.bam
	// 		mv ${output_name}.bam.bai ${output_name}.bai
	// 		"""
	// 	}
	// 	bqsr1out.subscribe { print "$it" }
  //
  //
	// 	process bqsr2 {
	//     errorStrategy 'finish'
	// 		echo true
	// 		// maxForks params.maxJob
	// 		// cpus params.nCpu
  //
	// 		input:
	// 		set val(sample_name), val(input_name), file(input_report) from gatk_bqsr1_report_ch
	// 		set val(sample_name), file(input_bam), file(input_bam) from gatk_bqsr1_bam_ch
  //
	// 		output:
	// 		file("${output_name}2.bam") into gatk_bqsr2_bam
	// 		file("${output_name}2.bam") into cnvcall_bam
  //
	// 		stdout bqsr2out
  //
	// 	    // afterScript 'cat .command.log > gatk_bqsr2.log; cat .command.err > gatk_bqsr2.err'
  //
	// 		script:
	// 		output_name=input_name+"_BQSR"
	// 		outdir="${params.resultDir}/bam/${sample_name}"
	// 		log.info ""
	// 		log.info "GATK BaseRecalibrator 2 ${input_bam}"
	// 		log.info ""
  //
	// 		"""
	//     echo "BASE QUALITY RECALIBRATOR - 3/5: RECAL REPORT 2 ${input_bam}"
	//   	gatk-launch BaseRecalibrator -R ${params.genomeRef} -I ${input_bam} --known-sites ${params.dbsnpAll} -L ${params.targetBed} -O ${output_name}-after_recalibration_report.grp
  //
	// 		echo "BASE QUALITY RECALIBRATOR - 4/5: RECAL BASE 2 ${input_bam}"
	// 		gatk-launch ApplyBQSR -R ${params.genomeRef} -I ${input_bam} --bqsr-recal-file ${output_name}-after_recalibration_report.grp -O ${output_name}2.bam
	// 		cp ${output_name}2.bam ${params.resultDir}/bam/${sample_name}
  //
	// 	 	echo "BASE QUALITY RECALIBRATOR - 5/5: PLOT ${input_bam}"
	// 	  gatk-launch AnalyzeCovariates -before ${output_name}-recalibration_report.grp -after ${output_name}-after_recalibration_report.grp -plots  ${params.resultDir}/bam/${sample_name}/${output_name}-recal_plots.pdf
  //
	// 		samtools index -@ ${task.cpus} ${output_name}2.bam
	// 		mv ${output_name}2.bam.bai ${output_name}2.bai
	// 		cp ${output_name}2.bai ${params.resultDir}/bam/${sample_name}
	// 	  """
	// 	}
  //
	// 	bqsr2out.subscribe { print "$it" }

}
