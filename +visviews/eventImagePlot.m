% visviews.eventImagePlot display element vs block values as an image
%
% Usage:
%   >>   visviews.eventImagePlot(parent, manager, key)
%   >>   obj = visviews.eventImagePlot(parent, manager, key)
%
% Description:
% visviews.eventImagePlot(parent, manager, key) displays the 
%    values of a summarizing function as an image (elements � clump), 
%    with pixel color representing the value of the function. 
%    The y-axis corresponds to elements (e.g., channels) and 
%    the x-axis corresponds to time (e.g., window or clump number).
%
%    The parent is a graphics handle to the container for this plot. The
%    manager is an viscore.dataManager object containing managed objects
%    for the configurable properties of this object, and key is a string
%    identifying this object in the property manager GUI.
% 
% 
% obj = visviews.eventImagePlot(parent, manager, key) returns a handle to
%    the newly created object.
%
% visviews.eventImagePlot is configurable, resizable, clickable, and cursor explorable.
%
% Configurable properties:
% The visviews.eventImagePlot has four configurable parameters: 
%
% ClumpFactor specifies the number of consecutive windows or epochs 
%    represented by each pixel column. When the ClumpFactor is one (the default), 
%    each pixel column represents its own window. If ClumpFactor is greater than 
%    one, each pixel column represents several consecutive blocks. 
%    Users can trade-off clump size versus block size to see different 
%    representations of the data.
%
% CombineMethod specifies how to combine multiple blocks into a 
%    single block to determine an overall block value. The value can be be
%   'max'  (default), 'min', 'mean', or  'median'. Detail plots use this 
%    block value to determine slice colors. 
%
%    For example, with 32 channels, a clump size of 3, a block size of 
%    1000 samples, the eventImagePlot delivers a slice representing 
%    32�1000�3 worth of data. A detail plot such as signalStackedPlot 
%    combines this data based on its own CombineMethod property, 
%    say by taking the mean to plot 32�1000 data points on 32 line graphs. 
%    However, we would like to use line colors for the signals based 
%    on the block function values in the image plot. The detail plots use 
%    image plot's CombineMethod to combine the blocks to get appropriate 
%    colors for the slice. 
%
%    Usually signal plots combine signals using mean or median, while 
%    summary plots such as blockBoxPlot use the max, although users may 
%    choose other combinations.
%
% IsClickable is a boolean specifying whether this plot should respond to
%    user mouse clicks when incorporated into a linkable figure. The
%    default value is true.
%
% LinkDetails is a boolean specifying whether clicking this plot in a
%    linkable figure should cause detail views to display the clicked
%    slice. The default value is true.
%
% Example: 
% Create a block image plot of kurtosis of 32 exponentially distributed channels
%
%    % Create a block box plot
%    sfig = figure('Name', 'Kurtosis for 32 exponentially distributed channels');
%    bp = visviews.eventImagePlot(sfig, [], []);
%
%    % Generate some data to plot
%    data = random('exp', 1, [32, 1000, 20]);
%    testVD = viscore.blockedData(data, 'Exponenitally distributed');
%    
%    % Create a kurtosis block function object
%    defaults = visfuncs.functionObj.createObjects('visfuncs.functionObj', ...
%               visfuncs.functionObj.getDefaultFunctions());
%    thisFunc = defaults{1};
%    thisFunc.setData(testVD);
%    
%    % Plot the block function
%    bp.plot(testVD, thisFunc, []);
%   
%    % Adjust the margins
%    gaps = bp.getGaps();
%    bp.reposition(gaps);
%
% Notes:
%  - If the manager parameter is empty, the class defaults are used to
%    initialize.
%  - If the key parameter is empty, the class name is used to identify in
%    GUI configuration.
%  - Choose a neutral background color to emphasize important blocks.
%
% Class documentation:
% Execute the following in the MATLAB command window to view the class 
% documentation for visviews.eventImagePlot:
%
%    doc visviews.eventImagePlot
%
% See also: visviews.axesPanel, visviews.blockBoxPlot, visviews.clickable,
%           visprops.configurable, visviews.cursorExplorable,
%           visviews.elementBoxPlot, and visviews.resizable

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

% $Log: eventImagePlot.m,v $
% Revision: 1.00  04-Dec-2011 09:11:20  krobbins $
% Initial version $
%

