#!/bin/bash
# 对 RNA-seq数据处理

help_str="
参数说明：
  -b:	数据分组结果（Seq_group）
  -o:	输出文件夹
  -g:	基因组数据 (Example:B73)
  -h：	help document
"
# 解析命令行
getopt_cmd=$(getopt -o b:o:g:h --long help -n $(basename $0) -- "$@")
[ $? -ne 0 ] && exit 1
eval set -- "$getopt_cmd"
# 解析选项
while [ -n "$1" ]
do
    case "$1" in
        -b)
            input_file="$2"
            shift ;;
        -g)
			if [ $2=="B73" ];then
            	genome="/data/yulab/qzh/Analysis/qzh/data_Ref/Maize/STAR_index"
				mtRNA="/data/yulab/qzh/Analysis/qzh/data_Ref/Maize/bowtie2_index/B73_MT"
				chloroRNA="/data/yulab/qzh/Analysis/qzh/data_Ref/Maize/bowtie2_index/B73_Chloro"
				MT_chloroRNA="/data/yulab/qzh/Analysis/qzh/data_Ref/Maize/bowtie2_index/B73_MT_Chloro"
			fi
			shift ;;
        -o)
            out_dir="$2"
            shift ;;
		-h|--help)
            echo -e "$help_str"
            exit ;;
        --) shift
            break ;;
         *) echo "$1 is not an option"
            exit 1 ;;
    esac
    shift
done

# function design
function clean_reads(){
    /data/yulab/qzh/Analysis/qzh/software/TrimGalore-0.6.6/trim_galore -q 30 \
		--length 60 --phred33 -e 0.1 -j 10 \
		--stringency 3 --paired -o $3 $1 $2
}
function align_mt {
    /data/yulab/qzh/anaconda3/envs/hiseq/bin/bowtie2 \
		--mm -p 10 -q --local --un-conc-gz $3/$(basename $1 "_1_val_1.fq.gz")_unmap \
		--very-sensitive --no-unal --no-mixed --no-discordant  -I 10 -X 700  \
		-x $4 -1 $1 -2 $2 1>$3/$(basename $1 "_1_val_1.fq.gz")_rRNA.sam \
		2> $3/$(basename $1 "_1_val_1.fq.gz")_rRNA.bowtie2.log && samtools view -Sub <(samtools view -H $3/$(basename $1 "_1_val_1.fq.gz")_rRNA.sam; samtools view -F 2048 $3/$(basename $1 "_1_val_1.fq.gz")_rRNA.sam | \
		grep 'YT:Z:CP') | samtools sort -@ 6 -o $3/$(basename $1 "_1_val_1.fq.gz")_rRNA.bam - && \
		samtools index $3/$(basename $1 "_1_val_1.fq.gz")_rRNA.bam
}
function align_genome(){
    STAR --runThreadN 10 --genomeDir $4 \
        --runMode alignReads \
        --readFilesCommand zcat \
        --limitBAMsortRAM 10000000000 \
        --readFilesIn $1 $2 \
        --outFileNamePrefix $3/$(basename $1 "_unmap.1")_ \
        --outSAMtype BAM SortedByCoordinate \
        --outBAMsortingThreadN 5 \
        --outFilterMismatchNoverLmax 0.07 \
        --seedSearchStartLmax 20 \
        --outFilterMultimapNmax 1 
}
function quantify(){
    featureCounts -T 5 -a /data/yulab/qzh/Analysis/qzh/data_Ref/Maize/Zea.gtf \
		-o $2/$(basename $1 "_Aligned.sortedByCoord.out.bam").count \
		-p -B -C -t exon -g gene_id $1
}

