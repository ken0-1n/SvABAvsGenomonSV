import sys
import os
import re
import logging
import pysam

vcffile = open(sys.argv[1],'r')
is_somatic = sys.argv[2] #True/False

for line in vcffile:
    line = line.rstrip()
    
    if line.startswith("#"): continue

    record = line.split('\t')

    chr1 = record[0]
    pos1 = record[1]
    ID = record[2]
    ref = record[3]
    alt = record[4]
    qual = record[5]
    info = record[7]
    fmt = record[9]
    if is_somatic == "True":
        fmt = record[10]

    freq_item = fmt.split(':')
    tumor_var = freq_item[1]

    pattern1 = re.compile("[A-Za-z]\][A-Za-z0-9]+:[0-9]+\]")
    pattern2 = re.compile("[A-Za-z]\[[A-Za-z0-9]+:[0-9]+\[")
    pattern3 = re.compile("\][A-Za-z0-9]+:[0-9]+\][A-Za-z]+")
    pattern4 = re.compile("\[[A-Za-z0-9]+:[0-9]+\[[A-Za-z]+")

    match1 = pattern1.match(alt)
    match2 = pattern2.match(alt)
    match3 = pattern3.match(alt)
    match4 = pattern4.match(alt)

    dir1 = ""
    dir2 = ""
    chr_pos = []

    if match1:
      alt_list = (match1.group(0)).split("]")[1]
      chr_pos = alt_list.split(":")
      dir1 = "+"
      dir2 = "+"
    elif match2:
      alt_list = (match2.group(0)).split("[")[1]
      chr_pos = alt_list.split(":")
      dir1 = "+"
      dir2 = "-"
    elif match3:
      alt_list = (match3.group(0)).split("]")[1]
      chr_pos = alt_list.split(":")
      dir1 = "-"
      dir2 = "+"
    elif match4:
      alt_list = (match4.group(0)).split("[")[1]
      chr_pos = alt_list.split(":")
      dir1 = "-"
      dir2 = "-"
      
    chr2 = chr_pos[0]
    pos2 = chr_pos[1]

    if chr1 > chr2 or chr1 == chr2 and int(pos1) > int(pos2):
        chr1, chr2, pos1, pos2, dir1, dir2 = chr2, chr1, pos2, pos1, dir2, dir1

    variant_type = "translocation"
    if chr1 == chr2:
      if dir1 == "+" and dir2 == "-":
        variant_type = "deletion"
      elif dir1 == "-" and dir2 == "+":
        variant_type = "tandem_duplication"
      elif dir1 == dir2:
        variant_type = "inversion"

    # print chr1 + '\t' + pos1 + '\t' + dir1 + '\t' + chr2 + '\t' + pos2 + '\t' + dir2 + "\t" + qual + "\t---\t---\t---\t---\t---\t" + tumor_ref +"\t"+ tumor_var
    print chr1 + '\t' + pos1 + '\t' + dir1 + '\t' + chr2 + '\t' + pos2 + '\t' + dir2 + "\t" + qual + "\t"+ variant_type +"\t---\t---\t---\t---\t---\t"+ tumor_var
        

####
vcffile.close()


