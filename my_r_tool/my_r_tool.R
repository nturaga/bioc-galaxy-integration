## How to run tool
# $Rscript my_r_tool.R --input input.csv --output output.csv

# Setup R error handling to go to stderr
options(show.error.messages=F, error=function(){cat(geterrmessage(),file=stderr());q("no",1,F)})
# We need to not crash galaxy with an UTF8 error on German LC settings.
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

# Import library
library("getopt")
options(stringAsfactors = FALSE, useFancyQuotes = FALSE)
# Take in trailing command line arguments
args <- commandArgs(trailingOnly = TRUE)

# get options, using the spec as defined by the enclosed list.
# we read the options from the default: commandArgs(TRUE).
option_specification = matrix(c(
  'input', 'i', 2, 'character',
  'output', 'o', 2, 'character'
), byrow=TRUE, ncol=4);

# Parse options
options = getopt(option_specification);

# Print options to see what is going on
cat("\n input: ",options$input)
cat("\n output: ",options$output)


# READ in your input file
inp = read.csv(file=options$input, stringsAsFactors = FALSE)

# Do something with you input
# This one changes every value in the first column to 0
inp$V1 = c(rep(0,10))

# Save your output as the file you want to Galaxy to recognize.
write.csv(inp, file=options$output,row.names = FALSE)
cat("\n success \n")
