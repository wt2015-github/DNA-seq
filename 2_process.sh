#!/bin/bash
# call germline and somatic variants for each individual sample using GATK pipelines

# sbatch command
# sbatch -J ExomeSeq1 -p campus-new -c 6 -t 10-12 --output log-%j.out --error error-%j.out 2_process_batch1.sh
# squeue -u username
# scancel jobID

fastqfolder="path-to-fastqs"
outfolder="path-to-output"
adapters="/app/software/Trimmomatic/0.39-Java-11/adapters/TruSeq3-PE-2.fa"
refgenome="path-to/gatk_resource_hg38/Homo_sapiens_assembly38.fasta"
dbsnp="path-to/gatk_resource_hg38/Homo_sapiens_assembly38.dbsnp138.vcf.gz"
vcfGlk="path-to/gatk_resource_hg38/1000G_phase1.snps.high_confidence.hg38.vcf.gz"
germlineresource="path-to/Mutect2_data/hg38/af-only-gnomad.hg38.vcf.gz"
ponvcf="path-to/Mutect2_data/hg38/1000g_pon.hg38.vcf.gz"
germlinecommon="/path-to/Mutect2_data/hg38/small_exac_common_3.hg38.vcf.gz"

fastq_files=(`find ${fastqfolder} -maxdepth 1 -name "*.fastq.gz" -type f | sort`)
for ((i=0; i<${#fastq_files[@]}; i+=2)); do
		subfolder=$(echo ${fastq_files[$i]} | rev | cut -d '/' -f1 | rev | awk -F "_L00" '{print $1}')
		mkdir ${outfolder}/${subfolder}
		echo "=== analyzing for sample ${subfolder} ==="
		echo "=== cut adapters and trim reads for sample ${subfolder} ==="
		module load Trimmomatic/0.39-Java-11
		java -jar $EBROOTTRIMMOMATIC/trimmomatic-0.39.jar PE -threads ${SLURM_JOB_CPUS_PER_NODE} -phred33 ${fastq_files[$i]} ${fastq_files[$i+1]} ${outfolder}/${subfolder}/${subfolder}.R1_P_T.fq.gz ${outfolder}/${subfolder}/${subfolder}.R1_UP_T.fq.gz ${outfolder}/${subfolder}/${subfolder}.R2_P_T.fq.gz ${outfolder}/${subfolder}/${subfolder}.R2_UP_T.fq.gz ILLUMINACLIP:${adapters}:2:30:10:8:TRUE LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 2> ${outfolder}/${subfolder}/${subfolder}.trimmomatic.log
		echo "=== mapping to reference genome with BWA MEM for sample ${subfolder} ==="
		module load BWA/0.7.17-GCC-8.3.0
		module load SAMtools/1.10-GCCcore-8.3.0
		bwa mem -t ${SLURM_JOB_CPUS_PER_NODE} -M -T 0 -R @RG\\tID:${subfolder}\\tSM:${subfolder}\\tLB:${subfolder}\\tPL:ILLUMINA\\tPU:${subfolder} ${refgenome} ${outfolder}/${subfolder}/${subfolder}.R1_P_T.fq.gz ${outfolder}/${subfolder}/${subfolder}.R2_P_T.fq.gz | samtools view -Shb -o ${outfolder}/${subfolder}/${subfolder}.bam -
		echo "=== sort and mark duplicates in bam file for sample ${subfolder} ==="
		module load picard/2.21.6-Java-11
		mkdir ${outfolder}/${subfolder}/${subfolder}.tmp
		java -Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE} -jar $EBROOTPICARD/picard.jar SortSam CREATE_INDEX=true INPUT=${outfolder}/${subfolder}/${subfolder}.bam OUTPUT=${outfolder}/${subfolder}/${subfolder}.sorted.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=STRICT TMP_DIR=${outfolder}/${subfolder}/${subfolder}.tmp
		java -Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE} -jar $EBROOTPICARD/picard.jar MarkDuplicates CREATE_INDEX=true INPUT=${outfolder}/${subfolder}/${subfolder}.sorted.bam OUTPUT=${outfolder}/${subfolder}/${subfolder}.sorted.markDup.bam METRICS_FILE=${outfolder}/${subfolder}/${subfolder}.sorted.markDup.metrics ASSUME_SORT_ORDER=coordinate VALIDATION_STRINGENCY=STRICT TMP_DIR=${outfolder}/${subfolder}/${subfolder}.tmp
		java -Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE} -jar $EBROOTPICARD/picard.jar CollectAlignmentSummaryMetrics R=${refgenome} I=${outfolder}/${subfolder}/${subfolder}.sorted.markDup.bam O=${outfolder}/${subfolder}/${subfolder}.sorted.markDup.AlignSummary TMP_DIR=${outfolder}/${subfolder}/${subfolder}.tmp
		echo "=== base quality score recalibration for sample ${subfolder} ==="
		module load GATK/4.1.8.1-GCCcore-8.3.0-Java-11
		gatk --java-options "-Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" BaseRecalibrator -R ${refgenome} -I ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.bam --known-sites ${dbsnp} --known-sites ${vcfGlk} -O ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.table --tmp-dir ${outfolder}/${subfolder}/${subfolder}.tmp
		gatk --java-options "-Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" ApplyBQSR -R ${refgenome} -I ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.bam --bqsr-recal-file ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.table -O ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.bam --tmp-dir ${outfolder}/${subfolder}/${subfolder}.tmp
		echo "=== call somatic variants for sample ${subfolder} ==="
		gatk --java-options "-Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" Mutect2 -R ${refgenome} -I ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.bam -O ${outfolder}/${subfolder}/${subfolder}.soma.vcf.gz --f1r2-tar-gz ${outfolder}/${subfolder}/${subfolder}.f1r2.tar.gz --germline-resource ${germlineresource} --panel-of-normals ${ponvcf} --native-pair-hmm-threads ${SLURM_JOB_CPUS_PER_NODE} --tmp-dir ${outfolder}/${subfolder}/${subfolder}.tmp
		echo "=== learn read orientation model for sample ${subfolder} ==="
		gatk --java-options "-Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" LearnReadOrientationModel -I ${outfolder}/${subfolder}/${subfolder}.f1r2.tar.gz -O ${outfolder}/${subfolder}/${subfolder}.readOrientationModel.tar.gz --tmp-dir ${outfolder}/${subfolder}/${subfolder}.tmp
		echo "=== get pileup summaries for sample ${subfolder} ==="
		gatk --java-options "-Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" GetPileupSummaries -I ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.bam -O ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.pileupSummary.table -V ${germlinecommon} -L ${germlinecommon} --tmp-dir ${outfolder}/${subfolder}/${subfolder}.tmp
		echo "=== calculate contamination for sample ${subfolder} ==="
		gatk --java-options "-Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" CalculateContamination -I ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.pileupSummary.table -O ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.contamination.table --tumor-segmentation ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.segments.table --tmp-dir ${outfolder}/${subfolder}/${subfolder}.tmp
		echo "=== filter mutect2 variants for sample ${subfolder} ==="
		gatk --java-options "-Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" FilterMutectCalls -R ${refgenome} -V ${outfolder}/${subfolder}/${subfolder}.soma.vcf.gz -O ${outfolder}/${subfolder}/${subfolder}.soma.filtered.vcf.gz --contamination-table ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.contamination.table --tumor-segmentation ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.segments.table --orientation-bias-artifact-priors ${outfolder}/${subfolder}/${subfolder}.readOrientationModel.tar.gz --tmp-dir ${outfolder}/${subfolder}/${subfolder}.tmp
		echo "=== call germline variants for sample ${subfolder} ==="
		gatk --java-options "-Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" HaplotypeCaller -R ${refgenome} -I ${outfolder}/${subfolder}/${subfolder}.sorted.markDup.recal.bam -O ${outfolder}/${subfolder}/${subfolder}.germ.g.vcf.gz -ERC GVCF --native-pair-hmm-threads ${SLURM_JOB_CPUS_PER_NODE} --tmp-dir ${outfolder}/${subfolder}/${subfolder}.tmp
		echo "=== GenotypeGVCFs for sample ${subfolder} ==="
		gatk --java-options "-Xmx20G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" GenotypeGVCFs -R ${refgenome} -V ${outfolder}/${subfolder}/${subfolder}.germ.g.vcf.gz -O ${outfolder}/${subfolder}/${subfolder}.germ.vcf.gz --tmp-dir ${outfolder}/${subfolder}/${subfolder}.tmp
		rm ${outfolder}/${subfolder}/${subfolder}.bam
		rm ${outfolder}/${subfolder}/${subfolder}.sorted.ba*
		#rm ${outfolder}/${subfolder}/*fq.gz
done

