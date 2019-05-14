import sys
import os
import re
import math
from scipy import stats
import logging

# logging.basicConfig(level=logging.DEBUG)

vcffile = open(sys.argv[1],'r')
base_filename = sys.argv[2]
is_somatic = sys.argv[3] #True/False

def get_sample_idx(line, barcode):
  header_record = line.split('\t')
  idx = header_record[9].find(barcode)
  if idx > -1:
    tumor_idx = 9
    normal_idx = 10
    return tumor_idx, normal_idx
  idx = header_record[10].find(barcode)
  if idx > -1:
    tumor_idx = 10
    normal_idx = 9
    return tumor_idx, normal_idx

def get_format_key_index(record, key):
    format_keys = record[8]
    format_key_list = format_keys.split(':')
    return format_key_list.index(key)

def get_format_value(record, sample_idx, format_idx):
    fmt_t = record[sample_idx]
    freq_item = fmt_t.split(':')
    return freq_item[format_idx]

def get_sample_value(record, sample_idx, format_key):
    format_idx = get_format_key_index(record, format_key)
    return get_format_value(record, sample_idx, format_idx)

def get_info_value(record, info_key):
    ret = ""
    info = record[7]
    info_list = info.split(";")
    for infos in info_list:
      if infos.startswith(info_key):
        key_val = infos.split("=")
        ret = key_val[1]
        break
    return ret

def get_alt_value(record):
    alt = record[4]
    pattern1 = re.compile("[A-Za-z]\][A-Za-z0-9.]+:[0-9]+\]")
    pattern2 = re.compile("[A-Za-z]\[[A-Za-z0-9.]+:[0-9]+\[")
    pattern3 = re.compile("\][A-Za-z0-9.]+:[0-9]+\][A-Za-z]+")
    pattern4 = re.compile("\[[A-Za-z0-9.]+:[0-9]+\[[A-Za-z]+")

    match1 = pattern1.match(alt)
    match2 = pattern2.match(alt)
    match3 = pattern3.match(alt)
    match4 = pattern4.match(alt)

    if match1:
        alt_list = (match1.group(0)).split("]")[1]
        dir1 = "+"
        dir2 = "+"
    elif match2:
        alt_list = (match2.group(0)).split("[")[1]
        dir1 = "+"
        dir2 = "-"
    elif match3:
        alt_list = (match3.group(0)).split("]")[1]
        dir1 = "-"
        dir2 = "+"
    elif match4:
        alt_list = (match4.group(0)).split("[")[1]
        dir1 = "-"
        dir2 = "-"

    chr_pos = alt_list.split(":")
    return chr_pos[0], chr_pos[1], dir1, dir2

def get_variant_type(chr1,chr2,dir1,dir2):
    variant_type = "translocation"
    if chr1 == chr2:
        if dir1 == "+" and dir2 == "-":
            variant_type = "deletion"
        elif dir1 == "-" and dir2 == "+":
            variant_type = "tandem_duplication"
        elif dir1 == dir2:
            variant_type = "inversion"
    return variant_type

# main
tumor_idx = -1
normal_idx = -1
barcode = base_filename.split('.')[0]

for line in vcffile:
    line = line.rstrip()
    
    # meta data
    if line.startswith("##"): continue
    # header
    if line.startswith("#"):
        tumor_idx, normal_idx = get_sample_idx(line, barcode)
        continue

    record = line.split('\t')
    chr1 = record[0]
    pos1 = record[1]
    ref = record[3]
    qual = record[5]

    # alt
    chr2, pos2, dir1, dir2 = get_alt_value(record)

    # info
    insertion = get_info_value(record, "INSERTION")

    if chr1 > chr2 or chr1 == chr2 and int(pos1) > int(pos2):
        chr1, chr2, pos1, pos2, dir1, dir2 = chr2, chr1, pos2, pos1, dir2, dir1

    variant_type = get_variant_type(chr1, chr2, dir1, dir2)

    # format
    tumor_dp = get_sample_value(record, tumor_idx, 'DP')
    tumor_ad = get_sample_value(record, tumor_idx, 'AD')
    # if float(tumor_dp) > 0: tumor_vaf = round(float(tumor_ad) / float(tumor_dp), 3) 
    tumor_vaf = 0
    if float(tumor_ad) > 0:
        tumor_vaf = round(float(tumor_ad) / (float(tumor_dp) + float(tumor_ad)), 3) 

    logging.debug('C: '+line)
    logging.debug(is_somatic)

    if is_somatic == "True":
        # format normal
        normal_dp = get_sample_value(record, normal_idx, 'DP')
        normal_ad = get_sample_value(record, normal_idx, 'AD')
        normal_vaf = 0
        # if float(normal_dp) > 0: normal_vaf = round(float(normal_ad) / float(normal_dp), 3) 
        if float(normal_ad) > 0:
            normal_vaf = round(float(normal_ad) / (float(normal_dp) + float(normal_ad)), 3) 

        print chr1 +'\t'+ pos1 +'\t'+ dir1 +'\t'+ chr2 +'\t'+ pos2 +'\t'+ dir2 +"\t"+ \
            insertion +"\t"+ \
            variant_type +'\t'+ \
            "---\t---\t---\t---\t"+ \
            str(tumor_dp) +'\t'+ str(tumor_ad) +'\t'+ str(tumor_vaf) +'\t'+ \
            str(normal_dp) +'\t'+ str(normal_ad) +'\t'+ str(normal_vaf) +'\t'+ \
            "---\t---\t---\t---\t---\t" + qual
    else:
        print chr1 +'\t'+ pos1 +'\t'+ dir1 +'\t'+ chr2 +'\t'+ pos2 +'\t'+ dir2 +"\t"+ \
            insertion +"\t"+ \
            variant_type +'\t'+ \
            "---\t---\t---\t---\t"+ \
            tumor_dp +'\t'+ tumor_ad +'\t'+ str(tumor_vaf) +'\t'+ \
            "---\t---\t---\t---\t---\t" + qual
        
####
vcffile.close()


