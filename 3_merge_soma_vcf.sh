#!/bin/bash

# sbatch command
# sbatch -J Soma_vcf -p campus-new -c 6 -t 4-12 --output log-%j.out --error error-%j.out 3_merge_soma_vcf.sh
# squeue -u twang23
# scancel jobID

infolder="/fh/fast/grady_w/users/twang23/halberg/process"
outfolder="/fh/fast/grady_w/users/twang23/halberg/process/merge/somatic"
regions="/fh/fast/grady_w/users/twang23/Data/gatk_resource_hg38/S31285117_Regions_GRCh38.bed"

echo "=== merge vcf files of multiple samples into one ==="
module load VCFtools/0.1.16-foss-2019b-Perl-5.30.0
vcf-merge ${infolder}/batch*/*/*soma.filtered.vcf.gz > ${outfolder}/merge_soma_filtered.vcf

echo "=== vcf.gz and index ==="
module load tabix/0.2.6-GCCcore-8.3.0
bgzip ${outfolder}/merge_soma_filtered.vcf
tabix -p vcf ${outfolder}/merge_soma_filtered.vcf.gz

echo "=== extract specific chromosomes, regions and PASS variants ==="
module load BCFtools/1.9-GCC-8.3.0
bcftools view -f "PASS" -r chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY -Oz -o ${outfolder}/merge_soma_filtered_newChr_PASS.vcf.gz ${outfolder}/merge_soma_filtered.vcf.gz
tabix -p vcf ${outfolder}/merge_soma_filtered_newChr_PASS.vcf.gz

bcftools view -R ${regions} -Oz -o ${outfolder}/merge_soma_filtered_newChr_PASS_regionFilt.vcf.gz ${outfolder}/merge_soma_filtered_newChr_PASS.vcf.gz
tabix -p vcf ${outfolder}/merge_soma_filtered_newChr_PASS_regionFilt.vcf.gz

echo "=== annotation ==="
module load Java/11.0.2 
java -Xmx10G -jar /home/twang23/snpEff/snpEff.jar -v -stats ${outfolder}/merge_soma_filtered_newChr_PASS_ann.html GRCh38.99 ${outfolder}/merge_soma_filtered_newChr_PASS.vcf.gz > ${outfolder}/merge_soma_filtered_newChr_PASS_ann.vcf
module load tabix/0.2.6-GCCcore-8.3.0
bgzip ${outfolder}/merge_soma_filtered_newChr_PASS_ann.vcf
tabix -p vcf ${outfolder}/merge_soma_filtered_newChr_PASS_ann.vcf.gz

java -Xmx10G -jar /home/twang23/snpEff/snpEff.jar -v -stats ${outfolder}/merge_soma_filtered_newChr_PASS_regionFilt_ann.html GRCh38.99 ${outfolder}/merge_soma_filtered_newChr_PASS_regionFilt.vcf.gz > ${outfolder}/merge_soma_filtered_newChr_PASS_regionFilt_ann.vcf
bgzip ${outfolder}/merge_soma_filtered_newChr_PASS_regionFilt_ann.vcf
tabix -p vcf ${outfolder}/merge_soma_filtered_newChr_PASS_regionFilt_ann.vcf.gz

