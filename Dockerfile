# Dockerfile for integrating R/BioConductor tools in Galaxy
# This is a supplement to the paper DOI: 
#
# Maintainer: Nitesh Turaga 
# email: nitesh dot turaga at gmail dot com

# PULL base image
FROM r-base:latest

## Install pip
RUN apt-get update \
	&& apt-get install -y python-pip

## Install git + local Galaxy
RUN apt-get install -y git-all
RUN git clone -b release_16.07 https://github.com/galaxyproject/galaxy.git

## Install planemo
RUN pip install planemo

## Add BiocInstaller to R (needed to use biocLite())
ADD install.R /tmp/
RUN R -f /tmp/install.R && echo "library(BiocInstaller)" > $HOME/.Rprofile

## Install R dependencies
RUN Rscript -e "install.packages('getopt')"
RUN Rscript -e "biocLite('affy')"
RUN Rscript -e "biocLite('seqTools')"
