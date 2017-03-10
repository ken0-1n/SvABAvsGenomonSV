import sys
import os
import pysam
import glob

in_genomon_mutation = sys.argv[1]
blacklist_tabix = sys.argv[2]
result_file = sys.argv[3]
black_result = sys.argv[4]
min_candidate = sys.argv[5]
max_variant_size = sys.argv[6]
min_ins_size = sys.argv[7]
min_del_size = sys.argv[8]

tb = pysam.TabixFile(blacklist_tabix)

hout = open(result_file, 'w')
hout_black = open(black_result, 'w')
is_header = False
with open(in_genomon_mutation, 'r') as hin:
    for line in hin:

        print_flag = True
        # skip meta data
        if line.startswith("#"):
            print >> hout, line.rstrip('\n')
            continue
        if is_header:
            header = line
            ghi.set_header_information(header)
            print >> hout, header.rstrip('\n')
            is_header = False
            continue
        try:
            F = line.rstrip('\n').split('\t')
            chr_in = F[0]
            start_in = F[1]
            end_in = F[2]
            ref_in = F[3]
            alt_in = F[4]
            if len(ref_in) > int(max_variant_size) or len(alt_in) > int(max_variant_size): continue
            if ref_in == "-" and len(alt_in) < int(min_ins_size): continue
            if alt_in == "-" and len(ref_in) < int(min_del_size): continue

            records = tb.fetch(chr_in, (int(start_in) - 1), int(end_in))
            for record_line in records:
                record = record_line.split('\t')
                ref_tb = record[3]
                alt_tb = record[4]
                sample_num = record[5]

                if ref_in == ref_tb and alt_in == alt_tb and int(sample_num) >= int(min_candidate):
                    print >> hout_black, line.rstrip("\n")
                    print_flag = False
                    break

            if print_flag:
                    print >> hout, line.rstrip("\n")

        except ValueError:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            # print >> sys.stderr, fname


