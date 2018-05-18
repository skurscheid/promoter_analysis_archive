__author__ = "Sebastian Kurscheid (sebastian.kurscheid@anu.edu.au)"
__license__ = "MIT"
__date__ = "2016-12-05"

import os
import fnmatch
from snakemake.exceptions import MissingInputException

rule:
    version: 0.2

localrules:
    all

home = os.environ['HOME']

wrapper_dir = home + "/Development/snakemake-wrappers/bio"

include_prefix = home + "/Development/JCSMR-Tremethick-Lab/Breast/snakemake/rules/"

include:
    include_prefix + "run_fastp.py"

# define global variables such as reference version of genome so that it can be accessed
# throughout the whole worfklow
REF_GENOME = config["references"]["genomes"][1]

# set local variables
home = os.environ['HOME']
REF_GENOME = "hg19"
REF_VERSION = "GRCh37_hg19_UCSC"

rule bowtie2_pe:
    version:
        "0.2"
    params:
        max_in = 250,
        bt2_index = home + config["references"][REF_GENOME]["bowtie2"][REF_VERSION]
    threads:
        8
    input:
        trimmed_read1 = "{assayID}/{processed_dir}/{trim_data}/{unit}_end1.fastq.gz",
        trimmed_read2 = "{assayID}/{processed_dir}/{trim_data}/{unit}_end2.fastq.gz"
    output:
        temp("{assayID}/{outdir}/{reference_version}/bowtie2/{sample}.bam")
    shell:
        """
            bowtie2 \
            -x {params.bt2_index}\
            --no-mixed \
            --no-discordant \
            --maxins {params.max_in} \
            --threads {threads}\
            --rg-id '{wildcards.sample}' \
            --rg 'LB:{wildcards.sample}' \
            --rg 'SM:{wildcards.sample}' \
            --rg 'PL:Illumina' \
            --rg 'PU:NA' \
            -1 {input.read1} \
            -2 {input.read2} \
            | samtools view -Sb - > {output}
        """

rule bam_quality_filter:
    params:
        qual = config["alignment_quality"]
    input:
        rules.bowtie2_pe.output
    output:
        temp("{assayID}/{outdir}/{reference_version}/bowtie2/quality_filtered/Q{qual}/{unit}.bam")
    shell:
        "samtools view -b -h -q {params.qual} {input} > {output}"

rule bam_sort:
    params:
        qual = config["alignment_quality"]
    threads:
        4
    input:
        rules.bam_quality_filter.output
    output:
        temp("{assayID}/{outdir}/{reference_version}/bowtie2/sorted/Q{qual}/{unit}.bam")
    shell:
        "samtools sort -@ {threads} {input} -T {wildcards.unit}.Q{params.qual}.sorted -o {output}"

rule bam_mark_duplicates:
    params:
        qual = config["alignment_quality"],
        picard = home + config["picard"],
        temp = home + config["temp_dir"]
    input:
        rules.bam_sort.output
    output:
        temp("{assayID}/{outdir}/{reference_version}/bowtie2/sorted/Q{qual}/duplicates_marked/{unit}.bam")
    shell:
        """
            java -Djava.io.tmpdir={params.temp} \
            -Xmx24G \
            -jar {params.picard} MarkDuplicates \
            INPUT={input}\
            OUTPUT={output}\
            ASSUME_SORTED=TRUE\
            METRICS_FILE={output}.metrics.txt
        """

rule bam_rmdup:
    input:
        rules.bam_mark_duplicates.output
    output:
        protected("{assayID}/{outdir}/{reference_version}/bowtie2/sorted/Q{qual}/duplicates_removed/{unit}.bam")
    shell:
        "samtools rmdup {input} {output}"

rule bam_rmdup_index:
    params:
        qual = config["alignment_quality"]
    input:
        rules.bam_rmdup.output
    output:
        protected("{assayID}/{outdir}/{reference_version}/bowtie2/sorted/Q{qual}/duplicates_removed/{unit}.bam.bai")
    shell:
        "samtools index {input} {output}"

rule all:
    input:
        expand("{assayID}/{outdir}/{reference_version}/bowtie2/sorted/Q{qual}/duplicates_removed/{unit}.{suffix}",
               assayID = "PromoterSeqCap",
               outdir = config["processed_dir"],
               reference_version = config["references"][REF_GENOME]["version"],
               duplicates = "duplicates_removed",
               sample = config["units"],
               qual = config["alignment_quality"],
               suffix = ["bam", "bam.bai"]),