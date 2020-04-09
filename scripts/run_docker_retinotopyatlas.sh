subjectID=som726
bidsFolder=/Volumes/server/Projects/BAIR/Data/BIDS/visual 

docker run --rm -it -v ${bidsFolder}/derivatives/freesurfer:/subjects/ nben/neuropythy atlas sub-${subjectID} --verbose\