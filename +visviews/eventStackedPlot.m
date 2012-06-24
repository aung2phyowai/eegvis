% visviews.eventStackedPlot()  display stacked view of individual element or window events
%
% Usage:
%   >>  visviews.eventStackedPlot(parent, manager, key)
%   >>  obj = visviews.eventStackedPlot(parent, manager, key)
%
% Description:
% obj = visviews.eventStackedPlot(parent, manager, key) shows each 
%     member of a slice of events offset vertically, with the lowest numbered 
%     member at the top and the highest number slice at the bottom. 
%     The stacked event plot can show three possible slices: by channel, 
%     by sample, or by window. Plotting by window is the most traditional display. 
% 
%     The parent is a graphics handle to the container for this plot. The
%     manager is an viscore.dataManager object containing managed objects
%     for the configurable properties of this object, and |key| is a string
%     identifying this object in the property manager GUI.
% 
%
% obj = visviews.eventStackedPlot(parent, manager, key) returns a handle to
%     the newly created object.
%
% visviews.eventStackedPlot is configurable, resizable, and cursor explorable.
%
%
% Configurable properties:
% The visviews.eventStackedPlot has five configurable parameters: 
%
% ClippingOn    is a boolean, which if true causes the individual events
%               to be truncated so that they appear inside the axes. 
%
% CombineMethod specifies how to combine multiple blocks 
%               when displaying a clumped slice.  The value can be 
%               'max', 'min', 'mean', 'median', or 
%               'none' (the default). 
%
% RemoveMean    is a boolean flag specifiying whether to remove the 
%               the individual channel means for the data before 
%               trimming or plotting.
%
% SignalLabel   is a string identifying the units of the event. 
%
% SignalScale   is a numerical factor specifying the vertical spacing 
%               of the individual line plots. The spacing is SignalScale 
%               times the 10% trimmed mean of the standard deviation 
%               of the data.
%
% TrimPercent   is a numerical value specifying the percentage of 
%               extreme points to remove from the window before 
%               plotting. If the percentage is t, the largest
%               t/2 percentage and the smallest t/2 percentage of the
%               data points are removed (over all elements or channels).
%               The event scale is calculated relative to the trimmed 
%               event and all of the events are clipped at the
%               trim cutoff before plotting.
%
% Example: 
% Create a stacked event plot for random events
%
%   % Create a sinusoidal data set with random amplitude and phase 
%   data = random('normal', 0, 1, [32, 1000, 20]);
%   testVD = viscore.blockedData(data, 'Rand1');
%
%   % Create a block function and a slice
%   defaults = visfuncs.functionObj.createObjects('visfuncs.functionObj', ...
%              visfuncs.functionObj.getDefaultFunctions());
%   thisFunc = defaults{1};
%   thisSlice = viscore.dataSlice('Slices', {':', ':', '1'}, ...
%               'DimNames', {'Channel', 'Sample', 'Window'});
%
%   % Create the figure and plot the data
%   sfig  = figure('Name', 'Stacked event plot with random data');
%   sp = visviews.eventStackedPlot(sfig3, [], []);
%   sp.SignalScale = 2.0;
%   sp.plot(testVD3, thisFunc, thisSlice);
%  
%   % Adjust the margins
%   gaps = sp.getGaps();
%   sp.reposition(gaps);
%
% Notes:
% -  If manager is empty, the class defaults are used to initialize
% -  If key is empty, the class name is used to identify in GUI configuration
% -  The plot calculates the spacing as the event scale times the
%    10% trimmed mean of the standard deviations of the event. That is,
%    the standard deviation of each plot is calculated. Then the lower
%    and upper 5% of the values are removed and the mean standard
%    deviation is computed. This value is multiplied by the event scale
%    to determine the plot spacing.
%
% Class documentation:
% Execute the following in the MATLAB command window to view the class 
% documentation for visviews.eventStackedPlot:
%
%    doc visviews.eventStackedPlot
%
% See also: visviews.clickable, visviews.configurable, visviews.resizable, and
%           visviews.shadowSignalPlot
%


% Copyright (C) 2011  Kay Robbins, UTSA, krobbins@cs.utsa.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Log: eventStackedPlot.m,v $
% Revision: 1.00  04-Dec-2011 09:11:20  krobbins $
% Initial version $
%

