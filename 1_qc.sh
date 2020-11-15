#!/bin/bash
# First Fastqc then Multiqc to summarize QC results

# sbatch command
# sbatch -J qc --partition=campus-new -c 4 -t 2-12 --output log-%j.out --error error-%j.out ./qc.sh
# squeue -u username
# scancel jobID

module load FastQC/0.11.9-Java-11

fastq_files1=(`find <path-to-fastqs> -maxdepth 1 -name "*.fastq.gz" -type f | sort`)
for file1 in ${fastq_files1[@]}; do fastqc $file1 -t 4 -o <path-to-fastqc-output>; done

module load MultiQC/1.9-foss-2019b-Python-3.7.4

multiqc -v -o <path-to-multiqc-output> <path-to-fastqc-output>

