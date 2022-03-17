docker pull nben/neuropythy
# note: if Docker doesn't run all requested atlases, change memory settings on Docker to use more RAM (see https://github.com/noahbenson/neuropythy/issues/27) 
subjectID=p03
bidsFolder=/Users/iiagroen/surfdrive/BAIR/BIDS/visual_ecog_recoded

docker run --rm -it -v ${bidsFolder}/derivatives/freesurfer:/subjects/ nben/neuropythy atlas sub-${subjectID} --atlases=benson14 --verbose\

docker run --rm -it -v ${bidsFolder}/derivatives/freesurfer:/subjects/ nben/neuropythy atlas sub-${subjectID} --atlases=wang15 --verbose\

docker run --rm -it -v ${bidsFolder}/derivatives/freesurfer:/subjects/ nben/neuropythy atlas sub-${subjectID} --atlases=glasser16 --verbose\

docker run --rm -it -v ${bidsFolder}/derivatives/freesurfer:/subjects/ nben/neuropythy atlas sub-${subjectID} --atlases=rosenke18 --verbose\