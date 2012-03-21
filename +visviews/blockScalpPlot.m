% visviews.blockScalpPlot display a scalp map of blocked function values by window
%
% Usage:
%   >>   visviews.blockScalpPlot(parent, manager, key)
%   >>   obj = visviews.blockScalpPlot(parent, manager, key)
%
% Description:
% obj = visviews.blockScalpPlot(parent, manager, key) displays a scalp map
%    of combined block function values for a specified slice of time.
%    The display includes a contour map of the combined values over the
%    time and either points, labels, or numbers identifying the positions
%    of the elements. The block scalp plot assumes that the elements
%    correspond to eeg channels positioned on a scalp. If no channel
%    locations are provided, the scalp map arrays the elements in a circle
%    and does not draw a contour map.
%
%    The parent is a graphics handle to the container for this plot. The
%    manager is an viscore.dataManager object containing managed objects
%    for the configurable properties of this object, and key is a string
%    identifying this object in the property manager GUI.
%
% obj = visviews.blockScalpPlot(parent, manager, key) returns a handle to
%    the newly created object.
%
% visviews.blockScalpPlot is configurable, resizable, clickable, and cursor explorable.
%
% Configurable properties:
% The visviews.blockScalpPlot has five configurable properties:
%
% BoxColors provides a list of colors used to alternate through in
%     displaying the boxes. For data with lots of clumps, the
%     boxes appear highly compressed due to limited viewing space and
%     alternating colors help users distinguish the individual boxes. The
%     default is |[0.7, 0.7, 0.7; 1, 0, 1]|.
%
% ClumpFactor specifies the number of consecutive windows or epochs
%    represented by each box. When the |ClumpFactor| is one (the default),
%    each box represents a signle window or element. If |ClumpFactor| is greater than
%    one, each box represents several consecutive blocks.
%    Users can trade-off clump size versus block size to see different
%    representations of the data.
%
% CombineMethod specifies how to combine multiple blocks into a
%    single block to determine an overall block value. The value can be
%   'max'  (default), 'min', 'mean', or  'median'. Detail plots use the
%    combined block value to determine slice colors.
%
%    Suppose the plot has 128 channels, a clump size of 3, and a block size of
%    1000 samples, and 100 windows. A user click delivers a slice representing
%    3�1000 worth of data. A detail plot such as stackedSignalPlot
%    combines this data based on its own CombineMethod property,
%    say by taking the mean to plot 32�1000 data points on 32 line graphs.
%    However, we would like to use line colors for the signals based
%    on the block function values in the box plot. The detail plots use
%    box plot's CombineMethod to combine the blocks to get appropriate
%    colors for the slice.
%
%    Usually signal plots combine signals using mean or median, while
%    summary plots such as blockScalpPlot use the max, although users may
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
%
% Example:
% % Create a boxplot of kurtosis of 32 exponentially distributed channels
%
%    % Create a block box plot
%    sfig = figure('Name', 'Kurtosis for 32 exponentially distributed channels');
%    bp = visviews.blockScalpPlot(sfig, [], []);
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
%
% Notes:
%   - If manager is empty, the class defaults are used to initialize.
%   - If key is empty, the class name is used to identify in GUI configuration.
%
% Class documentation:
% Execute the following in the MATLAB command window to view the class
% documentation for visviews.blockScalpPlot:
%
%    doc visviews.blockScalpPlot
%
%
% See also: visviews.axesPanel, visviews.blockImagePlot, visviews.clickable,
%           visprops.configurable, visviews.cursorExplorable,
%           visviews.elementBoxPlot, and visviews.resizable
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

% $Log: blockScalpPlot.m,v $
% Revision: 1.00  04-Dec-2011 09:11:20  krobbins $
% Initial version $
%