classdef eventStackedPlot < visviews.axesPanel  & visprops.configurable 
    %Panel that plots window events
    %
    % Inputs:
    %    parent    handle of parent container for this panel
    %    settings  structure or ModelSettings object containing this
    
    properties
        ColorSelected =   [1, 0, 0];   % face color of selected event
        ColorUnselected = [0, 1, 0];   % face color of unselected events
        ColorCertain = [0, 0, 0];      % edge color for certain events
        ColorUncertain = [0.8, 0.8, 0.8]; % edge color for uncertain events
        Threshold = 0.5               % uncertainty threshold (0 and 1)
        
    end % public properties 
    
    properties (Access = private)   
        BlockEnd = 1;                % ending block of currently plotted slice
        BlockStart = 1;              % starting block of currently plotted slice
        ColorLines = [0.8, 0.8, 0.8]; % color of grid lines
        CurrentSlice = [];           % current data slice
        CurrentEvents = [];          % array with current event numbers
        Events = [];                 % event object
        EventStart = 1;              % starting event of currently plotted slice 
        EventsUnique = 0;            % cell array of unique events
        HitList = {};                % list of hithandles
        PlotWindow = true;           % if true, a window is being plotted
        SelectedBlockOffset = 0;     % start of selected block in seconds
        SelectedHandle = [];         % handle of selected event or empty
        SelectedEvent = [];          % data in selected event or empty
        SelectedTagNumber = [];      % number of selected event within events
        VisData = [];                % original data for interrogation
        TimeUnits = 's';             % time units of the access
        XValues = [];                % x values of current plot
    end % private properties
    
    methods
        
        function obj = eventStackedPlot(parent, manager, key)
            % Create a stacked event plot, updating properties from  manager
            obj = obj@visviews.axesPanel(parent);
            obj = obj@visprops.configurable(key);
            % Update properties if any are available
            if isa(manager, 'viscore.dataManager')
                visprops.property.updateProperties(obj, manager);
            end
            set(obj.MainAxes, 'Box', 'on', 'YDir', 'reverse', ...
                'Tag', 'stackedSignalAxes', 'HitTest', 'on');
        end % eventStackedPlot constructor
        
        function [cbHandles, hitHandles] = getHitObjects(obj)
            % Return handles to register as callbacks and hit handles
            % Required for the visviews.clickable interface
            cbHandles = obj.HitList;
            hitHandles = obj.HitList;
        end % getHitObjects
        
        function plot(obj, visData, bFunction, dSlice)
            % Plot the events for the specified data slice
            obj.reset();
            if isempty(visData)
                return;
            end
            bFunction.setData(visData);
            obj.VisData = visData; % Keep data for cursor exploration

            obj.Events = visData.getEvents();    
            if isempty(obj.Events) || obj.Events.getNumberEvents() == 0
                return;
            end
            % Figure out whether the slice is by window or by element
            if isempty(dSlice)
               obj.CurrentSlice = viscore.dataSlice();
            else
                obj.CurrentSlice = dSlice;
            end
            
            % Calculate sizes and number of clumps, adjust for uneven clumps
            [e, s, b] = visData.getDataSize();
            [slices, names, cDims] = obj.CurrentSlice.getParameters(3);
 
            if isempty(cDims) || ~isempty(intersect(cDims, 3))  % Plot all elements for a window
                obj.PlotWindow = true; 
            elseif ~isempty(intersect(cDims, 1))  % Plot all windows for an element    
                obj.PlotWindow = false;
            else
                warning('eventStackedPlot:plotSlice', ...
                        'array slice is empty and cannot be plotted');
                return;
            end
            
            % Extract the slice  
            [dSlice, starts, sizes] = viscore.dataSlice.getSliceEvaluation(...
                                       [e, s, b], slices); %#ok<ASGLU>
            obj.BlockStart = starts(3);
            obj.BlockEnd = obj.BlockStart + sizes(3) - 1;
            
                       % Adjust signals to account for blocking
            if (obj.BlockEnd == obj.BlockStart)  || ...
                            (~visData.isEpoched() && obj.PlotWindow) 
                obj.YStringBase = 'Event';
                numPlots = [1, length(obj.Events.getUniqueTypes())];
                obj.XLimOffset = (obj.BlockStart - 1)*obj.Events.getBlockTime();
            else  % Plot vertically
                numPlots = [obj.BlockStart, obj.BlockEnd];
                obj.YStringBase = names{3};
                obj.XLimOffset = 0;
            end
          
           % Adjust the labels
            if visData.isEpoched() % add time scale to x label
                obj.XValues =  1000*visData.getEpochTimeScale();
                obj.XValues = [obj.XValues(1), obj.XValues(end)];
                obj.TimeUnits = 'ms';
            elseif ~obj.PlotWindow
                obj.XValues = [0, obj.Events.getBlockTime()];
                obj.TimeUnits = 's';
            else
                obj.XValues = [obj.XLimOffset, ...
                   obj.Events.getBlockStartTimes(obj.BlockEnd) ...
                                 + obj.Events.getBlockTime()];
                obj.TimeUnits = 's';
            end
           
            obj.CurrentEvents = obj.Events.getBlocks(obj.BlockStart, ...
                obj.BlockEnd);
            obj.EventsUnique = obj.Events.getUniqueTypes();
            obj.SelectedHandle = [];
            obj.SelectedEvent = [];
            obj.YString = obj.YStringBase;
            obj.XStringBase = ['Time(' obj.TimeUnits ') [' names{3} ' ' ...
                  viscore.dataSlice.rangeString(obj.BlockStart, sizes(3)) ']'];
            obj.XString = obj.XStringBase;
         
            obj.HitList = cell(1, length(obj.CurrentEvents) + 1);
            obj.HitList{1} = obj.MainAxes;
            [xTimes, yTimes] = obj.getPlotPositions();
            certainties = obj.Events.getCertainty(obj.CurrentEvents);
            for k = 1:length(obj.CurrentEvents);   
                if certainties(k) >= obj.Threshold
                    c = obj.ColorCertain;
                else
                    c = obj.ColorUncertain;
                end
                h =  plot(obj.MainAxes, xTimes{k}, yTimes{k}, '-s', ...
                         'Tag', num2str(obj.CurrentEvents(k)), ...
                          'LineWidth', 2, 'MarkerSize', 10, ...
                          'Color', obj.ColorUnselected, ...
                          'MarkerEdgeColor', c,...
                          'MarkerFaceColor', obj.ColorUnselected);
                obj.HitList{k + 1} = h;
            end
           
            yTickLabels = cell(1, numPlots(2) - numPlots(1) + 1);
            yTickLabels{1} = num2str(numPlots(1));
            yTickLabels{end} = num2str(numPlots(2));
            set(obj.MainAxes,  'YLimMode', 'manual', ...
                'YLim', [numPlots(1) - 1, numPlots(2) + 1], ...
                'YTickMode', 'manual', 'YTickLabelMode', 'manual', ...
                'YTick', numPlots(1):numPlots(2), 'YTickLabel', yTickLabels, ...
                'XLim', obj.XValues, ...
                'XLimMode', 'manual', 'XTickMode', 'auto');
             obj.redraw();
        end % plot
        
        function reset(obj)
            obj.reset@visviews.axesPanel();
            obj.HitList = {};
        end % reset

        function s = updateString(obj, point)
            % Return [Block, Element, Function] value string for point
            s = '';   % String to be returned
            try   % Use exception handling for small round-off errors
                [x, y, xInside, yInside] = obj.getDataCoordinates(point); %#ok<ASGLU>
                if ~xInside || ~yInside
                    return;
                end
                
                if ~obj.VisData.isEpoched()
                    t = x + obj.SelectedBlockOffset;
                    sample = floor(obj.VisData.SampleRate*(t)) + 1;
                    s = {['t: ' num2str(t) ' ' obj.TimeUnits]; ...
                        ['s: ' num2str(sample)]};
                    if ~isempty(obj.SelectedHandle)
                        rs = floor(obj.VisData.SampleRate*(x - obj.XLimOffset)) + 1;
                        s{3} = ['raw: '  num2str(obj.SelectedSignal(rs)) ...
                            ' ' obj.SignalLabel];
                    end
                else
                    a = (x - obj.VisData.EpochTimes(1))./1000;
                    a = floor(obj.VisData.SampleRate*a) + 1;
                    s = {['et: ' num2str(x) ' ' obj.TimeUnits]; ...
                        ['es: ' num2str(a)]};
                    if ~isempty(obj.SelectedHandle)
                        z = {['v: '  num2str(obj.SelectedSignal(a)) ...
                            ' ' obj.SignalLabel]};
                        s = [s; z];
                    end;
                end
            catch  ME  %#ok<NASGU>   ignore errors on cursor sweep
            end
        end % updateString
        
        function buttonDownPreCallback(obj, src, eventdata, master)  %#ok<INUSD>
            % Callback when user clicks on the plot to select a event
            if ~isempty(obj.SelectedHandle) && ishandle(obj.SelectedHandle)
                set(obj.SelectedHandle, ...
                    'MarkerFaceColor', obj.ColorUnselected, ...
                    'Color', obj.ColorUnselected);
            end

            if ~strcmpi(get(src, 'Type'), 'line')
                obj.SelectedHandle = [];
                obj.SelectedEvent = []; 
                obj.XString = obj.XStringBase;
                return;
            end 
            set(src, 'MarkerFaceColor', obj.ColorSelected, ...
                     'Color', obj.ColorSelected);
            obj.SelectedHandle = src;
            event = get(src, 'Tag');
            obj.SelectedEvent = str2double(event); 
            type = obj.Events.getTypes(obj.SelectedEvent); 
            obj.XString = [obj.XStringBase ' Event('  event '): ' ...
                  type{1} ' ' ...
                  num2str(obj.Events.getStartTimes(obj.SelectedEvent)) ' s'];
            obj.redraw();
        end % buttonDownPreCallback
        
    end % public methods
    
    methods (Access = private)

        function [xTimes, yTimes] = getPlotPositions(obj)
            xTimes = obj.Events.getStartTimes(obj.CurrentEvents);
            yTimes = obj.Events.getTypeNumbers(obj.CurrentEvents);
            if (obj.BlockStart == obj.BlockEnd) && obj.VisData.isEpoched()
                xTimes = obj.XValues(1) + 1000.*(xTimes - ...
                    obj.Events.getBlockStartTimes(obj.BlockStart));
            end
            xTimes = num2cell(xTimes);
            yTimes = num2cell(yTimes);
            if obj.BlockStart == obj.BlockEnd || (obj.PlotWindow && ~obj.VisData.isEpoched)
                return;
            end
            
            epochNums = obj.Events.getEventBlocks(obj.CurrentEvents);
            for k = 1:length(obj.CurrentEvents)
                t = epochNums{k};
                s = repmat(xTimes{k}, length(t), 1) - ...
                    obj.Events.getBlockStartTimes(t);
                if obj.VisData.isEpoched()
                    s = 1000.*s + obj.XValues(1);
                end
                xTimes{k} = s;
                yTimes{k} = t;
            end       
        end % getPlotPositions
        
    end % private methods
    
    methods(Static=true)
        
        function settings = getDefaultProperties()
            % Structure specifying how to set configurable public properties
            cName = 'visviews.eventStackedPlot';
            settings = struct( ...
                'Enabled',       { ...
                       true, ... %1
                       true, ... %2
                       true, ... %3
                       true, ... %4                      
                       true  ... %5
                      }, ...
                'Category',      { ...
                       cName, ... %1
                       cName, ... %2
                       cName, ... %3
                       cName, ... %4                      
                       cName  ... %5
                      }, ...
                'DisplayName',   { ...
                       'Threshold',       ... %1
                       'Color certain',   ... %2
                       'Color uncertain', ... %3
                       'Color selected',  ... %4                      
                       'Color unselected' ... %5   
                       }, ...
                'FieldName',     { ...
                       'Threshold',      ... %1
                       'ColorCertain',   ... %2
                       'ColorUncertain', ... %3
                       'ColorSelected',  ... %4                      
                       'ColorUnselected' ... %5   
                       }, ...              
                'Value',         { ...
                       0.5,              ... %1
                       [0, 0, 0],        ... %2
                       [0.8, 0.8, 0.8],  ... %3
                       [1, 0, 0],        ... %4                      
                       [0, 1, 0]         ... %5    
                       }, ...               
                'Type',          { ...
                       'visprops.doubleProperty', ... %1
                       'visprops.colorProperty',  ... %2
                       'visprops.colorProperty',  ... %3
                       'visprops.colorProperty',  ... %4                      
                       'visprops.colorProperty'   ... %5    
                       }, ...                               
                'Editable',      { ...
                       true, ... %1
                       true, ... %2
                       true, ... %3
                       true, ... %4                      
                       true  ... %5               
                        }, ...
                'Options',      { ...
                       [0, 1], ... %1
                       '',     ... %2
                       '',     ... %3
                       '',     ... %4                      
                       ''      ... %5       
                       }, ...
                'Description',   { ...
                       'Threshold for event certainty (must be in [0, 1])', ... %1
                       'Marker outline color for certain event',            ... %2
                       'Marker outline color for uncertain event',          ... %3                       
                       'Marker face color for selected event',              ... %4 
                       'Marker face color for unselected event',            ... %5
                       } ...
                );
        end % getDefaultProperties
               
    end % static methods
    
end % eventStackedPlot
