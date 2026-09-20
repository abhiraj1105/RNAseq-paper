#!/bin/bash

## Bwa align RNA-seq reads against CDS sequences predicted by TransDecoder from the Trinity de novo assembly
##created from the same reads.

#SBATCH --partition=uoa-compute
#SBATCH --array=1-12								# 1-N where N is the number of FASTA files to be aligned
#SBATCH -c 8 --mem 16G								
#SBATCH --mail-type=ALL
#SBATCH --mail-user=r03ac23@abdn.ac.uk


module load bwa			#aligner
module load samtools		#required


IMPUT_R="A_equina/complete/"							# directory for RNAseq reads
IMPUT_S="orthofinder2026_dge_longest_isoform/cds/longest"			# directory for the transdecoder CDS sequences
OUTPUT="orthofinder2026_dge_longest_isoform/cds/"				# parent directory for the output
OUTDIR="$OUTPUT/bwa_align_against_longest_red_transdecoder_cds"			# directory for output, one for green alignments and one for red



# bwa needs to index the reference sequence fasta file before alignment; run the below indexing commands before running this script
# bwa index $IMPUT_S/<greenCDS>.fa
# bwa index $IMPUT_S/<redCDS>.fa


lib=$(cut -f 1 metadata_reds.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1)	# text file with the names of RNA-seq reads FASTA files to be aligned 

bwa mem -t 8 $IMPUT_S/red_longest_cds.fa \
	$IMPUT_R/${lib}_1.fq.gz \
	$IMPUT_R/${lib}_2.fq.gz \
	> $OUTDIR/${lib}.sam

samtools sort -@ 8 $OUTDIR/${lib}.sam \
	-O bam -o $OUTDIR/${lib}.bam

# Only delete the SAM if the BAM was created successfully

if [ -s "$OUTDIR/${lib}.bam" ]; then
    rm "$OUTDIR/${lib}.sam"
else
    echo "WARNING: BAM file for ${lib} was not created, keeping SAM for debugging" >&2
fi

samtools index -@ 8 $OUTDIR/${lib}.bam
samtools flagstat -@ 8 $OUTDIR/${lib}.bam > $OUTDIR/${lib}.flagstat.txt
