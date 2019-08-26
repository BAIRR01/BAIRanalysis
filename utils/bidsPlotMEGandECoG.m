function bidsPlotMEGandECoG (projectDir, subject, session,runnums, tasks, ...
    saveFolder,plotChecks, goodChannelRatio)%epocLength,
%
% projectDir = '/Volumes/server/Projects/BAIR/Data/BIDS/visual';
% subject = 'wlsubj100';
% session = 'nyumeg01';
% tasks = {'hrf', 'temporalpattern', 'spatialobject', 'spatialpattern'};
% saveFolder = 'MEGpreprocessed';
% plotChecks = true;
% plotPrePostPreproc = true;
% runnums = [];
% goodChannelRatio = .2;

%% Set up paths and options
[session, tasks, runnums,siteModality ] = bidsSpecifyEPIs(projectDir, subject, session, tasks);

switch siteModality
    case 'meg'
        dataChannels            = 1:157;
        %environmentalChannels   = 158:160;
        %triggerChannels         = 161:168;
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
    allStimTypes = [];
    for jj = 1:length(runnums{ii})
        thisTimeSeries = ts{jj};
        expLength      = length(thisTimeSeries);
        [onsets,stimTypes , stimNums, stimTrigger] = parseTSVfile(rawDataDir, tasks{ii}, runnums{ii}(jj), expLength);
        if jj == 1, allOnsets   = [allOnsets; onsets];end
        if jj > 1,  allOnsets   = [allOnsets; (onsets + allOnsets(end))];end
        allTriggers = [allTriggers; stimTrigger];
        allStimTypes = [allStimTypes; stimTypes];
        fullTimeseries = cat(2,fullTimeseries,thisTimeSeries);
    end
    switch siteModality
        case 'meg'
            % Define length of epochs relative to stimTrigger onset and get sample rate
            epochLength = [0 1]; % start and end of epoch (seconds), zero is stimTrigger onset
            fs      = 1000;  % Hz
            % Get sensordata (time x epochs x channels) and conditions (epochs x 1)
            [epocedData, ~] = meg_make_epochs(fullTimeseries', allOnsets, epochLength, fs);
        case 'ecog'
            %epoc the data
    end
    
    t = 0:length(fullTimeseries)-1;
    tEpoc = 0:(size(epocedData,1)-1);
    allStims = allTriggers(find(allTriggers));
    allStimTypes = string(allStimTypes);
    goodChannels = findGoodMEGChannels(fullTimeseries,dataChannels, epocedData, goodChannelRatio);
    
    if plotChecks
        figure
        % Plot the triggers to check them
        hold on
        plot(t,allTriggers');
        xlabel('Time (ms)');
        ylabel('Condition nr');
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
        
        % Plot single channel: mean timeseries across all epocs
        figure
        plot(tEpoc, mean(epocedData(:,:,1),2))
        xlabel('Time (ms)');
        ylabel('Magnetic flux (Tesla)');
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
        
        % plot all sensors: mean timeseries by stimulus type in subplots
        figure;
        for ss = 1:length(stimNums)
            idx = allStims == stimNums(ss);
            mnTS = squeeze(mean(epocedData(:,idx,:),2));
            if length(stimNums)>1
                subplot(floor(length(stimNums)/2),length(stimNums)/floor(length(stimNums)/2), ss)
            end
            plot(tEpoc,mnTS(:, dataChannels))
            tmp = find(idx);
            title(sprintf('%s - All Channels',allStimTypes(tmp(1))))
        end
        xlabel('Time (ms)');
        ylabel('Magnetic flux (Tesla)');
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
    end
   
    
     % Plot all "good" channels: the mean time series of each stimulus type in subplots
    figure;
    for ss = 1:length(stimNums)
        idx = allStims == stimNums(ss);
        mnTS = squeeze(mean(epocedData(:,idx,:),2));
        if length(stimNums)>1
            subplot(floor(length(stimNums)/2),length(stimNums)/floor(length(stimNums)/2), ss)
        end
        tmp = find(idx);
        plot(tEpoc,mean(mnTS(:, goodChannels),2))
        title(sprintf('%s - "Good" Channel Mean (n = %d)',allStimTypes(tmp(1)),sum(goodChannels)))
        xlabel([]);
        ylabel('flux (T)','rot', 45);
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
    end
    xlabel('Time (ms)');
    
    
    % Plot all "good" channels: the mean time series of each stimulus type in one plot
    if length(stimNums)>1
        tmpIdx = find(goodChannels);
        channelsToPlot= floor(sum(goodChannels)/3)*round(sum(goodChannels)/floor(sum(goodChannels)/3));
        figure;
        
        for cc = 1:channelsToPlot
            subplot(floor(sum(goodChannels)/3),round(sum(goodChannels)/floor(sum(goodChannels)/3)), cc)
            for ss = 1:length(stimNums)
                idx = allStims == stimNums(ss);
                mnTS = squeeze(mean(epocedData(:,idx,:),2));
                tmp = find(idx);
                hold on
                plot(tEpoc,mnTS(:, goodChannels(tmpIdx(cc))))
                xlabel([]);
                ylabel([]);
                set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
            end
            %             xlabel('Time (ms)');
                         
        end
        legend(unique(allStimTypes),'Orientation','horizontal','Location','southoutside')
        
    end
    
    % plot single "good" channels with subplots of stimulus types
         
    figure;
    for ss = 1:length(stimNums)
        idx = allStims == stimNums(ss);
        mnTS = squeeze(mean(epocedData(:,idx,:),2));
        tmp = find(idx);
        hold on
        if length(stimNums)>1
            subplot(floor(length(stimNums)/2),length(stimNums)/floor(length(stimNums)/2), ss)
        end
        plot(tEpoc,mnTS(:, goodChannels))
        title(sprintf('%s ',allStimTypes(tmp(1))))
        xlabel([]);
        ylabel('flux (T)','rot', 45);
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
    end
        xlabel('Time (ms)');
       legend (sprintf('N = %d', sum(goodChannels)))
    
end
% Save it
%         if saveData
%             save(fullfile(outputDir, sprintf('sub-%s_ses-%s_MEGpreproc.mat',subject, session)), ...
%                 'tsDenoised', 'tsv', 'stimTrigger','conditions','sensorData', 'badChannels', 'badEpochs' )
%         end
end

function [onsets,stimTypes , stimNums, stimTrigger] = parseTSVfile (rawDataDir, task, runnum, expLength)
%load in the TSV file information to confirm everything lines up
tsvFile =  dir (fullfile(rawDataDir,  sprintf('*task-%s_run-%d_events.tsv',task,runnum )));
tsv = tdfread(fullfile(tsvFile.folder, tsvFile.name));
onsets = tsv.onset;
trigNums = tsv.trial_type;
stimTypes = tsv.trial_name;
stimNums = unique(trigNums);
stimTrigger = zeros( expLength,1);
stimTrigger(round(onsets*1000)) = trigNums;
end

function goodChannels = findGoodMEGChannels(fullTimeseries,dataChannels, epocedData, goodChannelRatio)
numChannels = size(dataChannels');
numGoodChannels = round(numChannels(1) * goodChannelRatio);
tmp = mean(squeeze(var(epocedData(:,:,dataChannels'))),1);
tmp2 = sort(tmp, 'descend');
cutoffVal = tmp2(numGoodChannels);
goodChannels = mean(tmp,1)>=cutoffVal;

end

