#!/bin/bash

set -e

# mkdir -p output_genomonSV/normal
# mkdir -p output_svaba/normal

DISEASE=$1

if [ $# -ne 1 ]; then
  echo "wrong number of arguments"
  exit 1
fi

: <<'#__co'
#__co
# -------------------------------------------------------------------------------------
# SvABA
# -------------------------------------------------------------------------------------
# 1.make control panel
for file in ../svaba-germline/${DISEASE}/*.svaba.sv.vcf; do
  bf=`basename $file`;
  echo $bf
  barcode=${bf%.*.*.*}
  echo $barcode
  python VCFtoGenomonSVFormat.py $file $barcode "False" | sort -u > ../svaba-control/${DISEASE}/${bf}.txt
done

ls ../svaba-control/${DISEASE}/*.svaba.sv.vcf.txt > ../svaba-control/${DISEASE}/all_control_panel_svaba.txt.tmp

cat ../svaba-control/${DISEASE}/all_control_panel_svaba.txt.tmp | awk -F "/" '{print $3"\tnormal\t"$0}' | sed -e 's/.svaba.sv.vcf.txt\t/\t/g' > ../svaba-control/${DISEASE}/all_control_panel_svaba.txt

sv_utils merge_control ../svaba-control/${DISEASE}/all_control_panel_svaba.txt ../svaba-control/${DISEASE}/all_merge_control_svaba

# -------------------------------------------------------------------------------------
# GenomonSV
# -------------------------------------------------------------------------------------
# 1.copy genomonSV results without header
for file in ~omega3/omega_project/genomon2_2_0_alpha/${DISEASE}/sv/*/*-1?.genomonSV.result.txt; do
  bf=`basename $file`;
  echo "bf="$bf
  cat $file | awk 'NR>4' > ../genomonsv-control/${DISEASE}/${bf};
done

# 2. make control panel
echo -n > ../genomonsv-control/${DISEASE}/all_control_panel_genomonsv.txt
for file in ../genomonsv-control/${DISEASE}/*-1?.genomonSV.result.txt; do
  bf=`basename $file`
  barcode=${bf%.*.*.*}
  echo "bf="$bf
  echo -e "$barcode\tnormal\t$file" >> ../genomonsv-control/${DISEASE}/all_control_panel_genomonsv.txt
done

sv_utils merge_control ../genomonsv-control/${DISEASE}/all_control_panel_genomonsv.txt ../genomonsv-control/${DISEASE}/all_merge_control_genomonSV

# -------------------------------------------------------------------------------------
# SvABA Indel
# -------------------------------------------------------------------------------------

# normal
for file in ../svaba-germline/${DISEASE}/*.svaba.indel.vcf; do
  bf=`basename $file`;
  echo "bf="$bf
  python svavaIndeltoAnnoFormat.py $file | sort -u > ../svaba-control/${DISEASE}/${bf}.txt;
done

python mapper.py "../svaba-control/${DISEASE}/TCGA-*indel.vcf.txt" | python reducer.py > ../svaba-control/${DISEASE}/svaba_short_indel_blacklist.bed
sort -k1,1 -k2,2n -k3,3n ../svaba-control/${DISEASE}/svaba_short_indel_blacklist.bed > ../svaba-control/${DISEASE}/svaba_short_indel_blacklist_sorted.bed
bgzip -f -c ../svaba-control/${DISEASE}/svaba_short_indel_blacklist_sorted.bed > ../svaba-control/${DISEASE}/svaba_short_indel_blacklist_sorted.bed.gz
tabix -p bed ../svaba-control/${DISEASE}/svaba_short_indel_blacklist_sorted.bed.gz

: <<'#__co'
#__co
<< COMMENTOUT
COMMENTOUT
