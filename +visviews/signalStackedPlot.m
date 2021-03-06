% visviews.signalStackedPlot()  display stacked view of individual element or window signals
%
% Usage:
%   >>  visviews.signalStackedPlot(parent, manager, key)
%   >>  obj = visviews.signalStackedPlot(parent, manager, key)
%
% Description:
% obj = visviews.signalStackedPlot(parent, manager, key) shows each
%     member of a slice of signals offset vertically, with the lowest numbered
%     member at the top and the highest number slice at the bottom.
%     The stacked signal plot can show three possible slices: by channel,
%     by sample, or by window. Plotting by window is the most traditional display.
%
%     The parent is a graphics handle to the container for this plot. The
%     manager is an viscore.dataManager object containing managed objects
%     for the configurable properties of this object, and |key| is a string
%     identifying this object in the property manager GUI.
%
%
% obj = visviews.signalStackedPlot(parent, manager, key) returns a handle to
%     the newly created object.
%
% visviews.signalStackedPlot is configurable, resizable, and cursor explorable.
%
%
% Configurable properties:
% The visviews.signalStackedPlot has seven configurable parameters:
%
% ClippingOn    is a boolean, which if true causes the individual signals
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
% SignalLabel   is a string identifying the units of the signal.
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
%               The signal scale is calculated relative to the trimmed
%               signal and all of the signals are clipped at the
%               trim cutoff before plotting.
% TrimScope     specifies the range over which trimming and removing
%               the mean takes place. A value of 'global' specifies that the
%               the trim percentages and means are computed on the entire
%               dataset, while a value of 'local' specifies that trimming
%               and removing the mean applies only to the block being
%               plotted.
%
% Example:
% Create a stacked signal plot for random signals
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
%   % Create the figure and plot the data, adjusting the margins
%   sfig  = figure('Name', 'Stacked signal plot with random data');
%   sp = visviews.signalStackedPlot(sfig, [], []);
%   sp.SignalScale = 2.0;
%   sp.plot(testVD, thisFunc, thisSlice);
%   gaps = sp.getGaps();
%   sp.reposition(gaps);
%
% Notes:
% -  If manager is empty, the class defaults are used to initialize
% -  If key is empty, the class name is used to identify in GUI configuration
% -  The plot calculates the spacing as the signal scale times the
%    10% trimmed mean of the standard deviations of the signal. That is,
%    the standard deviation of each plot is calculated. Then the lower
%    and upper 5% of the values are removed and the mean standard
%    deviation is computed. This value is multiplied by the signal scale
%    to determine the plot spacing.
%
% Class documentation:
% Execute the following in the MATLAB command window to view the class
% documentation for visviews.signalStackedPlot:
%
%    doc visviews.signalStackedPlot
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

% $Log: signalStackedPlot.m,v $
% Revision: 1.00  04-Dec-2011 09:11:20  krobbins $
% Initial version $
%

