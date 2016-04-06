Writing Galaxy tool wrappers for R and Bioconductor packages
===================


#### NOTE: PROOF READING IS WELCOME, PULL REQUESTS ARE ALSO WELCOME :) 


This tutorial is going to cover how to wrap R / Bioconductor packages as Galaxy tools. **It is aimed at complete beginners at Galaxy and also people writing Galaxy tools for the first time**. 

Aims: 

- R package integration to Galaxy
- Bioconductor package integration to Galaxy
- Best practices to handle R/Bioconductor tool integration


----------

### Table of contents

1. [Lets talk about Galaxy tools first](#lets-talk-about-galaxy-tools-first)
2. [Galaxy Tool Components](#galaxy-tool-components)
	* [Input](#input)
	* [Output](#output)
	* [Wrapper](#wrapper)
3. [Types of Tools](#types-of-tools)
	* [Single Input with Single Output](#single-input-with-single-output)
	* [Single Input with Multiple Outputs](#single-input-with-multiple-outputs)
	* [Multiple Inputs with Single Output](#multiple-inputs-with-single-output)
	* [Mutliple Inputs with Multiple Outputs](#multiple-inputs-with-multiple-outputs)
4. [R and Bioconductor tool integration best-practices](#r-and-bioconductor-tool-integration-best-practices)
	* [DESeq2 a model package for Galaxy written by Bjoern Gruening](#deseq2-a-model-package-for-galaxy-written-by-bjoern-gruening)
5. [Dataset collections for Bioconductor tools](#dataset-collections-for-bioconductor-tools)
6. [How to handle RData files](#how-to-handle-rdata-files)
7. [Putting your wrapper in configfile](#putting-your-wrapper-in-configfile)
8. [Publishing tools to IUC for Code review](#publishing-tools-to-IUC-for-code-review)
9. [R and Biocondutor tool wrapping tips](#r-and-bioconductor-tool-wrapping-tips)
  * [Leverage Planemo to build and test your tools](#leverage-planemo-to-build-and-test-your-tools)
  * [Test Test and Test some more](test-test-and-test-some-more)
  * [Interactive tours for your tool](interactive-tours-for-your-tool)
  * [Maintain it for future versions](maintain-it-for-future-versions)
10. [Join the Galaxy community](#join-the-galaxy-community)

------------


Lets talk about Galaxy tools first
-------------

A Galaxy tool has three important components, 

1. **Input** - Single Input or Multiple Inputs
2. **Output** - Single Output or Multiple Ouputs
3. **Wrapper** - Script or Wrapper which does the computation for your selected package of choice. 

This gives the option for a Galaxy tool to have the following **types of tools**,

1. Single input with Single Output
2. Single input with Multiple Outputs
3. Multiple inputs with Single Output
4. Multiple inputs with Multiple Outputs.


> **Note:** If you want to skip ahead to examples to each of these types of tools, click the links given below.

> - Single input with Single Output [INSERT Tool Example][1]
> - Single input with Multiple Outputs [INSERT Tool Example][2]
> - Multiple inputs with Single Output [INSERT Tool Example][3]
> - Multiple inputs with Multiple Outputs [INSERT Tool Example][4]

Some excellent resources you can refer to for more information: 

---------------

Galaxy Tool Components
-----------------------

This is going to be the minimal structure of your galaxy tool.

```
<tool id="your_tool_id" name="your_tool_name" version="0.1.0">
    <command><![CDATA[
        Rscript my_r_tool.R $input > $output
    ]]></command>
    <inputs>
        <param type="data" name="input1" format="input_datatype" />
    </inputs>
    <outputs>
        <data name="output1" format="output_datatype" />
    </outputs>
    <tests>
        <test>
            <param name="input1" value="name_of_input_file.extension"/>
            <output name="output1" file="name_of_output_file.extension"/>
        </test>
    </tests>
    <help><![CDATA[
        Write you tool help section HERE
    ]]></help>
    <expand macro="citations" />
</tool>
```

This is going to be the minimal structure of your tool wrapper, calling some bioconductor package or R package. The comments on top of each line of code in R wrapper explain the significance.

```{r}
# Setup R error handling to go to stderr
options(show.error.messages=F, error=function(){cat(geterrmessage(),file=stderr());q("no",1,F)})

# We need to not crash galaxy with an UTF8 error on German LC settings.
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

# Import library
library("getopt")
options(stringAsfactors = FALSE, useFancyQuotes = FALSE)
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
cat("cores = ", opt$cores, "\n")
cat("b_permutations = ",opt$b_permutations,"\n")
cat("smooth = ",opt$smooth,"\n")
cat("cutoff = ",opt$cutoff,"\n")
cat("l_value = ",opt$l_value,"\n")
cat("numPositions = ",opt$numPositions,"\n")
cat("shrinkVar = ",opt$shrinkVar,"\n")


# Load required libraries
suppressPackageStartupMessages({
    library("minfi")
    library("FlowSorted.Blood.450k")
    library("TxDb.Hsapiens.UCSC.hg19.knownGene")
    library("doParallel")
})


# Parse cheetah code and make dataframe for creating tmp dir
if ( verbose ) {
    cat("Minfi targets file:\n\n ")
    print(targets)
}
# Save result, which contains DMR's and closest genes
write.csv(annotated_dmrs,file = "dmrs.csv",quote=FALSE,row.names=FALSE)

# Garbage collect
gc()
```


#### Input


#### Output


#### Wrapper


#### Other components and their detailed reference

-------------

Types of Tools
----------------

#### Single Input with Single Output


#### Single Input with Multiple Outputs


#### Multiple Inputs with Single Output


#### Mutliple Inputs with Multiple Outputs



----------

R and Bioconductor tool integration best practices
-------------------

#### DESeq2 a model package for Galaxy written by Bjoern Gruening

The package is now being shipped in the Bioconductor distribution of DESeq2. 

----------




Dataset collections for Bioconductor tools
----------


-----------

How to handle RData files
-------------


---------------



Putting your wrapper in configfile
--------------------

There is another way to write wrappers without putting your script in a seperate file. It can be integrated into your XML through the ```<configfile>``` tag. This way, the developer can avoid having a seperate file for his Rscript. There are pros and cons to this method

Pros
1. Single file
2. 


How do I handle dependencies for my Bioconductor package
---------------

1. Conda
2. bioarchive.galaxyproject.org
3. bioconductor
4. bjoern's magic tool dependency resolving [script](https://github.com/bioarchive/aRchive_source_code/blob/master/get_galaxy_tool_dependencies.py)

--------------


Publishing tools to IUC for Code review (Recommended)
-------------

Once you are happy with your tools, you can publish it on Galaxy in many ways. List them all here.


----------


-------------------

R/Biocondutor tool wrapping tips
--------------------

#### Exit codes for R tools
#### How to handle inputs and outputs through getopt package
#### How to avoid the x11 trap
#### Leverage Planemo to build and test your tools
#### Test Test and Test some more
#### Interactive tours for your tool
#### Maintain it for future versions
#### Use the python package Rpy2 for your tool wrappers

Some tools in Bioconductor which are available through Galaxy
--------------
  
1. [cummerbund](https://github.com/galaxyproject/tools-devteam/tree/master/tools/cummerbund)
2. [DESeq2](https://github.com/galaxyproject/tools-iuc/tree/master/tools/deseq2)
3. [DEXseq](https://github.com/galaxyproject/tools-iuc/tree/master/tools/dexseq)

Join the Galaxy Community
--------------
[![](https://wiki.galaxyproject.org/Images/GalaxyLogos?action=AttachFile&do=get&target=galaxy_logo_25percent.png)](https://github.com/galaxyproject)

**NOTE** These tool design models will be constantly improving, if you see any changes that need to be made, please send me a pull request with the material or file an issue. Help from the community to improve this document is always welcome.
