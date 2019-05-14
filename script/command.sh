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

mkdir -p ../output_svaba/${DISEASE}
mkdir -p ../output_genomonSV/${DISEASE}
mkdir -p ../output_comp/${DISEASE}

SIMPLE_REPEAT=../simpleRepeat.txt.gz

# 1. format change
# tumor
for file in ../svaba-somatic/${DISEASE}/*-0?.svaba.somatic.sv.vcf; do
# for file in ../svaba-somatic/${DISEASE}/TCGA-P6-A5OG-01.svaba.somatic.sv.vcf; do
  bf=`basename $file`;
  echo $bf
  barcode=${bf%.*.*.*.*}
  echo "barcode=$barcode"
  python VCFtoGenomonSVFormat.py $file $barcode "True" | sort -u > ../output_svaba/${DISEASE}/${bf}.txt
  sv_utils filter --grc --simple_repeat_file ${SIMPLE_REPEAT} --pooled_control_file ../svaba-control/${DISEASE}/all_merge_control_svaba --min_size_thres 100 --inversion_size_thres 1000 ../output_svaba/${DISEASE}/${bf}.txt ../output_svaba/${DISEASE}/${bf}.filtered.txt
  sv_utils annotation --grc --re_gene_annotation ../output_svaba/${DISEASE}/${bf}.filtered.txt ../output_svaba/${DISEASE}/${bf}.annotated.txt
done

# 2. filtering genomonSV results
for file in ../genomonsv/${DISEASE}/*-0?.genomon_mutation.result.filt.svutil_mutation.txt; do
# for file in ../genomonsv/${DISEASE}/TCGA-P6-A5OG-01.genomon_mutation.result.filt.svutil_mutation.txt; do
  bf=`basename ${file%.*}`
  echo $bf
  sv_utils filter --grc --simple_repeat_file ${SIMPLE_REPEAT} --pooled_control_file ../genomonsv-control/${DISEASE}/all_merge_control_genomonSV --min_size_thres 100 --inversion_size_thres 1000 $file ../output_genomonSV/${DISEASE}/${bf}.filtered.txt
  sv_utils annotation --grc --re_gene_annotation ../output_genomonSV/${DISEASE}/${bf}.filtered.txt ../output_genomonSV/${DISEASE}/${bf}.annotated.txt
done

# 3. comp genomonSV and svaba 
for file in ../output_genomonSV/${DISEASE}/*-0?.genomon_mutation.result.filt.svutil_mutation.annotated.txt; do
  bf=`basename $file`
  echo $bf
  barcode=${bf%.*.*.*.*.*.*}
  echo $barcode
  fusion_utils comp ${file} genomonSV ../output_svaba/${DISEASE}/${barcode}.svaba.somatic.sv.vcf.annotated.txt genomonSV ../output_comp/${DISEASE}/${barcode}.GenomonSV_SvABA.comp.txt
  fusion_utils comp ../output_svaba/${DISEASE}/${barcode}.svaba.somatic.sv.vcf.annotated.txt genomonSV ${file} genomonSV ../output_comp/${DISEASE}/${barcode}.SvABA_GenomonSV.comp.txt
done
#__co

# 4. merge results file
python merge_result_final.py ${DISEASE} "../output_comp/${DISEASE}/*.GenomonSV_SvABA.comp.txt" > ../output_comp/${DISEASE}_GenomonSV_SvABA_comp.txt
python merge_result_final.py ${DISEASE} "../output_comp/${DISEASE}/*.SvABA_GenomonSV.comp.txt" > ../output_comp/${DISEASE}_SvABA_GenomonSV_comp.txt

: <<'#__co'
: <<'#__co'
#__co

