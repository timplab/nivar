#!/bin/bash

datadir=/uru/Data/Nanopore/projects/nivar/paperfigs

if [ $1 == repeat_check ] ; then
    ##mummer deleted repeats to check they appear elsewhere
    mkdir -p $datadir/revision/removed_mum
    
    nucmer -p $datadir/revision/removed_mum/removed \
	   $datadir/assembly_final/nivar.final.fasta \
	   $datadir/revision/removed.fa
    
    mummerplot --filter --fat --postscript \
	       -p $datadir/revision/removed_mum/removed \
	       $datadir/revision/removed_mum/removed.delta
    
    mummerplot --filter --fat --png \
	       -p $datadir/revision/removed_mum/removed \
	       $datadir/revision/removed_mum/removed.delta
    
    dnadiff -p $datadir/revision/removed_mum/removed \
	    $datadir/assembly_final/nivar.final.fasta \
	    $datadir/revision/removed.fa
fi

    
