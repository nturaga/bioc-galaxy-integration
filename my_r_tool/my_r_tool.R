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
spec <- matrix(c(
    'quiet', 'q', 2, "logical",
    'help' , 'h', 0, "logical",
    "input1","i",2,"double",
    "output1","o",2,"integer")
    ,byrow=TRUE, ncol=4)
opt <- getopt(spec)

# If help was asked for print a friendly message
# and exit with a non-zero error code
if (!is.null(opt$help)) {
    cat(getopt(spec, usage=TRUE))
    q(status=1)
}


## Set verbose mode
verbose = if(is.null(opt$quiet)){TRUE}else{FALSE}
if(verbose){
    cat("Verbose mode is ON\n\n")
}

# Enforce the following required arguments
if (is.null(opt$preprocess)) {
    cat("'--preprocess' is required\n")
    q(status=1)
}
cat("preprocess = ",opt$preprocess,"\n")


# Load required libraries
#suppressPackageStartupMessages({
	#library("doParallel")
#})


# Save result, which contains DMR's and closest genes
write.csv(annotated_dmrs,file = "dmrs.csv",quote=FALSE,row.names=FALSE)

