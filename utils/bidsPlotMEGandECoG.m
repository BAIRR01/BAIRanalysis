function bidsPlotMEGandECoG (projectDir, subject, session,runnums, tasks, ...
    saveFolder,plotChecks, goodChannelRatio)%epocLength,
%
% projectDir = '/Volumes/server/Projects/BAIR/Data/BIDS/visual';
% subject = 'wlsubj100';
% session = 'nyumeg01';
% tasks = {'hrfpattern', 'temporalpattern', 'spatialobject', 'spatialpattern'};
% saveFolder = 'MEGpreprocessed';
% plotChecks = true;
% runnums = [];
% goodChannelRatio = .1;

%% Set up paths and options
[session, tasks, runnums,siteModality ] = bidsSpecifyEPIs(projectDir, subject, session, tasks, runnums);

switch siteModality
    case 'meg'
        dataChannels            = 1:157;
        %environmentalChannels   = 158:160;
        %triggerChannels         = 161:168;
        rawDataFldr = 'meg';
        dataStr = 'meg';
        unit = 'Magnetic flux (T)';
    case 'ecog'
        rawDataFldr = 'ieeg';
        dataStr = 'ieeg';
end

rawDataDir  = fullfile (projectDir, sprintf('sub-%s', subject), sprintf('ses-%s', session),rawDataFldr);

if ~exist('saveFolder', 'var')|| isempty(saveFolder)
    saveData = false;
else
    outputDir   = fullfile (projectDir,'derivatives', saveFolder, sprintf('sub-%s', subject), sprintf('ses-%s', session));
    saveData = true;
    if ~exist('outputDir', 'dir'), mkdir(outputDir); end
end

