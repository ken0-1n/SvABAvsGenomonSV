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
    ins_seq = record[6]
    sv_type = record[7]
    region = ""

    if sv_type == "deletion":
        region = chr1+":"+pos1+"-"+str(int(pos2)-1)
    elif sv_type == "tandem_duplication":
        region = chr1+":"+pos1+"-"+pos2
        
    proc = subprocess.Popen(['samtools','faidx',fasta,region],stdout=subprocess.PIPE,)
    stdout_value = proc.communicate()[0]
    seq = stdout_value.split('\n')[1]

    chrom = chr1
    start = 0
    end = 0
    ref = ""
    alt = ""

    if sv_type == "deletion":
        start = int(pos1)
        end = int(pos2)-1
        ref = seq
        alt = "-"

    elif sv_type == "tandem_duplication":
        start = int(pos1)
        end = int(pos1)
        ref = "-"
        alt = seq
        if ins_seq != "---":
            alt = alt + ins_seq

    print chrom +"\t"+ str(start) +"\t"+ str(end) +"\t"+ ref +"\t"+ alt

    '''
    if sv_type == "deletion" and ins_seq != "---":
        start = int(pos2)
        end = int(pos2)
        ref = "-"
        alt = ins_seq
        print chrom +"\t"+ str(start) +"\t"+ str(end) +"\t"+ ref +"\t"+ alt
    '''

####
sv_filt.close()


