# Expected Test Outputs

This directory contains expected outputs for pipeline testing and validation.

## Test Data Structure

```
test_data/
├── fastq/                          # Input FASTQ files
│   ├── test_cancer_1_R1.fastq.gz
│   ├── test_cancer_1_R2.fastq.gz
│   ├── test_cancer_2_R1.fastq.gz
│   ├── test_cancer_2_R2.fastq.gz
│   ├── test_healthy_1_R1.fastq.gz
│   ├── test_healthy_1_R2.fastq.gz
│   ├── test_healthy_2_R1.fastq.gz
│   └── test_healthy_2_R2.fastq.gz
├── reference/                       # Reference genome
│   └── test_genome.fa
├── expected_outputs/                # Expected pipeline outputs
│   ├── fastqc/
│   ├── trimgalore/
│   ├── bismark/
│   ├── methylation_extraction/
│   ├── coverage_filtering/
│   ├── dmr_analysis/
│   └── multiqc/
└── samplesheet_test.csv            # Test samplesheet
```

## Generating Test Data

To generate synthetic test data:

```bash
python bin/generate_test_data.py --outdir assets/test_data/fastq --reads 1000
```

## Running Tests

### Quick test (synthetic data):
```bash
nextflow run main.nf -profile test,docker
```

### Full test (real data):
```bash
nextflow run main.nf -profile test_full,docker
```

## Test Validation

The pipeline should produce:

1. **FastQC reports** for all input files
2. **Trimmed FASTQ files** (if trimming enabled)
3. **Bismark alignment files** (.bam)
4. **Methylation extraction outputs** (.cov, .bedGraph)
5. **Filtered coverage files** for DMR analysis
6. **DMR results** from metilene
7. **MultiQC report** summarizing all results

## Expected File Counts

For the test dataset (4 samples):
- 8 FastQC HTML reports (2 per sample)
- 4 Bismark BAM files
- 4 Coverage files (.cov)
- 4 Filtered coverage files
- 2 DMR result files (cancer vs healthy)
- 1 MultiQC report