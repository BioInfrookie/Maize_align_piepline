#!/usr/bin/env Rscripts

## make qc stat
## save to a html file

args <- commandArgs(T)

library(dplyr)
library(patchwork)
library(prettydoc)

indir <- args[1]
filename <- args[2]
species_names <- args[3]
dir_in <- normalizePath(paste0(indir,"/Seq-qc.Rmd"), winslash = "\\", mustWork = NA)
rmarkdown::render(dir_in, html_pretty(),
                  params = list(input_dir = indir,file_name=filename,species_names=species_names),
                  output_file = paste0(filename, "-","report", ".html"))