classdef blockScalpPlot < visviews.axesPanel  & visprops.configurable
    
    properties
        % configurable properties
        CombineMethod = 'max';         % method of combining blocks
        ElectrodeColor = [0, 0, 0];    % electrode color
        HeadColor = [0.75, 0.75, 0.75];   % color for plotting the head
        InterpolationType = 'square';  % method
    end % public properties
    
    properties (Access = private)
        CurrentElement = [];     % last valid clicked element
        CurrentFunction = [];    % handle to block function for this
        CurrentSlice = [];       % current data slice
        InterpolationRadius = 0.5; % radius for extent of interpolation
        NumberBlocks = 0;        % number of blocks being plotted
        NumberElements = 0;      % number of blocks being plotted
        PlotRadius = 0.5  ;      % radius for plotting electrodes
        SliceElectrodes = {};    % electrodes that should produce a slice
        StartBlock = 1;          % starting block of currently plotted slice
        StartElement = 1;        % starting element of currently plotted slice
        SqueezeFactor = 1;       % radial squeeze factor for rescaling
        TextLabel = [];          % handle to label at bottom of head
        ValidElements = [];      % list of the valid elements
    end % private properties
    
    properties (Constant)
        HeadRadius = 0.5;              % head radius (do not change)
    end % constant properties
    
    methods
        
        function obj = blockScalpPlot(parent, manager, key)
            % Parent is non-empty handle to container for axes panel but manager can be empty
            obj = obj@visviews.axesPanel(parent);
            obj = obj@visprops.configurable(key);
            % Update properties if any are available
            if isa(manager, 'viscore.dataManager')
                visprops.property.updateProperties(obj, manager);
            end
            set(obj.MainAxes, 'Tag', 'blockScalpAxes');
        end % blockScalpPlot constructor
        
        function buttonDownPreCallback (obj, src, eventdata)  %#ok<INUSD>
            % Set the current element based on the tag
            obj.CurrentElement = str2double(get(src, 'Tag'));
            if isempty(intersect(obj.CurrentElement, obj.ValidElements))
                obj.CurrentElement = [];
            end
        end % buttonDownPreCallback
        
        function [dSlice, bFunction] = getClicked(obj)
            % Clicking on the electrodes always causes plot of an element
            bFunction = obj.CurrentFunction;
            if isempty(obj.CurrentElement)
                dSlice = [];
            else
                blockSlice = viscore.dataSlice.rangeString( ...
                    obj.StartBlock, obj.NumberBlocks);
                [slices, names] = obj.CurrentSlice.getParameters(3); %#ok<ASGLU>
                dSlice = viscore.dataSlice('Slices', ...
                    {num2str(obj.CurrentElement), ':', blockSlice}, ...
                    'DimNames', names);
            end
        end % getClicked
        
        function [cbHandles, hitHandles] = getHitObjects(obj)
            % Return handles that should register callbacks as well has hit handles
            cbHandles = [{obj.MainAxes}, obj.SliceElectrodes];
            hitHandles = [{obj.MainAxes}, obj.SliceElectrodes];
        end % getHitObjects
        
        function plot(obj, visData, bFunction, dSlice)
            % Plots the scalp map with color bar and electrodes
            obj.reset();
            
            % Get needed information from the data and function objects
            bFunction.setData(visData);
            obj.CurrentFunction = bFunction;
            
            if isempty(dSlice)
                obj.CurrentSlice = viscore.dataSlice();
            else
                obj.CurrentSlice = dSlice;
            end
            
            [slices, names] = obj.CurrentSlice.getParameters(3);
            
            % Get values for unsliced elements first (for interpolation)
            [bValues, sStarts, sSizes] =  viscore.dataSlice.getDataSlice(...
                obj.CurrentFunction.getBlockValues(), {':', slices{3}}, ...
                2, obj.CombineMethod);
            obj.StartBlock = sStarts(2);
            obj.NumberBlocks = sSizes(2);
            
            % Now get values sliced for elements
            [sValues, sStarts, sSizes] =  viscore.dataSlice.getDataSlice(...
                bValues, slices(1), [], []);
            obj.StartElement = sStarts(1);
            obj.NumberElements = sSizes(1);
            
            [x, y, labels, values] = ...
                obj.findLocations(visData.getElementLocations(), bValues);
            
            x = x*obj.SqueezeFactor;
            y = y*obj.SqueezeFactor;
            myFigure = ancestor(obj.MainAxes, 'figure');
            set(0, 'CurrentFigure', myFigure);
            set(gcf, 'CurrentAxes', obj.MainAxes);
            
            % Create the label at the bottom
            if obj.NumberBlocks ~= size(sValues, 2)
                combineString = [obj.CombineMethod ' '];
            else
                combineString = '';
            end
            obj.XStringBase = [obj.CurrentFunction.getValue(1, 'DisplayName'), ...
                ' (' combineString names{3} ' ' num2str(obj.StartBlock) ':' ...
                num2str(obj.StartBlock + obj.NumberBlocks - 1) ')'];
            obj.XString = obj.XStringBase;
            hold on
            obj.setBackgroundColor([1, 1, 1]);
            obj.plotMap(x, y, values)
            obj.plotHead();
            obj.plotElectrodes(x, y, labels);  
            hold off
            obj.redraw();
        end % plot
        
    end % public methods
    
    methods (Access = private)
        
        function [x, y, labels, values] = ...
                findLocations(obj, elementLocs, bValues)
            % Find channels with valid locations and set locations
            x = []; y = []; labels = {}; values = [];
            if isempty(elementLocs)   % element locations not defined
                return;
            end
            obj.ValidElements = find(~cellfun('isempty', {elementLocs.theta}));
            validElements = intersect(find(~cellfun('isempty', {elementLocs.X})), ...
                obj.ValidElements);
            badElements = union(find(isnan(bValues)), find(isinf(bValues))); % NaN and Inf values
            if ~isempty(badElements)
                obj.ValidElements = setdiff(obj.ValidElements, ...
                    badElements + obj.StartElement - 1);
            end
            if isempty(obj.ValidElements)
                
                return;
            end
            validElements = sort(validElements);
            theta = {elementLocs.theta};
            theta = pi/180*cell2mat(theta(validElements));
            radius = {elementLocs.radius};
            radius = cell2mat(radius(validElements));
            
            % Transform electrode locations from polar to cartesian coordinates
            [x, y] = pol2cart(theta, radius);
            labels = {elementLocs.labels};
            labels = char(labels(validElements));
            values = bValues(validElements);
            obj.InterpolationRadius = min(1.0, max(radius)*1.02); % just outside outermost electrode location
            obj.PlotRadius = max(obj.InterpolationRadius, 0.5);   % plot to 0.5 head boundary
            obj.SqueezeFactor = obj.HeadRadius/obj.PlotRadius;
            obj.ValidElements = validElements;
        end % findLocations
        
        function markerSize = getMarkerSize(obj, ylen)   %#ok<MANU>
            % Determine the marker size based on the number of electrodes
            mSizes = [10, 3, 4, 5, 6, 8];
            mCutoffs = [100, 80, 64, 48, 32];
            markerSize = mSizes(1);
            for k = 1:length(mCutoffs)
                if ylen > mCutoffs(k)
                    markerSize = mSizes(k + 1);
                    break;
                end
            end
        end % getMarkerSize
        
        function labelCallback (obj, src, eventdata, textobj, labels) %#ok<INUSL,MANU>
            % Callback for switching string of textobj among labels on click
            labelNum = get(src, 'userdata');
            labelNum = mod(labelNum, length(labels)) + 1;
            set(textobj, 'String', labels{labelNum});
            set(src, 'userdata', labelNum);
        end % labelCallback
        
        function plotElectrodes(obj, x, y, labels)
            % Plot electrode points and positions, setting callbacks
            if isempty(x)  % don't plot anything if no electrodes
                return;
            end
            mSize = obj.getMarkerSize(length(x));
            elements = intersect(obj.ValidElements, ...
                obj.StartElement:(obj.StartElement + obj.NumberElements - 1));
            elementMask = false(length(x), 1);
            elementMask(elements) = true;
            obj.SliceElectrodes = cell(1, length(elements));
            sPos = 1;   % indexing variable
            for k = 1:length(x)
                if elementMask(k)    % Element in the slice
                    obj.SliceElectrodes{sPos} = ...
                        plot3(y(k), x(k), 2.1, '.', 'Color', obj.ElectrodeColor, ...
                        'markersize', mSize, 'Tag', num2str(k));
                    % Element labels switch
                    h = text(double(y(k)+0.01),double(x(k)),...
                        2.1, num2str(k),'HorizontalAlignment','left',...
                        'VerticalAlignment','middle','Color', [0, 0, 0], ...
                        'userdata', 1 , ...
                        'FontSize', get(0,'DefaultAxesFontSize'));
                    set(h, 'ButtonDownFcn', {@obj.labelCallback, h, ...
                        {labels(k,:), num2str(obj.ValidElements(k))}});
                    sPos = sPos + 1;
                else
                    h = text(double(y(k)+0.01),double(x(k)),...
                        2.1, '','HorizontalAlignment','left',...
                        'VerticalAlignment','middle','Color', obj.HeadColor, ...
                        'FontSize', get(0,'DefaultAxesFontSize'));
                    plot3(y(k), x(k), 2.1, '.', 'Color', obj.HeadColor, ...
                        'markersize', mSize, 'userdata', 1, 'Tag', num2str(k), ...
                        'ButtonDownFcn', {@obj.labelCallback, h, ...
                        {'', labels(k,:), num2str(obj.ValidElements(k))}});
                end
            end
            
        end % plotElectrodes
        
        function plotHead(obj)
            % Plot head outline and label the graph
            
            % Plot filled ring to mask jagged grid boundary
            hwidth = 0.007;                         % cartoon head ring width
            hin  = obj.SqueezeFactor*obj.HeadRadius*(1 - hwidth/2); % inner head ring radius
            rwidth = 0.035;                         % blanking ring width
            rin = max(hin, obj.HeadRadius*(1 - rwidth/2));   % inner ring radius
            
            % Mask the outer circle
            circ = linspace(0, 2*pi, 201);         % create a circular grid
            rx = sin(circ);
            ry = cos(circ);
            ringx = [[rx(:)' rx(1) ]*(rin + rwidth)  [rx(:)' rx(1)]*rin];
            ringy = [[ry(:)' ry(1) ]*(rin + rwidth)  [ry(:)' ry(1)]*rin];
            patch(ringx, ringy, 0.01*ones(size(ringx)), ...
                obj.getBackgroundColor(), 'edgecolor', 'none'); hold on
            
            % Plot head outline
            headx = [[rx(:)' rx(1) ]*(hin + hwidth)  [rx(:)' rx(1)]*hin];
            heady = [[ry(:)' ry(1) ]*(hin + hwidth)  [ry(:)' ry(1)]*hin];
            patch(headx, heady, ones(size(headx)), ...
                obj.HeadColor, 'edgecolor', obj.HeadColor); hold on
            
            % Plot ears and nose
            base  = obj.HeadRadius - 0.0046;
            basex = 0.18*obj.HeadRadius;              % nose width
            tip   = 1.15*obj.HeadRadius;
            tiphw = 0.04*obj.HeadRadius;              % nose tip half width
            tipr  = 0.01*obj.HeadRadius;              % nose tip rounding
            earX = [0.492, 0.510, 0.518, 0.5299, 0.5419, 0.54, 0.547, ...
                0.532, 0.510, 0.484];                % head radius = 0.5
            earY = [0.0955, 0.1175, 0.1183, 0.1146, 0.0955, -0.0055, ...
                -0.0932, -0.1313, -0.1384, -0.1199];
            
            plot3([basex; tiphw; 0; -tiphw; -basex]*obj.SqueezeFactor, ... % nose
                [base; tip - tipr; tip; tip - tipr; base]*obj.SqueezeFactor,...
                2*ones(size([basex; tiphw; 0; -tiphw; -basex])),...
                'Color', obj.HeadColor, 'LineWidth', 1.7);
            plot3(earX*obj.SqueezeFactor, earY*obj.SqueezeFactor, ... % left ear
                2*ones(size(earX)), 'Color', obj.HeadColor, 'LineWidth', 1.7)
            plot3(-earX*obj.SqueezeFactor, earY*obj.SqueezeFactor,  ... % right ear
                2*ones(size(earY)), 'Color', obj.HeadColor, 'LineWidth', 1.7)
            
            axis square
            axis off
            axis equal;
            set(gca, 'xlim', [-0.555 0.555]);
            set(gca, 'ylim', [-0.555 0.555]);
            obj.TextLabel = text(0.0, -0.555, 2.1, ...   % set the bottom label
                obj.XStringBase, 'HorizontalAlignment','center',...
                'VerticalAlignment','middle','Color', [0, 0, 0]);
        end % plotHead
        
        function plotMap(obj, x, y, values)
            % Plot contour map image for interpolation electrodes
            if isempty(values)  % Nothing to plot
                return;
            end
            
            % Find the elements to interpolate
            intElements = find(x <= obj.InterpolationRadius & y <= obj.InterpolationRadius); % interpolate and plot channels inside interpolation square
            intElements = intersect(obj.ValidElements, intElements);
            intx  = x(intElements);
            inty  = y(intElements);
            intValues = values(intElements);
            xmin = min(-obj.HeadRadius, min(intx));
            xmax = max(obj.HeadRadius, max(intx));
            ymin = min(-obj.HeadRadius, min(inty));
            ymax = max(obj.HeadRadius, max(inty));
            
            xi = linspace(xmin, xmax, 67);   % x-axis description (row vector)
            yi = linspace(ymin, ymax, 67);   % y-axis description (row vector)
            [Xi, Yi ,Zi] = griddata(inty, intx, intValues, yi', xi, 'invdist'); % interpolate
            mask = (sqrt(Xi.^2 + Yi.^2) > obj.HeadRadius); % mask outside the plotting circle
            Zi(mask)  = NaN;                 % mask non-plotting areas
            delta = xi(2) - xi(1); % length of grid entry
            
            % instead of default larger AXHEADFAC
            AXHEADFAC = 1.3;        % head to axes scaling factor
            if obj.SqueezeFactor < 0.92 && obj.PlotRadius-obj.HeadRadius > 0.05  % (size of head in axes)
                AXHEADFAC = 1.05;     % do not leave room for external ears if head cartoon
            end
            set(gca, 'Color', [1, 1, 1], ...
                'Xlim', [-obj.HeadRadius obj.HeadRadius]*AXHEADFAC, ...
                'Ylim', [-obj.HeadRadius obj.HeadRadius]*AXHEADFAC);
            surface(Xi - delta/2, Yi - delta/2, zeros(size(Zi)), ...
                Zi, 'EdgeColor', 'none', 'FaceColor', 'flat');
            caxis([min(Zi(:)) max(Zi(:))]); % set coloraxis
            colorbar
        end % plotMap
    
    end % private methods
    
    methods (Static = true)
        
        function settings = getDefaultProperties()
            % Structure specifying how to set configurable public properties
            cName = 'visviews.elementBoxPlot';
            settings = struct( ...
                'Enabled',       {true, true, true}, ...
                'Category',      {cName, cName, cName}, ...
                'DisplayName',   {...
                'Box plot colors', ...
                'Elements per clump (boxplot)', ...
                'Combination method'}, ...
                'FieldName',     {'BoxColors', 'ClumpFactor', 'CombineMethod'}, ...
                'Value',         { ...
                [0.7, 0.7, 0.7; 0, 0, 1], ...
                1, ...
                'max'}, ...
                'Type',          {...
                'visprops.colorListProperty', ...
                'visprops.unsignedIntegerProperty', ...
                'visprops.enumeratedProperty'}, ...
                'Editable',      {true, true, true}, ...
                'Options',       {'', [1, inf], {'max', 'min', 'mean', 'median'}}, ...
                'Description',   {...
                'elementBoxPlot alternating box colors (cannot be empty)', ...
                'Number of elements grouped into a clump represented by one box plot', ...
                'Method for combining elements in a clump'} ...
                );
            
        end % getDefaultProperties
        
    end % static methods
    
end % blockScalpPlot