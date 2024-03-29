source("~/Development/GeneralPurpose/R/amILocal.R")
source("~/Development/GeneralPurpose/R/heatmap.3.R")
source("~/Development/GeneralPurpose/R/lsos.R")
require(deepToolsUtils)
require(biomaRt)
require(tidyr)
require(rtracklayer)
require(RColorBrewer)

ensemblHost <- "mar2016.archive.ensembl.org"
dataset <- "hsapiens_gene_ensembl"
biomart <- "ensembl"
colors <- RColorBrewer::brewer.pal(3, "Set2")

if (amILocal("JCSMR027564ML")){
setwd("~/mount/gduserv/Data/Tremethick/Breast/RNA-Seq/NB501086_0067_RDomaschenz_JCSMR_RNASeq/R_Analysis/")
load("~/mount/gduserv/Data/References/Annotations/Homo_sapiens/GRCh38_ensembl84/hsapiens_gene_ensembl_GRCh38.rda")
dataPath <- "~/mount/gduserv/Data/Tremethick/Breast/RNA-Seq/NB501086_0067_RDomaschenz_JCSMR_RNASeq/processed_data/GRCh38_ensembl84_ERCC/HTSeq/count/"
} else {
setwd("~/Data/Tremethick/Breast/RNA-Seq/NB501086_0067_RDomaschenz_JCSMR_RNASeq/R_Analysis/")
load("~/Data/References/Annotations/Homo_sapiens/GRCh38_ensembl84/hsapiens_gene_ensembl_GRCh38.rda")
dataPath <- "~/Data/Tremethick/Breast/RNA-Seq/NB501086_0067_RDomaschenz_JCSMR_RNASeq/processed_data/GRCh38_ensembl84_ERCC/HTSeq/count/"
}

files <- list.files(path = dataPath, full.names = T)
names(files) <- list.files(path = dataPath, full.names = F)

# preparing annotation data from Ensembl ----------------------------------
if (!file.exists("ensGenes.rda")){
  mart <- biomaRt::useEnsembl(biomart = biomart, dataset = dataset, host = ensemblHost)
                              attribs <- biomaRt::listAttributes(mart)
                              ensGenes <- biomaRt::getBM(attributes = c("ensembl_gene_id",
                              "external_gene_name",
                              "chromosome_name",
                              "start_position",
                              "end_position",
                              "strand",
                              "band",
                              "description",
                              "percentage_gc_content",
                              "gene_biotype"),
                              mart = mart)
  save(ensGenes, file = "ensGenes.rda")

  # get Ensembl transcripts
  ensTranscripts <- biomaRt::getBM(attributes = c("ensembl_transcript_id",
                                                  "ensembl_gene_id",
                                                  "transcript_length",
                                                  "version", 
                                                  "transcript_version",
                                                  "external_gene_name"),
                                   mart = mart,
                                   filter = "ensembl_gene_id",
                                   values = ensGenes$ensembl_gene_id)
  save(ensTranscripts, file = "ensTranscripts.rda")
  
  # create t2g object
  t2g <- ensTranscripts[, c("ensembl_transcript_id", 
                            "ensembl_gene_id", 
                            "external_gene_name", 
                            "version", 
                            "transcript_version")]
  t2g$ensembl_transcript_id <- paste(t2g$ensembl_transcript_id, t2g$transcript_version, sep = ".")
  t2g <- dplyr::rename(t2g, target_id = ensembl_transcript_id, ens_gene = ensembl_gene_id, ext_gene = external_gene_name)
  save(t2g, file = "t2g.rda")
  
  mylength <- sapply(ensGenes$ensembl_gene_id, function(x){
    y <- ensTranscripts[which(ensTranscripts$ensembl_gene_id == x), ]
    y <- y[which.max(y$transcript_length), ]$transcript_length})
  save(mylength, file = "mylength.rda")
  mygc <- ensGenes$percentage_gc_content
  names(mygc) <- ensGenes$ensembl_gene_id
  save(mygc, file = "mygc.rda")
  mybiotypes <- ensGenes$gene_biotype
  names(mybiotypes) <- ensGenes$ensembl_gene_id
  save(mybiotypes, file = "mybiotypes.rda")
  mychroms <- data.frame(Chr = ensGenes$chromosome_name, GeneStart = ensGenes$start_position, GeneEnd = ensGenes$end_position)
  save(mychroms, file = "mychroms.rda")
  } else {
  load("ensGenes.rda")
  load("ensTranscripts.rda")
  load("mylength.rda")
  load("mygc.rda")
  load("mybiotypes.rda")
  load("mychroms.rda")
  load("t2g.rda")
}


