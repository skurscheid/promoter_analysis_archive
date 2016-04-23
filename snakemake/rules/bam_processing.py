__author__ = "Sebastian Kurscheid (sebastian.kurscheid@anu.edu.au)"
__license__ = "MIT"
__date__ = "2016-04-23"

# vim: syntax=python tabstop=4 expandtab
# coding: utf-8


"""
Rules for processing SAM/BAM files
For usage, include this in your workflow.
"""

# import other packages
import os
import fnmatch
from snakemake.exceptions import MissingInputException

# rules
rule all:
 input:
     expand("./processed_data/duplicates_removed/{unit}.DeDup.sorted.fastq_q20.bam", unit = config["units"]),

rule bam_sort:
    version:
        "0.1"
    params:
        qual = config["alignment_quality"],
        data_dir = config["data_dir"]
    input:
        "{params.data_dir}/{unit}.fastq_q20.bam"
    output:
        "./processed_data/sorted/{unit}.sorted.fastq_q20.bam"
    shell:
        "samtools sort {input} -T {wildcards.unit}.Q{params.qual}.sorted -o {output}"

rule bam_mark_duplicates:
    version:
        "0.1"
    params:
        qual = config["alignment_quality"]
    input:
        "./processed_data/sorted/{unit}.sorted.fastq_q20.bam"
    output:
        "./processed_data/duplicates_marked/{unit}.MkDup.sorted.fastq_q20.bam"
    shell:
        """
            java -Djava.io.tmpdir=/home/skurscheid/tmp \
            -Xmx36G \
            -jar /home/skurscheid/Bioinformatics/picard-tools-1.131/picard.jar MarkDuplicates \
            INPUT={input}\
            OUTPUT={output}\
            ASSUME_SORTED=TRUE\
            METRICS_FILE={output}.metrics.txt
        """

rule bam_index:
    version:
        "0.1"
    params:
        qual = config["alignment_quality"]
    input:
        "./processed_data/duplicates_marked/{unit}.MkDup.sorted.fastq_q20.bam"
    output:
        "./processed_data/duplicates_marked/{unit}.MkDup.sorted.fastq_q20.bam.bai"
    shell:
        "cd processed_data/duplicates_marked && samtools index ../.{input}"

# rule bam_quality_filter:
#     version:
#         "0.1"
#     params:
#         qual = config["alignment_quality"]
#     input:
#         "./processed_data/{unit}.bam"
#     output:
#         "./processed_data/quality_filtered/{unit}.Q{qual}.bam"
#     shell:
#         "samtools view -b -h -q {params.qual} {input} > {output}"

rule bam_rmdup:
    version:
        "0.1"
    input:
        "./processed_data/duplicates_marked/{unit}.MkDup.sorted.fastq_q20.bam"
    output:
        "./processed_data/duplicates_removed/{unit}.DeDup.sorted.fastq_q20.bam",
        "./processed_data/duplicates_removed/{unit}.DeDup.sorted.fastq_q20.bam.bai"
    shell:
        "samtools rmdup {input} {output[0]}; samtools index {output[0]} {output[1]}"