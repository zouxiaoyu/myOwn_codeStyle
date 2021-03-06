#!/bin/bash

fnList=$1
clientAccount=$2
clientCnt=$(cat $clientAccount | wc -l)
prLimit=200 #closed PR number >=200
issueLimit=20 #closed issues number >=20

cnt=1
#rm failed prIssueOk_fn filteredFn
for fn in $(cat $fnList)
do

    clientNum=$((cnt%clientCnt + 1))
    client=$(sed -n "${clientNum}p" $clientAccount)
    issueUrl="https://api.github.com/search/issues?q=type:issue+repo:${fn}+state:closed&${client}&per_page=1"
    prUrl="https://api.github.com/search/issues?q=type:pr+repo:${fn}+state:closed&${client}&per_page=1"

    rm prtmp issuetmp
    curl -m 120 $prUrl -o prtmp
    cnt=$((cnt+1))
    cldPrCnt=0
    cldPrCnt=$(grep "\"total_count\":" prtmp | awk '{print $NF}' | cut -f1 -d ",")
    if [ "$cldPrCnt" = "" ];then
        echo "$fn:curl prs failed" >>failed
        continue
    fi

    cldIssueCnt="no_need_to_search"
    if [ $cldPrCnt -ge $prLimit ];then
        curl -m 120 $issueUrl -o issuetmp
        cldIssueCnt=$(grep "\"total_count\":" issuetmp | awk '{print $NF}' | cut -f1 -d ",")
        if [ "$cldIssueCnt" = "" ];then
            echo "$fn:curl issues failed" >>failed
            continue
        fi
        if [ $cldIssueCnt -ge $issueLimit ];then
            echo $fn $cldPrCnt $cldIssueCnt >> prIssueOk_fn
        fi
            echo $fn $cldPrCnt $cldIssueCnt >> filteredFn
    else
        echo $fn $cldPrCnt $cldIssueCnt >> filteredFn
    fi
        
done
