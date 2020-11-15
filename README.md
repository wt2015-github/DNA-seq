# DNA-seq

Analysis of Whole Exome (or Whole Genome) DNA-seq data to call germline and somatic variants from individual samples (not paired tumor-normal samples) using GATK (4.1.8.1) pipelines

## Reference genome and variant data can be downloaded from GATK

[GATK resource bundle](https://gatk.broadinstitute.org/hc/en-us/articles/360035890811-Resource-bundle) Google Cloud bucket for [hg38](https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/)

* *callSNP_RNAseq.sh* is for SNP calling using the RNA-seq analysis results for each sample.

Downstream analyses, such as different expression analysis and pathway enrichment analaysis, are case specific, so are not included in this pipeline.


## Contact
[Ting Wang](http://wt2015-github.github.io/) (wang9ting@gmail.com).
