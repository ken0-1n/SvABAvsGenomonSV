
import glob
import sys,os
import pysam

disease = sys.argv[1]
result_txt = sys.argv[2]
header_txt = "header_svaba.txt"

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
            file_name_array = file_name.split("/")
            base, ext = os.path.splitext( os.path.basename(file_name) )
            barcode = base.split(".")[0]

            line = line.rstrip('\r\n')
            F = line.split("\t")
            gene1 = F[8]
            gene2 = F[9]
            exon1 = F[10]
            exon2 = F[11]
            if gene1 not in cancer_gene_hash: gene1 = "---"
            if gene2 not in cancer_gene_hash: gene2 = "---"
            if exon1 not in cancer_gene_hash: exon1 = "---"
            if exon2 not in cancer_gene_hash: exon2 = "---"

            print disease +"\t"+ barcode +"\t"+ line + "\t" +gene1+ "\t" +gene2+ "\t" + exon1 +"\t"+ exon2

