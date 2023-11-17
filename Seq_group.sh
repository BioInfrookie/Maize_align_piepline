#!/bin/bash
# 对 RNA-seq数据分组

help_str="
参数说明：
  -M, --Mut:	实验组Mut/Experiment
  -C, --WT:	对照组WT/Control
  -r:		数据目录位置
  -b:		输出文件(.tb)
"
# 解析命令行
getopt_cmd=$(getopt -o b:M:C:r:h --long Mut:,WT:,help -n $(basename $0) -- "$@")
[ $? -ne 0 ] && exit 1
eval set -- "$getopt_cmd"
# 解析选项
while [ -n "$1" ]
do
    case "$1" in
        -b)
            out_file="$2"
            shift ;;
        -r)
            data_dir_1="$2"
            shift ;;
        -C|--WT)
            WT_name="$2"
            shift ;;
        -M|--Mut)
            Mut_name="$2"
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

cd ${data_dir_1}
data_dir=`pwd`
rm ${data_dir}/${out_file}

ls ${data_dir}/*${WT_name}*_1.fq.gz | while read id;
do
	rep2_name=${id%_1.fq*}_2.fq.gz
    rep1_name=${id%_1.fq*}_1.fq.gz
	# rep1=`echo ${rep1_name}`
	# rep2=`echo ${rep2_name}`
	echo -e "${rep1_name}\t${rep2_name}\tWT" >> ${data_dir}/${out_file}
done

if [[ ${Mut_name} ]]
then
    ls ${data_dir}/*${Mut_name}*_1.fq.gz | while read id;
    do
        rep2_name=${id%_1.fq*}_2.fq.gz
        rep1_name=${id%_1.fq*}_1.fq.gz
        # rep1=`echo ${rep1_name}`
        # rep2=`echo ${rep2_name}`
        echo -e "${rep1_name}\t${rep2_name}\tMut" >> ${data_dir}/${out_file}
    done
fi

cat ${data_dir}/${out_file}