Writing Galaxy tool wrappers for R and Bioconductor packages
===================

This tutorial will cover how to wrap R/Bioconductor packages as Galaxy tools. **It is aimed at beginners and those writing Galaxy tools for R/Bioconductor packages for the first time**. [Bioconductor](https://www.bioconductor.org/) represents a large collection of tools for the analysis of high-throughput genomic data, which are ready to be integrated into the Galaxy platform.

Aims to familiarize readers with:

- R/Bioconductor package integration into Galaxy
- Best practices to handle R/Bioconductor tool integration

NOTE: Galaxy is language agnostic, so tools written in different languages can be integrated into Galaxy. This document focuses on R/Bioconductor tool integration.

----------

Table of contents
--------------


- [An Overview of Galaxy Tools](#an-overview-of-galaxy-tools)
    - [Quick summary](#quick-summary)
    - [Types of Galaxy Tools](#types-of-galaxy-tools)
- [Galaxy Tool Components](#galaxy-tool-components)
    - [Directory structure](#directory-structure)
    - [Tool definition file](#tool-definition-file)
        - [Inputs](#inputs)
        - [Outputs](#outputs)
        - [Command](#command)
    - [Custom R script](#custom-r-script)
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
    - [Others]
- [Some tools in Bioconductor which are available through Galaxy](#some-tools-in-bioconductor-which-are-available-through-galaxy)
- [Join the Galaxy Community](#join-the-galaxy-community)


------------

An Overview of Galaxy Tools
-------------

### Quick summary

A Galaxy tool is defined by two components. The first component is a **Tool definition file** (or **Tool wrapper**) in XML format. This file contains three important parts:

1. *Inputs* - Single or multiple input files
2. *Outputs* - Single or multiple output files
3. *Command* - The command which needs to be run by Galaxy via the R interpreter

The second component needed for integrating an R/Bioconductor tool is a **Custom R script** which uses the R/Bioconductor tool to perform an analysis.

Some excellent resources for more information:
- [Official Galaxy Tool Wiki](https://wiki.galaxyproject.org/Admin/Tools/)
- [Add a tool tutorial Wiki](https://wiki.galaxyproject.org/Admin/Tools/AddToolTutorial)

### Types of Galaxy tools

Based on the nature of how the inputs and outputs are designed, a Galaxy tool can have multiple inputs and multiple outputs. This gives the option for a Galaxy tool to have the following configurations:

1. Single input with Single Output 
2. Single input with Multiple Outputs 
3. Multiple inputs with Single Output 
4. Multiple inputs with Multiple Outputs 

---------------

Galaxy Tool Components
-----------------------

### Directory structure

The *Tool definition file* and *Custom R script* exist in their own directory (*e.g.* ```my_r_tool```). The directory structure for the R/Bioconductor tool ```my_r_tool```, for example, would look like the following:

```
my_r_tool/
├── my_r_tool.R # Custom R script
├── my_r_tool.xml # Tool definition file
├── test-data # Test data for tool to work with Planemo
│   ├── input.csv
│   └── output.csv
```

### Tool definition file

The tool definition file is an XML file that informs Galaxy how to handle your input/output and variable parameters in your R script. The command section is where you define how Galaxy should run the R script. The inputs section is where you establish how your variable parameters appear in the Galaxy GUI. Each input parameter should have its own entry. For each input variable parameter you establish in this file, you should also establish it in the R script file where you set variable parameters. The output section is where you establish the name and format of your output. The help section is where you can provide text to describe your tool and any other information you deem will be of use to the user. 

The example XML code below represents the minimal structure of a Galaxy *Tool definition file* (```my_r_tool.xml```) to call the R/Bioconductor tool MY_R_TOOL. Another example *Tool definition file* can be found [here](https://wiki.galaxyproject.org/Tools/SampleToolTemplate?action=show&redirect=Admin%2FTools%2FExampleXMLFile).

```
<tool id="my_r_tool" name="MY_R_TOOL" version="0.1.0">
    <command detect_errors="exit_code"><![CDATA[
        Rscript </path/to/directory/my_r_tool/my_r_tool.R --input $galaxy_input --output $galaxy_output
    ]]></command>
    <inputs>
        <param type="data" name="galaxy_input" format="csv" />
    </inputs>
    <outputs>
        <data name="galaxy_output" format="csv" />
    </outputs>
    <tests>
        <test>
            <param name="galaxy_input" value="input.csv"/>
            <output name="galaxy_output" file="output.csv"/>
        </test>
    </tests>
    <help><![CDATA[
        Write your tool help section here
    ]]></help>
    <citations>
        <!-- Sample citation to the original Galaxy paper -->
        <citation>10.1186/gb-2010-11-8-r86</citation>
    </citations>
</tool>

```

#### Inputs

Inputs to the Galaxy *Tool definition file* are given by the XML tags ```<inputs>```, and each input inside is given by the ```<param>``` tag. In the ```<param>``` tag you can define ```name, value, type, label, format``` attributes. More details can be found [here](https://wiki.galaxyproject.org/Admin/Tools/ToolConfigSyntax#A.3Cinputs.3E_tag_set).

#### Outputs

Outputs of the Galaxy *Tool definition file* are given by the XML tags ```<outputs>```, and each output inside is given by the ```<data>``` tag. In the ```<data>``` tag you can define ```name, format, from_work_dir``` attributes. More details can be found  [here](https://wiki.galaxyproject.org/Admin/Tools/ToolConfigSyntax#A.3Cdata.3E_tag_set).

#### Command

The full path to the Galaxy tool is set in the *Tool definition file*. For example: ```/path/to/directory/my_r_tool/my_r_tool.R```.

### Custom R script

This file contains required information (first six commands), your variable parameters, and the actual R commands your tool will run. 
Below is an example of a *Custom R script* (```my_r_tool.R```). It sets the first column of an input CSV file to zeros and saves the output as another CSV file.

```{r}
# Setup R error handling to go to stderr
options(show.error.messages=F, error=function(){cat(geterrmessage(),file=stderr());q("no",1,F)})

# We need to not crash galaxy with an UTF8 error on German LC settings.
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

# Import libraries your R script uses
library("getopt")
options(stringAsfactors = FALSE, useFancyQuotes = FALSE)
# Take in trailing command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Parse options
options = getopt(option_specification);

# These are the variable paramters of your R script
# getopt will use the information provided for each variable to populate variable parameters of your R script 
# For each variable, establish a name, single letter name, the number 2 (?), and the input type (character, integer, float, etc). 
option_specification = matrix(c(
  'input', 'i', 2, 'character',
  'output', 'o', 2, 'character'
), byrow=TRUE, ncol=4);


# Print options to see what is going on
# This information will be viewable with the output file (in your history)
cat("\n input: ",options$input)
cat("\n output: ",options$output)


# The following section contains your R script

# READ in your input file
inp = read.csv(file=options$input, stringsAsFactors = FALSE)

# Do something with you input
# This one changes every value in the first column to 0
inp$V1 = c(rep(0,10))

# Save your output as the file you want to Galaxy to recognize.
write.csv(inp, file=options$output,row.names = FALSE)
cat("\n success \n")
```

*Custom R scripts* should be written so that they are testable and usable outside of Galaxy. Scripts can be tested using the following command line instruction:

```
Rscript my_r_tool.R --input 'input.csv' --output 'output.csv'
```

If we look at the script run by the Galaxy tool, it looks very similar. This can be found if you click on the information (**i**) icon on your job run. These icons are highlighted in the image below.

<img src="images/information.png" >

```
Job Command-Line:   Rscript /Users/nturaga/Documents/galaxyproject/bioc-galaxy-integration/my_r_tool/my_r_tool.R
--input /Users/nturaga/Documents/PR_testing/galaxy/database/files/000/dataset_243.dat
--output /Users/nturaga/Documents/PR_testing/galaxy/database/files/000/dataset_249.dat
```

Print statements in *Custom R scripts* should be sent to standard output (stdout) and are shown in the image below. Placing print statements strategically in the *Custom R script* is useful for the user to interpret the tools performance. The example in the image below is taken from the script ```my_r_tool.R```. 

```
23 cat("\n input: ",options$input)
24 cat("\n output: ",options$output)
```

```
36 cat("\n success \n")
```

<img src="images/stdout.png" >


Do not print logs to standard error (stderr), because this will be interpreted as a tool error in Galaxy.


------------

How Galaxy Tool Components Work Together
-------------

### Tool execution

First, the input file (*e.g.* ```input.csv```) should be uploaded to Galaxy. When MY_R_TOOL executes,```input.csv``` is passed by the ```--input``` argument in the *Tool definition file* to the *Custom R script*. The *Custom R script* executes and sends the results back to the *Tool definition file* to be saved according to the value set for ```--output```. The output file is then available in Galaxy.

Its important not to worry about the working directory while writing your R script, because by default its going to be in the job working directory in Galaxy. So, ```setwd()``` and ```getwd()``` should not be needed.

### Tool integration into Galaxy

If not using [Planemo](https://planemo.readthedocs.org/en/latest/) and [ToolShed](https://wiki.galaxyproject.org/ToolShed):

When the *Tool definition file* and *Custom R script* are complete, the last step is to tell Galaxy to add the new tool by completing the following:

1. Copy your own tool configuration file from the sample:
 ```cp $GALAXY_ROOT/config/tool_conf.xml.sample $GALAXY_ROOT/config/tool_conf.xml```

2. Modify it by adding your own section and your wrapper inside like this:
    ```
    <section name="Example R tool" id="rTools">
         <tool file="/path/to/directory/my_r_tool/my_r_tool.xml" />
    </section>
    ```
    More details can be found [here](https://wiki.galaxyproject.org/Admin/Tools/AddToolTutorial#A4._Make_Galaxy_aware_of_the_new_tool:).

3. Restart Galaxy.

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

In an XML document or external parsed entity, a CDATA section is a section of element content that is marked for the parser to interpret purely as textual data, not as markup. A CDATA section is merely an alternative syntax for expressing character data. There is no semantic difference between character data that manifests as a CDATA section and character data that manifests as in the usual syntax in which. For example, "<" and "&" would be represented by ```&lt;``` and ```&amp;``` respectively. Using CDATA is a good idea if you don't want to use the usual syntax. It is also a [best practice](https://galaxy-iuc-standards.readthedocs.org/en/latest/best_practices/tool_xml.html#command-tag).


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
