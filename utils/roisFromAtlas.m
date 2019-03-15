function [lh, rh, bh, bensonAreaLabels, wangAreaLabels] = roisFromAtlas(subject)
% Gets the following from the the subjects freesurfer directory:
%       - Benson 2014 Atlas
%       - Benson 2014 eccentricity maps
%       - Wang 2015 Atlas
%
% Note: Also concatenates both hemispheres (bh) 
%
% Read here for more information on generating the above: 
%   - https://github.com/noahbenson/neuropythy
%   - https://osf.io/knb5g/wiki/Usage/

if ~exist('subject', 'var') || isempty(subject)
    error('Subject ID is a required input')
end

% Set ROI labels
bensonAreaLabels = {'V1','V2','V3','hV4','VO1', 'VO2','LO1', 'LO2', 'TO1',...
    'TO2','V3b', 'V3a'};

wangAreaLabels = {'V1v','V1d', 'V2v','V2d','V3v','V3d', 'hV4', 'VO1','VO2',...
     'PHC1','PHC2','TO2','TO1','LO2','LO1', 'V3b','V3a', 'IPS0','IPS1','IPS2',...
     'IPS3','IPS4','IPS5','SPL1','FEF'};

fsPth = getenv('SUBJECTS_DIR');

lh.varea = MRIread(fullfile(fsPth, subject, 'surf', 'lh.benson14_varea.mgz'));
rh.varea = MRIread(fullfile(fsPth, subject, 'surf', 'rh.benson14_varea.mgz'));
lh.eccen = MRIread(fullfile(fsPth, subject, 'surf', 'lh.benson14_eccen.mgz'));
rh.eccen = MRIread(fullfile(fsPth, subject, 'surf', 'rh.benson14_eccen.mgz'));
lh.wang  = MRIread(fullfile(fsPth, subject, 'surf', 'lh.wang15_mplbl.mgz'));
rh.wang  = MRIread(fullfile(fsPth, subject, 'surf', 'rh.wang15_mplbl.mgz'));

% concatenate both hemispheres (bh)
bh.varea = cat(1, squeeze(lh.varea.vol), squeeze(rh.varea.vol));
bh.eccen = cat(1, squeeze(lh.eccen.vol), squeeze(rh.eccen.vol));
bh.wang  = cat(1, squeeze(lh.wang.vol),  squeeze(rh.wang.vol));

end

% Benson Areas:
%   0	No visual area
%   1	V1
%   2	V2
%   3	V3
%   4	hV4
%   5	VO1
%   6	VO2
%   7	LO1
%   8	LO2
%   9	TO1
%   10	TO2
%   11	V3b
%   12	V3a