classdef eventImagePlot < visviews.axesPanel & visprops.configurable
    
    properties
        % configurable properties
        ClumpFactor = 1.0;       % number of blocks in each box plot (clump)
        CombineMethod = 'max';   % method for combining blocks when grouped
    end % public properties
    
    properties (Access = private)
        CurrentFunction = [];    % block function that is currently displayed
        CurrentSlice = [];       % current slice
        NumberBlocks = 0;        % number of blocks
        NumberClumps = 0;        % current number of clumps (boxplots)
        NumberElements = 0;      % number of elements in slice (for downstream)
        NumberEvents = 0;        % number of events being plotted
        StartBlock = 1;          % starting block of currently plotted slice
        StartElement = 1;        % starting element of currently plotted slice  
    end % private properties
    
    methods
        
        function obj = eventImagePlot(parent, manager, key)
            % Constructor must have parent for axesPanel
            obj = obj@visviews.axesPanel(parent);
            obj = obj@visprops.configurable(key);
            % Update properties if any are available
            if isa(manager, 'viscore.dataManager')
                visprops.property.updateProperties(obj, manager);
            end
            set(obj.MainAxes, 'Box', 'on',  'Tag', 'blockImageAxes', ...
                'ActivePositionProperty', 'position', ...
                'YDir', 'reverse');
        end % eventImagePlot constructor
        
        function [dSlice, bFunction] = getClicked(obj)
            % Clicking on the boxplot always causes plot of group of blocks
            bFunction = obj.CurrentFunction;
            point = get(obj.MainAxes, 'CurrentPoint');
            dSlice = obj.getClumpSlice(point(1, 1));        
        end % getClicked
        
        function dSlice = getClumpSlice(obj, clump)
            dSlice = [];
            if clump <= 0 || clump >= obj.NumberClumps + 1 || ...
                    obj.NumberClumps ~= ...      % needs to be recalculated
                    ceil(double(obj.NumberBlocks)/double(obj.ClumpFactor));
                return;
            end
            clump = min(obj.NumberClumps, max(1, round(clump))); % include edges
            if obj.ClumpFactor == 1
                s = num2str(clump + obj.StartBlock - 1);
            else
                startBlock = (clump - 1)* obj.ClumpFactor + obj.StartBlock; % adjust to win num
                endBlock = min(obj.StartBlock + obj.NumberBlocks - 1, ...
                               startBlock + obj.ClumpFactor - 1);
                s = [num2str(startBlock) ':' num2str(endBlock)];
            end
            [slices, names] = obj.CurrentSlice.getParameters(3); %#ok<ASGLU>
            elementSlice = viscore.dataSlice.rangeString( ...
                                obj.StartElement, obj.NumberElements);
            dSlice = viscore.dataSlice('Slices', {elementSlice, ':', s}, ...
                'CombineMethod', obj.CombineMethod, 'CombineDim', 3, ...
                'DimNames', names);
        end % getClumpSlice
        
        function plot(obj, visData, bFunction, dSlice)
            % Plot the blocked data using an image
            obj.reset();
            
            % Get needed information from the data and function objects
            bFunction.setData(visData);    % Make sure data is correct
            obj.CurrentFunction = bFunction; % Remember for data explorer
            if isempty(dSlice)
                obj.CurrentSlice = viscore.dataSlice();
            else
                obj.CurrentSlice = dSlice;
            end
            
            [slices, names] = obj.CurrentSlice.getParameters(3);  %#ok<ASGLU>
            [data, s] = bFunction.getBlockSlice(obj.CurrentSlice);
            if isempty(data)
                warning('eventImagePlot:emptyData', 'No data for this plot');
                return;
            end
            obj.StartBlock = s(2);
            obj.StartElement = s(1);
            [obj.NumberElements, obj.NumberBlocks] = size(data);
            
            % Calculate the number of clumps and adjust for uneven clumps
            obj.NumberClumps = ceil(double(obj.NumberBlocks)/double(obj.ClumpFactor));
