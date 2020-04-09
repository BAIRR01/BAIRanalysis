subjectID=som726
bidsFolder=/Volumes/server/Projects/BAIR/Data/BIDS/visual 

docker run --rm -it -v ${bidsFolder}/derivatives/freesurfer:/subjects/ nben/neuropythy atlas sub-${subjectID} --verbose\
#docker run --rm -it -v ${bidsFolder}/derivatives/freesurfer:/subjects/ nben/neuropythy atlas sub-${subjectID} --atlases=glasser16,benson14,wang15,rosenke18 --verbose\