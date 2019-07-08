function bidsPreprocToUpsampledToGLMdenoise (projectDir, subject, session, tasks , ...
    runnums, dataStr, upsample, upsampleFactor,upsampleFolder, dataFolder,makeDesign, designFolder,tr,modelType, glmOptsPath)
%
% bidsPreprocToUpsampledToGLMdenoise (projectDir, subject, [session], [tasks] , ...
%     [runnums], dataStr, upsample, [upsampleFactor],[upsampleFolder], dataFolder,...
%      makeDesign, designFolder,modelType, [glmOptsPath])
%
% Example 1:
%     projectDir        = '/Volumes/server/Projects/BAIR/Data/BIDS/visual_BIDS_compatible';
%     subject           = 'umcuchaam';
%     upsampleFactor    = 5;
%     dataStr           = 'fsnative';
%     upsampleFolder    = 'fmriprepUpsampled';
%     session           = 'umcu3tday139';
%     tasks             = 'temporalpattern';
%     runnums           = [];
%     dataFolder        = 'fmriprepUpsampled';
%     makeDesign        = true;
%     designFolder      = 'temporalpatternUpsampled';
%     tr                = .85/upsampleFactor;
%     modelType         = 'temporalpatternUpsampled';
%     upsample          = true;
%     glmOptsPath       = [];
%
%     bidsPreprocToUpsampledToGLMdenoise (projectDir, subject, session, tasks , ...
%     runnums, dataStr, upsample, upsampleFactor,upsampleFolder, dataFolder, makeDesign, designFolder,modelType, glmOptsPath)
%
% Assumes data has been previously preprocessed using fmriprep
%

%set an environment variable for our freesurfer directory 
fsDir = fullfile(projectDir,'derivatives','freesurfer');
setenv('SUBJECTS_DIR',fsDir);

% Make sure the benson atlas files have been generated, otherwise make them:
fsFiles = dir(fullfile(fsDir,sprintf('sub-%s', subject), 'surf'));
if ~any(contains ({fsFiles.name},'benson'))&& ~any(contains({fsFiles.name},'wang'))
    system(sprintf('docker run -ti --rm -v %s:/subjects nben/neuropythy:latest atlas --verbose sub-%s', fsDir, subject))
end

% Upsample the data
if upsample
    bidsUpsampleGiftis (projectDir, subject, session ,tasks, upsampleFactor, dataStr, upsampleFolder)
end

% Make design matrices
if makeDesign
    bidsTSVtoDesign(projectDir, subject, session, tasks, runnums, designFolder, tr, dataFolder, dataStr);
end

% Run GLM denoise
stimdur           = [];

bidsGLM(projectDir, subject, session, tasks, runnums, ...
    dataFolder, dataStr, designFolder, stimdur, modelType, glmOptsPath, tr)

% Plot results
conditionsOfInterest = [];
makeFigures          = true;
saveFigures          = false;
isfmriprep           = true;

bidsSummarizeGLMDenoisebyArea (projectDir , subject, modelType,...
    session,tasks, conditionsOfInterest, makeFigures, saveFigures, isfmriprep);

% process the GLMdenoise figures for viewing
figDir = fullfile(projectDir,'derivatives', 'GLMdenoise' ,modelType, sprintf('sub-%s',subject), sprintf('ses-%s', session),'figures');
system(sprintf('python %s/toolboxes/MRI_tools/BIDS/GLMdenoisePNGprocess.py %s', userpath, figDir));

end






