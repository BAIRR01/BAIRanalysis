function bidsUpsampleGiftis (projectDir, subject, session,tasks, ...
    upsampleFactor, dataStr, outputFolder)
% bidsUpsampleGiftis (projectDir, subject, [session] ,[tasks], upsampleFactor, [dataStr], [outputFolder])
%
% Example 1:
%
%     projectDir     = '/Volumes/server/Projects/BAIR/Data/BIDS/visual';
%     subject        = 'wlsubj051';
%     tasks          = {'hrf' 'spatialobject' 'spatialpattern' 'temporalpattern'};
%     session        = 'nyu3t01';
%     upsampleFactor = 5;
%     dataStr        = 'fsnative';
%     outputFolder   = 'fmriprepUpsampled';
%
%    bidsUpsampleGiftis (projectDir, subject, session,tasks,upsampleFactor, dataStr, outputFolder)
%
% assumes data has been prepocessed and slicetime corrected by fmriprep
%

% Set up paths
[session, tasks, runnums] = bidsSpecifyEPIs(projectDir, subject,...
    session, tasks);

dataPath = fullfile (projectDir,'derivatives', 'fmriprep',...
    sprintf('sub-%s',subject), sprintf('ses-%s',session), 'func');
rawDataPath = fullfile(projectDir, sprintf('sub-%s', subject), ...
    sprintf('ses-%s', session), 'func');
dataPathOut = fullfile (projectDir,'derivatives', outputFolder,...
    sprintf('sub-%s',subject), sprintf('ses-%s',session));

% check or make these paths
if ~exist(dataPathOut, 'dir') , mkdir(dataPathOut); end
if ~exist(dataPath, 'dir')|| isempty( dataPath)
    error ('Preprocessed data path is empty or does not exist')
end
if ~exist(rawDataPath, 'dir')|| isempty( rawDataPath)
    error ('Raw data path is empty or does not exist')
end

for ii = 1:length(tasks)
    for jj = 1:length (runnums{ii})
        % Use a json file to deduce information
        tr = bidsGetJSONval(rawDataPath,tasks(ii), {runnums{ii}(jj)}, 'RepetitionTime');
        
        % load in our data one at a time
        % we want to check for both 0-padded and non-0-padded versions...
        fnamePrefix  = sprintf('*_task-%s*run-%d_*%s*',...
            tasks{ii},runnums{ii}(jj), dataStr);
        fnamePrefixZeroPad = sprintf('*_task-%s*run-%02d_*%s*',...
            tasks{ii},runnums{ii}(jj), dataStr);
        
        fname = dir(fullfile(dataPath, fnamePrefix));
        % we only need to check both if they're different; if we're
        % looking at run 10, 0-padded and non-0-padded will be the
        % same string
        if ~strcmp(fnamePrefix, fnamePrefixZeroPad)
            fname = [fname; dir(fullfile(dataPath, fnamePrefixZeroPad))];
        end
        % We want brain images, not text files, so remove json/tsv files
        istxt = contains({fname.name}, {'.json', '.tsv'});
        fname = fname(~istxt);
             
        assert(length(fname) == 2);
        hemis = {'L', 'R'};
        for ll = 1: length (hemis)
            % We index to make sure the order is always the same
            idx = contains ({fname.name} , sprintf('hemi-%s',hemis{ll}), 'IgnoreCase', true);
            fprintf('Loading gifti: task-%s_run-%02d %s hemisphere...\n', tasks{ii}, runnums{ii}(jj), hemis{ll})
            g = gifti(fullfile (dataPath, fname(idx).name));
            data = g.cdata;
            sz = size(data);
            numTimepoints = sz(2);
            numVtx = sz(1);
            % Time vector at the resolution of the TR
            t =  (0:numTimepoints-1)*tr{1};
            
            % Time vector upsampled to deal with stimulus jitter
            t2 = (0:(numTimepoints-1)*upsampleFactor)*tr{1}/upsampleFactor;
            
            % Initialize a matrix for the upsampled and slice-time corrected EPI data
            dataUpsampled = zeros(1,sz(1),1, length(t2), 'single');
           
            % do the upsampling
            fprintf('Upsampling...\n')
            for vv = 1:numVtx
                v = data(vv, :);
                vq = interp1(t, v, t2, 'pchip');
                
                dataUpsampled(1,vv,1,:) = vq;
            end
            mri.vol = double(dataUpsampled);
            
            %write data
            fprintf('Writing...\n')
            MRIwrite(mri,fullfile(dataPathOut,fname(idx).name));
            clear data dataUpsampled
        end
    end
end