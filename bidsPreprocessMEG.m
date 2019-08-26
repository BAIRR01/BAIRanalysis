function bidsPlotMEGandECoG (projectDir, subject, session,tasks, saveFolder,...
    plotChecks)%epocLength,
%
% projectDir = '/Volumes/server/Projects/BAIR/Data/BIDS/visual_new';
% subject = 'wlsubj100';
% session = 'nyumeg01';
% tasks = [];
% saveFolder = 'MEGpreprocessed';
% plotChecks = true;
% plotPrePostPreproc = true;

%% Set up paths and options
[session, tasks, runnums,siteModality ] = bidsSpecifyEPIs(projectDir, subject, session, tasks);

switch siteModality
    case 'meg'
        dataChannels            = 1:157;
        environmentalChannels   = 158:160;
        triggerChannels         = 161:168;
        rawDataFldr = 'meg';
        dataStr = 'meg';
    case 'ecog'
        rawDataFldr = 'ieeg';
        dataStr = 'ieeg';
end

rawDataDir  = fullfile (projectDir, sprintf('sub-%s', subject), sprintf('ses-%s', session),rawDataFldr);

if ~exist('saveFolder', 'var')|| isempty(saveFolder)
    %saveData = false;
else
    outputDir   = fullfile (projectDir,'derivatives', saveFolder, sprintf('sub-%s', subject), sprintf('ses-%s', session));
    %saveData = true;
    if ~exist('outputDir', 'dir'), mkdir(outputDir); end
end

%% Load data and check triggers (Fieldtrip)
for ii = 1:length (tasks)
    % get all data for an experiment type
    ts          = bidsGetPreprocData(rawDataDir, dataStr,{tasks{ii}}, runnums(ii));
    allOnsets   = [];
    allTriggers = [];
    fullTimeseries = [];
    
    for jj = 1:length(runnums{ii})
        thisTimeSeries = ts{jj};
        expLength      = length(thisTimeSeries);
        tsv = @parseTSVfile;
        [onsets,stimTypes , stimNums, trigger] = tsv(rawDataDir, tasks{ii}, runnums{ii}(jj), expLength);
        allOnsets   = [allOnsets onsets];
        if jj > 1,  allOnsets   = [allOnsets (onsets + allOnsets(end))];end
        allTriggers = [allTriggers trigger];
        fullTimeseries = [fullTimeseries thisTimeSeries];
    end
    switch siteModality
        case 'meg'
            % Define length of epochs relative to trigger onset and get sample rate
            epochLength = [0 1]; % start and end of epoch (seconds), zero is trigger onset
            fs      = 1000;  % Hz
            
            % Get sensordata (time x epochs x channels) and conditions (epochs x 1)
            [epocedData, ~] = meg_make_epochs(fullTimeseries', allOnsets, epochLength, fs);
        case 'ecog'
            %epoc the data
    end
    
    % Plot the triggers to check them
    if plotChecks
        figure;
        t = 0:expLength-1;
        hold on
        plot(t,trigger');
        xlabel('Time (ms)');
        ylabel('Condition nr');
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
    end
    
    % Plot the mean time series of a single channel
    if plotChecks
        t = 0:(size(epocedData,1)-1);
        figure; plot(t, mean(epocedData(:,:,1),2))
        xlabel('Time (ms)');
        ylabel('Magnetic flux (Tesla)');
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
    end
end
% Plot the mean time series of each stimulus type accross channels

% plot mean timeseries for each sensor for a given stimulus type

% Save it
%         if saveData
%             save(fullfile(outputDir, sprintf('sub-%s_ses-%s_MEGpreproc.mat',subject, session)), ...
%                 'tsDenoised', 'tsv', 'trigger','conditions','sensorData', 'badChannels', 'badEpochs' )
%         end
end

function [onsets,stimTypes , stimNums, trigger] = parseTSVfile (rawDataDir, task, runnum, expLength)
%load in the TSV file information to confirm everything lines up
tsvFile =  dir (fullfile(rawDataDir,  sprintf('*task-%s_run-%d_events.tsv',task,runnum )));
tsv = tdfread(fullfile(tsvFile.folder, tsvFile.name));
onsets = tsv.onsets;
trigNums = tsv.trial_type;
stimTypes = tsv.trial_name;
stimNums = unique(trigNums);
trigger = zeros( expLength,1);
trigger(tsv.onset*1000) = trigNums;
end


