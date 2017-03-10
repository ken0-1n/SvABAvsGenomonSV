
import sys
import glob

in_m1 = sys.argv[1]
in_m2 = sys.argv[2]

del_hash = {}
ins_hash = {}
with open(in_m2, "r") as hin:

    is_header = True
    for line in hin:
        # skip meta data
        if line.startswith("#"):
            continue
        # skip header line
        if is_header:
            is_header = False
            continue

        F = line.rstrip("\n").split("\t")
        if F[3] == "-":
            ins_hash[F[0] +":"+ F[1]] = 1
        elif F[4] == "-":
            del_hash[F[0] +":"+ F[1]] = 1

with open(in_m1, "r") as hin:
    is_header = True
    for line in hin:
        # skip meta data
        if line.startswith("#"):
            continue
        # skip header line
        if is_header:
            is_header = False
            continue

        is_comp = False
        line = line.rstrip("\n")
        F = line.split("\t")
        if F[3] == "-":
            for chr_pos in ins_hash:
                pos_array = chr_pos.split(":")
                if F[0] == pos_array[0] and (int(pos_array[1]) - 30) < int(F[1]) and int(F[1]) < (int(pos_array[1]) + 30):
                    line = line + chr_pos
                    is_comp = True
                    break
        elif F[4] == "-":
            for chr_pos in del_hash:
                pos_array = chr_pos.split(":")
                if F[0] == pos_array[0] and (int(pos_array[1]) - 30) < int(F[1]) and int(F[1]) < (int(pos_array[1]) + 30):
                    line = line + chr_pos
                    is_comp = True
                    break

        if not is_comp:
            line = line + "---"

        print line

        
