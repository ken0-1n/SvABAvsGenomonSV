# SvABAvsGenomonSV
The comparison of SvABA and GenomonSV

1. SvABAの実行

2. 9470検体のコントロールパネルを作成
2-1 SvABA(SV)のコントロールパネルを作成する
2-2 GenomonSVのコントロールパネルを作成する
2-3 SvABA(InDel)のコントロールパネルを作成する

3. SVの比較
3-1. sv_utils filterでSvABAの結果をフィルタ
3-2. sv_utils filterでGenomonSVの結果をフィルタ
3-3. SvABAとGenomonSVを比較する

4. Indelの比較
4-1. sv_utils filterでSvABA SVの結果をフィルタ
4-2. SvABA indelの結果をフィルタ
3-2. 
3-3.

### 1. SVABAの実行
```
Program: SvABA
FH Version: 134

# Tumor/Normalペアでrunする。
svaba run -a output_dir -G reference -t tumor.bam -n normal.bam -A -v 1

# Normalシングルでrunする。
svaba run -a output_dir -G reference -t normal.bam -A -v 1

# 補足
# -A --all-contigs  output all contigs, regardless of mapping or length
# -v --verbose       select verbosity level (0-4).
```

### 2. 9470検体のコントロールパネルを作成
2-1 SvABA(SV)のコントロールパネルを作成する
```
# SvABAのSV結果(VCF)をGenomonSV形式に変換する。
python VCFtoGenomonSVFormat.py svaba_result.vcf "False"  | sort -u > svaba_result.txt

# 補足
# argv[2]: Normalのみの場合はFalseを指定する。

# 9470検体分のノーマルリストを作成し、sv_utils merge_controlを実行
sv_utils merge_control all_control_panel.list all_merge_control_svaba
```
2-2 GenomonSVのコントロールパネルを作成する
```
# 9470検体分のノーマルリストを作成し、sv_utils merge_controlを実行
sv_utils merge_control all_control_panel.list all_merge_control_genomonsv
```
2-3 SvABA(InDel)のコントロールパネルを作成する
```
# SvABA(InDel)をAnnovar形式に変換する
python svabaIndeltoAnnovarFormat.py svaba_result_indel.vcf | sort -u > svaba_result_indel.txt
# BED形式に変換してTabixをはる
python mapper.py *svaba_result_indel.txt | python reducer.py > svaba_indel_blacklist.bed
bgzip -f svaba_indel_blacklist.bed.gz
tabix -p bed svaba_indel_blacklist.bed.gz
```

### 3,SVの比較
3-1. SvABAの結果をフィルタする
```
# VCFをGenomonSVフォーマットに変換する
python VCFtoGenomonSVFormat.py svaba_result.vcf "True"  | sort -u > svaba_result.txt

# 補足
# argv[2]: Tumor/Normalペアの場合はTrueを指定する。

# フィルタする
sv_utils filter \
    --remove_simple_repeat \
    --re_annotation \
    --pooled_control_file all_merge_control_svaba.bedpe.gz \
    --min_variant_size 100 \
    --inversion_size_thres 1000 \
    svaba_result.txt \
    svaba.filtered.txt \
    resources
```
3-2. GenomonSVの結果をフィルタする
```
sv_utils filter \
    --remove_simple_repeat \
    --pooled_control_file all_merge_control_genomonsv.bedpe.gz \
    --min_tumor_allele_freq 0.05 \
    --min_variant_size 100 \
    --inversion_size_thres 1000 \
    genomonSV_result.filt.txt \
    genomonSV.filtered.txt \
    resources
```
3-3. SvABAとGenomonSVを比較する
```
fusion_utils comp \
    genomonSV.filtered.txt \
    genomonSV \
    svaba.filtered.txt \
    genomonSV \
    genomon-svaba.result.txt \
    bdtools/bin \
    
fusion_utils comp \
    svaba.filtered.txt \
    genomonSV \
    genomon.filtered.txt \
    genomonSV \
    svaba-genomon.result.txt \
    bdtools/bin \
```
### Indelの比較
4-1. SvABA SVファイルの結果をフィルタする
```
#  VCFをGenomonSVフォーマットに変換する
python VCFtoGenomonSVFormat.py svaba_result.vcf "True"  | sort -u > svaba_result.txt

# フィルタする
sv_utils filter \
    --without_translocation \
    --remove_simple_repeat \
    --re_annotation \
    --pooled_control_file all_merge_control\svaba.bedpe.gz \
    --max_variant_size 100 \
    --min_ins_variant_size 12 \
    --min_del_variant_size 20 \
    svaba_result.txt \
    svaba_filtered_tmp.txt \
    resources
    
# GenomonSVからANNOフォーマットに変換する
python svabaSVtoAnnoFormat.py svaba_filtered_tmp.txt | sort -u > svaba.sv.filtered.txt

```
4-2. SvABA indelファイルの結果をフィルタする
```
# VCFをANNOフォーマットに変換する
python svabaIndeltoAnnoFormat.py svaba.indel.vcf > svaba.indel.vcf

# フィルタする
python blacklist.py svaba.indel.txt svaba_indel_blacklist.bed.gz svaba.indel_filtered.txt svaba.error.txt 10 100 12 20

# 補足
# argv[5]: min_candidate = 10
# argv[6]: max_variant_size = 100
# argv[7]: min_ins_size = 12
# argv[8]: min_del_size = 20 
```
4-3.　4-1.と4-2.で出力したファイルをマージし、アノテーションする
```
cat svaba_filtered.txt svaba.indel_filtered.txt > svaba.sv.indel.filtered.txt

# Annovarでアノテーションする
table_annovar.pl --outfile svaba.sv.indel.anno.txt -buildver hg19 -remove --otherinfo -protocol refGene -operation g svaba.sv.indel.filtered.txt
```
4-4 GenomonSVをフィルタしてアノテーションする
```
sv_utils filter \
    --without_translocation \
    --remove_simple_repeat \
    --pooled_control_file all_merge_control\svaba.bedpe.gz \
    --min_tumor_allele_freq 0.05 \
    --max_variant_size 100 \
    --min_ins_variant_size 12 \
    --min_del_variant_size 20 \
    genomonSV.result.filt.txt \
    genomonSV.filtered.tmp.txt \
    resources
    
# GenomonSVからANNOフォーマットに変換する
python svabaSVtoAnnoFormat.py genomonSV.filtered.tmp.txt | sort -u > genomonSV.filtered.txt

# Annovarでアノテーションする
table_annovar.pl --outfile genomonSV.anno.txt -buildver hg19 -remove --otherinfo -protocol refGene -operation g genomonSV.filtered.txt
```
4-5. SvABAとGenomonSVを比較する
```
python comp_anno.py genomonSV.anno.txt svaba.sv.inde.anno.txt >  genomon-svaba.shortSV.txt
python comp_anno.py svaba.sv.inde.anno.txt genomonSV.anno.txt >  svaba-genomon.shortSV.txt
```
