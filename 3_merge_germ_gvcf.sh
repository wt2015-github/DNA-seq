#!/bin/bash
# sbatch command
# sbatch -J germ_vcf -p campus-new -c 10 -t 7-12 --output log-%j.out --error error-%j.out 3_merge_germ_gvcf.sh
# squeue -u twang23
# scancel jobID

infolder="/fh/fast/grady_w/users/twang23/halberg/process"
outfolder="/fh/fast/grady_w/users/twang23/halberg/process/merge/germline"
genomicsdb="/fh/fast/grady_w/users/twang23/halberg/process/genomicsdb"
tmpfolder="/fh/fast/grady_w/users/twang23/halberg/process/tmp"
#intervals="/fh/fast/grady_w/users/twang23/Data/gatk_resource_b37/Broad.human.exome.b37.interval_list"
samplemap="/fh/fast/grady_w/users/twang23/halberg/process/merge/germline/file_germ.gvcf.map"
refgenome="/fh/fast/grady_w/users/twang23/Data/gatk_resource_hg38/Homo_sapiens_assembly38.fasta"
vcfHapmap="/fh/fast/grady_w/users/twang23/Data/gatk_resource_hg38/hapmap_3.3.hg38.vcf.gz"
vcfOmni="/fh/fast/grady_w/users/twang23/Data/gatk_resource_hg38/1000G_omni2.5.hg38.vcf.gz"
vcfGlk="/fh/fast/grady_w/users/twang23/Data/gatk_resource_hg38/1000G_phase1.snps.high_confidence.hg38.vcf.gz"
vcfDbsnp="/fh/fast/grady_w/users/twang23/Data/gatk_resource_hg38/Homo_sapiens_assembly38.dbsnp138.vcf.gz"
vcfMills="/fh/fast/grady_w/users/twang23/Data/gatk_resource_hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"
vcfAxiom="/fh/fast/grady_w/users/twang23/Data/gatk_resource_hg38/Axiom_Exome_Plus.genotypes.all_populations.poly.hg38.vcf.gz"
regions="/fh/fast/grady_w/users/twang23/Data/gatk_resource_hg38/S31285117_Regions_GRCh38.bed"

module load GATK/4.1.8.1-GCCcore-8.3.0-Java-11

echo "=== GenomicsDBImport, super slow ==="
gatk --java-options "-Xms200G -Xmx200G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" GenomicsDBImport \
	--reader-threads ${SLURM_JOB_CPUS_PER_NODE} \
	--tmp-dir ${tmpfolder} \
	--genomicsdb-workspace-path ${genomicsdb} \
	--batch-size 20 \
	--sample-name-map ${samplemap} \
	-L chr1 \
	-L chr2 \
	-L chr3 \
	-L chr4 \
	-L chr5 \
	-L chr6 \
	-L chr7 \
	-L chr8 \
	-L chr9 \
	-L chr10 \
	-L chr11 \
	-L chr12 \
	-L chr13 \
	-L chr14 \
	-L chr15 \
	-L chr16 \
	-L chr17 \
	-L chr18 \
	-L chr19 \
	-L chr20 \
	-L chr21 \
	-L chr22 \
	-L chrX \
	-L chrY

echo "=== GenotypeGVCFs, slow ==="
gatk --java-options "-Xmx100G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" GenotypeGVCFs \
	-R ${refgenome} \
	-V gendb://${genomicsdb} \
	-O ${outfolder}/merge_germ.vcf.gz \
	--tmp-dir ${tmpfolder}

echo "=== Variant Quality Score Recalibration for SNPs ==="
module load GATK/4.1.8.1-GCCcore-8.3.0-Java-11
module load R/4.0.2-foss-2019b
gatk --java-options "-Xmx100G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" VariantRecalibrator \
	-R ${refgenome} \
	-V ${outfolder}/merge_germ.vcf.gz \
	--max-gaussians 6 \
	--tmp-dir ${tmpfolder} \
	--resource:hapmap,known=false,training=true,truth=true,prior=15.0 ${vcfHapmap} \
	--resource:omni,known=false,training=true,truth=true,prior=12.0 ${vcfOmni} \
	--resource:1000G,known=false,training=true,truth=false,prior=10.0 ${vcfGlk} \
	--resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${vcfDbsnp} \
	-an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
	-mode SNP \
	-O ${outfolder}/merge_germ_SNP.recal \
	--tranches-file ${outfolder}/merge_germ_recal_SNP.tranches \
	--rscript-file ${outfolder}/merge_germ_recal_SNP.plots.R