if (!file.exists("htSeqCountMatrix.rda")){
  htSeqCountMatrix <- makeHTSeqCountMatrix(files)
  # remove the HTSeq count summary stats
  startn <- nrow(htSeqCountMatrix)-4
  endn <- nrow(htSeqCountMatrix)
  htSeqCountReport <- htSeqCountMatrix[startn:endn, ]
  htSeqCountMatrix <- htSeqCountMatrix[-(startn:endn), ]
  save(htSeqCountMatrix, file = "htSeqCountMatrix.rda")
  } else {
  load("htSeqCountMatrix.rda")
}
colnames(htSeqCountMatrix)


htSeqCountMatrixList <- htSeqCountMatrix
names(htSeqCountMatrixList) <- "all"
htSeqCountMatrixList[["a;;"]]
htSeqCountMatrixList[["all"]]
dim(htSeqCountMatrix)
htSeqCountMatrixList <- list("all" = htSeqCountMatrix)
dim(htSeqCountMatrix)
head(htSeqCountMatrixList[["all"]])
require(edgeR)
require(NOISeq)
require(RUVSeq)
require(EDASeq)
analysis_version <- 1
analysis_output_file <- paste("DifferentialGeneExpressionAnalysis_", analysis_version, ".rda", sep = "")
LEplotRUVg = rleRUVg,
PCAplotRUVg = pcaRUVg,
DGEList = y,
glmFit = fit,
glmLRT = lrt,
topTags = tt,
AnnotatedTopTags = annotatedTT,
DGEList_noRUV = y1,
glmFit_noRUV = fit1,
glmLRT_noRUV = lrt1,
topTags_noRUV = tt1,
AnnotatedTopTags_noRUV = annotatedTT1,
NOISeqRaw = list(mydata = mydata,
myexplodata = myexplodata,
mybiodetection = mybiodetection,
mycountsbio = mycountsbio,
mysaturation = mysaturation,
mylengthbias = mylengthbias,
myGCbias = myGCbias,
mycd = mycd),
NOISeqNorm = list(mydataNorm = mydataNorm,
myexplodataNorm = myexplodataNorm,
mybiodetectionNorm = mybiodetectionNorm,
mycountsbioNorm = mycountsbioNorm,
mysaturationNorm = mysaturationNorm,
mylengthbiasNorm = mylengthbiasNorm,
myGCbiasNorm = myGCbiasNorm,
mycdNorm = mycdNorm)))
})
names(processedData) <- names(htSeqCountMatrix.brain)
save(processedData, file = analysis_output_file)
} else {
load(analysis_output_file)
}
# actual processing -------------------------------------------------------
if (!file.exists(analysis_output_file)){
processedData <- lapply(names(htSeqCountMatrixList), function(x){
original <- htSeqCountMatrixList[[x]]
filter <- apply(original, 1, function(y) length(y[y>5])>=2)
filtered <- original[filter, ]
genes <- rownames(filtered)[grep("ENS", rownames(filtered))]
spikes <- rownames(filtered)[grep("ERCC", rownames(filtered))]
#---------------------------------------------
# create expression set
condition <- as.factor(unlist(lapply(strsplit(colnames(filtered), "_"), function(z) z[3])))
condition <- factor(condition, levels(condition)[c(2,1)])
set <- newSeqExpressionSet(as.matrix(filtered),
phenoData = data.frame(condition, row.names=colnames(filtered)))
#---------------------------------------------
# data exploration
rle <- plotRLE(set, outline = FALSE, col = colors[condition])
pca <- plotPCA(set, col = colors[condition])
#---------------------------------------------
# NOISeq analysis
# create eSet
tissue <- as.factor(unlist(lapply(strsplit(colnames(original), "_"), function(z) z[4])))
myfactors <- data.frame(Tissue = tissue, Condition = condition)
mydata <- NOISeq::readData(data = original,
length = mylength,
gc = mygc,
biotype = mybiotypes,
chromosome = mychroms,
factors = myfactors)
# actual data exploration
myexplodata <- dat(mydata, type = "biodetection")
mybiodetection <- dat(mydata, k = 0, type = "biodetection", factor = NULL)
mycountsbio <- dat(mydata, factor = NULL, type = "countsbio")
mysaturation <- dat(mydata, k = 0, ndepth = 10, type = "saturation")
# checking biases
# length
mylengthbias <- dat(mydata, factor = "Tissue", type = "lengthbias")
myGCbias <- dat(mydata, factor = "Tissue", type = "GCbias")
# compositional bias
mycd <- dat(mydata, type = "cd", norm = FALSE, refColumn = 1)
#---------------------------------------------
# upper quartile normalization
set <- betweenLaneNormalization(set, which="upper")
rleUQ <- plotRLE(set, outline = FALSE, col = colors[condition])
pcaUQ <- plotPCA(set, col = colors[condition])
#---------------------------------------------
# RUVg using spike ins
set1 <- RUVg(set, spikes, k = 1)
rleRUVg <- plotRLE(set1, outline=FALSE, col=colors[condition])
pcaRUVg <- plotPCA(set1, col=colors[condition], cex=1.2)
#---------------------------------------------
# NOISeq post-normalization & RUV
mydataNorm <- NOISeq::readData(data = normCounts(set1),
length = mylength,
gc = mygc,
biotype = mybiotypes,
chromosome = mychroms,
factors = myfactors)
# actual data exploration
myexplodataNorm <- dat(mydataNorm, type = "biodetection", norm = TRUE)
mybiodetectionNorm <- dat(mydataNorm, k = 0, type = "biodetection", factor = NULL, norm = TRUE)
mycountsbioNorm <- dat(mydataNorm, factor = NULL, type = "countsbio",  norm = TRUE)
mysaturationNorm <- dat(mydataNorm, k = 0, ndepth = 10, type = "saturation", norm = TRUE)
# checking biases
# length
mylengthbiasNorm <- dat(mydataNorm, factor = "Tissue", type = "lengthbias", norm = TRUE)
myGCbiasNorm <- dat(mydataNorm, factor = "Tissue", type = "GCbias", norm = TRUE)
# compositional bias
mycdNorm <- dat(mydataNorm, type = "cd", refColumn = 1, norm = TRUE)
#---------------------------------------------
# differential expression analysis using edgeR
# here including the RUVg factor to account for "unwanted variation"
design <- model.matrix(~condition + W_1, data = pData(set1))
y <- DGEList(counts = counts(set1), group = condition)
y <- calcNormFactors(y, method="upperquartile")
y <- estimateGLMCommonDisp(y, design)
y <- estimateGLMTagwiseDisp(y, design)
fit <- glmFit(y, design)
lrt <- glmLRT(fit, coef=2)
tt <- topTags(lrt, n = 5000)
annotatedTT <- merge(tt[[1]], ensGenes, by.x = "row.names", by.y = "ensembl_gene_id")
#---------------------------------------------
# differential expression analysis using plain vanilla edgeR
design1 <- model.matrix(~condition, data = pData(set))
y1 <- DGEList(counts = counts(set), group = condition)
y1 <- calcNormFactors(y1, method="upperquartile")
y1 <- estimateGLMCommonDisp(y1, design1)
y1 <- estimateGLMTagwiseDisp(y1, design1)
fit1 <- glmFit(y1, design1)
lrt1 <- glmLRT(fit1, coef=2)
tt1 <- topTags(lrt1, n = 5000)
annotatedTT1 <- merge(tt1[[1]], ensGenes, by.x = "row.names", by.y = "ensembl_gene_id", all.x = T, sort = F)
#---------------------------------------------
# return all objects
return(list(original = original,
filtered = filtered,
genes = genes,
spikes = spikes,
eSet = set,
RLEplot = rle,
PCAplot = pca,
RLEplotUQ = rleUQ,
RLEplotPCA = pcaUQ,
eSetRUVg = set1,
RLEplotRUVg = rleRUVg,
PCAplotRUVg = pcaRUVg,
DGEList = y,
glmFit = fit,
glmLRT = lrt,
topTags = tt,
AnnotatedTopTags = annotatedTT,
DGEList_noRUV = y1,
glmFit_noRUV = fit1,
glmLRT_noRUV = lrt1,
topTags_noRUV = tt1,
AnnotatedTopTags_noRUV = annotatedTT1,
NOISeqRaw = list(mydata = mydata,
myexplodata = myexplodata,
mybiodetection = mybiodetection,
mycountsbio = mycountsbio,
mysaturation = mysaturation,
mylengthbias = mylengthbias,
myGCbias = myGCbias,
mycd = mycd),
NOISeqNorm = list(mydataNorm = mydataNorm,
myexplodataNorm = myexplodataNorm,
mybiodetectionNorm = mybiodetectionNorm,
mycountsbioNorm = mycountsbioNorm,
mysaturationNorm = mysaturationNorm,
mylengthbiasNorm = mylengthbiasNorm,
myGCbiasNorm = myGCbiasNorm,
mycdNorm = mycdNorm)))
})
names(processedData) <- names(htSeqCountMatrix.brain)
save(processedData, file = analysis_output_file)
} else {
load(analysis_output_file)
}
x <- all
original <- htSeqCountMatrixList[[x]]
head(htSeqCountMatrixList[["all"]])
original <- htSeqCountMatrixList[[x]][[1]]
x
x <- "all"
original <- htSeqCountMatrixList[[x]][[1]]
dim(original)
original <- htSeqCountMatrixList[[x]]
dim(original)
filter <- apply(original, 1, function(y) length(y[y>5])>=2)
filtered <- original[filter, ]
genes <- rownames(filtered)[grep("ENS", rownames(filtered))]
spikes <- rownames(filtered)[grep("ERCC", rownames(filtered))]
length(genes)
length(spikes)
condition <- as.factor(unlist(lapply(strsplit(colnames(filtered), "_"), function(z) z[3])))
condition
head(colnames(filtered))
colnames(filtered)
colnames(htSeqCountMatrix)
colnames(htSeqCountMatrix)["MCF10A_rep1", "MCF10A_rep1"]
colnames(htSeqCountMatrix)[c("MCF10A_rep1", "MCF10A_rep1")]
grep(colnames(htSeqCountMatrix), c("MCF10A_rep1", "MCF10A_rep2"))
grep(colnames(htSeqCountMatrix), paste(c("MCF10A_rep1", "MCF10A_rep2"), collapse = "|"))
paste(c("MCF10A_rep1", "MCF10A_rep2"), collapse = "|")
grep(paste(c("MCF10A_rep1", "MCF10A_rep2"), collapse = "|"), colnames(htSeqCountMatrix))
grep(paste(c("MCF10A_rep1", "MCF10A_rep2", "MCF10Ca1a_rep1", "MCF10Ca1a_rep2"), collapse = "|"), colnames(htSeqCountMatrix))
colnames(htSeqCountMatrix)[grep(paste(c("MCF10A_rep1", "MCF10A_rep2", "MCF10Ca1a_rep1", "MCF10Ca1a_rep2"), collapse = "|"), colnames(htSeqCountMatrix))]
unlist(lapply(strsplit(c("MCF10A_rep1", "MCF10A_rep2", "MCF10Ca1a_rep1", "MCF10Ca1a_rep2"), "_")),
function(x) paste(x[1], "wt", x[2], collapse = "_"))
strsplit(c("MCF10A_rep1", "MCF10A_rep2", "MCF10Ca1a_rep1", "MCF10Ca1a_rep2"), "_")
unlist(lapply(strsplit(c("MCF10A_rep1", "MCF10A_rep2", "MCF10Ca1a_rep1", "MCF10Ca1a_rep2"), "_"),
function(x) paste(x[1], "wt", x[2], collapse = "_")))
unlist(lapply(strsplit(c("MCF10A_rep1", "MCF10A_rep2", "MCF10Ca1a_rep1", "MCF10Ca1a_rep2"), "_"),
function(x) paste(x[1], "wt", x[2], sep = "_")))
newColNames <- unlist(lapply(strsplit(c("MCF10A_rep1", "MCF10A_rep2", "MCF10Ca1a_rep1", "MCF10Ca1a_rep2"), "_"), function(x) paste(x[1], "wt", x[2], sep = "_")))
newColNames
colnames(htSeqCountMatrix)[grep(paste(c("MCF10A_rep1", "MCF10A_rep2", "MCF10Ca1a_rep1", "MCF10Ca1a_rep2"),
collapse = "|"),
colnames(htSeqCountMatrix))] <- newColNames
colnames(htSeqCountMatrix)
htSeqCountMatrixList <- list("all" = htSeqCountMatrix)
c
x
original <- htSeqCountMatrixList[[x]]
filter <- apply(original, 1, function(y) length(y[y>5])>=2)
filtered <- original[filter, ]
genes <- rownames(filtered)[grep("ENS", rownames(filtered))]
spikes <- rownames(filtered)[grep("ERCC", rownames(filtered))]
condition <- as.factor(unlist(lapply(strsplit(colnames(filtered), "_"), function(z) z[1:2])))
condition
condition <- as.factor(unlist(lapply(strsplit(colnames(filtered), "_"), function(z) paste(z[1:2], collapse = "_"))))
condition
condition <- factor(condition, levels(condition)[c(3,2,1,5,4)])
condition
set <- newSeqExpressionSet(as.matrix(filtered),
phenoData = data.frame(condition, row.names=colnames(filtered)))
rle <- plotRLE(set, outline = FALSE, col = colors[condition])
colors <- RColorBrewer::brewer.pal(5, "Set2")
rle <- plotRLE(set, outline = FALSE, col = colors[condition])
pca <- plotPCA(set, col = colors[condition])
mychroms
dim(mychroms)
head(mychroms)
dim(ensGenes)
length(unique(ensGenes$ensembl_gene_id))
which(duplicated(ensGenes$ensembl_gene_id))
ensGenes[which(duplicated(ensGenes$ensembl_gene_id)),]
table(ensGenes$chromosome_name)
file.remove("ensGenes.rda")
if (!file.exists("ensGenes.rda")){
mart <- biomaRt::useEnsembl(biomart = biomart, dataset = dataset, host = ensemblHost)
attribs <- biomaRt::listAttributes(mart)
ensGenes <- biomaRt::getBM(attributes = c("ensembl_gene_id",
"external_gene_name",
"chromosome_name",
"start_position",
"end_position",
"strand",
"band",
"description",
"percentage_gc_content",
"gene_biotype"),
mart = mart)
ensGenes <- ensGenes[-which(duplicated(ensGenes$ensembl_gene_id)),]
save(ensGenes, file = "ensGenes.rda")
ensTranscripts <- biomaRt::getBM(attributes = c("ensembl_gene_id",
"ensembl_transcript_id",
"transcript_length"),
mart = mart,
filter = "ensembl_gene_id",
values = ensGenes$ensembl_gene_id)
save(ensTranscripts, file = "ensTranscripts.rda")
mylength <- sapply(ensGenes$ensembl_gene_id, function(x){
y <- ensTranscripts[which(ensTranscripts$ensembl_gene_id == x), ]
y <- y[which.max(y$transcript_length), ]$transcript_length
})
save(mylength, file = "mylength.rda")
mygc <- ensGenes$percentage_gc_content
names(mygc) <- ensGenes$ensembl_gene_id
save(mygc, file = "mygc.rda")
mybiotypes <- ensGenes$gene_biotype
names(mybiotypes) <- ensGenes$ensembl_gene_id
save(mybiotypes, file = "mybiotypes.rda")
mychroms <- data.frame(Chr = ensGenes$chromosome_name, GeneStart = ensGenes$start_position, GeneEnd = ensGenes$end_position)
rownames(mychroms) <- ensGenes$ensembl_gene_id
save(mychroms, file = "mychroms.rda")
} else {
load("ensGenes.rda")
load("ensTranscripts.rda")
load("mylength.rda")
load("mygc.rda")
load("mybiotypes.rda")
load("mychroms.rda")
}
mychroms
cellLine <- as.factor(unlist(lapply(strsplit(colnames(original), "_"), function(z) z[1])))
myfactors <- data.frame(CellLine = cellLine, Condition = condition)
myfactors
mydata <- NOISeq::readData(data = original,
length = mylength,
gc = mygc,
biotype = mybiotypes,
chromosome = mychroms,
factors = myfactors)
# actual data exploration
myexplodata <- dat(mydata, type = "biodetection")
mybiodetection <- dat(mydata, k = 0, type = "biodetection", factor = NULL)
mycountsbio <- dat(mydata, factor = NULL, type = "countsbio")
mysaturation <- dat(mydata, k = 0, ndepth = 10, type = "saturation")
# checking biases
# length
mylengthbias <- dat(mydata, factor = "Tissue", type = "lengthbias")
myGCbias <- dat(mydata, factor = "Tissue", type = "GCbias")
# compositional bias
mycd <- dat(mydata, type = "cd", norm = FALSE, refColumn = 1)
set <- betweenLaneNormalization(set, which="upper")
rleUQ <- plotRLE(set, outline = FALSE, col = colors[condition])
pcaUQ <- plotPCA(set, col = colors[condition])
