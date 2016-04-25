Writing Galaxy tool wrappers for R and Bioconductor packages
===================


This tutorial is going to cover how to wrap R / Bioconductor packages as Galaxy tools. **It is aimed at complete beginners at Galaxy and also people writing Galaxy tools for R or Bioconductor packages for the first time**. [Bioconductor](https://www.bioconductor.org/) represents a large body of bioconductor tools which are waiting to be integrated into the Galaxy ecosystem. 

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

1. **Inputs** - Single or Multiple Inputs
2. **Outputs** - Single or Multiple Ouputs
3. **Wrapper** - Script or Wrapper which does the interface between Galaxy and the selected package of your choice. 

This gives the option for a Galaxy tool to have the following **types of tools**,

1. Single input with Single Output
2. Single input with Multiple Outputs
3. Multiple inputs with Single Output
4. Multiple inputs with Multiple Outputs.


**Note:** If you want to skip ahead to examples to each of these types of tools, click the links given below.

- Single input with Single Output [INSERT Tool Example][1]
- Single input with Multiple Outputs [INSERT Tool Example][2]
- Multiple inputs with Single Output [INSERT Tool Example][3]
- Multiple inputs with Multiple Outputs [INSERT Tool Example][4]

Some excellent resources you can refer to for more information:
- [Official Galaxy Tool Wiki](https://wiki.galaxyproject.org/Admin/Tools/)

---------------

Galaxy Tool Components
-----------------------

This is going to be the minimal structure of your galaxy tool. This part of your tool will go into your xml file: 
**my_r_tool.xml**. The full path to your tool is set in the wrapper file, in the **my_r_tool** directory. For example: **/Users/nturaga/Documents/galaxyproject/bioc-galaxy-integration/my_r_tool/my_r_tool.R** (this is a reference in my home directory). 

```
<tool id="my_r_tool" name="MY NIFTY R TOOL" version="0.1.0">
    <command detect_errors="exit_code"><![CDATA[
        Rscript </full/path/>my_r_tool.R --input $galaxy_input --output $galaxy_output
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

This is going to be the minimal structure of your tool wrapper, calling some bioconductor package or R package. The comments on top of each line of code in R wrapper explain the significance. This part goes into your **my_tool.R** 


**What is this CDATA?**

In an XML document or external parsed entity, a CDATA section is a section of element content that is marked for the parser to interpret purely as textual data, not as markup. A CDATA section is merely an alternative syntax for expressing character data; there is no semantic difference between character data that manifests as a CDATA section and character data that manifests as in the usual syntax in which, for example, "<" and "&" would be represented by "&lt;" and "&amp;", respectively. So, using CDATA is good if you don't want to use the usual syntax. It is also a [best practice](https://galaxy-iuc-standards.readthedocs.org/en/latest/best_practices/tool_xml.html#command-tag).

Remi's suggestions for the next script:
- Do you think it is a good idea to map R code with Wrapper code. For example:
```{r}
'input', 'i', 2, 'character' # Match your <inputs><param type="data" name="galaxy_input" format="csv" /></inputs> in the wrapper
```

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


#### Input

The input files in R are passed via 

#### Output


#### Wrapper


#### Other components and their detailed reference
- If not using [Planemo](https://planemo.readthedocs.org/en/latest/) and [ToolShed](https://wiki.galaxyproject.org/ToolShed), once you are done with your wrapper locally, you *NEED* to tell Galaxy you have a new tool by doing this:
 1. Copy your own tool configuration file from the sample: ```cp $GALAXY_ROOT/config/tool_conf.xml.sample $GALAXY_ROOT/config/tool_conf.xml```
 2. Modify it by adding your own section and your wrapper inside like this: 
    ```
    <section name="MyTools" id="mTools">
         <tool file="myTools/toolExample.xml" />
    </section>
    ```
    More details [here](https://wiki.galaxyproject.org/Admin/Tools/AddToolTutorial#A4._Make_Galaxy_aware_of_the_new_tool:)
  3. Restart your Galaxy

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

There is another way to write wrappers without putting your script in a separate file. It can be integrated into your XML through the ```<configfile>``` tag. This way, the developer can avoid having a separate file for his Rscript. There are pros and cons to this method

Pros
1. Single file
2. 

---------
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


-------------------


R and Biocondutor tool wrapping tips
--------------------

#### Exit codes for R tools

#### How to handle inputs and outputs through getopt package

#### How to avoid the x11 trap      

#### Leverage Planemo to build and test your tools

#### Test Test and Test some more

#### R session running on your galaxy

You local machine is going to have you R_HOME set to your default R installtion. But you want to invoke the R installation with the galaxy tool dependency directory. The **tool-dependency** directory is set via your galaxy.ini file. 

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


--------

Join the Galaxy Community
--------------

1. [https://github.com/galaxyproject](https://github.com/galaxyproject)
2. [https://usegalaxy.org](https://usegalaxy.org)
3. [https://galaxyproject.org](https://galaxyproject.org)
4. [https://github.com/galaxyproject/tools-iuc](https://github.com/galaxyproject/tools-iuc)
5. [https://github.com/galaxyproject/tools-devteam](https://github.com/galaxyproject/tools-devteam)
6. #galaxyproject on IRC (server: irc.freenode.net)


[![](https://wiki.galaxyproject.org/Images/GalaxyLogos?action=AttachFile&do=get&target=galaxy_logo_25percent.png)](https://github.com/galaxyproject)

**NOTE** These tool design models will be constantly improving, if you see any changes that need to be made, please send me a pull request with the material or file an issue. Help from the community to improve this document is always welcome.
