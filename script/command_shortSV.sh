#!/bin/bash
#
#$ -S /bin/bash         # set shell in UGE
#$ -cwd                 # execute at the submitted dir
#$ -o log -e log

set -e 

DISEASE=$1

if [ $# -ne 1 ]; then
  echo "wrong number of arguments"
  exit 1
fi

: <<'#__co'
#__co
#__co

mkdir -p ../output_svaba_shortSV/${DISEASE}
mkdir -p ../output_genomonSV_shortSV/${DISEASE}
mkdir -p ../output_comp_shortSV/${DISEASE}

SIMPLE_REPEAT=../simpleRepeat.txt.gz
REFERENCE=/home/w3varann/.genomon_local/genomon_pipeline-2.6.1/database/GRCh37/GRCh37.fa
ANNOVAR_DIR=/home/kchiba/tools/annovar

# 1-1. combert svaba.sv to annover format 
# tumor
# for file in ../svaba-somatic/${DISEASE}/TCGA-OR-A5J6-01.svaba.somatic.sv.vcf; do
for file in ../svaba-somatic/${DISEASE}/*-0?.svaba.somatic.sv.vcf; do
  bf=`basename $file`;
  echo $bf
  barcode=${bf%.*.*.*.*}
  echo "barcode=$barcode"
  python VCFtoGenomonSVFormat.py $file $barcode "True" | sort -u > ../output_svaba_shortSV/${DISEASE}/${bf}.txt;
  sv_utils filter --grc --simple_repeat_file ${SIMPLE_REPEAT} --pooled_control_file ../svaba-control/${DISEASE}/all_merge_control_svaba --inversion_size_thres 1000 ../output_svaba_shortSV/${DISEASE}/${bf}.txt ../output_svaba_shortSV/${DISEASE}/${bf}.filtered.txt
  sv_utils format --reference $REFERENCE ../output_svaba_shortSV/${DISEASE}/${bf}.filtered.txt ../output_svaba_shortSV/${DISEASE}/${bf}.indel.vcf
  python vcftoAnnoFormat.py ../output_svaba_shortSV/${DISEASE}/${bf}.indel.vcf | sort -u > ../output_svaba_shortSV/${DISEASE}/${bf}.indel.vcf.txt
done

# 1-2. combert svaba.indel to annover format 
# for file in ../svaba-somatic/${DISEASE}/TCGA-OR-A5J6-01.svaba.somatic.indel.vcf; do
for file in ../svaba-somatic/${DISEASE}/*-0?.svaba.somatic.indel.vcf; do
  bf=`basename $file`;
  echo $bf
  python vcftoAnnoFormat.py $file | sort -u > ../output_svaba_shortSV/${DISEASE}/${bf}.txt
done

for file in ../output_svaba_shortSV/${DISEASE}/*.svaba.somatic.sv.vcf.indel.vcf.txt; do
  bf=`basename ${file%.*}`
  barcode=${bf%.*.*.*.*.*.*}
  echo $barcode
  cat $file ../output_svaba_shortSV/${DISEASE}/${barcode}.svaba.somatic.indel.vcf.txt > ../output_svaba_shortSV/${DISEASE}/${barcode}.svaba.indel.merge.txt

  python blacklist.py ../output_svaba_shortSV/${DISEASE}/${barcode}.svaba.indel.merge.txt ../svaba-control/${DISEASE}/svaba_short_indel_blacklist_sorted.bed.gz ../output_svaba_shortSV/${DISEASE}/${barcode}.svaba.indel.filtered.txt ../output_svaba_shortSV/${DISEASE}/${barcode}.svaba.indel.blacklist.txt 10 100 12 20

  ${ANNOVAR_DIR}/table_annovar.pl --outfile ../output_svaba_shortSV/${DISEASE}/${barcode}.svaba.indel.filtered -buildver hg19 -remove --otherinfo -protocol refGene -operation g ../output_svaba_shortSV/${DISEASE}/${barcode}.svaba.indel.filtered.txt ${ANNOVAR_DIR}/humandb
done

# 2. copy genomonSV results without header
# for file in ../genomonsv/${DISEASE}/*-0?.genomon_mutation.result.filt.svutil_mutation.txt; do
for file in ../genomonsv/${DISEASE}/TCGA-OR-A5J6-01.genomon_mutation.result.filt.svutil_mutation.txt; do
  bf=`basename $file`;
  echo $bf
  barcode=${bf%.*.*.*.*.*}
  echo $barcode
  cat $file | awk 'NR>4' > ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.txt;
  sv_utils filter --grc --simple_repeat_file ${SIMPLE_REPEAT} --pooled_control_file ../genomonsv-control/${DISEASE}/all_merge_control_genomonSV --inversion_size_thres 1000 ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.txt ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.filtered.txt
  sv_utils format --reference $REFERENCE ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.filtered.txt ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.indel.vcf
  python vcftoAnnoFormat.py ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.indel.vcf | sort -u > ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.indel.vcf.txt
  python blacklist.py ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.indel.vcf.txt empty_blacklist.bed.gz ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.indel.vcf.filtered.txt ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.indel.vcf.blacklist.txt 10 100 12 20
  ${ANNOVAR_DIR}/table_annovar.pl --outfile ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.indel.vcf.filtered -buildver hg19 -remove --otherinfo -protocol refGene -operation g ../output_genomonSV_shortSV/${DISEASE}/${barcode}.genomonSV.result.indel.vcf.filtered.txt ${ANNOVAR_DIR}/humandb
done

# 3. comp genomonSV and svaba 
for file in ../output_genomonSV_shortSV/${DISEASE}/*-0?.genomonSV.result.indel.vcf.filtered.hg19_multianno.txt; do
  bf=`basename $file`
  barcode=${bf%.*.*.*.*.*.*.*}
  echo $barcode
  python comp_anno.py ${file} ../output_svaba_shortSV/${DISEASE}/${barcode}.svaba.indel.filtered.hg19_multianno.txt > ../output_comp_shortSV/${DISEASE}/${barcode}.GenomonSV_SvABA.comp.txt 
  python comp_anno.py ../output_svaba_shortSV/${DISEASE}/${barcode}.svaba.indel.filtered.hg19_multianno.txt ${file} > ../output_comp_shortSV/${DISEASE}/${barcode}.SvABA_GenomonSV.comp.txt
done

# 4. merge results file
python merge_result_final_shortSV.py $DISEASE "../output_comp_shortSV/${DISEASE}/*.GenomonSV_SvABA.comp.txt" > ../output_comp_shortSV/${DISEASE}_GenomonSV_SvABA_comp_shortSV.txt
python merge_result_final_shortSV.py $DISEASE "../output_comp_shortSV/${DISEASE}/*.SvABA_GenomonSV.comp.txt" > ../output_comp_shortSV/${DISEASE}_SvABA_GenomonSV_comp_shortSV.txt

: <<'#__co'
: <<'#__co'
#__co
#__co
#__co
#__co
