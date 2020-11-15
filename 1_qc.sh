#!/bin/bash

# sbatch command
# sbatch -J qc --partition=campus-new -c 4 -t 2-12 --output log-%j.out --error error-%j.out ./qc.sh
# squeue -u username
# scancel jobID

module load FastQC/0.11.9-Java-11

fastq_files1=(`find /fh/fast/grady_w/users/twang23/halberg/exome/wave1/fastq/batch1/ -maxdepth 1 -name "*.fastq.gz" -type f | sort`)
for file1 in ${fastq_files1[@]}; do fastqc $file1 -t 4 -o /fh/fast/grady_w/users/twang23/halberg/qc/raw/fastqc/batch1/; done

fastq_files2=(`find /fh/fast/grady_w/users/twang23/halberg/exome/wave1/fastq/batch2/ -maxdepth 1 -name "*.fastq.gz" -type f | sort`)
for file2 in ${fastq_files2[@]}; do fastqc $file2 -t 4 -o /fh/fast/grady_w/users/twang23/halberg/qc/raw/fastqc/batch2/; done

module load MultiQC/1.9-foss-2019b-Python-3.7.4

multiqc -v -o /fh/fast/grady_w/users/twang23/halberg/qc/raw/multiqc/ /fh/fast/grady_w/users/twang23/halberg/qc/raw/fastqc/

