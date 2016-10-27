## How to execute this tool
## $Rscript my_r_tool_verbose.R --verbose TRUE --input input.csv

# Send R errors to stderr
options(show.error.messages = F, error = function(){cat(geterrmessage(), file = stderr()); q("no", 1, F)})

# Avoid crashing Galaxy with an UTF8 error on German LC settings
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

# Import library
# NOTE: It is OK to load getopt without supressing message because
#       there are no logs generated through this import.
library("getopt")

options(stringAsfactors = FALSE, useFancyQuotes = FALSE)

# Take in trailing command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Get options using the spec as defined by the enclosed list
# Options are read from the default: commandArgs(TRUE)
option_specification = matrix(c(
  "help", "h", 0, "logical",
  "verbose", "v", 2, "logical",
  'input', 'i', 2, 'character'
), byrow=TRUE, ncol=4);

# Parse options
options = getopt(option_specification);
verbose <- options$verbose

if (!length(args) > 0) {
	cat("Please give required arguments")
}

# Display help options
if (!is.null(options$help)) {
  cat(getopt(option_specification, usage=TRUE));
  q(status=1);
}

# cat ("verbose type", typeof(verbose))

# Print options to stderr for debugging
if (!is.null(verbose)) {
    cat("\n verbose: ",options$verbose)
    cat("\n input: ",options$input)
} else {
  	cat("verbose option not used \n")
}

# cat("HERE")
# READ in your input file
inp = read.csv(file=options$input, stringsAsFactors = FALSE)
	
# Change every value in the first column to 0
inp$V1 = c(rep(0,10))

# Write output to new file which will be recognized by Galaxy
write.csv(inp, file="output.csv",row.names = FALSE)

# Print on success
if (!is.null(verbose)) {
    cat("\n === Success ===\n")
}
