# SvABAvsGenomonSV
The comparison of SvABA and GenomonSV

1. SvABAの実行
2. SVの比較
2-1. SvABAの結果(VCF)をGenomon形式に変換する
2-2. SvABAの9470検体分のコントロールパネルを作成する
2-3. sv_utils filterでSvABAの結果をフィルタ
2-4. GenomonSVの9470検体分のコントロールパネルを作成する
2-5. sv_utils filterでGenomonSVの結果をフィルタ
2-6. SvABAとGenomonSVを比較する
3. Indelの比較
3-1.
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

### 2-1. SvABAのSV結果(VCF)をGenomon形式に変換する
```
# somaticの場合は引数2を"True"にする。
python VCFtoGenomonSVFormat.py svaba_result.vcf "True"  | sort -u > svaba_result.txt

# normalの場合は引数2を"True"にする。
python VCFtoGenomonSVFormat.py svaba_result.vcf "false"  | sort -u > svaba_result.txt
```

### 2-2. SvABAのコントロールパネルを作成する
```
# 9470検体分のノーマルリストを作成し、sv_utils merge_controlを実行
sv_utils merge_control all_control_panel.list all_merge_control_svaba
```

## 2-3. sv_utils filterでSvABAの結果をフィルタ
```
sv_utils filter \
    --remove_simple_repeat \
    --re_annotation \
    --pooled_control_file all_merge_control_svaba.bedpe.gz \
    --min_variant_size 100 \
    --inversion_size_thres 1000 \
    svaba_result.txt \
    resource
```

### 2-4. GenomonSVのコントロールパネルを作成する
```
# 9470検体分のノーマルリストを作成し、sv_utils merge_controlを実行
sv_utils merge_control all_control_panel.list all_merge_control_genomonsv
```

## 2-5. sv_utils filterでGenomonSVの結果をフィルタ
```
sv_utils filter \
    --remove_simple_repeat \
    --pooled_control_file all_merge_control_genomonsv.bedpe.gz \
    --min_tumor_allele_freq 0.05 \
    --min_variant_size 100 \
    --inversion_size_thres 1000 \
    svaba_result.txt \
    resource
```

## 2-5. SvABAとGenomonSVを比較する
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
