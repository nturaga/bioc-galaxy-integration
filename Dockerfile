# Dockerfile for integrating R/BioConductor tools in Galaxy
# This is a supplement to the paper DOI: 
#
# Maintainer: Nitesh Turaga 
# email: nitesh dot turaga at gmail dot com

# Build with: docker build -t <name>/testdocker:v2 .
# Run with: docker run -ti -p 8080:80 <name>/testdocker:v2 /bin/bash
# Galaxy will be accessible on the host on 127.0.0.1:8080

# PULL base image
FROM r-base:latest

## Install pip, git
RUN apt-get update \
	&& apt-get install -y python-pip git vim curl

## Install local Galaxy
RUN git clone https://github.com/galaxyproject/galaxy.git

## Install planemo
RUN pip install planemo

## Add BiocInstaller to R (needed to use biocLite())
RUN Rscript -e "source('http://bioconductor.org/biocLite.R')"
RUN echo "library(BiocInstaller)" > $HOME/.Rprofile

## Install R dependencies
RUN Rscript -e "install.packages('getopt')"
RUN Rscript -e "biocLite('affy')"
RUN Rscript -e "biocLite('seqTools')"

EXPOSE :80

## Copy tool_conf.xml for editing
ADD paper_supp_files/tool_conf.xml /galaxy/config/tool_conf.xml

## Upload galaxy.ini from host
## This file contains changes to host/port for viewing Galaxy in browser
ADD paper_supp_files/galaxy.ini /galaxy/config/galaxy.ini

## Make new tool directory
RUN mkdir /galaxy/tools/mytools
RUN mkdir /galaxy/tools/mytools/test_data

## Upload seqTools example files
ADD paper_supp_files/my_seqTools_tool.R /galaxy/tools/mytools/my_seqTools_tool.R
ADD paper_supp_files/my_seqTools_tool.xml /galaxy/tools/mytools/my_seqTools_tool.xml
ADD paper_supp_files/tool_dependencies.xml /galaxy/tools/mytools/tool_dependencies.xml

## Upload affy example files
ADD paper_supp_files/my_affy_tool.R /galaxy/tools/mytools/my_affy_tool.R
ADD paper_supp_files/my_affy_tool.xml /galaxy/tools/mytools/my_affy_tool.xml
ADD paper_supp_files/my_affy_tool_Case2.xml /galaxy/tools/mytools/my_affy_tool_Case2.xml

## Automatically run Galaxy
#CMD ["sh /galaxy/run.sh"]

