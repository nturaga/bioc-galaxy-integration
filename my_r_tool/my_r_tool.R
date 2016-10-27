## How to execute this tool
# $Rscript my_r_tool.R --input input.csv --output output.csv

# Send R errors to stderr
options(show.error.messages = F, error = function(){cat(geterrmessage(), file = stderr()); q("no", 1, F)})

# Avoid crashing Galaxy with an UTF8 error on German LC settings
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

# Import library
library("getopt")

options(stringAsfactors = FALSE, useFancyQuotes = FALSE)

# Take in trailing command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Get options using the spec as defined by the enclosed list
# Options are read from the default: commandArgs(TRUE)
option_specification = matrix(c(
  'input', 'i', 2, 'character',
  'output', 'o', 2, 'character'
), byrow=TRUE, ncol=4);

# Parse options
options = getopt(option_specification);

# Print options to stderr for debugging
cat("\n input: ", options$input)
cat("\n output: ", options$output)

# Read in the input file
inp = read.csv(file = options$input, stringsAsFactors = FALSE)

# Changes every value in the first column to 0
inp$V1 = c(rep(0,10))

# Write output to new file which will be recognized by Galaxy
write.csv(inp, file = options$output,row.names = FALSE)

cat("\n success \n")
