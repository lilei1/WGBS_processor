#!/usr/bin/env python3

import os
import sys
import errno
import argparse

def parse_args(args=None):
    Description = "Reformat nf-core/methylseq samplesheet file and check its contents."
    Epilog = "Example usage: python check_samplesheet.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    return parser.parse_args(args)

def make_dir(path):
    if len(path) > 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise exception

def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check samplesheet -> {}".format(error)
    if context != "" and context_str != "":
        error_str = "ERROR: Please check samplesheet -> {}\n{}: '{}'".format(
            error, context, context_str.strip()
        )
    print(error_str)
    sys.exit(1)

def check_samplesheet(file_in, file_out):
    """
    This function checks that the samplesheet follows the following structure:
    sample_id,fastq_1,fastq_2,condition
    """
    sample_mapping_dict = {}
    with open(file_in, "r") as fin:
        ## Check header
        MIN_COLS = 4
        HEADER = ["sample_id", "fastq_1", "fastq_2", "condition"]
        header = [x.strip('"') for x in fin.readline().strip().split(",")]
        if header[: len(HEADER)] != HEADER:
            print("ERROR: Please check samplesheet header -> {} != {}".format(",".join(header), ",".join(HEADER)))
            sys.exit(1)

        ## Check sample entries
        for line_idx, line in enumerate(fin, 2):
            if line.strip():
                lspl = [x.strip().strip('"') for x in line.strip().split(",")]
                
                # Check valid number of columns per row
                if len(lspl) < len(HEADER):
                    print_error(
                        "Invalid number of columns (minimum = {})!".format(len(HEADER)),
                        "Line",
                        line,
                    )
                num_cols = len([x for x in lspl if x])
                if num_cols < MIN_COLS:
                    print_error(
                        "Invalid number of populated columns (minimum = {})!".format(MIN_COLS),
                        "Line",
                        line,
                    )

                ## Check sample name entries
                sample_id, fastq_1, fastq_2, condition = lspl[: len(HEADER)]
                if sample_id.find(" ") != -1:
                    print_error("Sample ID contains spaces!", "Line", line)
                if not sample_id:
                    print_error("Sample ID not specified!", "Line", line)

                ## Check FastQ file extension
                for fastq in [fastq_1, fastq_2]:
                    if fastq:
                        if fastq.find(" ") != -1:
                            print_error("FastQ file contains spaces!", "Line", line)
                        if not fastq.endswith(".fastq.gz") and not fastq.endswith(".fq.gz"):
                            print_error(
                                "FastQ file does not have extension '.fastq.gz' or '.fq.gz'!",
                                "Line",
                                line,
                            )

                ## Auto-detect paired-end/single-end
                sample_info = []
                if sample_id and fastq_1 and fastq_2:  ## Paired-end short reads
                    sample_info = [sample_id, fastq_1, fastq_2, condition]
                else:
                    print_error("Invalid combination of columns provided!", "Line", line)

                ## Create sample mapping dictionary with metadata
                sample_info = sample_info + [line_idx]
                if sample_id not in sample_mapping_dict:
                    sample_mapping_dict[sample_id] = [sample_info]
                else:
                    if sample_info in sample_mapping_dict[sample_id]:
                        print_error("Samplesheet contains duplicate rows!", "Line", line)
                    else:
                        sample_mapping_dict[sample_id].append(sample_info)

    ## Write validated samplesheet with appropriate columns
    if len(sample_mapping_dict) > 0:
        out_dir = os.path.dirname(file_out)
        make_dir(out_dir)
        with open(file_out, "w") as fout:
            fout.write(",".join(["sample_id", "fastq_1", "fastq_2", "condition"]) + "\n")
            for sample_id in sorted(sample_mapping_dict.keys()):
                for idx, sample_info in enumerate(sample_mapping_dict[sample_id]):
                    fout.write(",".join(sample_info[:-1]) + "\n")
    else:
        print_error("No entries to process!", "Samplesheet: {}".format(file_in))

def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.FILE_IN, args.FILE_OUT)

if __name__ == "__main__":
    main()