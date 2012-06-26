%% visviews.blockBoxPlot
% Display a boxplot of blocked function values by window
%
%% Syntax
%     visviews.blockBoxPlot(parent, manager, key)
%     obj = visviews.blockBoxPlot(parent, manager, key)
%
%% Description
% |obj = visviews.blockBoxPlot(parent, manager, key)| displays a series of 
% vertical box plots using a compressed style. The block box plot 
% displays the distribution of values of a summarizing function for 
% a clump of consecutive time windows or epochs for all channels. 
% Each window or epoch produces a single value for each element. 
%
% The |parent| is a graphics handle to the container for this plot. The
% |manager| is an |viscore.dataManager| object containing managed objects
% for the configurable properties of this object, and |key| is a string
% identifying this object in the property manager GUI.
% 
% |obj = visviews.blockBoxPlot(parent, manager, key)| returns a handle to
% the newly created object.
%
% |visviews.blockBoxPlot| is configurable, resizable, clickable, and cursor explorable.
%
%% Configurable properties
% The |visviews.blockBoxPlot| has five configurable properties: 
%
% |BoxColors| provides a list of colors used to alternate through in 
% displaying the boxes. For data with lots of clumps, the 
% boxes appear highly compressed due to limited viewing space and 
% alternating colors help users distinguish the individual boxes. The
% default is |[0.7, 0.7, 0.7; 1, 0, 1]|.
%
% |ClumpSize| specifies the number of consecutive windows or epochs 
% represented by each box. When the |ClumpSize| is one (the default), 
% each box represents its own window. If |ClumpSize| is greater than 
% one, each box represents several consecutive blocks. 
% Users can trade-off clump size versus block size to see different 
% representations of the data.
%
% |CombineMethod| specifies how to combine multiple blocks into a 
% single block to determine an overall block value. The value can be 
% |'max'|  (default), |'min'|, |'mean'|, |'median'| or |'sum'|. Detail plots use 
% the combined block value to determine slice colors. 
%
% Suppose the plot has 128 channels, a clump size of 3, a block size of 
% 1000 samples, and 100 windows. A user click delivers a slice representing 
% 3�1000 worth of data. A detail plot such as |signalStackedPlot| 
% combines this data based on its own |CombineMethod| property, 
% say by taking the mean to plot 32�1000 data points on 32 line graphs. 
% However, we would like to use line colors for the signals based 
% on the block function values in the box plot. The detail plots use 
% box plot's |CombineMethod| to combine the blocks to get appropriate 
% colors for the slice. 
%
% Usually signal plots combine signals using mean or median, while 
% summary plots such as |blockBoxPlot| use the max, although users may 
% choose other combinations.
%
% |IsClickable| is a boolean specifying whether this plot should respond to
% user mouse clicks when incorporated into a linkable figure. The
% default value is |true|.
%
% |LinkDetails| is a boolean specifying whether clicking this plot in a
% linkable figure should cause detail views to display the clicked
% slice. The default value is |true|.
%

%% Example 1
% Create a boxplot of kurtosis for EEG data

    % Create a element box plot
    sfig = figure('Name', 'Kurtosis for EEG data');
    bp = visviews.blockBoxPlot(sfig, [], []);

    % Read some eeg data to display
    load('EEG.mat');  % Saved EEGLAB EEG data
    testVD = viscore.blockedData(EEG.data, 'Sample EEG data', ...
         'SampleRate', EEG.srate);

    % Create a kurtosis block function object
    funs = visfuncs.functionObj.createObjects('visfuncs.functionObj', ...
               visfuncs.functionObj.getDefaultFunctions());
    
    % Plot the block function, adjusting margins for display
    bp.plot(testVD, funs{1}, []);
    gaps = bp.getGaps();
    bp.reposition(gaps);

    
%% Example 2
% Create a boxplot of kurtosis of clumps of 3 windows 

    % Create a block box plot
    sfig = figure('Name', 'Kurtosis for 32 exponentially distributed channels');
    bp = visviews.blockBoxPlot(sfig, [], []);
    bp.ClumpSize = 3;

    % Generate some data to plot
    data = random('exp', 1, [32, 1000, 20]);
    testVD = viscore.blockedData(data, 'Exponenitally distributed');
    
    % Create a kurtosis block function object
    funs = visfuncs.functionObj.createObjects('visfuncs.functionObj', ...
               visfuncs.functionObj.getDefaultFunctions());
    
    % Plot the block function, adjusting margins for display
    bp.plot(testVD, funs{1}, []);
    gaps = bp.getGaps();
    bp.reposition(gaps);
    

%% Notes
%
% * If |manager| is empty, the class defaults are used to initialize.
% * If |key| is empty, the class name is used to identify in GUI
% configuration.
%
%% Class documentation
% Execute the following in the MATLAB command window to view the class 
% documentation for |visviews.blockBoxPlot|:
%
%    doc visviews.blockBoxPlot
%
%% See also
% <axesPanel_help.html |visviews.axesPanel|>,
% <blockImagePlot_help.html |visviews.blockImagePlot|>, 
% <clickable_help.html |visviews.clickable|>, 
% <configurable_help.html |visprops.configurable|>,
% <cursorExplorable_help.html |visviews.cursorExplorable|>, 
% <elementBoxPlot_help.html |visviews.elementBoxPlot|>, and
% <resizable_help.html |visviews.resizable|> 
%

%% 
% Copyright 2011 Kay A. Robbins, University of Texas at San Antonio