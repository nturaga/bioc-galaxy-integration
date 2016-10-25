# Dockerfile for integrating R/BioConductor tools in Galaxy
# This is a supplement to the paper DOI: 
#
# Maintainer: Nitesh Turaga 
# email: nitesh dot turaga at gmail dot com

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
RUN cp /galaxy/config/tool_conf.xml.sample /galaxy/config/tool_conf.xml

## Upload galaxy.ini from host
## This file contains changes to host/port for viewing Galaxy in browser
ADD galaxy.ini /galaxy/config/galaxy.ini

## Upload example tool files
RUN mkdir /galaxy/tools/mytools
RUN mkdir /galaxy/tools/mytools/test_data
ADD my_seqTools_tool.R /galaxy/tools/mytools/my_seqTools_tool.R
ADD my_seqTools_tool.xml /galaxy/tools/mytools/my_seqTools_tool.xml
ADD tool_dependencies.xml /galaxy/tools/mytools/tool_dependencies.xml
ADD test_data/test_input.fq.gz /galaxy/tools/mytools/test_data/test_input.fq.gz
ADD test_data/test_output.txt /galaxy/tools/mytools/test_data/test_output.txt

## Automatically run Galaxy
#CMD ["sh /galaxy/run.sh"]