echo "=== Apply variant recalibation to SNPs ==="
gatk --java-options "-Xmx100G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" ApplyVQSR \
	-R ${refgenome} \
	-V ${outfolder}/merge_germ.vcf.gz \
	-O ${outfolder}/merge_germ_recal_SNP.vcf.gz \
	-mode SNP \
	--tmp-dir ${tmpfolder} \
	--recal-file ${outfolder}/merge_germ_SNP.recal \
	--tranches-file ${outfolder}/merge_germ_recal_SNP.tranches \
	--truth-sensitivity-filter-level 99.5

echo "=== Variant Quality Score Recalibration for Indels ==="
module load GATK/4.1.8.1-GCCcore-8.3.0-Java-11
module load R/4.0.2-foss-2019b
gatk --java-options "-Xmx100G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" VariantRecalibrator \
	-R ${refgenome} \
	-V ${outfolder}/merge_germ_recal_SNP.vcf.gz \
	-O ${outfolder}/merge_germ_SNP_Indel.recal \
	-mode INDEL \
	--max-gaussians 4 \
	--tranches-file ${outfolder}/merge_germ_recal_SNP_Indel.tranches \
	-an QD -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
	--rscript-file ${outfolder}/merge_germ_recal_SNP_Indel.plots.R \
	--tmp-dir ${tmpfolder} \
	--resource:mills,known=false,training=true,truth=true,prior=12.0 ${vcfMills} \
	--resource:axiomPoly,known=false,training=true,truth=false,prior=10.0 ${vcfAxiom} \
	--resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${vcfDbsnp}

echo "=== Apply variant recalibation to Indels ==="
gatk --java-options "-Xmx100G -XX:+UseParallelGC -XX:ParallelGCThreads=${SLURM_JOB_CPUS_PER_NODE}" ApplyVQSR \
	-R ${refgenome} \
	-V ${outfolder}/merge_germ_recal_SNP.vcf.gz \
	-O ${outfolder}/merge_germ_recal_SNP_Indel.vcf.gz \
	-mode INDEL \
	--tmp-dir ${tmpfolder} \
	--recal-file ${outfolder}/merge_germ_SNP_Indel.recal \
	--tranches-file ${outfolder}/merge_germ_recal_SNP_Indel.tranches \
	--truth-sensitivity-filter-level 99.0

echo "=== extract specific chromosomes, regions and PASS variants ==="
module load BCFtools/1.9-GCC-8.3.0
bcftools view -f "PASS" -Oz -o ${outfolder}/merge_germ_recal_SNP_Indel_PASS.vcf.gz ${outfolder}/merge_germ_recal_SNP_Indel.vcf.gz
tabix -p vcf ${outfolder}/merge_germ_recal_SNP_Indel_PASS.vcf.gz

bcftools view -R ${regions} -Oz -o ${outfolder}/merge_germ_recal_SNP_Indel_PASS_regionFilt.vcf.gz ${outfolder}/merge_germ_recal_SNP_Indel_PASS.vcf.gz
tabix -p vcf ${outfolder}/merge_germ_recal_SNP_Indel_PASS_regionFilt.vcf.gz

echo "=== annotation ==="
module load Java/11.0.2
java -Xmx10G -jar /home/twang23/snpEff/snpEff.jar -v -stats ${outfolder}/merge_germ_recal_SNP_Indel_PASS_ann.html GRCh38.99 ${outfolder}/merge_germ_recal_SNP_Indel_PASS.vcf.gz > ${outfolder}/merge_germ_recal_SNP_Indel_PASS_ann.vcf
module load tabix/0.2.6-GCCcore-8.3.0
bgzip ${outfolder}/merge_germ_recal_SNP_Indel_PASS_ann.vcf
tabix -p vcf ${outfolder}/merge_germ_recal_SNP_Indel_PASS_ann.vcf.gz

java -Xmx10G -jar /home/twang23/snpEff/snpEff.jar -v -stats ${outfolder}/merge_germ_recal_SNP_Indel_PASS_regionFilt_ann.html GRCh38.99 ${outfolder}/merge_germ_recal_SNP_Indel_PASS_regionFilt.vcf.gz > ${outfolder}/merge_germ_recal_SNP_Indel_PASS_regionFilt_ann.vcf
bgzip ${outfolder}/merge_germ_recal_SNP_Indel_PASS_regionFilt_ann.vcf
tabix -p vcf ${outfolder}/merge_germ_recal_SNP_Indel_PASS_regionFilt_ann.vcf.gz


