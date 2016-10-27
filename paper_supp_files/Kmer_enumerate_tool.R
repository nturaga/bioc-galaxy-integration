## How to run tool
# Rscript Kmer_enumerate_tool.R --input1 input1.fq --input2 input2 --output output.txt

# Set up R error handling to go to stderr
options(show.error.messages=F, error=function(){cat(geterrmessage(),file=stderr());q("no",1,F)})

# Avoid crashing Galaxy with an UTF8 error on German LC settings
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

# Import required libraries
library("getopt")
library("seqTools")
options(stringAsfactors = FALSE, useFancyQuotes = FALSE)

# Take in trailing command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Get options using the spec as defined by the enclosed list
# Read the options from the default: commandArgs(TRUE)
option_specification = matrix(c(
  'input1', 'i1', 2, 'character',
  'input2', 'i2', 2, 'integer',
  'output', 'o', 2, 'character'
), byrow=TRUE, ncol=4);

# Parse options
options = getopt(option_specification);

# Print options to stderr
# Useful for debugging
#cat("\n input file: ",options$input1)
#cat("\n kmer: ",options$input2)
#cat("\n output file: ",options$output)

# Read in fastq file and call fastqq to enumerate kmers
fq <- fastqq(options$input1, k = options$input2)

# List kmers and counts from fastqq object
kc <- kmerCount(fq)[, 1]

# Output kmer counts
write.table(kc, file = options$output, quote = F, col.names = F)

cat("\n Successfully counted kmers in fastq file. \n")
