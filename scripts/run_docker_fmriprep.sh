bidsFolder=/Volumes/server/Projects/BAIR/Data/BIDS/visual 
subjectID=som726

docker run --rm -it -v /Applications/freesurfer/license.txt:/opt/freesurfer/license.txt:ro \
		-v ${bidsFolder}:/data \
		-v ${bidsFolder}/derivatives:/out \
		nben/fmriprep:latest \
		/data \
		/out \
		participant \
		--participant_label $subjectID \
		--output-spaces T1w MNI152NLin2009cAsym func fsnative fsaverage \
		--no-submm-recon \
		--skip-bids-validation \
		--coreg-init-header \
		--nthreads 6 | tee /${bidsFolder}/derivatives/preprocessing_logs/sub-${subjectID}/sub-${subjectID}_fMRIPrep.txt