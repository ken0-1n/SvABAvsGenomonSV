#! /bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l s_vmem=5.3G,mem_req=5.3G
#$ -e log/ -o log/
#$ -pe def_slot 8
#$ -l os7


TUMOR_BAM=$1
NORMAL_BAM=$2
OUTPUTDIR=$3

export PATH=/home/kchiba/work_directory/work_svaba/output_190415/svaba/bin:${PATH}
REFERENCE=/home/w3varann/.genomon_local/genomon_pipeline-2.6.1/database/GRCh37/GRCh37.fa
svaba run -a ${OUTPUTDIR} -p 8 -v 1 -G ${REFERENCE} -t ${TUMOR_BAM} -n ${NORMAL_BAM} -A



