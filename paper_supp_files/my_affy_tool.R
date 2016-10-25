## How to run tool
# Rscript my_affy_tool.R --input input.CEL --output output.txt

# Set up R error handling to go to stderr
options(show.error.messages = F, error = function(){cat(geterrmessage(),file=stderr());q("no", 1, F)})

# Avoid crashing Galaxy with an UTF8 error on German LC settings
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

# Import required libraries
library("getopt")
library("affy")
options(stringAsfactors = FALSE, useFancyQuotes = FALSE)

# Take in trailing command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Get options using the spec as defined by the enclosed list
# Read the options from the default: commandArgs(TRUE)
option_specification = matrix(c(
  'input', 'i', 2, 'character',
  'output', 'o', 2, 'character'
), byrow=TRUE, ncol=4);

# Parse options
options = getopt(option_specification);

# Print options to stderr
# Useful for debugging
#cat("\n input file: ",options$input)
#cat("\n output file: ",options$output)

# Read in data
inputfile <- as.character(options$input)
data <- ReadAffy(filenames = inputfile)

# Create ExpressionSet object using RMA
eset <- rma(data)

# Output expression values
write.exprs(eset, file = options$output)

cat("\n Successfully generating expression values from CEL file. \n")