%% Load data and check triggers (Fieldtrip)
for ii = 1:length (tasks)
    % get all data for an experiment type
    [ts, hdr]   = bidsGetPreprocData(rawDataDir, dataStr,{tasks{ii}}, runnums(ii));
    % initialize some variables
    allOnsets   = []; allTriggers = [];fullTimeseries = []; allStimNames = []; allStimNums = [];
    
    for jj = 1:length(runnums{ii})
        thisTimeSeries = ts{jj};
        expLength      = length(thisTimeSeries);
        [onsets,stimTypes , trigNums, stimTrigger] = parseTSVfile(rawDataDir, tasks{ii}, runnums{ii}(jj), expLength);
        if jj == 1, allOnsets   = [allOnsets; onsets];end
        if jj > 1,  allOnsets   = [allOnsets; (onsets + allOnsets(end))];end
        allTriggers = [allTriggers; stimTrigger];
        allStimNames = [allStimNames; string(stimTypes)];
        fullTimeseries = cat(2,fullTimeseries,thisTimeSeries);
        allStimNums = [allStimNums; trigNums];
    end
    stimNums = unique(allStimNums);
    
    switch siteModality
        case 'meg'
            % Define length of epochs relative to stimTrigger onset and get sample rate
            epochLength = [0 1]; % start and end of epoch (seconds), zero is stimTrigger onset
            fs      = 1000;  % Hz
            % Get sensordata (time x epochs x channels) and conditions (epochs x 1)
            [epocedData, ~] = meg_make_epochs(fullTimeseries', allOnsets, epochLength, fs);
            sensorsToPlot = findMEGChannels(hdr{1}, tasks{ii},plotChecks);
            sensorNumsToPlot = dataChannels(sensorsToPlot);
            goodChannels = findGoodMEGChannels(sensorNumsToPlot, epocedData, goodChannelRatio,plotChecks);
            
            for ss = 1:length(stimNums)
                idx = allStimNums == stimNums(ss);
                % mean timeseries
                mnTS{ss} = squeeze(mean(epocedData(:,idx,:),2));
                % Transform to Fourier space and take the amplitudes
                amps = abs(fft(epocedData(:,idx,:)))/length(epocedData(1))*2;
                % Take mean across epochs, rescale by number of timepoints
                meanAmps{ss} = squeeze(mean(amps,2));
                tmp = find(idx);
                stimNames{ss} = allStimNames(tmp(1));
            end
        case 'ecog'
            % do something
            
    end
    t = 0:(size(epocedData,1)-1);
    f = 0:length(t)-1;
    
    if plotChecks
        plotSanityChecks (epocedData, allTriggers, unit)
    end
    if length(stimNums) > 3
        stimNumsToPlot{1} = stimNums(1:length(stimNums)/2);
        stimNamesToPlot{1} = stimNames(1:length(stimNames)/2);
        stimNumsToPlot{2} = stimNums(length(stimNums)/2+1:length(stimNums));
        stimNamesToPlot{2} = stimNames(length(stimNames)/2+1:length(stimNames));
    else
        stimNumsToPlot{1} = stimNums;
        stimNamesToPlot{1} = stimNames;
    end
    
    % Plot mean time series and amplitudes averaged across sensors in one plot
    for c = 1:length(stimNumsToPlot)
        thisfig = figure('Name',sprintf('%s - set%d',tasks{ii}, c)); clf;
        subplot(1,2,1); cla;
        for n = 1:length (stimNumsToPlot{c})
            tmpIdx = stimNums == stimNumsToPlot{c}(n);
            plot(t, mean(mnTS{tmpIdx}(:,goodChannels),2)), hold on;
        end
        %xlim([min(t) max(t)]);
        xlabel('Time (ms)')
        ylabel(unit)
        title(sprintf('MeanTS (Across %d Sensors)', length(goodChannels)))
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
       legend (stimNamesToPlot{c},'Location','best')
        box off;
        
        subplot(1,2,2); cla;
        for n = 1:length (stimNumsToPlot{c})
            tmpIdx = stimNums == stimNumsToPlot{c}(n);
            plot(f, mean(meanAmps{tmpIdx}(:,goodChannels),2));hold on
        end
        xlabel('Frequency (Hz)')
        ylabel('Amplitudes (T)')
        title(sprintf('MeanFFT (Across %d Sensors)',length(goodChannels)))
        set(gca, 'XScale', 'log', 'YScale', 'log')
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
        set(thisfig, 'Position', (thisfig.Position.*[1 1 2 2]))
        legend (stimNamesToPlot{c},'Location','best')
        %save
        if saveData
            print (fullfile(outputDir,sprintf('sub-%s_%s_AvgAcross%dSensors_1',...
                subject,tasks{ii}, length(goodChannels))),'-dpng')
        end
    end

% Plot the mean time series and amplitudes for every sensor on the
% same plots with subplots by condition
thisfig = figure('Name',subject) ; clf;
figCount = 1;
for s = 1:length(stimNums)
    subplot(length(stimNums),2,figCount); cla;
    plot(t, mnTS{s}(:,goodChannels));
    title(sprintf('%s MeanTS - Top %2.1f %% of Channels',stimNames{s},(length(goodChannels)/157)*100))
    ylabel(unit)
    xlabel([])
    set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
    box off;
    
    if  figCount == length(stimNums), xlabel('Time (ms)'), end
    figCount = figCount+1;
    
    subplot(length(stimNums),2,figCount); cla;
    plot(f, meanAmps{s}(:,goodChannels));
    xlabel([])
    ylabel('Amp(T)')
    title(sprintf('%s MeanFFT - Top %2.1f %% of Channels',stimNames{s},(length(goodChannels)/157)*100))
    set(gca, 'XScale', 'log', 'YScale', 'log')
    set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
    
    if figCount == length(stimNums)*2,xlabel('Frequency (Hz)'),end
    figCount = figCount+1;
end
% if length(stimNums) >1
%     linkaxes(thisfig.Children(1:2:end),'xy')
%     linkaxes(thisfig.Children(2:2:end),'xy')
% end
legend(string(goodChannels),'Orientation','horizontal')
set(thisfig, 'Position', (thisfig.Position.*[1 1 2 2]))
%save
if saveData
    print (fullfile(outputDir,sprintf('sub-%s_%s_MEG_multiSensor',...
        subject,tasks{ii})),'-dpng')
end

%Plot subplots for each sensor containing multiple stimuli
for c = 1:length(stimNumsToPlot)
    for j = 1:2:length(goodChannels)
        thisfig = figure; clf;
        subplot(1,2,1); cla;
        for n = 1:length (stimNumsToPlot{c})
            tmpIdx = stimNums == stimNumsToPlot{c}(n);
            plot(t, mnTS{tmpIdx}(:,goodChannels(j)));hold on
        end
        legend (stimNamesToPlot{c},'Location','best')
        xlabel('Time (ms)')
        ylabel(unit)
        title(sprintf('MnTS - %s',string(goodChannels(j))))
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
        box off;
       
        subplot(1,2,2); cla;
        for n = 1:length (stimNumsToPlot{c})
            tmpIdx = stimNums == stimNumsToPlot{c}(n);
            plot(f, meanAmps{tmpIdx}(:,goodChannels(j)));hold on
        end
        xlabel('Frequency (Hz)')
        ylabel('Amplitudes (T)')
        title(sprintf('MnFFT - %s',string(goodChannels(j))))
        legend (stimNamesToPlot{c},'Location','best')
        set(gca, 'XScale', 'log', 'YScale', 'log')
        set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
        set(thisfig, 'Position', (thisfig.Position.*[1 1 2 2]))
    %save
    if saveData
        print (fullfile(outputDir,sprintf('sub-%s_%s_MEG_sensor%d_%d',...
            subject,tasks{ii}, goodChannels(j), c)),'-dpng')
    end
    end
   
end
clear stimNamesToPlot stimNumsToPlot stimNames stimNums
end
end





function [onsets,stimTypes , trigNums, stimTrigger] = parseTSVfile (rawDataDir, task, runnum, expLength)
%load in the TSV file information to confirm everything lines up
tsvFile =  dir (fullfile(rawDataDir,  sprintf('*task-%s_run-%d_events.tsv',task,runnum )));
tsv = tdfread(fullfile(tsvFile.folder, tsvFile.name));
onsets = tsv.onset;
trigNums = tsv.trial_type;
stimTypes = tsv.trial_name;
stimTrigger = zeros( expLength,1);
stimTrigger(round(onsets*1000)) = trigNums;
end

function sensorsToPlot = findMEGChannels(hdr, task,plotChecks)  %fullTimeseries,dataChannels, epocedData, goodChannelRatio)
layout = ft_prepare_layout([],hdr);
% Define x and y sensor positions
xpos = layout.pos(1:157,1);
ypos = layout.pos(1:157,2);

