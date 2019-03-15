function bidsMakeGLMSummaryPlots(projectDir , subjects, modelTypes, sessions,...
    tasks, conditionsOfInterest, saveFigures, imDir, plotAllConditions, plotGroupAvg)
% bidsMakeGLMSummaryPlots(projectDir , subjects, modelTypes, [sessions],...
%     [tasks], [conditionsOfInterest], [saveFigures],[plotAllConditions])
%
% Computes the mean betaweights using function summarizeGLMDenoisebyArea
% and then plots the data in various ways
%
% Example 1:
%     projectDir = '/Volumes/server/Projects/BAIR/Data/BIDS/visual';
%     modelTypes  = {'UpsampledToSurfaceTemporal'};
%     subjects    = {'wlsubj048', 'wlsubj051', 'wlsubj052', 'wlsubj053', 'wlsubj054'};
%     conditionsOfInterest = [ "onepulse", "twopulse"]; %"crf",
%     plotAllConditions = false;
%
% bidsMakeGLMSummaryPlots(projectDir , subjects, modelTypes, [],...
%     [], conditionsOfInterest, [],[], plotAllConditions)
%
% Example 2:
% projectDir = '/Volumes/server/Projects/BAIR/Data/BIDS/visual';
% modelTypes  = {'temporalpatternRoundedTRToSurface','temporalpatternUpsampledToSurface'};
% subjects = {'wlsubj001', 'wlsubj062'};
% sessions = {'nyu3t01', 'nyu3t01'};
% conditionsOfInterest = ["onepulse", "twopulse"];
% tasks = {'temporalpattern'};
% saveFigures = 0;
% plotAllConditions = true
%
% bidsMakeGLMSummaryPlots(projectDir , subjects, modelTypes, sessions,...
%     tasks, conditionsOfInterest, saveFigures)

% Set ROI labels and load some stimulus conditions
[~, ~, ~, bensonAreaLabels] = roisFromAtlas(subjects{1});

load('designMatrixConditions.mat', 'allConditions', 'temporalpattern',...
    'spatialobject', 'spatialpattern', 'conditionSubsets');


%% check for inputs and set defaults
if ~exist ('imDir', 'var' )|| isempty(imDir)
    imDir = fullfile(projectDir, 'derivatives','GLMdenoise', 'summaryFigures');
end
if ~exist(imDir, 'dir' ), mkdir(imDir), end
if ~exist ('plotGroupAvg', 'var' )|| isempty(plotGroupAvg)
    plotGroupAvg = false;
end

if ~exist ('saveFigures', 'var' )|| isempty(saveFigures)
    saveFigures = false;
end
if plotAllConditions
    if ~exist ('tasks', 'var' )|| isempty(tasks)
        conditionsToPlot = struct2cell(conditionSubsets);
    else
        for cc = 1:length(tasks)
            conditionsToPlot{cc} = eval(tasks{cc});
        end
    end
else
    for cc = 1:length(conditionsOfInterest)
        conditionsToPlot{cc} = eval(sprintf('conditionSubsets.%s',conditionsOfInterest(cc)));
    end
end
if ~exist('sessions', 'var') || isempty(sessions)
    session = [];
    skip = true;
else
    skip = false;
end

%% figure out what to compute, then plot it
for mm = 1:length(modelTypes)
    modelType = modelTypes{mm};
    for ii = 1:length(subjects)
        subject = subjects{ii};
        if ~skip, session = sessions{ii}; end
        % compute the
        [meanBeta{ii} , stErr{ii}, GLMconditions] = bidsSummarizeGLMDenoisebyArea (projectDir , subject, modelType,session,tasks, conditionsOfInterest);
    end
    
    if plotGroupAvg
        for c = 1:length(GLMconditions)
            for a = 1: length(bensonAreaLabels)
                for s = 1:length(subjects)
                    temp(s) = meanBeta{s}(a,c);
                end
                groupMn{1}(a,c) = mean(temp);
                groupStErr{1}(a,c) = std(temp)/sqrt(length(temp));
            end 
        end
        subjects = {'GroupAvg'};
        meanBeta = groupMn;
        stErr = groupStErr;
    end
    
    % For each visual area, make a subplot for each subject across all stimulus GLMconditions
    for ll = 1:length(bensonAreaLabels)
        f =  figure('Name', sprintf('%s',bensonAreaLabels{ll}));
        
        for jj = 1:length(subjects)
            subplot(length(subjects),1, jj)
            bar(meanBeta{jj}(ll,:))
            hold on
            errorbar(meanBeta{jj}(ll,:),stErr{jj}(ll,:),'LineStyle','none')
            title(sprintf('%s',subjects{jj}))
            xticks(1: length(GLMconditions))
            xticklabels([])
            ylabel ('BW')
            
        end
        set(f, 'Position', (f.Position.*[1 1 1.5 2]))
        xticklabels(GLMconditions)
        xlabel('Condition')
        xtickangle(45)
        
        % Save it
        if(saveFigures)
            print (fullfile(imDir,sprintf('%s_AvgBetaWeight',bensonAreaLabels{ll})),'-dpng')
        end
    end
    
    % For each visual area, make a subplot for each subject and stimulus subset
    for ll = 1:length (bensonAreaLabels)
        f = figure('Name', sprintf('%s',bensonAreaLabels{ll}));
        count = 1;
        for ii = 1:length(conditionsToPlot)
            idx = contains (GLMconditions, conditionsToPlot{ii});
            for jj = 1: length(subjects)
                subplot (length(conditionsToPlot), length(subjects), count)
                bar(meanBeta{jj}(ll,idx))
                hold on
                errorbar(meanBeta{jj}(ll,idx),stErr{jj}(ll,idx),'LineStyle','none')
                title (subjects{jj})
                xticks(1: length(conditionsToPlot{ii}))
                xticklabels(conditionsToPlot{ii})
                xtickangle(45)
                ylabel ('BW')
                xlabel('Condition')
                count = count+1;
            end
        end
        
        
        set(f, 'Position', (f.Position.*[1 1 1.5 2]))
        % Save it
        if(saveFigures)
            print (fullfile(imDir,sprintf('%s_acrossSubjs_AvgBetaWeight',...
                bensonAreaLabels{ll})),'-dpng')
        end
    end
    
    % For each subject and stimulus subset, make subplots for each visual area
    for jj = 1: length(subjects)
        for ii = 1:length(conditionsToPlot)
            f = figure('Name', sprintf('%s',subjects{jj}));
            idx = contains (GLMconditions, conditionsToPlot{ii});
            
            for ll = 1:length (bensonAreaLabels)
                subplot (3, 4, ll)
                bar(meanBeta{jj}(ll,idx))
                hold on
                errorbar(meanBeta{jj}(ll,idx),stErr{jj}(ll,idx),'LineStyle','none')
                xticks(1: length(conditionsToPlot{ii}))
                title (bensonAreaLabels{ll})
                
                if ll == 1 || 5 || 9; ylabel ('BW'); end
                
                if any(ll == 9:12)
                    xticklabels(conditionsToPlot{ii})
                    xlabel('Condition')
                    xtickangle(45)
                else
                    xticklabels([])
                end
            end
            set(f, 'Position', (f.Position.*[1 1 1.5 2]))
            
            %save it
            if(saveFigures)
                print (fullfile(imDir,sprintf('sub-%s_stimSubset-%d_AvgBW',...
                    subjects{jj}, ii)),'-dpng')
            end
        end
    end
    clear meanBeta stErr
    close all
end
