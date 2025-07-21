#!/usr/bin/env python3
"""
Generate synthetic WGBS test data for pipeline testing
"""

import os
import gzip
import random
import argparse
from pathlib import Path

def generate_bisulfite_read(length=150, gc_content=0.4):
    """Generate a synthetic bisulfite-converted read"""
    bases = ['A', 'T', 'G', 'C']
    
    # Generate base sequence with specified GC content
    sequence = []
    for _ in range(length):
        if random.random() < gc_content:
            sequence.append(random.choice(['G', 'C']))
        else:
            sequence.append(random.choice(['A', 'T']))
    
    # Simulate bisulfite conversion (C -> T conversion)
    converted_seq = []
    for base in sequence:
        if base == 'C' and random.random() < 0.95:  # 95% conversion rate
            converted_seq.append('T')
        else:
            converted_seq.append(base)
    
    return ''.join(converted_seq)

def generate_quality_string(length=150):
    """Generate quality scores (Phred+33)"""
    # Generate mostly high-quality scores (30-40)
    qualities = []
    for _ in range(length):
        qual = random.randint(25, 40)
        qualities.append(chr(qual + 33))
    return ''.join(qualities)

def generate_fastq_pair(sample_name, num_reads=10000, read_length=150):
    """Generate paired-end FASTQ files"""
    
    r1_reads = []
    r2_reads = []
    
    for i in range(num_reads):
        # Generate read pair
        r1_seq = generate_bisulfite_read(read_length)
        r2_seq = generate_bisulfite_read(read_length)
        
        r1_qual = generate_quality_string(read_length)
        r2_qual = generate_quality_string(read_length)
        
        # FASTQ format
        read_id = f"@{sample_name}_{i+1:06d}"
        
        r1_reads.extend([
            f"{read_id}/1",
            r1_seq,
            "+",
            r1_qual
        ])
        
        r2_reads.extend([
            f"{read_id}/2", 
            r2_seq,
            "+",
            r2_qual
        ])
    
    return r1_reads, r2_reads

def write_fastq_gz(reads, filename):
    """Write reads to gzipped FASTQ file"""
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    with gzip.open(filename, 'wt') as f:
        for line in reads:
            f.write(line + '\n')

def main():
    parser = argparse.ArgumentParser(description='Generate test WGBS data')
    parser.add_argument('--outdir', default='assets/test_data/fastq', 
                       help='Output directory for test data')
    parser.add_argument('--reads', type=int, default=10000,
                       help='Number of reads per sample')
    parser.add_argument('--length', type=int, default=150,
                       help='Read length')
    
    args = parser.parse_args()
    
    # Sample information
    samples = [
        ('test_cancer_1', 'cancer'),
        ('test_cancer_2', 'cancer'), 
        ('test_healthy_1', 'healthy'),
        ('test_healthy_2', 'healthy')
    ]
    
    print(f"Generating test data in {args.outdir}")
    
    for sample_name, condition in samples:
        print(f"Generating {sample_name} ({condition})...")
        
        # Generate reads
        r1_reads, r2_reads = generate_fastq_pair(
            sample_name, args.reads, args.length
        )
        
        # Write files
        r1_file = f"{args.outdir}/{sample_name}_R1.fastq.gz"
        r2_file = f"{args.outdir}/{sample_name}_R2.fastq.gz"
        
        write_fastq_gz(r1_reads, r1_file)
        write_fastq_gz(r2_reads, r2_file)
        
        print(f"  Written: {r1_file}")
        print(f"  Written: {r2_file}")
    
    print("Test data generation complete!")

if __name__ == "__main__":
    main()