function bidsMakeGLMSummaryPlots(projectDir , subjects, modelTypes, sessions,...
    tasks, conditionsOfInterest, saveFigures, imFolder, plotAllConditions, plotGroupAvg)
% bidsMakeGLMSummaryPlots(projectDir , subjects, modelTypes, [sessions],...
%     [tasks], [conditionsOfInterest], [saveFigures],[plotAllConditions])
%
% summarizeGLMDenoisebyArea (projectDir , subject, modelType, [session],...
%   [tasks], [conditionsOfInterest], [makeFigures], [saveFigures])
%
% Required input:
%
%   projectDir  : path where the BIDS projects lies (string)
%   subjects    : BIDS subject name (string, all lower case)
%   modelTypes  : name of folder containing outputs of GLMdenoised 
%
% Optional input:
%
%   sessions             : BIDS session names 
%   tasks                : The tasks used for running the GLM
%                               default : use all tasks 
%                                   (HRF, temporalpattern, spatialpattern, spatialobject)
%                               Note: The total number of conditions should
%                               matchn the number of columns in design matrices
%                               used for GLM
%   saveFigures          : 0 = don't save figures, 1 = save figures (default: 0)
%   imFolder             : name of folder to save plots (will be within GLMdenoise folder)
%                               default = modelTypes      
%   conditionsOfInterest : one or more types experimental conditions used
%                           for thresholding (string or cell array of strings)
%                               default: uses all conditions
%   plotAllConditions    : Whether to plot all tasks/conditions
%                             default : true - will plot all conditions
%                                           used in running GLMdenoise 
%                              Note if false:
%                               If conditions of interest are provided,
%                               only those conditions will be plotted If no
%                               conditions of interest are provided, but
%                               tasks are provided, conditions in those
%                               tasks will be plotted 
%   plotGroupAverage     : will take the average of all subjects provided
%                              and compute a standard error of this mean
%                                   default : false
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
% imFolder = {'roundedTR_12', 'upsampled_12'};
%
% bidsMakeGLMSummaryPlots(projectDir , subjects, modelTypes, sessions,...
%     tasks, conditionsOfInterest, saveFigures, imFolder)

% Set ROI labels and load some stimulus conditions
[~, ~, ~, bensonAreaLabels] = roisFromAtlas(subjects{1});

load('designMatrixConditions.mat', 'allConditions', 'temporalpattern',...
    'spatialobject', 'spatialpattern', 'conditionSubsets');


%% check for inputs and set defaults
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
    
    % set a dirctory for saving images
    if ~exist ('imFolder', 'var' )|| isempty(imFolder),saveFolder =  modelTypes{mm}; end
    if length(imFolder) > 1, saveFolder = imFolder{mm}; else saveFolder = char(imFolder); end
    imDir = fullfile(projectDir, 'derivatives','GLMdenoise', 'summaryFigures', saveFolder);
    if ~exist(imDir, 'dir' ), mkdir(imDir), end
    
    %loop through subjects and compute the means and standard errors
    for ii = 1:length(subjects)
        subject = subjects{ii};
        if ~skip, session = sessions{ii}; end
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
    
%     % For each visual area, make a subplot for each subject across all stimulus GLMconditions
%     for ll = 1:length(bensonAreaLabels)
%         f =  figure('Name', sprintf('%s',bensonAreaLabels{ll}));
%         
%         for jj = 1:length(subjects)
%             subplot(length(subjects),1, jj)
%             bar(meanBeta{jj}(ll,:))
%             hold on
%             errorbar(meanBeta{jj}(ll,:),stErr{jj}(ll,:),'LineStyle','none')
%             title(sprintf('%s',subjects{jj}))
%             xticks(1: length(GLMconditions))
%             xticklabels([])
%             ylabel ('BW')
%             
%         end
%         set(f, 'Position', (f.Position.*[1 1 2 2]))
%         xticklabels(GLMconditions)
%         xlabel('Condition')
%         xtickangle(45)
%         linkaxes(f.Children,'y')
%         % Save it
%         if(saveFigures)
%             print (fullfile(imDir,sprintf('%s_AvgBetaWeight',bensonAreaLabels{ll})),'-dpng')
%         end
%     end
    
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
        
        linkaxes(f.Children,'y')
        set(f, 'Position', (f.Position.*[1 1 2 2]))
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
           
            for ll = 1:length(bensonAreaLabels) 
                subplot (3, 4, ll) %subplot (3, 4, ll)
                bar(meanBeta{jj}(ll,idx))
                hold on
                errorbar(meanBeta{jj}(ll,idx),stErr{jj}(ll,idx),'LineStyle','none')
                xticks(1: length(conditionsToPlot{ii}))
                title (bensonAreaLabels{ll})
              %  ylabel ('Avg BetaWeight')
                
                if ll == 1 || ll == 5 || ll == 9; ylabel ('Avg BetaWeight'); end
                
                if any(ll == 9:12)
                    xticklabels(conditionsToPlot{ii})
                    xlabel('Condition')
                    xtickangle(45)
                else
                    xticklabels([])
                end
                
            end
%             xticklabels(conditionsToPlot{ii})
%             xlabel('Condition')
%             xtickangle(45)
            set(f, 'Position', (f.Position.*[1 1 2 2]))
           % linkaxes(f.Children,'y')
            %save it
            if(saveFigures)
                print (fullfile(imDir,sprintf('sub-%s_stimSubset-%d_AvgBW',...
                    subjects{jj}, ii)),'-dpng')
            end
        end
    end
    clear meanBeta stErr
    %close all
end
