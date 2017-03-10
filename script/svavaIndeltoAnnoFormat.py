import sys
import os
import re
import logging
import pysam

vcffile = open(sys.argv[1],'r')

for line in vcffile:
    line = line.rstrip()
    
    if line.startswith("#"): continue

    record = line.split('\t')

    chr_org = record[0]
    start_org = record[1]
    end_org = record[1]
    ID = record[2]
    ref = record[3]
    alt = record[4]

    start = int(start_org)
    ref_len = len(ref)
    alt_len = len(alt)
    
    # SNV
    if alt_len == 1 and ref_len == 1:
        end = int(end_org)

    # deletion
    elif alt_len < ref_len and ref.startswith(alt):
        ref = ref[alt_len:]
        start = start + ref_len - len(ref)
        end = start + len(ref) - 1
        alt = '-'

    # insertion
    elif alt_len > ref_len and alt.startswith(ref):
        alt = alt[ref_len:]
        start = start + alt_len - len(alt)
        end = start
        ref = '-'

    # block substitution 1
    else:
        # print >> sys.stderr, chr_org +"\t"+ start_org +"\t"+ end_org+"\t"+ ref +"\t"+ alt +"\t"+ HGMDID
        continue

    print chr_org +"\t"+ str(start) +"\t"+ str(end) +"\t"+ ref +"\t"+ alt
                
####
vcffile.close()