# pipeline
mkdir -p ${out_dir}
cat ${input_file} | while read rep1 rep2 group;
do	
	sample_name=$(basename $rep1 "_1.fq.gz")
	# Step1 clean adapter
	echo "Step1 clean reads"
	mkdir -p ${out_dir}/${sample_name}/01-clean_reads
	raw_read=`seqkit stat ${rep1} | tail -n 1 | awk '{print $4}' | sed "s/,//g"`
	[[ -f ${out_dir}/${sample_name}/01-clean_reads/${sample_name}_1_val_1.fq.gz ]] || clean_reads ${rep1} ${rep2} ${out_dir}/${sample_name}/01-clean_reads
	wait
	clean_read=`seqkit stat ${out_dir}/${sample_name}/01-clean_reads/${sample_name}_1_val_1.fq.gz | tail -n 1 | awk '{print $4}' | sed "s/,//g"`
	
	# Step2 trim ncRNA
	echo "Step2 trim ncRNA"
	mkdir -p ${out_dir}/${sample_name}/02-align_rRNA
	[[ -f ${out_dir}/${sample_name}/02-align_rRNA/${sample_name}_rRNA.sam ]] || align_mt ${out_dir}/${sample_name}/01-clean_reads/${sample_name}_1_val_1.fq.gz ${out_dir}/${sample_name}/01-clean_reads/${sample_name}_2_val_2.fq.gz ${out_dir}/${sample_name}/02-align_rRNA ${MT_chloroRNA}
	ncRNA_read=`cat ${out_dir}/${sample_name}/02-align_rRNA/${sample_name}_rRNA.bowtie2.log | sed -n 4,5p | awk '{sum+=$1} END{print sum}'`
	wait
	
	# Step3 map genome
	echo "Step3 map genome"
	mkdir -p ${out_dir}/${sample_name}/03-align_genome
	[[ -f ${out_dir}/${sample_name}/03-align_genome/${sample_name}_Aligned.sortedByCoord.out.bam ]] || align_genome ${out_dir}/${sample_name}/02-align_rRNA/${sample_name}_unmap.1 ${out_dir}/${sample_name}/02-align_rRNA/${sample_name}_unmap.2 ${out_dir}/${sample_name}/03-align_genome ${genome}
	map_read=`cat ${out_dir}/${sample_name}/03-align_genome/${sample_name}_Log.final.out | sed -n 9p | cut -f2`
	input_read=`cat ${out_dir}/${sample_name}/03-align_genome/${sample_name}_Log.final.out | sed -n 6p | cut -f2`
	wait

	# Step4 quantify counts
	echo "Step4 quantify counts"
	mkdir -p ${out_dir}/${sample_name}/04-counts
	[[ -f ${out_dir}/${sample_name}/04-counts/${sample_name}.count ]] || quantify ${out_dir}/${sample_name}/03-align_genome/${sample_name}_Aligned.sortedByCoord.out.bam ${out_dir}/${sample_name}/04-counts
	cat ${out_dir}/${sample_name}/04-counts/${sample_name}.count | tail -n +3 | cut -f1,7 | awk -v sample=${sample_name} 'BEGIN{print "gene_id\t"sample}{print $0}' > ${out_dir}/${sample_name}/04-counts/${sample_name}_count.txt
	wait

	# Step5 Summary
	echo "Step5 Summary reporter"
	mkdir -p ${out_dir}/${sample_name}/05-reporter
	echo -e "${sample_name}\t${group}\t${raw_read}\t${clean_read}\t${ncRNA_read}\t${input_read}\t${map_read}" > ${out_dir}/${sample_name}/05-reporter/01_reads.txt
	wait
done

mkdir -p ${out_dir}/Summary
echo -e "sample\tgroup\traw_reads\tclean_reads\tncRNA_reads\tinput_reads\tmap_reads" > ${out_dir}/Summary/00-header
cat ${out_dir}/Summary/00-header ${out_dir}/*/05-reporter/01_reads.txt > ${out_dir}/Summary/01_merge_reads.txt

paste ${out_dir}/*/04-counts/*_count.txt | cut -f1 > ${out_dir}/Summary/gene_id.txt
paste ${out_dir}/*/04-counts/*_count.txt | awk -F '\t' '{for(i=1;i<=NF;i++){if(i%2==0){printf $i"\t"}}printf"\n"}' > ${out_dir}/Summary/gene_counts.txt
paste ${out_dir}/Summary/gene_id.txt ${out_dir}/Summary/gene_counts.txt > ${out_dir}/Summary/02-megre_counts.txt
rm ${out_dir}/Summary/gene_id.txt ${out_dir}/Summary/gene_counts.txt

Script_dir=$(dirname $(readlink -f "$0"))
work_dir=$(dirname $(readlink -f "${out_dir}/Summary/gene_counts.txt"))
cp ${Script_dir}/Seq-qc.R ${work_dir}
cp ${Script_dir}/Seq-qc.Rmd ${work_dir}
Rscript ${work_dir}/Seq-qc.R ${work_dir} ${input_file%.*}