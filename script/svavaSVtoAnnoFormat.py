import sys
import os
import re
import logging
import subprocess

sv_filt = open(sys.argv[1],'r')

fasta = "/home/w3varann/genomon_pipeline-2.2.0/database/GRCh37/GRCh37.fa"

for line in sv_filt:
    line = line.rstrip()
    
    if line.startswith("#"): continue

    record = line.split('\t')

    chr1 = record[0]
    pos1= record[1]
    pos2= record[4]
    sv_type = record[7]

    chrom = chr1
    start = 0
    end = 0
    ref = ""
    alt = ""
    if sv_type == "deletion":
        start = int(pos1)
        end = int(pos2)
    elif sv_type == "tandem_duplication":
        start = int(pos1)+1
        end = int(pos2)+1

    region = chrom+":"+str(start)+"-"+str(end)
    proc = subprocess.Popen(['samtools','faidx',fasta,region],stdout=subprocess.PIPE,)
    stdout_value = proc.communicate()[0]
    seq = stdout_value.split('\n')[1]

    if sv_type == "deletion":
        ref = seq
        alt = "-"
    elif sv_type == "tandem_duplication":
        end = start
        ref = "-"
        alt = seq

    print chrom +"\t"+ str(start) +"\t"+ str(end) +"\t"+ ref +"\t"+ alt


####
sv_filt.close()


