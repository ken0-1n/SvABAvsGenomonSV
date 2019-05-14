#! /bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l s_vmem=5.3G,mem_req=5.3G
#$ -e log/ -o log/
#$ -pe def_slot 8
#$ -l os7


BAM=$1
OUTPUTDIR=$2

export PATH=/home/kchiba/work_directory/work_svaba/output_190415/svaba/bin:${PATH}
REFERENCE=/home/w3varann/.genomon_local/genomon_pipeline-2.6.1/database/GRCh37/GRCh37.fa
svaba run -a ${OUTPUTDIR} -p 8 -v 1 -G ${REFERENCE} -t ${BAM} -A



