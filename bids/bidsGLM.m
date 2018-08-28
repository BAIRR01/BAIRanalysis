function results = bidsGLM(projectDir, subject, session, tasks, runnums, ...
        dataFolder, designFolder, modelType, glmOpts)
%
% results = bidsGLM(projectDir, subject, [session], [tasks], [runnums], ...
%        [dataFolder], [designFolder], [modelType], [glmOpts]);
%
% Input
%
%   Required
%
%     projectDir:       path where the BIDS projects lies (string)
%     subject:          BIDS subject name (string, all lower case)
%
%   Optional
%
%     session:          BIDS session name (string, all lower case)
%                           default: folder name inside subject dir (if
%                           more than one or less than one, return error)
%     tasks:            one or more BIDS tasks (string or cell array of strings)
%                           default: all tasks in session
%     runnums:           BIDS run numbers (vector or cell array of vectors)
%                           default: all runs for specified tasks
%     dataFolder:       folder name containing preprocessed BOLD data. Note
%                           that this folder should reside in
%                               <projectDir>/derivatives/
%                           and should contain subdirectories and BOLD
%                           files of the form
%                               <subject>/<session>/*.nii
%                           default: 'preprocessed'
%     designFolder:     folder name containing design matrices for glmDenoise
%                           Note that this folder should reside in 
%                               <projectDir>/derivatives/design_matrices/<subject>/<session>/
%                           and should contain either .tsv or .mat files
%                           default = [], which means no subfolder inside
%                               <projectDir>/derivatives/design_matrices/<subject>/<session>/
%     stimdur:          duration of trials in seconds
%                           default = tr;
%     modelType:        name of folder to store outputs of GLMdenoised (string)
%                           default = designFolder;
%     glmOpts:          path to json file specifying GLMdenoise options
%                           default = [];
% 
% Output
%     results:          structured array with GLMdenoise results
%                           See GLMdenoisedata for details.
%
% Dependencies
%     GLMdenoisedata repository (https://github.com/kendrickkay/GLMdenoise)
%     BIDS matlab toolbox: for now: /Volumes/server/Projects/BAIR/Data/BIDS/visual/derivatives/Analyses/visual/code
%
% Example 1
%     projectDir        = '/Volumes/server/Projects/BAIR/Data/BIDS/visual'; 
%     subject           = 'wlsubj054';
%     session           = 'nyu3t01';
%     tasks             = 'spatialobject';
%     runnums           = 1:4;
%     dataFolder        = 'preprocessed';                 
%     designFolder      = 'spatialobjectRoundedTR';
%     modelType         = 'spatialObjectRoundedTR';
%     glmOpts           = [];        
%       
%     % make the design matrices
%     bidsTSVtoDesign(projectDir, subject, session, tasks, runnums, designFolder);
%     % run the GLM
%     bidsGLM(projectDir, subject, session, tasks, runnums, ...
%        dataFolder, designFolder, modelType, glmOpts);
%
%   See also bidsTSVtoDesign

%% Check inputs

if ~exist('session', 'var'),    session = [];   end
if ~exist('tasks', 'var'),      tasks   = [];   end
if ~exist('runnums', 'var'),     runnums  = [];   end

[session, tasks, runnums] = bidsSpecifyEPIs(projectDir, subject,...
    session, tasks, runnums);


% <dataFolder>
if ~exist('dataFolder', 'var') || isempty(dataFolder)
    dataFolder = 'preprocessed';
end
dataPath = fullfile (projectDir,'derivatives', dataFolder,...
    sprintf('sub-%s',subject), sprintf('ses-%s',session));
rawDataPath = fullfile(projectDir, sprintf('sub-%s', subject), ...
    sprintf('ses-%s', session), 'func');

% <designFolder>
if ~exist('designFolder', 'var'), designFolder = []; end
designPath = fullfile(projectDir, 'derivatives', 'design_matrices', ...
    designFolder, sprintf('sub-%s',subject), sprintf('ses-%s',session));
if ~exist(designPath, 'dir')
    error('Design path not found: %s', designPath); 
end
     
% <modelType>
if ~exist('modelType', 'var') || isempty(modelType)
    modelType = designFolder;
end

% <glmOpts>
if ~exist('glmOpts', 'var'), glmOpts = []; end


%% Create GLMdenoisedata inputs

%****** Required inputs to GLMdenoise *******************
% < design>
design = getDesign(designPath, tasks, runnums);

% <data>
data = getData(dataPath, tasks, runnums);

% <tr>
tr = getTR(rawDataPath,tasks, runnums);

% <stimdur>
if ~exist('stimdur', 'var') || isempty(stimdur),
    stimdur = tr; 
end

%****** Optional inputs to GLMdenoise *******************
hrfmodel = [];
hrfknobs = [];
opt      = [];

% glm opts
% 
% if ~exist('glmOpts', 'var') || isempty(glmOpts)
%     glmOpts = glmOptsMakeDefaultFile();
% end

%  <hrfmodel>

%   <hrfknobs>

%   <opt>

%   <figuredir>

figuredir   = fullfile (projectDir,'derivatives','GLMdenoise', modelType, ...
                 sprintf('sub-%s',subject), sprintf('ses-%s',session), 'figures');

if ~exist(figuredir, 'dir'); mkdir(figuredir); end

%% Run the denoising alogithm


results  = GLMdenoisedata(design,data,stimdur,tr,hrfmodel,hrfknobs,opt,figuredir);

% save the results
fname = sprintf('sub-%s_ses-%s_%s_results', subject, session, modelType);
save(fullfile(figuredir, fname), 'results');

end


%% ******************************
% ******** SUBROUTINES **********
% *******************************
function design = getDesign(designPath, tasks, runnums)
% <design> is the experimental design.  There are three possible cases:
%   1. A where A is a matrix with dimensions time x conditions.
%      Each column should be zeros except for ones indicating condition onsets.
%      (Fractional values in the design matrix are also allowed.)
%   2. {A1 A2 A3 ...} where each of the A's are like the previous case.
%      The different A's correspond to different runs, and different runs
%      can have different numbers of time points.
%   3. {{C1_1 C2_1 C3_1 ...} {C1_2 C2_2 C3_2 ...} ...} where Ca_b is a vector of
%      onset times (in seconds) for condition a in run b.  Time starts at 0
%      and is coincident with the acquisition of the first volume.  This case
%      is compatible only with <hrfmodel> set to 'assume'.
%   Because this function involves cross-validation across runs, there must
%   be at least two runs in <design>.
%

tsvFiles = dir([designPath '/*_design.tsv']);

tsvNames = {tsvFiles.name};

scan = 1;

for ii = 1:length(tasks)
    for jj = 1:length(runnums{ii})
        
        tsvIdx = contains(tsvNames,sprintf('task-%s_run-%d',...
            tasks{ii}, runnums{ii}(jj)));
        
        if isempty(find(tsvIdx, 1)) % double check that there's a design matrix
            error (['Design Matrix *_task-%s_run-%d_design.tsv'...
                ' was not found'],tasks{ii}, runnums{ii}(jj))
        else
            design{scan} = load(fullfile(tsvFiles(tsvIdx).folder,tsvFiles(tsvIdx).name));
            scan         = scan+1;
        end
    end
end
end

function data = getData(dataPath, tasks, runnums)
%   <data> is the time-series data with dimensions X x Y x Z x time or a cell vector of 
%   elements that are each X x Y x Z x time.

fprintf('Loading data')
scan = 1;
for ii = 1:length(tasks)
    for jj = 1:length(runnums{ii})
        fprintf('.')
        fnamePrefix  = sprintf('/*_task-%s_run-%d_preproc.nii*',tasks{ii},runnums{ii}(jj));
        fname         = dir([dataPath fnamePrefix]);
        assert(~isempty(fname));
        
        data{scan}    = niftiread(fullfile (dataPath, fname.name));
        scan          = scan+1;
    end
end
fprintf('\n')
end

function tr = getTR(rawDataPath,tasks, runnums)
% <tr> is the sampling rate in seconds

scan = 1;
for ii = 1:length(tasks)
    for jj = 1:length(runnums{ii})
        
        jsonPrefix = sprintf('/*_task-%s_run-%d_bold.json',tasks{ii}, runnums{ii}(jj));
        jsonName    = dir([rawDataPath jsonPrefix]);
        json        = fileread(fullfile (rawDataPath, jsonName.name));
        jsonInfo    = jsondecode(json);
        tr(scan)    = jsonInfo.RepetitionTime; % 850 ms
        scan        = scan+1;
    end
end

if length(unique(tr)) > 1
    disp(unique(tr))
    error(['More than one TR found:' ...
        'GLMdenoise expects all scans to have the same TR.'])
else
    tr = unique(tr);
end

end

                      
function pth = glmOptsMakeDefaultFile()
    % field / value pairs
    

end          
           