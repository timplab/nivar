library(tidyverse)
library(tidyr)
library(gridExtra)
library(Biostrings)
library(R.utils)
library(foreach)
library(doParallel)

dbxdir='~/Dropbox/yfan/nivar/'
datadir='/uru/Data/Nanopore/projects/nivar/paperfigs/'
asmfile=paste0(datadir,'assembly/nivar.contigs.fasta')
scafilegla=paste0(datadir,'medusa/glabrata/nivar.final.scaffold.fasta')
ragfilegla=paste0(datadir,'ragtag/glabrata/ragtag.scaffolds.fasta')
scafile=paste0(datadir,'medusa/nivariensis/nivar.final.scaffold.fasta')
ragfile=paste0(datadir,'ragtag/nivariensis/ragtag.scaffolds.fasta')
fbsfile=paste0(datadir,'freebayes/nivar_fb3_bwa.fasta')
reffile='/uru/Data/Nanopore/projects/nivar/reference/candida_nivariensis.fa'
glafile='/uru/Data/Nanopore/projects/nivar/reference/medusa_fungi/candida_glabrata.fa'


##check telomeres
fwdtelo='CTGGGTGCTGTGGGGT'
revtelo='ACCCCACAGCACCCAG'
telocheck <- function(asmfile, fwdtelo, revtelo) {
    asm=readDNAStringSet(asmfile)
    seqs=as.character(asm)
    
    teloinfo=tibble(chr=names(asm)) %>%
        mutate(length=width(asm[chr])) %>%
        mutate(fwd=str_count(as.character(asm[chr]), fwdtelo)) %>%
        mutate(rev=str_count(as.character(asm[chr]), revtelo))
}

scatelo=telocheck(scafile, fwdtelo, revtelo)
scatelogla=telocheck(scafilegla, fwdtelo, revtelo)
asmtelo=telocheck(asmfile, fwdtelo, revtelo)
ragtelo=telocheck(ragfile, fwdtelo, revtelo)
ragtelogla=telocheck(ragfilegla, fwdtelo, revtelo)
glatelo=telocheck(glafile, fwdtelo, revtelo)
fbstelo=telocheck(fbsfile, fwdtelo, revtelo)


scatelocsv=paste0(dbxdir,'/paperfigs/raw/telocounts_scaffold.csv')
write_csv(scatelo, scatelocsv)
asmtelocsv=paste0(dbxdir,'/paperfigs/raw/telocounts_assembly.csv')
write_csv(asmtelo, asmtelocsv)
ragtelocsv=paste0(dbxdir,'/paperfigs/raw/telocounts_ragtag.csv')
write_csv(ragtelo, ragtelocsv)


teloplot <- function(asmfile, fwdtelo, revtelo) {
    asm=readDNAStringSet(asmfile)

    teloinfo=foreach(i=1:length(asm), .combine=rbind) %dopar% {
        seq=as.character(asm[i])
        len=width(asm[i])
        
        fwdlocs=gregexpr(fwdtelo, seq)[[1]]
        fwdinfo=data.frame(telopos=fwdlocs, percpos=fwdlocs/len, telo='fwd', chr=names(asm[i]))
        revlocs=gregexpr(revtelo, seq)[[1]]
        revinfo=data.frame(telopos=revlocs, percpos=revlocs/len, telo='rev', chr=names(asm[i]))

        allinfo=rbind(fwdinfo, revinfo)
        return(allinfo)
    }
    cleanteloinfo=as_tibble(teloinfo) %>%
        mutate(name=asmfile) %>%
        filter(telopos!=-1)
    return(cleanteloinfo)
}        

asmteloplot=as_tibble(teloplot(asmfile, fwdtelo, revtelo)) %>%
    mutate(name='assembly')
scateloplot=as_tibble(teloplot(scafile, fwdtelo, revtelo)) %>%
    mutate(name='medusa')
