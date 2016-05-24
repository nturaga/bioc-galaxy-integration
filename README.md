Writing Galaxy tool wrappers for R and Bioconductor packages
===================

This tutorial will cover how to wrap R/Bioconductor packages as Galaxy tools. **It is aimed at beginners and those writing Galaxy tools for R or Bioconductor packages for the first time**. [Bioconductor](https://www.bioconductor.org/) represents a large collection of tools for the analysis of high-throughput genomic data, which are ready to be integrated into the Galaxy platform.

Aims to familiarize readers with:

- R package integration into Galaxy
- Bioconductor package integration into Galaxy
- Best practices to handle R/Bioconductor tool integration

NOTE: Galaxy is language agnostic, so tools written in different languages can be integrated into Galaxy. This document focuses on R/Bioconductor tool integration.

----------

Table of contents
--------------

<!-- MarkdownTOC -->

- [An Overview of Galaxy Tools](#an-overview-of-galaxy-tools)
- [Galaxy Tool Components](#galaxy-tool-components)
    - [Tool definition file](#tool-definition-file)
        - [What is CDATA?](#what-is-cdata)
        - [Inputs](#inputs)
        - [Outputs](#outputs)
        - [Command](#command)
    - [Custom R script](#custom-r-script)
    - [How does it all work together?](#how-does-it-all-work-together)
        - [Make Galaxy aware of your tool](#make-galaxy-aware-of-your-tool)
- [Types of Tools](#types-of-tools)
    - [Single Input with Single Output](#single-input-with-single-output)
    - [Single Input with Multiple Outputs](#single-input-with-multiple-outputs)
    - [Multiple Inputs with Single Output](#multiple-inputs-with-single-output)
    - [Multiple Inputs with Multiple Outputs](#multiple-inputs-with-multiple-outputs)
- [Handling dependencies for Bioconductor packages](#handling-dependencies-for-bioconductor-packages)
- [R and Bioconductor tool integration best practices](#r-and-bioconductor-tool-integration-best-practices)
    - [DESeq2 a model package for Galaxy written by Björn Gruening](#deseq2-a-model-package-for-galaxy-written-by-björn-gruening)
    - [List of some best practices](#list-of-some-best-practices)
- [Dataset collections for Bioconductor tools](#dataset-collections-for-bioconductor-tools)
- [How to handle RData files](#how-to-handle-rdata-files)
- [Putting your wrapper in configfile](#putting-your-wrapper-in-configfile)
- [Publishing tools to IUC for Code review (Recommended)](#publishing-tools-to-iuc-for-code-review-recommended)
- [R and Bioconductor tool wrapping tips](#r-and-bioconductor-tool-wrapping-tips)
    - [Exit codes for R tools](#exit-codes-for-r-tools)
    - [How to handle inputs and outputs through getopt package](#how-to-handle-inputs-and-outputs-through-getopt-package)
    - [How to avoid the x11 trap](#how-to-avoid-the-x11-trap)
    - [Leverage Planemo to build and test your tools](#leverage-planemo-to-build-and-test-your-tools)
    - [Test Test and Test some more](#test-test-and-test-some-more)
    - [R session running on your galaxy](#r-session-running-on-your-galaxy)
    - [Interactive tours for your tool](#interactive-tours-for-your-tool)
    - [Maintain it for future versions](#maintain-it-for-future-versions)
    - [Use the python package Rpy2 for your tool wrappers](#use-the-python-package-rpy2-for-your-tool-wrappers)
- [Some tools in Bioconductor which are available through Galaxy](#some-tools-in-bioconductor-which-are-available-through-galaxy)
- [Join the Galaxy Community](#join-the-galaxy-community)

<!-- /MarkdownTOC -->

------------


An Overview of Galaxy Tools
-------------

A Galaxy tool is defined by a **Tool definition file** or **Tool wrapper** in XML format and has three important components:

1. *Inputs* - Single or multiple input files
2. *Outputs* - Single or multiple output files
3. *Command* - The command which needs to be run by Galaxy via the R interpreter

The final component needed for integrating an R/Bioconductor package is a **Custom R script** which uses the R/Bioconductor package to perform an analysis.

Some excellent resources for more information:
- [Official Galaxy Tool Wiki](https://wiki.galaxyproject.org/Admin/Tools/)
- [Add a tool tutorial Wiki](https://wiki.galaxyproject.org/Admin/Tools/AddToolTutorial)

---------------


Galaxy Tool Components
-----------------------

**Directory structure of your tool**

The *Tool definition file* and *Custom R script* go into their own directory (*e.g.* ```my_r_tool```). The directory structure for R/Bioconductor tool ```my_r_tool``` would look like:

```
my_r_tool/
├── my_r_tool.R # Custom R script
├── my_r_tool.xml # Tool definition file
├── test-data # Test data for tool to work with Planemo
│   ├── input.csv
│   └── output.csv
```

### Tool definition file

The example XML code below represents the minimal structure of a Galaxy *Tool definition file* (```my_r_tool.xml```) to call an R/Bioconductor package. Another example *Tool definition file* can be found [here](https://wiki.galaxyproject.org/Tools/SampleToolTemplate?action=show&redirect=Admin%2FTools%2FExampleXMLFile).

```
<tool id="my_r_tool" name="MY NIFTY R TOOL" version="0.1.0">
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
        Write you tool help section here
    ]]></help>
    <citations>
        <!-- Sample citation to the original Galaxy paper -->
        <citation>10.1186/gb-2010-11-8-r86</citation>
    </citations>
</tool>

```


#### What is CDATA?

In an XML document or external parsed entity, a CDATA section is a section of element content that is marked for the parser to interpret purely as textual data, not as markup. A CDATA section is merely an alternative syntax for expressing character data. There is no semantic difference between character data that manifests as a CDATA section and character data that manifests as in the usual syntax in which, for example, "<" and "&" would be represented by "&lt;" and "&amp;", respectively. So, using CDATA is a good idea if you don't want to use the usual syntax. It is also a [best practice](https://galaxy-iuc-standards.readthedocs.org/en/latest/best_practices/tool_xml.html#command-tag).


#### Inputs

Inputs to the Galaxy *Tool definition file* are given by the XML tags ```<inputs>```, and each input inside is given by the ```<param>``` tag. In the ```<param>``` tag you can define ```name, value, type, label``` attributes. More details can be found [here](https://wiki.galaxyproject.org/Admin/Tools/ToolConfigSyntax#A.3Cinputs.3E_tag_set).

#### Outputs

Outputs of the Galaxy *Tool definition file* are given by the XML tags ```<outputs>```, and each output inside is given by the ```<data>``` tag. In the ```<data>``` tag you can define ```name, format, from_work_dir``` attributes. More details can be found  [here](https://wiki.galaxyproject.org/Admin/Tools/ToolConfigSyntax#A.3Cdata.3E_tag_set).


#### Command

The full path to the Galaxy tool is set in the *Tool definition file*. For example: ```/path/to/directory/my_r_tool/my_r_tool.R```.

### Custom R script

Below is a simple example *Custom R script* (```my_r_tool.R```). It sets the first column of an input CSV file to zeros and saves the output as another CSV file.

```{r}
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
```


### How does it all work together?

First, upload input file(s) (*e.g.* ```input.csv```) to Galaxy. When the tool executes,```input.csv``` is passed via the *Tool definition file* (```my_r_tool.xml```) into the *Custom R script* (```my_r_tool.R```). The script takes in command line arguments ```--input``` and ```--output```, and the input file(s) ```input.csv``` is passed to the tool via the argument ```--input``` and the processed by it (```options$input``` is your ```input.csv``` file now). The value for ```--output``` is passed in by Galaxy, as the resulting dataset produced.

Its important not to worry about the working directory while writing your R script, because by default its going to be in the job working directory in Galaxy. So, ```setwd()``` and ```getwd()``` should not be needed. The

You should write your R script in such a way that, it is testable and usable outside of Galaxy. This allows your script to be easily accessible to users both within the Galaxy world and outside. You can test this R script with the command line instruction

```
Rscript my_r_tool.R --input 'input.csv'  --output 'output.csv'
```

If we look at the script run by the Galaxy tool, it looks very similar. This can be found if you click on the information *i* icon on your job run.

<img src="images/information.png" >

```
Job Command-Line:   Rscript /Users/nturaga/Documents/my_r_tool/my_r_tool.R
--input /Users/nturaga/Documents/galaxy/database/files/000/dataset_243.dat
--output /Users/nturaga/Documents/galaxy/database/files/000/dataset_249.dat
```

The print statements which you put into your R script go to your standard output (stdout), and are shown in the image below. You need to make sure none of your logs go into the stderr, because this will be interpreted as a tool error in Galaxy.

<img src="images/stdout.png" >


#### Make Galaxy aware of your tool

If not using [Planemo](https://planemo.readthedocs.org/en/latest/) and [ToolShed](https://wiki.galaxyproject.org/ToolShed), once you are done with your wrapper locally, you *NEED* to tell Galaxy you have a new tool by doing this:

1. Copy your own tool configuration file from the sample:
 ```cp $GALAXY_ROOT/config/tool_conf.xml.sample $GALAXY_ROOT/config/tool_conf.xml```

2. Modify it by adding your own section and your wrapper inside like this:
    ```
    <section name="Example R tool" id="rTools">
         <tool file="/Users/Documents/my_r_tool/my_r_tool.xml" />
    </section>
    ```
    More details [here](https://wiki.galaxyproject.org/Admin/Tools/AddToolTutorial#A4._Make_Galaxy_aware_of_the_new_tool:)

3. Restart your Galaxy

-------------


Types of Tools
----------------

Based on the nature of how the inputs and outputs are designed. A galaxy tool can have multiple inputs and multiple outputs. This gives the option for a Galaxy tool to have the following **types of tools**,

1. Single input with Single Output
2. Single input with Multiple Outputs
3. Multiple inputs with Single Output
4. Multiple inputs with Multiple Outputs.


#### Single Input with Single Output
- Single input with Single Output [INSERT Tool Example][1]

#### Single Input with Multiple Outputs
- Single input with Multiple Outputs [INSERT Tool Example][2]

#### Multiple Inputs with Single Output
- Multiple inputs with Single Output [INSERT Tool Example][3]

#### Multiple Inputs with Multiple Outputs
- Multiple inputs with Multiple Outputs [INSERT Tool Example][4]

----------


Handling dependencies for Bioconductor packages
---------------

Dependency resolution for R/Bioconductor tools in Galaxy is made easy by a [script](https://github.com/bioarchive/aRchive_source_code/blob/master/get_galaxy_tool_dependencies.py)script developed and available through the bioarchive github repository. For now, the script is still needing a little refinement. The updates can be found in branch [bioarchive/get_tool_deps_fox](https://github.com/bioarchive/aRchive_source_code/tree/get_tool_deps_fix).

The dependencies need to go into a file called ```tool_dependencies.xml```, and Galaxy will set up an R environment with the dependencies referenced in this file. The exact versions of each of these packages is required.

Sample directory structure for each package:

```
package_BioconductorTool_1_0/
└── tool_dependencies.xml
└── .shed.yml
```

Example package shown here is [CRISPRSeek version 1.11.0](https://github.com/galaxyproject/tools-iuc/tree/3c4a2b13b0f3a280de4f98f4f5e0dc29e10fc7a0/packages/package_r_crisprseek_1_11_0):

1. [tool_dependencies.xml file for package CRISPRSeek](https://github.com/galaxyproject/tools-iuc/blob/3c4a2b13b0f3a280de4f98f4f5e0dc29e10fc7a0/packages/package_r_crisprseek_1_11_0/tool_dependencies.xml)

2. [.shed.yml file for CRISPRSeek](https://github.com/galaxyproject/tools-iuc/blob/3c4a2b13b0f3a280de4f98f4f5e0dc29e10fc7a0/packages/package_r_crisprseek_1_11_0/.shed.yml)


There are other solutions being actively developed by Galaxy for tool dependency resolution:

1. [Conda](http://conda.pydata.org/docs/get-started.html)

2. [Bioconda channel](https://bioconda.github.io/)

3. [bioarchive.galaxyproject.org](https://bioarchive.galaxyproject.org/)


--------------



R and Bioconductor tool integration best practices
-------------------

#### DESeq2 a model package for Galaxy written by Björn Gruening

The DESeq2 script which can be used with Galaxy is now shipped along with the Bioconductor package directly. This script can be found here at this [link](https://github.com/Bioconductor-mirror/DESeq2/blob/release-3.2/inst/script/deseq2.R). This could be an valuable example for new Bioconductor tool authors who want to make their tool more easily available to the community.

The way factors are represented in the script works well with the Galaxy framework. The way the factors are represented in the Galaxy tool form is also extremely functional, and allows users to choose multiple factors that effect the experiment pretty easily. There are many Bioconductor tools which work with a differential comparison model controlling for multiple factors, which could use this sort of tool form. The tool form for DESeq2 can be found here at this [link](https://github.com/galaxyproject/tools-iuc/blob/master/tools/deseq2/deseq2.xml).


#### Extra best practices section

The R script which is written for a Galaxy tool has a minimal set of requirements. These are non exhaustive and are listed below:

* It needs to take in command line arguments for inputs.

In the example script given (```my_r_tool.R```), we use the R package ```getopt``` to add command line arguments with flags. This can also be done in other ways using ```args = commandArgs(trailingOnly=TRUE)``` and then running your script with ```Rscript --vanilla randomScript.R input.csv output.csv``` which doesn't give you the option of defining flags, or using the package ```optparse``` for a more pythonic style. Refer this blog, if you want more details on [how to pass command line arguemnts in R](http://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines). We generally prefer options being passed through flags.

*  A couple of extra lines which can be added to your script at the top are to setup R error handling to go stderr on Galaxy, and to handle a UTF8 error.

```
# Setup R error handling to go to stderr
options(show.error.messages=F, error=function(){cat(geterrmessage(),file=stderr());q("no",1,F)})

# We need to not crash galaxy with an UTF8 error on German LC settings.
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")
```

* The ```cat``` (or ```print```) statements in the R script given as example are only to show how inputs and outputs are passed. These statements will into your stdout.

* The outputs in your script should be saved in a format which is present in the list of galaxy recognized datatypes - [List of galaxy datatypes](https://wiki.galaxyproject.org/Learn/Datatypes). Galaxy now also saves files as Rdata files, and the feature to visualize them is under development. Once the output is generated by your script, Galaxy recognizes it and then displays it as your job output.

* Another good measure to avoid flooding the stdout() in your Galaxy is  to suppress messages within your R script while loading Bioconductor packages is

```
# Load required libraries without seeing messages
suppressPackageStartupMessages({
    library("minfi")
    library("FlowSorted.Blood.450k")
})
```

* You can also set toggle verbose outputs via your R script and getopt package, this allows for easier debugging within your R script. You can also set intermittent status messages while your script is processing large datasets. This makes your R script usable outside of Galaxy as well. The script inside the file ```my_r_tool_again.R``` has a list of options which are better defined.

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

* Feature soon to be available : Conda dependency resolution for R/Bioconductor packages integrated in Galaxy.

----------


Dataset collections for Bioconductor tools
----------

Dataset collections written by the amazing [John Chilton](https://github.com/jmchilton) give Galaxy the ability to represent complex datasets and also run tools, on a collection of samples. Dataset collections are specially useful for tools which run on multiple files at the same time, the input would then comprise of a "collection of files".

Some examples for tools based on dataset collections are:

1. Minfi
2. Sickle

---------------




How to handle RData files
-------------




---------------
Putting your wrapper in configfile
--------------------

There is another way to write wrappers without putting your script in a separate file. It can be integrated into your XML through the ```<configfile>``` tag. This way, the developer can avoid having a separate file for his Rscript. There are pros and cons to this method

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

**Pros**

1. Single file

2. You don't need to use getopt package or any command line argument parser. The inputs are passed into your script directly.

**Cons**

1. You can't reuse the R script outside of Galaxy

2. Debugging is NOT easy when you put your script inside the ```<configfile>``` tag.



Publishing tools to IUC for Code review (Recommended)
-------------
Once you are happy with your tools, you can publish it on Galaxy in many ways. List them all here:


-------------------


R and Bioconductor tool wrapping tips
--------------------

#### Exit codes for R tools

#### How to handle inputs and outputs through getopt package

#### How to avoid the x11 trap

#### Leverage Planemo to build and test your tools

#### Test Test and Test some more

#### R session running on your galaxy

You local machine is going to have you R_HOME set to your default R installation. But you want to invoke the R installation with the galaxy tool dependency directory. The **tool-dependency** directory is set via your galaxy.ini file.

```
tool_dependency_dir = /Users/nturaga/Documents/workspace/minfi_galaxy/shed_tools
```

#### Interactive tours for your tool

#### Maintain it for future versions

#### Use the python package Rpy2 for your tool wrappers


--------


Some tools in Bioconductor which are available through Galaxy
--------------

1. [cummerbund](https://github.com/galaxyproject/tools-devteam/tree/master/tools/cummerbund)
2. [DESeq2](https://github.com/galaxyproject/tools-iuc/tree/master/tools/deseq2)
3. [DEXseq](https://github.com/galaxyproject/tools-iuc/tree/master/tools/dexseq)
4. [minfi]()

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
