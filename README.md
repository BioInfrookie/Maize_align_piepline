# Maize_align_piepline
### Transcriptome dynamic landscape underlying the improvement of maize lodging resistance under coronatine treatment

  Ren, Z., Wang, X., Tao, Q. *et al.* Transcriptome dynamic landscape underlying the improvement of maize lodging resistance under coronatine treatment. *BMC Plant Biol* **21**, 202 (2021).

**Availability of data：`PRJNA633707`**

**Abstract：**在这项研究中，我们发现冠状菌素（COR）作为一种新的植物生长调节剂，能够通过抑制茎间节在伸长过程中的生长，有效降低杂交种（ZD958和XY335）和自交系（B73）玉米的植株高度和穗位，从而提高玉米的抗倒伏性。为了研究COR处理后茎间节基因表达的变化，我们收集了自交系B73茎间节在正常条件和COR处理下的时空转录组。

PS：冠菌素（COR）是一种新型的植物生长调节剂，它是茉莉酸（JA）的结构类似物，是全球第一个实现产业化的茉莉酸类分子信号调控剂。

**Data select ：** 

  选取COR/H20 处理4天后，取玉米茎秆提取RNA测序

```Shell
SRR11809690	WT_internode_rep1
SRR11809691	WT_internode_rep2
SRR11809722	COR_internode_rep1
SRR11809723	COR_internode_rep2
```


**Code availability：**[https://github.com/BioInfrookie/Maize_align_piepline/tree/master](https://github.com/BioInfrookie/Maize_align_piepline/tree/master)

**Refence：**[https://ftp.ebi.ac.uk/ensemblgenomes/pub/release-57/plants/fasta/zea_mays/dna/Zea_mays.Zm-B73-REFERENCE-NAM-5.0.dna.toplevel.fa.gz](https://ftp.ebi.ac.uk/ensemblgenomes/pub/release-57/plants/fasta/zea_mays/dna/Zea_mays.Zm-B73-REFERENCE-NAM-5.0.dna.toplevel.fa.gz)

**GTF：**[https://ftp.ebi.ac.uk/ensemblgenomes/pub/release-57/plants/gtf/zea_mays/Zea_mays.Zm-B73-REFERENCE-NAM-5.0.57.gtf.gz](https://ftp.ebi.ac.uk/ensemblgenomes/pub/release-57/plants/gtf/zea_mays/Zea_mays.Zm-B73-REFERENCE-NAM-5.0.57.gtf.gz)

```Shell
# step1
bash Seq_group.sh -C WT_internode -M COR_internode -r ./ -b COR.tb

# step2
bash Seq_align.sh -b COR.tb -o ../02-result -g B73
```


