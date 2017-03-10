#!/bin/bash
#
#$ -S /bin/bash         # set shell in UGE
#$ -cwd                 # execute at the submitted dir
#$ -o log -e log

disease=$1

: <<'#__co'
#__co

mkdir -p output_svaba/${disease}
mkdir -p output_genomonSV/${disease}
mkdir -p output_comp/${disease}

# 1. format change
# tumor
for file in ../output/${disease}/*/*.svaba.somatic.sv.vcf; do
  bf=`basename $file`;
  echo $bf
  python VCFtoGenomonSVFormat.py $file "True" | sort -u > output_svaba/${disease}/${bf}.txt;
done

# 1-3. filtering svaba results
for file in output_svaba/${disease}/*.svaba.somatic.sv.vcf.txt; do
  bf=`basename ${file%.*}`
  echo $bf
  ~/.local/bin/sv_utils filter --remove_simple_repeat --re_annotation --pooled_control_file output_svaba/all_merge_control_svaba.bedpe.gz --min_variant_size 100 --inversion_size_thres 1000 $file output_svaba/${disease}/${bf}.filtered.txt /home/kchiba/work_directory/work_svaba/sv_utils-0.4.0beta/resource
done

# 2. copy genomonSV results without header
#for file in ~omega3/omega_project/genomon2_2_0_alpha/${disease}/sv/*/*.genomonSV.result.txt; do
for file in /home/kchiba/work_directory/work_svaba/database/omega_SV/${disease}/*.genomonSV.result.filt3.txt; do
  bf=`basename $file`;
  echo $bf
  barcode=${bf%.*.*.*.*}
  # cat $file | awk 'NR>4' > output_genomonSV/${disease}/${bf};
  cat $file | awk 'NR>1' > output_genomonSV/${disease}/${barcode}.genomonSV.result.txt;
done

# 2-2. filtering genomonSV results
for file in output_genomonSV/${disease}/*-0?.genomonSV.result.txt; do
  bf=`basename $file`
  barcode=${bf%.*.*.*}
  echo $barcode
  ~/.local/bin/sv_utils filter --remove_simple_repeat --pooled_control_file output_genomonSV/all_merge_control_genomonSV.bedpe.gz  --min_tumor_allele_freq 0.05 --min_variant_size 100 --inversion_size_thres 1000 $file output_genomonSV/${disease}/${barcode}.genomonSV.result.filtered.txt /home/kchiba/work_directory/work_svaba/sv_utils-0.4.0beta/resource
done

# 3. comp genomonSV and svaba 
for file in output_genomonSV/${disease}/*-0?.genomonSV.result.filtered.txt; do
  bf=`basename $file`
  barcode=${bf%.*.*.*.*}
  echo $barcode
  ~/.local/bin/fusion_utils comp ${file} genomonSV output_svaba/${disease}/${barcode}.svaba.somatic.sv.vcf.filtered.txt genomonSV output_comp/${disease}/${barcode}.GenomonSV_SvABA.comp.txt /home/w3varann/genomon_pipeline-2.2.0/tools/bedtools-2.24.0/bin
  ~/.local/bin/fusion_utils comp output_svaba/${disease}/${barcode}.svaba.somatic.sv.vcf.filtered.txt genomonSV ${file} genomonSV output_comp/${disease}/${barcode}.SvABA_GenomonSV.comp.txt /home/w3varann/genomon_pipeline-2.2.0/tools/bedtools-2.24.0/bin
done

# 4. merge results file
python merge_result_final.py $disease "output_comp/${disease}/*.GenomonSV_SvABA.comp.txt" > output_comp/${disease}_GenomonSV_SvABA_comp.txt
python merge_result_final2.py $disease  "output_comp/${disease}/*.SvABA_GenomonSV.comp.txt" > output_comp/${disease}_SvABA_GenomonSV_comp.txt

#__co