classdef signalStackedPlot < visviews.axesPanel  & visprops.configurable
    %Panel that plots individual element or window signals
    %
    % Inputs:
    %    parent    handle of parent container for this panel
    %    settings  structure or ModelSettings object containing this
    
    properties
        ClippingOn  = true;          % if true, the
        CombineMethod = 'mean';      % method for combining dimensions for display
        RemoveMean = true;           % remove the mean prior to plotting
        SignalLabel = '{\mu}V';      % label indicating units of the signal
        SignalScale = 1;             % scale factor to calculate plot spacing
        TrimPercent = 0;             % percentage of extreme points to trim
        TrimScope = 'global';        % apply 
    end % public properties
    
    properties (Access = private)
        ClippingTolerance = 0.05;    % clipped this much inside axes
        Colors = [];                 % needed for clickable
        CurrentSlice = [];           % current data slice
        CurrentTrimPercent = 0;      % current trim percent
        CurrentTrimValues = [];      % current lower and upper values
        HitList = {};                % list of hithandles
        LineWidthSelected = 2.0;     % width of selected signal line
        LineWidthUnselected = 0.5;   % width of unselected signal line
        PlotSpacing = [];            % spacing between plot axes
        PlotWindow = true;           % if true, a window is being plotted
        SelectedBlockOffset = 0;     % start of selected block in seconds
        SelectedHandle = [];         % handle of selected signal or empty
        SelectedSignal = [];         % data in selected signal or empty
        SelectedTagNumber = [];      % number of selected signal within signals
        Signals = [];                % data currently plotted in this panel
        StartBlock = 1;              % starting block of currently plotted slice
        StartElement = 1;            % starting element of currently plotted slice
        TotalBlocks = 0;             % total number of blocks in the data
        TotalElements = 0;           % total number of elements in the data
        VisData = [];                % original data for interrogation
        TimeUnits = 's';           % time units of the access
        XValues = [];                % x values of current plot
    end % private properties
    
    methods
        
        function obj = signalStackedPlot(parent, manager, key)
            % Create a stacked signal plot, updating properties from  manager
            obj = obj@visviews.axesPanel(parent);
            obj = obj@visprops.configurable(key);
            % Update properties if any are available
            if isa(manager, 'viscore.dataManager')
                visprops.property.updateProperties(obj, manager);
            end
            set(obj.MainAxes, 'Box', 'on', 'YDir', 'reverse', ...
                'Tag', 'stackedSignalAxes', 'HitTest', 'on');
        end % signalStackedPlot constructor
        
        function [cbHandles, hitHandles] = getHitObjects(obj)
            % Return handles to register as callbacks and hit handles
            % Required for the visviews.clickable interface
            cbHandles = obj.HitList;
            hitHandles = obj.HitList;
        end % getHitObjects
        
        function plot(obj, visData, bFunction, dSlice)
            % Plot specified data slice of visData using bFunction's colors
            obj.reset();
            if isempty(visData) || isempty(bFunction)
                warning('signalStackedPlot:emptyFunctionOrData', ...
                    'Missing summary function or block data for this plot');
                return;
            end
            bFunction.setData(visData);
            obj.VisData = visData; % Keep data for cursor exploration
            
            % Figure out whether the slice is by window or by element
            if isempty(dSlice)
                obj.CurrentSlice = viscore.dataSlice(...
                    'CombineMethod', obj.CombineMethod);
            else
                obj.CurrentSlice = dSlice;
            end
            
            combDim = 0;           % Don't combine
            [slices, names, cDims, combMethod] = obj.CurrentSlice.getParameters(3);
            bValues = bFunction.getBlockSlice(dSlice); % determines line color
            if isempty(bValues)
                warning('signalStackedPlot:emptyBlockValues', ...
                    'Slice has no values');
                return;
            end
            [obj.TotalElements, obj.TotalBlocks] = size(bValues); % Capture size before combining
            if isempty(cDims) || ~isempty(intersect(cDims, 3))  % Plot all elements for a window
                if (obj.TotalBlocks > 1) && obj.VisData.isEpoched()
                    combDim = 2;
                elseif (obj.TotalBlocks > 1)
                    combDim = -2;   % Combine for colors
                end
                obj.PlotWindow = true;
            elseif ~isempty(intersect(cDims, 1))  % Plot all windows for an element
                if obj.TotalElements > 1
                    combDim = 1;
                end
                obj.PlotWindow = false;
            else
                warning('signalStackedPlot:plotSlice', ...
                    'array slice is empty and cannot be plotted');
                return;
            end
            
            % Compute colors and adjust label of multiple blocks
            if  combDim ~= 0    % Combine blocks if necessary
                bValues = viscore.dataSlice.combineDims(...
                    bValues, abs(combDim), combMethod);
            end
            
            % Extract the signal based on the slice
            if obj.PlotWindow && ~obj.VisData.isEpoched()
                cDims = [];
            end
            [obj.Signals, sStart, sSizes] = ...
                viscore.dataSlice.getDataSlice(visData.getData(), ...
                slices, cDims, obj.CombineMethod);
            if isempty(obj.Signals)
                warning('signalStackedPlot:plotSlice', ...
                    'must have at least 2 samples to plot');
                return;
            end
            
            obj.StartElement = sStart(1);
            obj.StartBlock = sStart(3); 
            [nElements, nSamples, nBlocks] = size(obj.Signals);
            obj.Colors = bFunction.getBlockColors(bValues);
            if obj.PlotWindow  % Plot all elements for a window
                % If continguous windows are plotted reshape to align
                if ~obj.VisData.isEpoched() && nBlocks > 1  % windows displayed consecutively
                    obj.Signals = permute(obj.Signals, [2, 3, 1]);
                    obj.Signals = reshape(obj.Signals, [nSamples*nBlocks, nElements]);
                    obj.Signals = squeeze(obj.Signals');
                end
                obj.XLimOffset = (sStart(3) - 1)*nSamples/visData.getSampleRate();
                obj.YStringBase = names{1};
                obj.Colors = reshape(obj.Colors, size(bValues, 1), 3);
            else % Plot all windows for an element
                obj.Signals = permute(obj.Signals, [3, 2, 1]);
                obj.XLimOffset = 0;
                obj.YStringBase = names{3};
                obj.Colors = reshape(obj.Colors, size(bValues, 2), 3);
            end
            
            % Fix up the base string for the x axis to reflect the range
            combBlockString = '';
            combElementString = '';
            if combDim > 0 && obj.PlotWindow  % Adjust the label if necessary
                combBlockString = [obj.CombineMethod ' '];
            elseif combDim > 0
                combElementString = [obj.CombineMethod ' '];
            end     
            obj.XStringBase  = [combBlockString names{3} ' ' ...
                viscore.dataSlice.rangeString(obj.StartBlock, sSizes(3)) ...
                ' ('  combElementString names{1} ' ' ...
                viscore.dataSlice.rangeString(obj.StartElement, obj.TotalElements) ')'];
            
            if obj.VisData.isEpoched() % add time scale to x label
                obj.XValues = 1000*visData.getBlockTimeScale();
                obj.TimeUnits = 'ms';
            else
                obj.XValues = obj.XLimOffset + ...
                    (0:(size(obj.Signals, 2) - 1))/visData.getSampleRate();
                obj.TimeUnits = 's';
            end
            obj.SelectedHandle = [];
            obj.SelectedSignal = [];
            obj.YString = obj.YStringBase;
            obj.XStringBase = ['Time(' obj.TimeUnits ') [' obj.XStringBase ']'];
            obj.XString = obj.XStringBase;
            obj.displayPlot();
        end % plot
        
        function reset(obj)
            obj.reset@visviews.axesPanel();
            obj.HitList = {};
        end % reset
        
        function s = updateString(obj, point)
            % Return [Block, Element, Function] value string for point
            s = '';   % String to be returned
            % try   % Use exception handling for small round-off errors
            [x, y, xInside, yInside] = obj.getDataCoordinates(point); %#ok<ASGLU>
            if ~xInside || ~yInside
                return;
            end
            
            if ~obj.VisData.isEpoched()
                t = x + obj.SelectedBlockOffset;
                sample = floor(obj.VisData.getSampleRate()*(t)) + 1;
                s = {['Time: ' num2str(t) ' ' obj.TimeUnits]; ...
                    ['Sample: ' num2str(sample)]};
                if ~isempty(obj.SelectedHandle)
                    rs = floor(obj.VisData.getSampleRate()*(x - obj.XLimOffset)) + 1;
                    s{3} = ['Raw: '  num2str(obj.SelectedSignal(rs)) ...
                        ' ' obj.SignalLabel];
                end
            else
                a = (x - obj.VisData.getBlockTimeScale(1))./1000;
                a = floor(obj.VisData.getSampleRate()*a) + 1;
                s = {['Ep-time: ' num2str(x) ' ' obj.TimeUnits]; ...
                    ['Ep-sample: ' num2str(a)]};
                if ~isempty(obj.SelectedHandle)
                    z = {['Value: '  num2str(obj.SelectedSignal(a)) ...
                        ' ' obj.SignalLabel]};
                    s = [s; z];
                end;
            end
            % catch  ME  %#ok<NASGU>   ignore errors on cursor sweep
            % end
        end % updateString
        
        function buttonDownPreCallback(obj, src, eventdata, master)  %#ok<INUSD>
            % Callback when user clicks on the plot to select a signal
            if ~isempty(obj.SelectedHandle) && ishandle(obj.SelectedHandle)
                set(obj.SelectedHandle, 'LineWidth', obj.LineWidthUnselected);
            end
            obj.SelectedHandle = [];
            obj.SelectedSignal = [];
            obj.SelectedBlockOffset = 0;
            obj.YString = obj.YStringBase;
            srcTag = get(src, 'Tag');
            if ~isempty(srcTag) && strcmpi(get(src, 'Type'), 'line')
                set(src, 'LineWidth', obj.LineWidthSelected);
                obj.SelectedHandle = src;
                obj.SelectedSignal = obj.Signals(str2double(srcTag), :);
                if obj.PlotWindow
                    selected = str2double(srcTag) + obj.StartElement - 1;
                else
                    selected = str2double(srcTag) + obj.StartBlock - 1;
                end
                obj.YString = [obj.YStringBase ' [' num2str(selected) ']'];
                obj.SelectedTagNumber = str2double(srcTag);
                if ~obj.PlotWindow && ~obj.VisData.isEpoched()
                    obj.SelectedBlockOffset = obj.VisData.getBlockSize() * ...
                        (selected - 1) /obj.VisData.getSampleRate();
                end
            end
            obj.redraw();
        end % buttonDownPreCallback
        
    end % public methods
    
    methods (Access = private)
        
        function displayPlot(obj)
            % Plot the signals stacked one on top of another
            data = obj.Signals;
            numPlots = size(data, 1);
            if numPlots == 0 
                warning('signalStackedPlot:NaNValues', ...
                    'No data to plot');
                return;
            end
            % Take care of trimming based on scope
            if strcmpi(obj.TrimScope, 'global')
                [tMean, tStd, tLow, tHigh] = ...
                    obj.VisData.getTrimValues(obj.TrimPercent);
            else
                      [tMean, tStd, tLow, tHigh] = ...
                    obj.VisData.getTrimValues(obj.TrimPercent, data);
            end
            
            scale = obj.SignalScale;
            if isempty(scale)
                scale = 1;
            end
            plotSpacing = double(scale)*tStd;
            if isnan(plotSpacing)
                 warning('signalStackedPlot:NaNValues', ...
                    'No data to plot');
                return;
            end
            if plotSpacing == 0;
                plotSpacing = 0.1;
            end 
            data(data < tLow) = tLow;
            data(data > tHigh) = tHigh;
            
            % Remove the mean if necessary
            if obj.RemoveMean
                data = data - tMean;
            end

            %y-axis reversed, so must plot the negative of the signals
            eps = plotSpacing*obj.ClippingTolerance;
            obj.HitList = cell(1, numPlots + 1);
            obj.HitList{1} = obj.MainAxes;
            for k = 1:numPlots
                signals =  - data(k, :) + k*plotSpacing;
                if obj.ClippingOn
                    signals = min((numPlots + 1)*plotSpacing - eps, max(eps, signals));
                end
                hp = plot(obj.MainAxes, obj.XValues, signals, ...
                    'Color', obj.Colors(k, :), ...
                    'Clipping','on', 'LineWidth', obj.LineWidthUnselected);
                set(hp, 'Tag', num2str(k));
                obj.HitList{k + 1} = hp;
            end
            yTickLabels = cell(1, numPlots);
            yTickLabels{1} = '1';
            yTickLabels{numPlots} = num2str(numPlots);
            obj.XString = sprintf('%s (Scale: %g %s)', ...
                obj.XString, plotSpacing, obj.SignalLabel);
            set(obj.MainAxes,  'YLimMode', 'manual', ...
                'YLim', [0, plotSpacing*(numPlots + 1)], ...
                'YTickMode', 'manual', 'YTickLabelMode', 'manual', ...
                'YTick', plotSpacing:plotSpacing:numPlots*plotSpacing, ...
                'YTickLabel', yTickLabels, ...
                'XTickMode', 'auto', ...
                'XLim', [obj.XValues(1), obj.XValues(end)], 'XLimMode', 'manual', ...
                'XTickMode', 'auto');
            obj.redraw();
        end % displayPlot
        
    end % private methods
    
    methods(Static=true)
        
        function settings = getDefaultProperties()
            % Structure specifying how to set configurable public properties
            cName = 'visviews.signalStackedPlot';
            settings = struct( ...
                'Enabled',       { ... % display in property manager?...
                true,             ... %1 clip signal plots       
                true,             ... %2 method for combining clumps    
                true,             ... %3 remove mean before plotting
                true,             ... %4 label designating signal units
                true,             ... %5 spacing between stacked lines
                true,             ... %6 trim percentage for scale
                true              ... %7 trim scope (global or local)
                }, ...
                'Category',      {  ... % category for property
                cName,              ... %1 clip signal plots
                cName,              ... %2 method for combining clumps  
                cName,              ... %3 remove mean before plotting
                cName,              ... %4 label designating signal units
                cName,              ... %5 spacing between stacked lines
                cName,              ... %6 trim percentage for scale
                cName               ... %7 trim scope (global or local)
                }, ...
                'DisplayName',   { ... % display name in property manager
                'Clipping on',     ... %1 clip signal plots
                'Combine method',  ... %2 method for combining clumps  
                'Remove mean',     ... %3 remove mean before plotting
                'Signal label',    ... %4 label designating signal units
                'Signal scale',    ... %5 spacing between stacked lines
                'Trim percent',    ... %6 trim percentage for scale
                'Trim scope'       ... %7 trim scope (global or local)
                }, ...
                'FieldName',     { ... % name of public property
                'ClippingOn',      ... %1 clip signal plots 
                'CombineMethod',   ... %2 method for combining clumps  
                'RemoveMean',     ... %3 remove mean before plotting
                'SignalLabel',     ... %4 label designating signal units
                'SignalScale'      ... %5 spacing between stacked lines
                'TrimPercent',     ... %6 trim percentage for scale
                'TrimScope'        ... %7 trim scope (global or local)
                }, ... 
                'Value',         { ... % default or initial value
                true,              ... %1 clip signal plots
                'mean',            ... %2 method for combining clumps   
                true,              ... %3 remove mean before plotting
                '{\mu}V',          ... %4 label designating signal units
                3.0,               ... %5 spacing between stacked lines
                0,                 ... %6 trim percentage for scale
                'global'           ... %7 trim scope (global or local)
                }, ...
                'Type',          { ... % type of property for validation
                'visprops.logicalProperty', ... %1 clip signal plots
                'visprops.enumeratedProperty', ... %2 method for combining clumps  
                'visprops.logicalProperty', ... %3 remove mean before plotting
                'visprops.stringProperty',  ... %4 label designating signal units
                'visprops.doubleProperty',  ... %5 spacing between stacked lines
                'visprops.doubleProperty', ... %6 trim percentage for scale
                'visprops.enumeratedProperty' ... %7 trim scope (global or local)
                }, ...
                'Editable',      { ... % grayed out if false
                true,             ... %1 clip signal plots 
                true,             ... %2 method for combining clumps    
                true,             ... %3 remove mean before plotting
                true,             ... %4 label designating signal units
                true,             ... %5 spacing between stacked lines
                true,             ... %6 trim percentage for scale
                true              ... %7 trim scope (global or local)
                }, ...
                'Options',       { ... % restrictions on input values
                '',                ... %1 clip signal plots
                {'mean', 'median', 'max', 'min'}, ... %2 method for combining clumps  
                '',                ... %3 remove mean before plotting
                '',                ... %4 label designating signal units
                [0, inf],          ... %5 spacing between stacked lines
                [0, 100]           ... %6 trim percentage for scale
                {'global', 'local'}, ... %7 trim scope (global or local)
                }, ...
                'Description',   {  ... % description for property manager
                ['If true, individual signals are clipped ' ...
                'to fall within the plot window'], ... %1
                ['Specifies how to combine multiple windows ' ...
                'into a single window for plotting'], ... %2
                'If true, remove mean before plotting', ... %3
                'Label indicating signal units', ... %4
                ['Scale factor for plotting individual signal plots ' ...
                '(must be positive)'], ... %5
                ['Percentage of extreme points (half on each end ' ...
                'before calculating limits'], ... %6
                ['Scope for calculating trim percentages -- ' ...
                'global designates entire data set, ' ...
                'local designates this block only'] ...%7
                } ...
                );
        end % getDefaultProperties
        
        
    end % static methods
    
end % signalStackedPlot