ragteloplot=as_tibble(teloplot(ragfile, fwdtelo, revtelo)) %>%
    mutate(name='ragtag')
scateloplotgla=as_tibble(teloplot(scafilegla, fwdtelo, revtelo)) %>%
    mutate(name='medusa_glabrata')
ragteloplotgla=as_tibble(teloplot(ragfilegla, fwdtelo, revtelo)) %>%
    mutate(name='ragtag_glabrata')
refteloplot=as_tibble(teloplot(reffile, fwdtelo, revtelo)) %>%
    mutate(name='reference')
glateloplot=as_tibble(teloplot(glafile, fwdtelo, revtelo)) %>%
    mutate(name='glabrata')
fbsteloplot=as_tibble(teloplot(fbsfile, fwdtelo, revtelo)) %>%
    mutate(name='corrected')


##allteloplot=rbind(asmteloplot, scateloplot, ragteloplot, scateloplotgla, ragteloplotgla, refteloplot, glateloplot)
allteloplot=rbind(scateloplot, ragteloplot, scateloplotgla, ragteloplotgla)

teloplotfile=paste0(dbxdir, '/paperfigs/raw/teloplots.pdf')
pdf(teloplotfile, w=16, h=9)
ggplot(allteloplot, aes(x=percpos, colour=name, fill=name, alpha=.2)) +
    geom_histogram(position='identity') +
    facet_wrap(. ~ name, ncol=2) +
    ggtitle('Telo positions') +
    xlab('position (as percent of seq length)') +
    theme_bw()
dev.off()



##exclude sequences, extract mito
fbs=readDNAStringSet(fbsfile)
mito=fbs[19]
mitofile=paste0(datadir, 'assembly_final/nivar_fb3_bwa_mito.fasta')
writeXStringSet(mito, mitofile, format='fasta')


##cut mito based on mummer of nivar_fb3_bwa_mito.fasta
mumcols=c('refstart', 'refend', 'qstart', 'qend', 'rlen', 'qlen', 'ident', 'rtot', 'qtot', 'rperc', 'qperc', 'rname', 'qname')
mumfile=paste0(datadir, 'mummer/mito/nivar_mito.mcoords')
muminfo=read_tsv(mumfile, col_names=mumcols)
mitoextra=muminfo$qstart[1]-muminfo$qend[2]
mitolen=length(mito[[1]])-mitoextra
mitoclipped=DNAStringSet(mito[[1]][1:mitolen])
names(mitoclipped)='jhu_candida_nivariensis_seqMito'

newasm=c(fbs[-c(16, 17, 18, 19, 20, 21)], mitoclipped)
newasmfile=paste0(datadir, 'assembly_final/nivar.final.fasta')
writeXStringSet(newasm,newasmfile, format='fasta')


fintelo=telocheck(newasmfile, fwdtelo, revtelo)
fintelocsv=paste0(dbxdir,'/paperfigs/raw/telocounts_final.csv')
write_csv(fintelo, fintelocsv)

library(flextable)
telotable=paste0(dbxdir, '/paperfigs/raw/telocounts_final.docx')
fintelo=read_csv(fintelocsv, col_types='cccc')
ft=theme_vanilla(flextable(data=fintelo, col_keys=names(fintelo)))
save_as_docx('telo table'=ft, path=telotable)

finteloplot=as_tibble(teloplot(newasmfile, fwdtelo, revtelo)) %>%
    mutate(name='Assembly')
allteloplot=rbind(finteloplot, scateloplot, ragteloplot, scateloplotgla, ragteloplotgla)
finteloplotfile=paste0(dbxdir, '/paperfigs/raw/teloplots.pdf')
pdf(finteloplotfile, w=16, h=9)
ggplot(allteloplot, aes(x=percpos, colour=name)) +
    geom_histogram(position='identity', fill=NA) +
    ggtitle('Telo positions') +
    xlab('position (as percent of seq length)') +
    theme_bw()
dev.off()
