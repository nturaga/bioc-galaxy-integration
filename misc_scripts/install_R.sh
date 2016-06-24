sudo apt-get install libgsl-dev

brew install gsl

sudo Rscript --slave --no-save --no-restore-history -e "source('http://bioconductor.org/biocLite.R'); biocLite('motifbreakR'); biocLite('Rgraphviz');"

Rscript --slave --no-save --no-restore-history -e "library('motifbreakR')"
