%% Paths to t1 and field map or functional scan
t1   = niftiRead('/Volumes/server/Projects/BAIR/Data/BIDS/visual/sub-wlsubj050/ses-nyu3t01/anat/sub-wlsubj050_ses-nyu3t01_acq-highres_run-01_T1w.nii.gz');
func = niftiRead('/Volumes/server/Projects/BAIR/Data/BIDS/visual/sub-wlsubj050/ses-nyu3t01/fmap/sub-wlsubj050_ses-nyu3t01_acq-fMRI_dir-LR_run-01_epi.nii.gz');

%% align the two volumes via any tool such as kendrick kay's alignvolumedata
% assume this results in a 4x4 transform matrix, T, which aligns the image
% indices of the functional volume to the image indices of the t1 
% Specifically, T tells you how to go from 1-based image indices to 1-based
% image indices: 
%   T*functionalImage1 = T1image1

refvolume    = mean(func.data,4);
targetvolume = t1.data;

% we should derive 'tr' from the headers of the t1 and functional scans
%   we need to figure out how to do this
alignvolumedata(refvolume,func.pixdim(1:3),targetvolume,t1.pixdim(1:3), tr);

% DO THE ALIGNMENT

tr = alignvolumedata_exporttransformation;

% make the transformation into a 4x4 matrix
T = transformationtomatrix(tr,0,t1.pixdim(1:3));
%% rewrite the t1 header to incorporate the new alignment

% 1-indexing conversion
L = [1 0 0 1;
    0 1 0 1;
    0 0 1 1;
    0 0 0 1];

newXform = func.qto_xyz/L/T*L;
t1FIXED  = niftiSetQto(t1, newXform, true);

niftiWrite(t1FIXED, 't1_fixed.nii.gz');


