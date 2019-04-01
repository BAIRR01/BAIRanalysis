% For BIDS organized data with seperate directories for Raw, Preprocessed
% and Analysis data
subject         = 'wlsubj048';
session         = 'nyu3t01';
tasks           = {'hrf' 'spatialobject' 'spatialpattern' 'temporalpattern'};
dataFolderIn    = 'preprocessed';
dataFolderOut   = 'preprocessedUpsampled';
upsampleFactor  = 5;

% Bids project, subject and session context
projectDir     = '/Volumes/server/Projects/BAIR/Data/BIDS/visual/';


[session, tasks, runnums] = bidsSpecifyEPIs(projectDir, subject,...
    session, tasks);


% <dataFolder>
if ~exist('dataFolder', 'var') || isempty(dataFolderIn)
    dataFolderIn = 'preprocessed';
end

dataPathIn = fullfile (projectDir,'derivatives', dataFolderIn,...
    sprintf('sub-%s',subject), sprintf('ses-%s',session));
dataPathOut = fullfile (projectDir,'derivatives', dataFolderOut,...
    sprintf('sub-%s',subject), sprintf('ses-%s',session));
rawDataPath = fullfile(projectDir, sprintf('sub-%s', subject), ...
    sprintf('ses-%s', session), 'func');

if ~exist(dataPathOut, 'dir'), mkdir(dataPathOut); end

for thistask = 1:length(tasks)
    
    for thisrun = runnums{thistask}
        
        % Use a json file to deduce information
        tr = bidsGetJSONval(rawDataPath,tasks(thistask), {thisrun}, 'RepetitionTime');
        st = bidsGetJSONval(rawDataPath,tasks(thistask), {thisrun}, 'SliceTiming');
        
        
        % Pre-processed data
        [data, hdr] = bidsGetPreprocData(dataPathIn, tasks(thistask), {thisrun});

        % Because we are doing one run at a time...
        tr = tr{1}; st = st{1}; data = data{1}; hdr = hdr{1};

        
        numVolumes  = size(data,4);
        numSlices   = size(data,3);
        sz          = size(data);   % size of the 4D epi volume
        
        % Time vector at the resolution of the TR
        t =  (0:numVolumes-1)*tr;
        
        % Time vector upsampled to deal with stimulus jitter
        t2 = (0:(numVolumes-1)*upsampleFactor)*tr/upsampleFactor;
        
        % check that we did it right
        % figure, stem(t, ones(size(t))); hold on; stem(t2, ones(size(t2))*.5);
        
        % Initialize a matrix for the upsampled and slice-time corrected EPI data
        dataUpsampled = zeros(sz(1), sz(2), sz(3), length(t2), 'single');
        
        % Do the upsampling and slice-time correction, one slice at a time
        fprintf('\n')
        for jj = 1:numSlices
            fprintf('.');
            x = t + st(jj); % acquisition times
            v = single(data(:,:,jj, :)); % slice data
            v = permute(v, [4 1 2 3]);
            vq = interp1(x, v, t2, 'pchip');
            dataUpsampled(:,:,jj,:) = permute(vq, [2 3 1]);
        end
        fprintf('\n')
        
        % Debug:
        %         dims = size(data);
        %         d1 = reshape(data, dims(1)*dims(2), dims(3), []);
        %         d2 = reshape(dataUpsampled, dims(1)*dims(2), dims(3), []);
        %         d1mean = squeeze(mean(d1))';
        %         d2mean = squeeze(mean(d2))';
        %         figure(1), clf;
        %         for ii =1:size(d1mean,2)
        %             subplot(5,6,ii)
        %             plot(t, d1mean(:,ii), 'k-', t2-st(ii), d2mean(:,ii), 'r--', t2, d2mean(:,ii), 'b-', 'LineWidth',2)
        %             xlim([100 105])
        %             title(sprintf('Slice time %3.2f s', st(ii)));
        %         end
        %         figure(2), plot(t, mean(d1mean,2), 'o-', t2-mean(st), ...
        %         mean(d2mean,2), 'x--');  xlim([100 105])
        
        
        % 'sub-som682_ses-nyu3t01_task-hrf_run-1_preproc.nii.gz'
        [p, f, e] = fileparts(hdr.Filename);
        niftiwrite(dataUpsampled, fullfile(dataPathOut, f),'Compressed',true);
    end
end

% % TSV file with onsets to make the design matrix (vector)
% T = tdfread(fullfile(rawDataPath,sprintf('%s_events.tsv', hrf_basename)));
%
% % Convert the time (in seconds) to indices of the upsampled time vector
% indices                 = round(T.onset/(TR/5));
% designMatrix            = zeros(size(t2));
% designMatrix(indices)   = 1;
