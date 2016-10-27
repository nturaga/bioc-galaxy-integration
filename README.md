Writing Galaxy tool wrappers for R and Bioconductor packages
===================

This tutorial outlines how to integrate R/Bioconductor tools into Galaxy. **It is aimed at both novice and experienced R/Bioconductor and Galaxy tool developers.** [Bioconductor](https://www.bioconductor.org/) represents a large collection of [R](https://cran.r-project.org/) tools developed for the analysis of high-throughput genomic data. The goal of this tutorial is to guide developers through the steps required to integrate R/Bioconductor tools into the Galaxy platform. Galaxy is language agnostic, so tools written in different languages can be integrated into Galaxy. This tutorial specifically focuses on R/Bioconductor tool integration.

This tutorial aims to familiarize readers with:

- steps for R/Bioconductor tool integration into Galaxy
- best practices for R/Bioconductor tool integration

----------

Table of contents
--------------


- [Overview of Galaxy Tools](#an-overview-of-galaxy-tools)
    - [Quick summary](#quick-summary)
    - [Directory structure](#directory-structure)
- [Galaxy Tool Components](#galaxy-tool-components)
    - [Tool definition file](#tool-definition-file)
    - [Custom R file](#custom-r-file)
    - [Tool dependency file](#tool-dependency-file)
    - [Test data directory](#test-data-directory)
- [How Galaxy Tool Components Work Together](#how-galaxy-tool-components-work-together)
    - [Tool execution](#tool-execution)
    - [Tool integration into Galaxy](#tool-integration-into-galaxy)
- [Handling R/Bioconductor Dependencies](#handling-rbioconductor-dependencies)
- [Handling RData files](#handling-rdata-files)
- [Supplementary Information](#supplementary-information)
    - [DESeq2: a model for Galaxy tool integration](#deseq2-a-model-for-galaxy-tool-integration)
    - [Tool Wrapping with One File](#tool-wrapping-with-one-file)
    - [Dataset collections for Bioconductor tools](#dataset-collections-for-bioconductor-tools)
    - [CDATA](#cdata)
    - [Publishing tools to IUC for Code review](#publishing-tools-to-iuc-for-code-review)
    - [Best Practices for R/Bioconductor Tool Integration](#best-practices-for-rbioconductor-tool-integration)
    - [R/Bioconductor tool wrapping tips](#rbioconductor-tool-wrapping-tips)
    - [Publishing tools to IUC for Code review (Recommended)](#publishing-tools-to-iuc-for-code-review-recommended)
- [Some tools in Bioconductor which are available through Galaxy](#some-tools-in-bioconductor-which-are-available-through-galaxy)
- [Join the Galaxy Community](#join-the-galaxy-community)

------------

An Overview of Galaxy Tools
-------------

### Quick summary

In general, a Galaxy tool consists of one or more files that informs Galaxy how to run a script that was developed to execute a particular analysis. Galaxy tools can be written in a number of languages. This tutorial focuses on integrating tools written in [R](https://cran.r-project.org/), many of which take advantage of bioinformatic/genomic analysis tools avaialable in [Bioconductor](https://www.bioconductor.org/).

An integrated R/Bioconductor Galaxy tool is defined by four components. The first component is a **Tool definition file** (or **Tool wrapper**) in XML format. This file contains seven important parts (described in detail below):

1. *Requirements* - Dependencies needed to run the R command
2. *Inputs* - One or more input files/parameters given to Custom R file
3. *Outputs* - One or more output files generated by the Custom R file
4. *Command* - The R command executed by Galaxy via the R interpreter
5. *Tests* - Input/output parameters needed to test the R command
6. *Help* - Describes the R/Bioconductor tool
7. *Citations* - References cited using, for example, a DOI or a BibTeX entry

The second component needed for integrating an R/Bioconductor tool is a **Custom R file** which establishes the R environment and informs Galaxy what R command(s) to execute. This file contains three important sections (described in detail below):

1. *Header information*
2. *Parameter handling*
3. *R commands* - Code developed to execute the desired analysis

The third component needed for integrating an R/Bioconductor tool is a **Tool dependency file** in XML format. This file informs Galaxy where to find the required tool dependencies needed to execute the Custom R file. 

The fourth component needed for integrating an R/Bioconductor tool is a **Test data** directory which includes data file(s) intended as input to test the R script and any expected output data file(s). 

An example *Tool definition file*, *Custom R file*, *Tool dependencies file*, and *Test data directory* for an R/Bioconductor tool that enumerates k-mers in a fastq file is available in [paper_supp_files/](https://github.com/nturaga/bioc-galaxy-integration/paper_supp_files). This tool will subsequently be referred to as "Kmer_enumerate" and will be referenced throughout the remaining sections of this guide.

Additional resources for Galaxy tool development can be found here:
- [Official Galaxy Tool Wiki](https://wiki.galaxyproject.org/Admin/Tools/)
- [General tutorial for adding tools to Galaxy](https://wiki.galaxyproject.org/Admin/Tools/AddToolTutorial)

### Directory structure

The *Tool definition file*, *Custom R file*, *Tool dependencies file*, and *Test data directory* exist in their own directory (*e.g.* `Kmer_enumerate_tool`). The files should be organized using the following directory structure:

```
Kmer_enumerate_tool/
├── Kmer_enumerate_tool.R # Custom R file
├── Kmer_enumerate_tool.xml # Tool definition file
├── tool_dependencies.xml # Tool dependency file
├── test_data/ # Test data directory
│   ├── Kmer_enumerate_test_input.fq # Example fastq input file
│   ├── Kmer_enumerate_test_output.txt # Example output text file
│   └── ... # Additional inputs or outputs
```

---------------

Galaxy Tool Components
-----------------------

### Tool definition file

The *Tool definition file* informs Galaxy how to handle parameters in the Custom R file. The value given to "name" in the file header appears in the Galaxy tool panel and should be set to a meaningful short title of what the tool does. The example XML code below represents a Galaxy *Tool definition file* (`Kmer_enumerate_tool.xml`) to call the "Kmer_enumerate" R/Bioconductor tool. An important feature of the *Tool definition file* is that the variable names assigned to inputs and outputs in the `<command>` tag must also be used in the `<inputs>` and `<outputs>` tags. Additional examples of *Tool definition files* can be found in [my_r_tool/](https://github.com/nturaga/bioc-galaxy-integration/my_r_tool).

```{xml}
<tool id="my_seqTools_tool" name="Kmer enumerate" version="0.1.0">
    <!-- A simple description of the tool that will appear in the tool panel in Galaxy. -->
    <description> counts the number of kmers in a fastq file.</description>
    <!-- Handles exit codes in Galaxy. -->
    <stdio>
        <exit_code range="1:" />
    </stdio>
    <requirements>
        <requirement type="package" version="3.2.1">R</requirement>
        <requirement type="package" version="1.2.0">getopt</requirement>
        <requirement type="package" version="1.6.0">seqTools</requirement>
    </requirements>
    <command><![CDATA[
        Rscript /path/to/Kmer_enumerate_tool/Kmer_enumerate_tool.R --input1 $galaxy_input1 --input2 $galaxy_input2 --output $galaxy_output
    ]]></command>
    <inputs>
        <param type="data" name="galaxy_input1" format="fastq" label="Fastq file" />
        <param type="integer" name="galaxy_input2" value="1" label="Kmer size to count"/>
    </inputs>
    <outputs>
        <data name="galaxy_output" format="txt" />
    </outputs>
    <tests>
        <test>
            <param name="galaxy_input1" value="/galaxy/tools/mytools/test_data/test_input.fq.gz"/>
            <param name="galaxy_input2" value="2"/>
            <output name="galaxy_output" file="/galaxy/tools/mytools/test_data/test_output.txt"/>
        </test>
    </tests>
    <help><![CDATA[
        Reads in fastq file and enumerates kmers.
    ]]></help>
    <citations>
        <citation type="bibtex">
    @Manual{seqtools,
        title = {seqTools: Analysis of nucleotide, sequence and quality content on fastq files.},
        author = {Wolfgang Kaisers},
        year = {2013},
        note = {R package version 1.4.1},
        url = {http://bioconductor.org/packages/seqTools/},
    }
        </citation>
    </citations>
</tool>

```

#### Inputs

Each input to the Galaxy *Tool definition file* is given by a `<param>` tag in the `<inputs>` section. The ```<param>``` tag is used to define aspects of the input including its datatype, the input name (must match `<command>` tag), expected format *(e.g.* fastq), and a label that will appear in the tool form. Complete details regarding all tags available for Galaxy *Tool definition files* can be found [here](https://docs.galaxyproject.org/en/latest/dev/schema.html).

#### Outputs

Each output to the Galaxy *Tool definition file* is given by a `<data>` tag in the `<outputs>` section.  The `<data>` tag is used for outputs in much the same way as the `<param>` tag for inputs. Complete details regarding all tags available for Galaxy *Tool definition files* can be found [here](https://docs.galaxyproject.org/en/latest/dev/schema.html).

#### Command

The command section defines the R command that is executed in Galaxy via the R interpreter. The full path to the Galaxy tool must be set in this section. For example: `/path/to/Kmer_enumerate_tool/Kmer_enumerate_tool.R`. Variable names assigned to inputs and outputs much match what is given to the `<param>` and `<data>` tags, respectively. 

#### Requirements

The requirements section defines the tool dependencies needed to run the R script and includes the version of R used to develop the tool. 

#### Tests

The tests section defines the input parameters needed to test the R command and what output to expect as a result. This section is important for tool testing and debugging. 

#### Help

The help section should be used to describe the R/Bioconductor tool and will appear at the bottom of the Galaxy tool form. 

#### Citations

Appropriate references for any components of the R/Bioconductor tool (R packages, test data, etc.) can be provided using the citations section. These citations will appear at the bottom of the tool form in Galaxy. Multiple references can be cited but using multiple `<citation>` tags, and citations will be automatically formated if using, for example, a DOI or a BibTeX entry.

### Custom R file

The *Custom R file* establishes the R environment and informs Galaxy what R command(s) to execute. The example R code below executes the "Kmer_enumerate" R/Bioconductor tool. Additional examples of *Custom R files* can be found in [my_r_tool/](https://github.com/nturaga/bioc-galaxy-integration/my_r_tool/).

```{r}
## Command to run tool:
# Rscript Kmer_enumerate_tool.R --input Kmer_enumerate_test_input.fq --input 2 --output Kmer_enumerate_test_output.txt

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

# Print options to stdout
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
```

#### Header information

The header section handles error messages, loads required R libraries, and parses options. These requirements are needed for every R/Bioconductor tool being integrated; however, the list of imported R libraries will be specific to each tool. Handling error messages is particularly important because any information sent to standard error (stderr) will be interpreted as a tool error in Galaxy, and the tool execution will fail. Instead, all log messages and debugging statements should be printed to standard out (stdout).

#### Parameter handling

The parameter handling section defines how parameters are passed to the R command. Each parameter requires a unique name, a unique single letter designation, a flag indicating whether the parameter is required (0=no argument, 1=required, 2=optional), and the parameter type (*e.g.* character, integer, float). Variable names and values should be printed to stdout, which can be viewed in Galaxy when the tool executes. While not required, these printed statements can assist in debugging and inform whether the R/Bioconductor tool executed correctly. 

#### R commands

This section contains the R command(s) needed to execute the R/Bioconductor tool. The Kmer_enumerate tool above uses the R/Bioconductor package seqTools to read in a fastq file of DNA sequences, count the number of k-mers in the sequences where the value k is supplied by the user, and output the k-mers and their counts.

*Custom R scripts* should be written so that they are testable and usable outside of Galaxy. Scripts can be tested using the following command line instruction:

```
Rscript Kmer_enumerate_tool.R --input 'Kmer_enumerate_test_input.fq' --input 2 --output 'Kmer_enumerate_test_output.txt'
```

The command that a developer would run in the command-line (above) looks very similar to the command run by the Galaxy tool (below). The Galaxy command can be found by clicking the information (**i**) icon in the job run (highlighted in the image below).

TODO: update image and Job Command-Line output

<img src="images/information.png" >

```
Job Command-Line:   Rscript /Users/nturaga/Documents/galaxyproject/bioc-galaxy-integration/my_r_tool/my_r_tool.R
--input /Users/nturaga/Documents/PR_testing/galaxy/database/files/000/dataset_243.dat
--output /Users/nturaga/Documents/PR_testing/galaxy/database/files/000/dataset_249.dat
```

Print statements in the *Custom R file* should be sent to stdout and are shown in the image below. Placing print statements strategically in the *Custom R file* is useful for the user to interpret the tool's performance. The following snippets are from the `Kmer_enumerate_tool.R` *Custom R file*:

```{r}
cat("\n input file: ",options$input1)
cat("\n kmer: ",options$input2)
cat("\n output file: ",options$output)
```

```{r}
cat("\n Successfully counted kmers in fastq file. \n")
```

TODO: update image

<img src="images/stdout.png" >

### Tool dependency file

TODO

### Test data directory

TODO

------------

How Galaxy Tool Components Work Together
-------------

### Tool execution

First, any input files (*e.g.* `Kmer_enumerate_tool_test_input.fq`) should be uploaded to Galaxy. The appropriate tool should be selected from the tool panel, and any input files or parameters should be selected. When the tool executes, input files and parameters are passed by the `--input` argument in the *Tool definition file* to the *Custom R file*. The *Custom R file* executes and sends the results back to the *Tool definition file* to be saved according to the value(s) set for `--output`. The output file is then available for viewing in the Galaxy history panel.

Its important not to worry about the working directory while writing your R script, because by default its going to be in the job working directory in Galaxy. So, ```setwd()``` and ```getwd()``` should not be needed.

### Tool integration into Galaxy

If not using [Planemo](https://planemo.readthedocs.org/en/latest/) and [ToolShed](https://wiki.galaxyproject.org/ToolShed):

When the *Tool definition file* and *Custom R script* are complete, the last step is to tell Galaxy to add the new tool by completing the following:

1. Assemble the *Tool definition file*, *Custom R file*, *Tool dependency file*, and *Test data directory* with test data files in a single directory. Update the *Tool definition file* to provide the full path where appropriate. Alternatively, if the tool directory is saved in the `$GALAXY_ROOT/tools/` directory, a relative path is sufficient.

1. Copy the Tool configuration file `tool_conf.xml.sample`, if it does not already exist, and save it as `tool_conf.xml`.

	```cp $GALAXY_ROOT/config/tool_conf.xml.sample $GALAXY_ROOT/config/tool_conf.xml```

2. Modify `tool_conf.xml` by adding a new section under which the integrated tool will exist. The value given to "name" in the Tool configuration file will appear in the tool panel, and the value given to "name" in the *Tool definition file* will appear under this new section. Provide the full path to the *Tool definition file* if the tool directory is not in `$GALAXY_ROOT/tools/`. Otherwise, the relative path is sufficient.

	```{xml}
	<section name="Kmer enumerate" id="kmer_enumerate">
		<tool file="/path/to/Kmer_enumerate_tool/Kmer_enumerate_tool.xml" />
	</section>
	```

3. Restart Galaxy to integrate the modified `tool_conf.xml file`.

Additional details about how to add custom tools to the Galaxy tool panel can be found [here](https://wiki.galaxyproject.org/Admin/Tools/AddToolTutorial).

### Tool Testing

Including test cases for you tools is always a good idea. Plots should be saved as PNG files, as these are easier to test. 

More details about tool testing [here](https://wiki.galaxyproject.org/Admin/Tools/WritingTests)

----------


Handling R/Bioconductor Dependencies
---------------

Dependency resolution for R/Bioconductor tools in Galaxy is made easy by a [script](https://github.com/bioarchive/aRchive_source_code/blob/master/get_galaxy_tool_dependencies.py) available through the bioarchive github repository. The script is under active development. Updates can be found in branch [bioarchive/get_tool_deps_fix](https://github.com/bioarchive/aRchive_source_code/tree/get_tool_deps_fix).

R/Bioconductor dependencies (with exact versions) needed to run MY_R_TOOL should be listed in a file called ```tool_dependencies.xml```. Galaxy will automatically set up an R environment with these dependencies.

Sample directory structure for each package:

```
package_BioconductorTool_1_0/
└── tool_dependencies.xml
└── .shed.yml
```

Example package shown here is [CRISPRSeek version 1.11.0](https://github.com/galaxyproject/tools-iuc/tree/3c4a2b13b0f3a280de4f98f4f5e0dc29e10fc7a0/packages/package_r_crisprseek_1_11_0):

1. [tool_dependencies.xml](https://github.com/galaxyproject/tools-iuc/blob/3c4a2b13b0f3a280de4f98f4f5e0dc29e10fc7a0/packages/package_r_crisprseek_1_11_0/tool_dependencies.xml) for CRISPRSeek

2. [.shed.yml](https://github.com/galaxyproject/tools-iuc/blob/3c4a2b13b0f3a280de4f98f4f5e0dc29e10fc7a0/packages/package_r_crisprseek_1_11_0/.shed.yml) for CRISPRSeek

Other solutions being actively developed by Galaxy for tool dependency resolution include:

1. [Conda](http://conda.pydata.org/docs/get-started.html)

2. [Bioconda channel](https://bioconda.github.io/)

3. [bioarchive.galaxyproject.org](https://bioarchive.galaxyproject.org/)

---------------

Handling RData files
-------------

Directly using RData files poses security risks for Galaxy. If you must use RData files, consider launching a docker container or a VM to run custom tools which require RData files.

RData files are useful for aggregating multiple datasets into a single file. The RData file can then be loaded into an R session via an Rscript where all the data can be accessed by any R tools. Outputs from these tools can be either RData files or in other formats supported by Galaxy.

--------------

Supplementary Information
-------------------

### DESeq2: a model for Galaxy tool integration

The DESeq2 [*Custom R script*](https://github.com/Bioconductor-mirror/DESeq2/blob/release-3.2/inst/script/deseq2.R), which can be used with Galaxy, is now shipped along with the R/Bioconductor package directly. This is a good example for new R/Bioconductor tool authors who want to make their tool more easily available to the community.

The way factors are represented in the *Custom R scrip* works well with the Galaxy framework. The way factors are represented in the [*Tool definition form*](https://github.com/galaxyproject/tools-iuc/blob/master/tools/deseq2/deseq2.xml) is extremely functional and allows users to easily choose multiple factors that effect the experiment. There are many R/Bioconductor tools which work with a differential comparison model controlling for multiple factors, which could use this sort of tool form.

Additional example tools integrated into Galaxy:

1. [cummerbund](https://github.com/galaxyproject/tools-devteam/tree/master/tools/cummerbund)
2. [DEXseq](https://github.com/galaxyproject/tools-iuc/tree/master/tools/dexseq)
3. [minfi]()

### Tool Wrapping with One File

Another way to write a Galaxy tool wrapper is to put the *Custom R script* directly into the XML *Tool definition file* using the ```<configfile>``` tag. This way, developers can avoid having separate *Tool definition file* and *Custom R script* files.

```
<tool id="my_bioc_tool_configfile" name="bioc tool example" version="1.0">
    <description>This R/Bioc tool has script in configfile</description>
    <requirements>
        <requirement type="R-module" version="2.14.0">Rgraphviz</requirement>
    </requirements>
    <command detect_errors="exit_code">
        Rscript "${random_script_name}" 
    </command>
    <configfiles>
        <configfile name="random_script_name"><![CDATA[
## Load R/bioconductor library
library("Rgraphviz", quietly=TRUE, warn.conflicts=FALSE,verbose = FALSE)

set.seed(123)

## Load the RGset data
if(!is.null("${input1}")){
    v = read.csv("${input1}",stringsAsFactors = F)
    #v = v$x
}

if(!is.null(${input2})) {
    m = read.csv("${input2}",stringsAsFactors = F)
    #m = m$x
}

cat("I'm here making a graph")

# Make graph
g1 <- randomGraph(v$x, m$x, 0.2)

## Produce PDF file
if (!is.null("${pdffile}")) {
    ## Make PDF of graph plot
    pdf("${pdffile}")
    plot(g1,"${plottype}")
    dev.off()
}
      ]]></configfile>
    </configfiles>
    <inputs>
        <param name="input1" type="data" label="Choose V for graph plot" format="csv"/>
        <param name="input2" type="data" label="Choose M for graph plot" format="csv"/>
        <param name="plottype" type="text" value="Choose type of plot" label="neato or twopi" help="You can choose 'neato' or 'twopi' only" />
    </inputs>
	<outputs>
	  <data format="pdf" name="pdffile" label="PDF of Density plot"/>
	</outputs>
    <tests>
        <test>
            <param name="input1" value="V.csv" ftype="csv" />
            <param name="input2" value="M.csv" ftype="csv" />
            <param name="plottype" value="neato" ftype="text"/>
            <output name="pdffile" file="pdffile.pdf" ftype="pdf" />
        </test>
    </tests>
    <help><![CDATA[
  Makes a random graph
          ]]></help>
    <citations>
        <citation type="doi">10.1186/gb-2010-11-8-r86</citation>
    </citations>
</tool>
```

There are pros and cons to this approach:
 
**Pros**

1. Tool wrapper implemented with one file instead of two files.

2. Eliminates the need for a command line argument parser. The inputs are passed into the *Custom R script* directly.

**Cons**

1. *Custom R scripts* cannot be used outside of Galaxy.

2. Debugging is much harder.

### Dataset Collections for R/Bioconductor Tools

Dataset collections gives users the ability to represent complex datasets and run tools on multiple samples all at once. Dataset collections are specially useful for tools which run on multiple files at the same time, the input would then comprise of a "collection of files".

Some examples for tools based on dataset collections are:

1. [Minfi](link)
2. [Sickle](link)

### CDATA

Use CDATA to represent character data. In markup languages such as XML, a CDATA section represents content that should be interpreted purely as character data. Using CDATA is highly recommended, for example, for text in the help and command sections of the Tool definition file.

### Best Practices for R/Bioconductor Tool Integration

The *Custom R script* written for a Galaxy tool has a minimal set of requirements. Below is a non-exhaustive list of additional features that are suggested for *Custom R scripts*:

#### Pass command-line arguments with flags

In the example *Custom R script* (```my_r_tool.R```), the R package ```getopt``` is used to add command line arguments with flags. This can also be done in other ways. For example, using ```args = commandArgs(trailingOnly=TRUE)``` and then running ```Rscript --vanilla randomScript.R input.csv output.csv``` which doesn't give you the option of defining flags. Also, the package ```optparse``` can be used for a more pythonic style. Check out this [blog](http://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines) for more details on how to pass command line arguemnts in R.

####  Implement error handling

Include the following lines at the top of the *Custom R script* to send R errors to stderr on Galaxy and to handle a UTF8 error:

```
# Setup R error handling to go to stderr
options(show.error.messages=F, error=function(){cat(geterrmessage(),file=stderr());q("no",1,F)})

# We need to not crash galaxy with an UTF8 error on German LC settings.
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")
```

#### The ```cat``` (or ```print```) statements in the R script given as example are only to show how inputs and outputs are passed. These statements will into your stdout.

#### Choose output formats recognized by Galaxy

Output from the *Custom R script* should be saved in a format which is present in the list of [Galaxy recognized datatypes](https://wiki.galaxyproject.org/Learn/Datatypes). Galaxy now also saves files as Rdata files, and the feature to visualize them is under development. Once the output is generated by your script, Galaxy recognizes it and then displays it as your job output.

#### Avoid flooding stdout

It is recommended to suppress messages within your *Custom R script* while loading R/Bioconductor packages. For example:

```
# Load required libraries without seeing messages
suppressPackageStartupMessages({
    library("minfi")
    library("FlowSorted.Blood.450k")
})
```

#### Short title for this

Toggle verbose outputs via the *Custom R script* and getopt package to allows for easier debugging. You can also set intermittent status messages while your script is processing large datasets. This makes your R script usable outside of Galaxy as well. The script inside the file ```my_r_tool_again.R``` has a list of options which are better defined.

```
## Call this via "Rscript my_r_tool_again.R --verbose TRUE" from your command line
option_specifications <- matrix(c(
  "verbose", "v", 2, "logical"),
  byrow=TRUE, ncol=4)
options <- getopt(option_specifications)

# Toggle verbose option
if (options$verbose) {
  cat("Print something useful to show how my script is running in Galaxy stdout \n")
}
```

#### Conda dependency resolution for R/Bioconductor packages integrated in Galaxy.

New feature coming soon.

#### Exit codes for R tools

Let Galaxy do it for you in the command tag

```
<command detect_errors="exit_code">
```

#### R session running on your galaxy

You local machine is going to have you R_HOME set to your default R installation. But you want to invoke the R installation with the galaxy tool dependency directory. The **tool-dependency** directory is set via your galaxy.ini file.

```
tool_dependency_dir = /Users/nturaga/Documents/workspace/minfi_galaxy/shed_tools
```

#### Use the python package Rpy2 for your tool wrappers

Coming soon.

--------

[Join the Galaxy Community](https://wiki.galaxyproject.org/GetInvolved)
--------------

1. [https://github.com/galaxyproject](https://github.com/galaxyproject)
2. [https://usegalaxy.org](https://usegalaxy.org)
3. [https://galaxyproject.org](https://galaxyproject.org)
4. [https://github.com/galaxyproject/tools-iuc](https://github.com/galaxyproject/tools-iuc)
5. [https://github.com/galaxyproject/tools-devteam](https://github.com/galaxyproject/tools-devteam)
6. [Galaxyproject on IRC (server: irc.freenode.net)](https://wiki.galaxyproject.org/GetInvolved#IRC_Channel)
7. [https://wiki.galaxyproject.org/Admin/Tools/AddToolTutorial](https://wiki.galaxyproject.org/Admin/Tools/AddToolTutorial)

[![](https://wiki.galaxyproject.org/Images/GalaxyLogos?action=AttachFile&do=get&target=galaxy_logo_25percent.png)](https://github.com/galaxyproject)



**NOTE** These tool design models will be constantly improving, if you see any changes that need to be made, please send me a pull request with the material or file an issue. Help from the community to improve this document is always welcome.
