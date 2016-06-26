## How to run tool
# $ Rscript my_r_tool.R 
#            --input1 input1.csv 
#            --input2 input2.csv 
#            --output1 output.csv 
#            --output2 output2.csv

# Setup R error handling to go to stderr
options(show.error.messages=F, error=function(){cat(geterrmessage(),file=stderr());q("no",1,F)})
# We need to not crash galaxy with an UTF8 error on German LC settings.
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

# Import library
# Multiple libraries
library("getopt")
library("Rgraphviz")
library("motifbreakR")
library("GenomicRanges")


options(stringAsfactors = FALSE, useFancyQuotes = FALSE)
# Take in trailing command line arguments
args <- commandArgs(trailingOnly = TRUE)

# get options, using the spec as defined by the enclosed list.
# we read the options from the default: commandArgs(TRUE).
option_specification = matrix(c(
  'input1', 'i1', 2, 'character',
  'input2', 'i2', 2, 'character',
  'output1', 'o1', 2, 'character',
  'output2', 'o2', 2, 'character' 
), byrow=TRUE, ncol=4);

# Parse options
options = getopt(option_specification);

# READ in your input file
inp1 = read.csv(file=options$input1, stringsAsFactors = FALSE)
inp2 = read.csv(file=options$input2, stringsAsFactors = FALSE)

inp = rbind(inp1,inp2)

# Do something with you input
# This one changes every value in the first column to 0
out1 = inp1 + inp2

out2 = inp1 * inp2

# Save your output as the file you want to Galaxy to recognize.
write.csv(out1, file=options$output1,row.names = FALSE)
write.csv(out2, file=options$output2, row.names = FALSE)
cat("\n success \n")
