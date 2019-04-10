# SvABAvsGenomonSV
The comparison of SvABA and GenomonSV

1. SvABAの実行
2. SvABAの結果(VCF)をGenomon形式に変換する
3. SvABAのコントロールパネルを作成する
4. sv_utils filterでSvABAの結果をフィルタ

## 1. SVABAの実行
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

## 2. SvABAのSV結果(VCF)をGenomon形式に変換する
```
# somaticの場合は引数2を"True"にする。
python VCFtoGenomonSVFormat.py svaba_result.vcf "True"  | sort -u > svaba_result.txt

# normalの場合は引数2を"True"にする。
python VCFtoGenomonSVFormat.py svaba_result.vcf "false"  | sort -u > svaba_result.txt
```

## 3. SvABAのコントロールパネルを作成する
```
# 9470検体分のノーマルリストを作成し、sv_utils merge_controlを実行
sv_utils merge_control all_control_panel.list all_merge_control_svaba
```

## 4. sv_utils filterでSvABAの結果をフィルタ
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
