# WGBS Pipeline

A Nextflow pipeline for processing Whole-genome bisulfite sequencing (WGBS) data from plasma-derived cfDNA from early-stage cancer patients and healthy donors.

## Pipeline Overview

The workflow includes:

1. **Raw Data Quality Control** - FastQC, MultiQC, Trim Galore
2. **Bisulfite-Converted Read Alignment** - Bismark + Bowtie2  
3. **Methylation Extraction** - bismark_methylation_extractor
4. **Coverage Filtering and DMR Input Preparation** - Custom filtering
5. **DMR Identification** - metilene

## Quick Start

1. Install Nextflow and Docker/Singularity
2. Generate test data:
   ```bash
   make generate-data
   ```
3. Run the test:
   ```bash
   make test
   ```

## Usage

### Basic usage:
```bash
nextflow run main.nf --input samplesheet.csv --genome GRCh38 -profile docker
```

### With custom parameters:
```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --genome GRCh38 \
  --bismark_index /path/to/bismark/index \
  --min_coverage 10 \
  --skip_trimming false \
  -profile docker
```

## Input Format

The input samplesheet should be a CSV file with the following columns:

```csv
sample_id,fastq_1,fastq_2,condition
cancer_patient_1,/path/to/cancer_patient_1_R1.fastq.gz,/path/to/cancer_patient_1_R2.fastq.gz,cancer
healthy_donor_1,/path/to/healthy_donor_1_R1.fastq.gz,/path/to/healthy_donor_1_R2.fastq.gz,healthy
```

## Parameters

### Input/Output
- `--input`: Path to input samplesheet (required)
- `--outdir`: Output directory (default: './results')

### Reference Genome
- `--genome`: Genome build (e.g., GRCh38, GRCh37)
- `--bismark_index`: Path to Bismark index

### Processing Options
- `--skip_trimming`: Skip adapter trimming (default: false)
- `--skip_deduplication`: Skip PCR duplicate removal (default: false)
- `--min_coverage`: Minimum coverage for methylation calls (default: 5)

### DMR Analysis
- `--metilene_min_cpgs`: Minimum CpGs per DMR (default: 10)
- `--metilene_max_dist`: Maximum distance between CpGs (default: 300)

## Output Structure

```
results/
├── fastqc/                    # FastQC reports
├── trimgalore/               # Trimmed reads (if enabled)
├── bismark/                  # Alignment files
├── methylation_extraction/   # Methylation calls
├── coverage_filtering/       # Filtered coverage files
├── dmr_analysis/            # DMR results
├── multiqc/                 # Summary report
└── pipeline_info/           # Pipeline execution info
```

## Testing

### Quick test with synthetic data:
```bash
make test
```

### Full test with real data:
```bash
make test-full
```

### Generate synthetic test data:
```bash
make generate-data
```

## Dependencies

- Nextflow (≥21.10.3)
- Docker or Singularity
- FastQC
- Trim Galore
- Bismark
- Metilene
- MultiQC

## Citation

If you use this pipeline, please cite:

- The nf-core framework: https://doi.org/10.1038/s41587-020-0439-x
- Bismark: https://doi.org/10.1093/bioinformatics/btr167
- Metilene: https://doi.org/10.1186/s13059-016-0892-3
