docker pull cbinyu/bids_pydeface:v2.0.3

bidsFolder=/Volumes/server/Projects/BAIR/Data/BIDS/visual 
subjectID=som748
sessionID=som3t01

###   Deface:   ###
docker run -i --rm \
           --volume ${bidsFolder}:/bids_dataset \
           cbinyu/bids_pydeface \
               /bids_dataset /bids_dataset participant \
               --participant_label ${subjectID} \
               --session_label ${sessionID} \
               --skip_bids_validator | tee /${bidsFolder}/derivatives/preprocessing_logs/sub-${subjectID}/sub-${subjectID}_pyDeface.txt



