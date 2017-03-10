#!/bin/bash
#
#$ -S /bin/bash         # set shell in UGE
#$ -cwd                 # execute at the submitted dir
#$ -o log -e log

disease=$1

: <<'#__co'
#__co

mkdir -p output_svaba/${disease}
mkdir -p output_svaba_shortSV/${disease}
mkdir -p output_genomonSV/${disease}
mkdir -p output_genomonSV_shortSV/${disease}
mkdir -p output_comp/${disease}
mkdir -p output_comp_shortSV/${disease}

: <<'#__co'
#__co
: <<'#__co'
#__co
# 1. format change
# tumor
for file in ../output/${disease}/*/*.svaba.somatic.sv.vcf; do
  bf=`basename $file`;
  echo $bf
  python VCFtoGenomonSVFormat.py $file "True" | sort -u > output_svaba_shortSV/${disease}/${bf}.txt;
done

# tumor
for file in ../output/${disease}/*/*.svaba.somatic.indel.vcf; do
  bf=`basename $file`;
  echo $bf
  python svavaIndeltoAnnoFormat.py $file | sort -u > output_svaba_shortSV/${disease}/${bf}.txt;
done

# 1-3. filtering svaba results
for file in output_svaba_shortSV/${disease}/*.svaba.somatic.sv.vcf.txt; do
  bf=`basename ${file%.*}`
  echo $bf
  ~/.local/bin/sv_utils filter --without_translocation --remove_simple_repeat --re_annotation --pooled_control_file output_svaba/all_merge_control_svaba.bedpe.gz --max_variant_size 100 --min_ins_variant_size 12 --min_del_variant_size 20 $file output_svaba_shortSV/${disease}/${bf}.filtered.tmp.txt /home/kchiba/work_directory/work_svaba/sv_utils-0.4.0beta/resource

  python svavaSVtoAnnoFormat.py output_svaba_shortSV/${disease}/${bf}.filtered.tmp.txt | sort -u > output_svaba_shortSV/${disease}/${bf}.filtered.txt
done

for file in output_svaba_shortSV/${disease}/*.svaba.somatic.indel.vcf.txt; do
  bf=`basename ${file%.*}`
  echo $bf
  python blacklist.py $file output_svaba/svaba_short_indel_blacklist_sorted.bed.gz output_svaba_shortSV/${disease}/${bf}.filtered.txt output_svaba_shortSV/${disease}/${bf}.blacklist.txt 10 100 12 20
done

for file in output_svaba_shortSV/${disease}/*.svaba.somatic.sv.vcf.filtered.txt; do
  bf=`basename ${file%.*}`
  barcode=${bf%.*.*.*.*.*}
  cat $file output_svaba_shortSV/${disease}/${barcode}.svaba.somatic.indel.vcf.filtered.txt > output_svaba_shortSV/${disease}/${barcode}.svaba.somatic.sv.indel.filtered.txt

  /home/kchiba/tools/annovar/table_annovar.pl --outfile output_svaba_shortSV/${disease}/${barcode}.svaba.somatic.sv.indel.filtered -buildver hg19 -remove --otherinfo -protocol refGene -operation g output_svaba_shortSV/${disease}/${barcode}.svaba.somatic.sv.indel.filtered.txt /home/kchiba/tools/annovar/humandb
done

# 2. copy genomonSV results without header
for file in /home/kchiba/work_directory/work_svaba/database/omega_SV/${disease}/*.genomonSV.result.filt3.txt; do
  bf=`basename $file`;
  echo $bf
  barcode=${bf%.*.*.*.*}
  # cat $file | awk 'NR>4' > output_genomonSV_shortSV/${disease}/${bf};
  cat $file | awk 'NR>1' > output_genomonSV_shortSV/${disease}/${barcode}.genomonSV.result.txt;
done

# 2-2. filtering genomonSV results
for file in output_genomonSV_shortSV/${disease}/*-0?.genomonSV.result.txt; do
  bf=`basename $file`
  barcode=${bf%.*.*.*}
  echo $barcode
  ~/.local/bin/sv_utils filter --without_translocation --remove_simple_repeat --pooled_control_file output_genomonSV/all_merge_control_genomonSV.bedpe.gz  --min_tumor_allele_freq 0.05 --max_variant_size 100 --min_ins_variant_size 12 --min_del_variant_size 20 $file output_genomonSV_shortSV/${disease}/${barcode}.genomonSV.result.filtered.tmp.txt /home/kchiba/work_directory/work_svaba/sv_utils-0.4.0beta/resource

  python genomonSVtoAnnoFormat.py output_genomonSV_shortSV/${disease}/${barcode}.genomonSV.result.filtered.tmp.txt > output_genomonSV_shortSV/${disease}/${barcode}.genomonSV.result.filtered.txt

  /home/kchiba/tools/annovar/table_annovar.pl --outfile output_genomonSV_shortSV/${disease}/${barcode}.genomonSV.result.filtered -buildver hg19 -remove --otherinfo -protocol refGene -operation g output_genomonSV_shortSV/${disease}/${barcode}.genomonSV.result.filtered.txt /home/kchiba/tools/annovar/humandb
done

# 3. comp genomonSV and svaba 
for file in output_genomonSV_shortSV/${disease}/*-0?.genomonSV.result.filtered.hg19_multianno.txt; do
  bf=`basename $file`
  barcode=${bf%.*.*.*.*.*}
  echo $barcode
  python comp_anno.py ${file} output_svaba_shortSV/${disease}/${barcode}.svaba.somatic.sv.indel.filtered.hg19_multianno.txt > output_comp_shortSV/${disease}/${barcode}.GenomonSV_SvABA.comp.txt 
  python comp_anno.py output_svaba_shortSV/${disease}/${barcode}.svaba.somatic.sv.indel.filtered.hg19_multianno.txt ${file} > output_comp_shortSV/${disease}/${barcode}.SvABA_GenomonSV.comp.txt
done

# 4. merge results file
python merge_result_final1_shortSV.py $disease "output_comp_shortSV/${disease}/*.GenomonSV_SvABA.comp.txt" > output_comp_shortSV/${disease}_GenomonSV_SvABA_comp_shortSV.txt
python merge_result_final1_shortSV.py $disease "output_comp_shortSV/${disease}/*.SvABA_GenomonSV.comp.txt" > output_comp_shortSV/${disease}_SvABA_GenomonSV_comp_shortSV.txt

#__co
#__co
#__co