%             if obj.ClumpFactor > 1
%                 leftOvers = obj.NumberClumps*obj.ClumpFactor - obj.NumberBlocks;
%                 if leftOvers > 0
%                     data = [data, nan(obj.NumberElements, leftOvers)];
%                 end
%                 data = reshape(data', obj.ClumpFactor, obj.NumberClumps*obj.NumberElements);
%                 data = viscore.dataSlice.combineDims(data, 1, obj.CombineMethod);
%             else
%                 data = data';
%             end
            
            
            colors = permute(bFunction.getBlockColors(...
                reshape(data, obj.NumberClumps, obj.NumberElements)), [2, 1, 3]);
            iMap = image(colors, 'Parent', obj.MainAxes, 'Tag', 'ImageMap');
            set(iMap, 'HitTest', 'off') %Get position from axes not image
            
            % Fix up the labels, limits and tick marks as needed
            yLimits = [0.5, double(obj.NumberElements) + 0.5];
            yTickLabels = cell(1, obj.NumberElements);
            yTickLabels{1} = num2str(obj.StartElement);
            yTickLabels{obj.NumberElements} = ...
                num2str(obj.StartElement + obj.NumberElements - 1);
            
            xLimits = [0.5, double(obj.NumberClumps) + 0.5];
            [xTickMarks, xTickLabels, obj.XStringBase] = ...
                obj.getClumpTicks(names{3});
            
            obj.YStringBase = names{1};
            obj.YString =  obj.YStringBase;
            obj.XString = obj.XStringBase;
            if ~isempty(names{3})
                wString = names{3}(1);
            else
                wString = 'w';
            end
            if ~isempty(names{1})
                eString = names{1}(1);
            else
                eString = 'e';
            end
            obj.CursorString = {[wString ': ']; ...
                [eString ': ']; ...
                [bFunction.getValue(1, 'ShortName') ': ']; };
            set(obj.MainAxes, ...
                'XLimMode', 'manual', 'XLim', xLimits, ...
                'XTickMode','manual', 'XTick', xTickMarks, ...
                'XTickLabelMode', 'manual', 'XTickLabel', xTickLabels, ...
                'YLimMode', 'manual', 'YLim', yLimits, ...
                'YTickMode','manual', 'YTick', 1:obj.NumberElements, ...
                'YTickLabelMode', 'manual', 'YTickLabel', yTickLabels);
        end % plot
        
        function s = updateString(obj, point)
            % Return [Block, Element, Function] value string for point
            s = '';   % String to be returned
            [x, y, xInside, yInside] = getDataCoordinates(obj, point);
            if ~xInside || ~yInside
                return;
            end
            
            cNum = round(x);
            if cNum < 1 || cNum > obj.NumberClumps
                return;
            end
            w = min(ceil((x - 0.5)*double(obj.ClumpFactor)), obj.NumberBlocks) ...
                  + obj.StartBlock - 1; 
            y = ceil(y - 0.5);
            
            s = {[obj.CursorString{1} num2str(w)]; ...
                [obj.CursorString{2} num2str(y)]; ...
                [obj.CursorString{3} ...
                num2str(obj.CurrentFunction.getBlockValue(y, w))]};
        end % updateString
        
    end % public methods
    
    methods (Access = 'private')


        function [xTickMarks, xTickLabels, xStringBase] = getClumpTicks(obj, clumpName)
            % Calculate the x tick marks and labels based on clumps
            if obj.NumberClumps <= 1 && obj.ClumpFactor == 1
                xTickMarks = 1;
                xTickLabels = {num2str(obj.StartBlock)};
            elseif obj.NumberClumps <= 1
                xTickMarks = 1;
                xTickLabels = {'1'};
            elseif obj.ClumpFactor == 1;
                xTickMarks = [1, obj.NumberClumps];
                xTickLabels = {num2str(obj.StartBlock), ...
                    num2str(obj.StartBlock + obj.NumberClumps - 1)};
            else
                xTickMarks = [1, obj.NumberClumps];
                xTickLabels = {'1', num2str(obj.NumberClumps)};
            end
            if obj.ClumpFactor > 1
                if ~isempty(clumpName)
                    cName = [clumpName 's '];
                else
                    cName = '';
                end
                xStringBase = [cName ...
                    num2str(obj.StartBlock) ':' ...
                    num2str(obj.StartBlock + obj.NumberBlocks -1) ...
                    ' clumps of ' num2str(obj.ClumpFactor)];
                
            else
                xStringBase = clumpName;
            end
        end % getClumpTicks

    end % private methods
    
    methods (Static = true)
        
        function settings = getDefaultProperties()
            % Structure specifying how to set configurable public properties
            cName = 'visviews.eventImagePlot';
            settings = struct( ...
                'Enabled',       {true, true}, ...
                'Category',      {cName, cName}, ...
                'DisplayName',   { ...
                'Blocks per clump', ...
                'Combine method'}, ...
                'FieldName',     {'ClumpFactor',          'CombineMethod'}, ...
                'Value',         {1,                      'max'}, ...
                'Type',          { ...
                'visprops.unsignedIntegerProperty', ...
                'visprops.enumeratedProperty'}, ...
                'Editable',      {true,                    true}, ...
                'Options',       {[1, inf],  {'max', 'min', 'mean', 'median'}}, ...
                'Description',   {...
                'Number of blocks grouped into a clump represented by one image pixel column', ...
                'Method for combining blocks in a clump'} ...
                );
        end % getDefaultProperties
        
    end % static methods
    
end % eventImagePlot
