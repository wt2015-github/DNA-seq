# DNA-seq

Analysis of Whole Exome (or Whole Genome) DNA-seq data to call germline and somatic variants using GATK (4.1.8.1) pipelines

## Reference genome and variant data can be downloaded from 

* *run_RNAseq_STAR.RSEM.sh* includes QC, trimming, contamination screening, mapping, gene/isoform expression quantification, and summary steps.

* *callSNP_RNAseq.sh* is for SNP calling using the RNA-seq analysis results for each sample.

Downstream analyses, such as different expression analysis and pathway enrichment analaysis, are case specific, so are not included in this pipeline.


## Contact
[Ting Wang](http://wt2015-github.github.io/) (wang9ting@gmail.com).
