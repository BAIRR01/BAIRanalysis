docker pull cbinyu/bids_pydeface:latest

bidsFolder=/Users/iiagroen/surfdrive/BAIR/BIDS/visual_ecog_recoded
subjectID=p03
sessionID=som3t01

logFolder=${bidsFolder}/derivatives/preprocessing_logs/sub-${subjectID}

mkdir -p $logFolder

###   Deface:   ###
docker run -i --rm \
           --volume ${bidsFolder}:/bids_dataset \
           cbinyu/bids_pydeface \
               /bids_dataset /bids_dataset participant \
               --participant_label ${subjectID} \
               --session_label ${sessionID} \
               --skip_bids_validator | tee ${logFolder}/sub-${subjectID}_pyDeface.txt



