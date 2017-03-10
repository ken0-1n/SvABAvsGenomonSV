
import sys
import glob

in_genomon_mutation_glob = sys.argv[1]
files = glob.glob(in_genomon_mutation_glob)
for in_mutations in files:

    with open(in_mutations, "r") as hin:
        is_header = False
        for line in hin:
            # skip meta data
            if line.startswith("#"):
                continue
            # skip header line
            if is_header:
                is_header = False
                continue

            F = line.rstrip("\n").split("\t")
            print F[0] +"_"+ str(int(F[1])-1) +"_"+ F[2] +"_"+ F[3] +"_"+ F[4] +"\t1"

