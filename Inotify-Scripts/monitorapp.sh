#!/bin/bash
event=$1 
file=$2
monitoredfolder=$3
bucketName=$4
pathinbucket=`echo $file | awk -F "/$monitoredfolder/" '{print $2}'`
folderpath=`echo $file | awk -F "/$monitoredfolder/" -v folder="/$monitoredfolder" '{print $1folder }'`

buckettopcsyncing(){
    #get all the folders in you path variable 
    sensitiveawscommands=(cp mv sync)
    IFS=':'
    read -ra pathfolders <<< $PATH
    unset IFS
    for folder in "${pathfolders[@]}"; do
        command=`[ -r /proc/$awspid/cmdline ] && cat /proc/$awspid/cmdline | tr -d '\000'`
        if [[ "$command" = *"$folder/aws"* ]]; then
            stripawscommand=`echo $command | awk -F "$folder/aws" -v command="$folder/aws" '{print command$2 }' `
            for s3command in ${sensitiveawscommands[@]};do
                s3command=`echo "$folder/awss3${s3command}s3://"`
                waitingfinish="true"
                while [[ $waitingfinish = "true" ]]; do
                    if [[ "$stripawscommand" = $s3command* ]]; then
                        echo "waiting because aws is syncing something from the $bucketName to $folderIsRunning and might be your file"
                        command=`[ -r /proc/$awspid/cmdline ] && cat /proc/$awspid/cmdline| tr -d '\000'`
                        stripawscommand=`echo $command | awk -F "$folder/aws" -v command="$folder/aws" '{print command$2 }' `
                        sleep 5  
                    else
                        waitingfinish="false"
                    fi 
                done                
            done
        fi
    done 
}

syncverification(){
    #start proccess to verify if aws is download content to your folder
    syncing="true"
    #while a proccess aws is running the script keep checking 
    while [[ $syncing == "true" ]]; do
        awspids=`pgrep aws`
    #verify if exists an aws proccess running, if not set syncing variable to false
        if [ -n "$awspids" ] ; then
    #traverses all pids aws
            for awspid in $awspids; do
    #verify if the aws sync is in your folder
                folderIsRunning=`readlink -e /proc/$awspid/cwd/`
                if [[ "$folderIsRunning" == "$folderpath"* ]]; then
                    buckettopcsyncing   
                fi  
            done
            sleep 5 
        else 
            syncing="false"
        fi 
          
    done
}

syncverification

delete(){
    :
}

in_moved_from(){
    filename=`echo $file | rev | cut -d "/" -f1 | rev`
    infolder=`find $folderpath -iname $filename`
    if [ -n "$infolder" ]; then
        #escrever um arquivo controlador com o caminho antigo do arquivo pra poder fazer o mv no in_moved_to
    else
        delete
    fi
}

in_moved_to(){

    

}

move(){
    if [ "$event" = "IN_MOVED_TO" ]; then
        in_moved_to
    else 
        in_moved_from
    fi
}

write(){
    aws s3 cp $file s3://$bucketName/$monitoredfolder/$pathinbucket
}


case "$event" in
    *"DELETE"*)
        delete  
    ;;
    *"MOVE"*)
        move
    ;;
    *"WRITE"*)
        write
    ;;
esac


