# DNA-seq

Analysis of Whole Exome (or Whole Genome) DNA-seq data to call germline and somatic variants from individual samples (not paired tumor-normal samples) using GATK (4.1.8.1) pipelines

* *HaplotypeCaller* pipeline for germline variants

* *Mutect2* pipeline for somatic variants

## Reference genome and variant data can be downloaded from GATK

[GATK resource bundle](https://gatk.broadinstitute.org/hc/en-us/articles/360035890811-Resource-bundle)

Download Google Cloud bucket of general [hg38](https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/) resources

* *gsutil cp gs://genomics-public-data/resources/broad/hg38/v0 path-local-folder*

Download Google Cloud bucket of [hg38](https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-hg38?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false) resources for Mutect2 somatic variant caller

* *gsutil cp gs://gatk-best-practices/somatic-hg38 path-local-folder*

## Contact
[Ting Wang](http://wt2015-github.github.io/) (wang9ting@gmail.com).
