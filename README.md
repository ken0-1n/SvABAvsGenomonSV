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

3. Indelの比較
3-1. SvABAの結果(VCF)をGenomonSV形式に変換する
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

### 2-1 SvABA(SV)のコントロールパネルを作成する
```
# SvABAのSV結果(VCF)をGenomonSV形式に変換する。
python VCFtoGenomonSVFormat.py svaba_result.vcf "False"  | sort -u > svaba_result.txt

# 補足
# [2]: Normalのみの場合はFalseを指定する。Tumor/Normalペア解析の結果のVCFとカラム数が異なるため

# 9470検体分のノーマルリストを作成し、sv_utils merge_controlを実行
sv_utils merge_control all_control_panel.list all_merge_control_svaba
```
### 2-2 GenomonSVのコントロールパネルを作成する
```
# 9470検体分のノーマルリストを作成し、sv_utils merge_controlを実行
sv_utils merge_control all_control_panel.list all_merge_control_genomonsv
```
### 2-3 SvABA(InDel)のコントロールパネルを作成する
```
# SvABA(InDel)をAnnovar形式に変換する
python svabaIndeltoAnnovarFormat.py svaba_result_indel.vcf | sort -u > svaba_result_indel.txt
# BED形式に変換してTabixをはる
python mapper.py *svaba_result_indel.txt | python reducer.py > svaba_indel_blacklist.bed
bgzip -f svaba_indel_blacklist.bed.gz
tabix -p bed svaba_indel_blacklist.bed.gz
```

### 3-1. sv_utils filterでSvABAの結果をフィルタ
```
# somaticの場合は引数2を"True"にする。
python VCFtoGenomonSVFormat.py svaba_result.vcf "True"  | sort -u > svaba_result.txt

# フィルタする
sv_utils filter \
    --remove_simple_repeat \
    --re_annotation \
    --pooled_control_file all_merge_control_svaba.bedpe.gz \
    --min_variant_size 100 \
    --inversion_size_thres 1000 \
    svaba_result.txt \
    resource
```

### 3-2. sv_utils filterでGenomonSVの結果をフィルタ
```
sv_utils filter \
    --remove_simple_repeat \
    --pooled_control_file all_merge_control_genomonsv.bedpe.gz \
    --min_tumor_allele_freq 0.05 \
    --min_variant_size 100 \
    --inversion_size_thres 1000 \
    genomon_result.filt.txt \
    resource
```

### 3-3. SvABAとGenomonSVを比較する
```
fusion_utils comp \
    genomon.filtered.txt \
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

### 4-1. SvABAの結果(VCF)をGenomonSV形式に変換する
```
# somaticの場合は引数2を"True"にする。
python VCFtoGenomonSVFormat.py svaba_result.vcf "True"  | sort -u > svaba_result.txt
```
