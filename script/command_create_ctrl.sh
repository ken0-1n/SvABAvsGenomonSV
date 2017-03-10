#!/bin/bash

mkdir -p output_genomonSV/normal
mkdir -p output_svaba/normal

: <<'#__co'
#__co
# -------------------------------------------------------------------------------------
# SvABA
# -------------------------------------------------------------------------------------
# 1.make control panel
for file in ../output/*/*/*.svaba.sv.vcf; do
  bf=`basename $file`;
  echo $bf
  python VCFtoGenomonSVFormat.py $file "False" | sort -u > output_svaba/normal/${bf}.txt
done

ls /home/kchiba/work_directory/work_svaba/script/output_svaba/normal/*.svaba.sv.vcf.txt > output_svaba/all_control_panel_svaba.txt.tmp

cat output_svaba/all_control_panel_svaba.txt.tmp | awk -F "/" '{print $9"\tnormal\t"$0}' | sed -e 's/.svaba.sv.vcf.txt\t/\t/g' > output_svaba/all_control_panel_svaba.txt

~/.local/bin/sv_utils merge_control output_svaba/all_control_panel_svaba.txt output_svaba/all_merge_control_svaba

# -------------------------------------------------------------------------------------
# GenomonSV
# -------------------------------------------------------------------------------------
# 1.copy genomonSV results without header
for file in ~omega3/omega_project/genomon2_2_0_alpha/*/sv/*/*-1?.genomonSV.result.txt; do
  bf=`basename $file`;
  echo $bf
  cat $file | awk 'NR>4' > output_genomonSV/normal/${bf};
done

# 2. make control panel
echo -n > output_genomonSV/all_control_panel_genomonsv.txt

for file in /home/kchiba/work_directory/work_svaba/script/output_genomonSV/normal/*-1?.genomonSV.result.txt; do
  bf=`basename $file`
  barcode=${bf%.*.*.*}
  echo $barcode
  echo -e "$barcode\tnormal\t$file" >> output_genomonSV/all_control_panel_genomonsv.txt
done

~/.local/bin/sv_utils merge_control output_genomonSV/all_control_panel_genomonsv.txt output_genomonSV/all_merge_control_genomonSV

# -------------------------------------------------------------------------------------
# SvABA Indel
# -------------------------------------------------------------------------------------

# normal
for file in ../output/*/*/*.svaba.indel.vcf; do
  bf=`basename $file`;
  echo $bf
  python svavaIndeltoAnnoFormat.py $file | sort -u > output_svaba/normal/${bf}.txt;
done

python mapper.py "output_svaba/normal/TCGA-*indel.vcf.txt" | python reducer.py > output_svaba/svaba_short_indel_blacklist.bed
sort -k1,1 -k2,2n -k3,3n output_svaba/svaba_short_indel_blacklist.bed > output_svaba/svaba_short_indel_blacklist_sorted.bed
bgzip -f -c output_svaba/svaba_short_indel_blacklist_sorted.bed > output_svaba/svaba_short_indel_blacklist_sorted.bed.gz
tabix -p bed output_svaba/svaba_short_indel_blacklist_sorted.bed.gz

: <<'#__co'
#__co