switch task
    case {'temporalpattern', 'spatialpattern', 'spatialobject', 'hrf','hrfpattern', 'prf'}
        whichSensors = find(ypos<0 & xpos<1);
    case {'boldhand', 'fingermappingright','fingermappingleft', 'gestures', 'boldsat1', 'boldsat2' , 'boldsat3' , 'boldsat4' }
        
end
sensorsToPlot = zeros(1,157);
sensorsToPlot(whichSensors) = 1;
sensorsToPlot = boolean(sensorsToPlot);
if plotChecks% Get sensors over the lower back of the head (presumably occipital cortex)
    % Plot the selected sensors
    clims = [0 1];
    cmap  = colormap('gray');
    ttl   = 'MEG sensors y pos < 0';
    figure;clf;
    megPlotMap(sensorsToPlot, clims, [], cmap, ttl, [], [], 'interpolation', 'nearest');
end
end

function goodChannels = findGoodMEGChannels(sensorNumsToPlot, epocedData, goodChannelRatio,plotChecks)
numChannels = size(sensorNumsToPlot');
numGoodChannels = round(numChannels(1) * goodChannelRatio);
mnVar = mean(squeeze(var(epocedData(:,:,sensorNumsToPlot))),1);
sortedVar = sort(mnVar, 'descend');
cutoffVal = sortedVar(numGoodChannels);
theseChannels = mean(mnVar,1)>=cutoffVal;
goodChannels = sensorNumsToPlot(theseChannels);

if plotChecks
    clims = [0 1];
    cmap  = colormap('gray');
    ttl   = sprintf('Top %2.1f %% of MEG sensors',(numGoodChannels/157)*100);
    sensorsToPlot = zeros(1,157);
    sensorsToPlot(:,goodChannels) = 1;
    figure;clf;
    megPlotMap(sensorsToPlot, clims, [], cmap, ttl, [], [], 'interpolation', 'nearest');
end
end

function plotSanityChecks (epocedData, allTriggers, unit)
figure
% Plot the triggers to check them
plot(allTriggers');
xlabel('Time (ms)');
ylabel('Condition nr');
set(gca, 'TickDir', 'out', 'FontSize', 12); box off;

% Plot single channel: mean timeseries across all epocs
figure
plot( mean(epocedData(:,:,1),2))
xlabel('Time (ms)');
ylabel(unit);
set(gca, 'TickDir', 'out', 'FontSize', 12); box off;
end
