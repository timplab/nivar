library(tidyverse)
library(Biostrings)
library(GenomicRanges)


datadir='/uru/Data/Nanopore/projects/nivar/paperfigs'

##write out repeats
asmraw=file.path(datadir, 'assembly', 'nivar.contigs.fasta')
raw=readDNAStringSet(asmraw)
removed=raw[c(16,17,18,20,21)]

removedfa=file.path(datadir, 'revision', 'removed.fa')
writeXStringSet(removed, removedfa)
