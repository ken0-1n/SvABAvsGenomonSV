
import glob
import sys,os
import pysam

disease = sys.argv[1]
result_txt = sys.argv[2]
header_txt = "anno.header"

cancer_gene = "/home/kchiba/work_directory/work_svaba/database/vogelstein_science_2013.txt"

with open(header_txt, "r") as HI:
    for line in HI:
        line = line.rstrip('\r\n')
        print line

cancer_gene_hash = {}
header_flag = False
with open(cancer_gene, "r") as HI:
    for line in HI:
        if header_flag:
            header_flag = False
            continue
        line = line.rstrip('\r\n')
        key, value = line.split("\t")
        cancer_gene_hash[key] = value

files = glob.glob(result_txt)
for file_name in files:
    header_flag = False
    with open(file_name, "r") as HI:
        for line in HI:
            if header_flag:
                header_flag = False
                continue
            file_name = file_name.rstrip('\n')
            base, ext = os.path.splitext( os.path.basename(file_name) )
            barcode = base.split(".")[0]

            line = line.rstrip('\r\n')
            F = line.split("\t")
            gene1 = F[6]
            if gene1 not in cancer_gene_hash: gene1 = "---"

            print disease +"\t"+ barcode +"\t"+ line + "\t" +gene1

