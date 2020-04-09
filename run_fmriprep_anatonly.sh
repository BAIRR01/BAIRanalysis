
subjectID=som726

docker run --rm -it -v /Applications/freesurfer/license.txt:/opt/freesurfer/license.txt:ro \
		-v /Volumes/server/Projects/BAIR/Data/BIDS/visual:/data \
		-v /Volumes/server/Projects/BAIR/Data/BIDS/visual/derivatives:/out \
		poldracklab/fmriprep:20.0.5 \
		/data \
		/out \
		participant \
		--participant_label $subjectID \
		--output-spaces T1w MNI152NLin2009cAsym func fsnative fsaverage \
		--no-submm-recon \
		--skip-bids-validation \
		--anat-only \
		--nthreads 6 | tee /Volumes/server/Projects/BAIR/Data/BIDS/visual/derivatives/preprocessing_logs/sub-${subjectID}/sub-${subjectID}_fMRIPrep_anatonly.txt