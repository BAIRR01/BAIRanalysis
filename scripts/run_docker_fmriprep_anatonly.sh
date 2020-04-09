bidsFolder=/Volumes/server/Projects/BAIR/Data/BIDS/visual 
subjectID=som726

logFolder=${bidsFolder}/derivatives/preprocessing_logs/sub-${subjectID}

docker run --rm -it -v /Applications/freesurfer/license.txt:/opt/freesurfer/license.txt:ro \
		-v ${bidsFolder}:/data \
		-v ${bidsFolder}/derivatives:/out \
		poldracklab/fmriprep:20.0.5 \
		/data \
		/out \
		participant \
		--participant_label $subjectID \
		--output-spaces T1w MNI152NLin2009cAsym func fsnative fsaverage \
		--no-submm-recon \
		--skip-bids-validation \
		--anat-only \
		--nthreads 6 | tee ${logFolder}/sub-${subjectID}_fMRIPrep_anatonly.txt