% viewTestClass()   test class for generating defaults
%
% Usage:
%   >>  visviews.dualView()
%   >>  visviews.dualView('key1', 'value1', ....)
%   >>  obj = visviews.dualView()
%   >>  obj = visviews.dualView('key1', 'value1', ....)
%
%
% Optional inputs:
%    'VisData'        blockedData object or a 3D array of data
%    'Functions'      dataManager, structure, or cell array of initial functions
%    'Plots'          dataManager, structure, or cell array of initial plots
%    'Properties'     dataManager, structure, or cell array of initial properties
%    'Title'          title to be used for figure window
%    'UseEEGLab'      if true, start eeglab if necessary and refresh datasets
%
% Outputs:
%     obj             handle to dualView object
%
% Notes:
%   - Many summaries supported by this viewer are window or epoch oriented.
%   - Some displays treat epoched data differently than non-epoched data.
%   - Epoched data may not be continuous and cannot be reblocked by
%     changing the block size.
%
% Author: Kay Robbins, UTSA,
%
% See also: eegBrowse(), eegplugin_eegvis()
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

% $Log: dualView.m,v $
% Revision 1.00  10-Jun-2011 16:44:07  krobbins
% Initial version
%

classdef viewTestClass < hgsetget 
    
    
    methods
        
        function obj = viewTestClass(varargin)
            % Create visualization and initialize displays
        end % viewTestClass constructor
        
    end % public methods
    
    methods (Static=true)
               
        function fStruct = getDefaultFunctions()
            % Structure specifying the default functions (one per tab)
            fStruct = struct( ...
                'Enabled',        {true,         true}, ...
                'Category',       {'block',        'block'}, ...
                'DisplayName',    {'Kurtosis', 'Standard Deviation'}, ...
                'ShortName',      {'K',        'SD'}, ...
                'Definition',     {'@(x) (squeeze(kurtosis(x, 1, 2)))', ...
                '@(x) (squeeze(std(x, 0, 2)))'}, ...
                'ThresholdType',  {'z score',    'z score'}, ...
                'ThresholdScope', {'global'     'global'}, ...
                'ThresholdLevels', {3,              3}, ...
                'ThresholdColors', {[1, 0, 0],    [0, 1, 1]}, ...
                'BackgroundColor', {[0.7, 0.7, 0.7], [0.7, 0.7, 0.7]}, ...
                'Description',    {'Kurtosis computed for each (element, block)', ...
                'Block size for computation (must be positive)' ...
                });
        end % getDefaultFunctions
        
       function fStruct = getDefaultFunctionsNoSqueeze()
            % Structure specifying the default functions (one per tab)
            fStruct = struct( ...
                'Enabled',        {true,         true}, ...
                'Category',       {'block',        'block'}, ...
                'DisplayName',    {'Kurtosis', 'Standard Deviation'}, ...
                'ShortName',      {'K',        'SD'}, ...
                'Definition',     {'@(x) (kurtosis(x, 1, 2))', ...
                '@(x) (std(x, 0, 2))'}, ...
                'ThresholdType',  {'z score',    'z score'}, ...
                'ThresholdScope', {'global'     'global'}, ...
                'ThresholdLevels', {3,              3}, ...
                'ThresholdColors', {[1, 0, 0],    [0, 1, 1]}, ...
                'BackgroundColor', {[0.7, 0.7, 0.7], [0.7, 0.7, 0.7]}, ...
                'Description',    {'Kurtosis computed for each (element, block)', ...
                'Block size for computation (must be positive)' ...
                });
        end % getDefaultFunctionsNoSqueeze

 
        function fStruct = getDefaultFunctionsSpecificValues()
            % Structure specifying the default functions (one per tab)
            fStruct = struct( ...
                'Enabled',        {true,         true}, ...
                'Category',       {'block',        'block'}, ...
                'DisplayName',    {'Mean', 'Standard Deviation'}, ...
                'ShortName',      {'M',        'SD'}, ...
                'Definition',     {'@(x) (mean(x, 2))', ...
                '@(x) (std(x, 0, 2))'}, ...
                'ThresholdType',  {'z score',    'z score'}, ...
                'ThresholdScope', {'global'     'global'}, ...
                'ThresholdLevels', {3,              3}, ...
                'ThresholdColors', {[1, 0, 0],    [0, 1, 1]}, ...
                'BackgroundColor', {[0.7, 0.7, 0.7], [0.7, 0.7, 0.7]}, ...
                'Description',    {'Mean computed for each (element, block)', ...
                'Block size for computation (must be positive)' ...
                });
        end % getDefaultFunctionsSpecificValues
        
        function settings = getDefaultProperties()
            % Structure specifying how to set configurable public properties
            cName = 'visviews.dualView';
            settings = struct( ...
                'Enabled',       {true,         true,          true,             true,             true}, ...
                'Category',      {cName,        cName,         cName,            cName,            cName}, ...
                'DisplayName',   {'Block name', 'Block size',  'Element name',   'Epoch name',     'Visualization name'}, ...
                'FieldName',     {'BlockName', 'BlockSize'     'ElementName',    'EpochName',      'VisName'}, ...
                'Value',         {'Window',     1000,          'Channel',        'Epoch',          'eegVIS'}, ...
                'Type',          { ...
                'visprops.stringProperty', ...
                'visprops.doubleProperty', ...
                'visprops.stringProperty', ...
                'visprops.stringProperty', ...
                'visprops.stringProperty'}, ...
                'Editable',      {true,         true,          true,             true,             true}, ...
                'Options',       {'',           [0, inf],      '',               '',               ''}, ...
                'Description',   {...
                'Block name or label (e.g. ''Window'')', ...
                'Number of samples in a block (unsigned int)', ...
                'Element name (e.g. ''Channel'')', ...
                'Epoch name or label (e.g. ''Epoch'')', ...
                'Visualization figure title bar identification' ...
                });
        end % getDefaultProperties
        
        
        function pStruct = getDefaultPlots()
            % Structure specifying the individual visualizations used
            pStruct = struct( ...
                'Enabled',        {true,           true,           true,          false,           true,           true}, ...
                'Category',       {'summary',      'summary',      'summary',     'summary',       'detail',        'detail'}, ...
                'DisplayName',    {'Block image',  'Element box',  'Block box',   'Block histogram' 'Stacked signal', 'Shadow signal'}, ...
                'Definition', { ...
                'visviews.blockImagePlot', ...
                'visviews.elementBoxPlot', ...
                'visviews.blockBoxPlot', ...
                'visviews.blockHistogramPlot', ...
                'visviews.signalStackedPlot', ...
                'visviews.signalShadowPlot', ...
                }, ...
                'Sources', { ...
                'None', ...
                'Block image', ...
                'Block image, element box', ... 
                '', ...
                'Master,,Element box  ', ...
                'Master, Stacked signal '}, ...
                'Description', { ...
                'Image of blocked value array', ...
                'Box plot of blocked values for each element', ...
                'Box plot of blocked values for groups of blocks', ...
                'Histogram of the blocked values', ...
                'Stacked plot of raw signals in a time window', ...
                'Shadow plot of raw signals in a time window' ...
                });
        end % getDefaultPlots
        
        function pStruct = getDefaultPlotsDetailOnly()
            % Structure specifying the individual visualizations used
            pStruct = struct( ...
                'Enabled',        {true,           true}, ...
                'Category',       {'detail',        'detail'}, ...
                'DisplayName',    {'Stacked signal', 'Shadow signal'}, ...
                'Definition', { ...
                'visviews.signalStackedPlot', ...
                'visviews.signalShadowPlot', ...
                }, ...
                'Sources', { ...
                'Master', ...
                'Master, Stacked signal '}, ...
                'Description', { ...
                'Stacked plot of raw signals in a time window', ...
                'Shadow plot of raw signals in a time window' ...
                });
        end % getDefaultPlotsDetailOnly
        
        function pStruct = getDefaultPlotsLinkedSummary()
            % Structure specifying the individual visualizations used
            pStruct = struct( ...
                'Enabled',        {true,           true,           true,      true}, ...
                'Category',       {'summary',      'summary',      'summary', 'detail'}, ...
                'DisplayName',    {'Block image',  'Element box',  'Block box', 'StackedSignal'}, ...
                'Definition', { ...
                'visviews.blockImagePlot', ...
                'visviews.elementBoxPlot', ...
                'visviews.blockBoxPlot', ... 
                'visviews.signalStackedPlot' ...
                }, ...
                'Sources', { ...
                'None', ...
                'Block image', ...
                'Block image, element box', ...
                'Master,,Element box  '}, ...
                'Description', { ...
                'Image of blocked value array', ...
                'Box plot of blocked values for each element', ...
                'Box plot of blocked values for groups of blocks', ...
                'Stacked plot of raw signals in a time window' ...
                });
        end % getDefaultPlotsLinkedSummary
        
       function pStruct = getDefaultPlotsBlockBoxPlotLinked()
            % Structure specifying the individual visualizations used
            pStruct = struct( ...
                'Enabled',        {true,           true,           true,      true}, ...
                'Category',       {'summary',      'summary',      'summary', 'detail'}, ...
                'DisplayName',    {'Block image',  'Block box',   'Block box linked', 'StackedSignal'}, ...
                'Definition', { ...
                'visviews.blockImagePlot', ...
                'visviews.blockBoxPlot', ...
                'visviews.blockBoxPlot', ... 
                'visviews.signalStackedPlot' ...
                }, ...
                'Sources', { ...
                'None', ...
                'None', ...
                'Block box', ...
                'Master'}, ...
                'Description', { ...
                'Image of blocked value array', ...
                'Box plot of blocked values for groups of blocks', ...
                'Box plot of blocked values linked to previous box plots', ...
                'Stacked plot of raw signals in a time window' ...
                });
        end % getDefaultPlotsLinkedSummary
        
        function pStruct = getDefaultPlotsBlockImagePlotLinked()
            % Structure specifying the individual visualizations used
            pStruct = struct( ...
                'Enabled',        {true,           true,           true,             true,  true}, ...
                'Category',       {'summary',      'summary',      'summary',        'summary', 'detail'}, ...
                'DisplayName',    {'Block image',  'Block box',   'Block box linked', 'Block image linked', 'StackedSignal'}, ...
                'Definition', { ...
                'visviews.blockImagePlot', ...
                'visviews.blockBoxPlot', ...
                'visviews.blockBoxPlot', ... 
                'visviews.blockImagePlot', ...
                'visviews.signalStackedPlot' ...
                }, ...
                'Sources', { ...
                'None', ...
                'None', ...
                'Block box', ...
                'Block box', ...
                'Master'}, ...
                'Description', { ...
                'Image of blocked value array', ...
                'Box plot of blocked values for groups of blocks', ...
                'Box plot of blocked values linked to previous box plots', ...
                'Image plot linked to both an image plot and box plot', ...
                'Stacked plot of raw signals in a time window' ...
                });
        end % getDefaultPlotsBlockImagePlotLinked
        
        function pStruct = getPlotsBlockImageMultipleLinked()
            % Structure specifying the individual visualizations used
            pStruct = struct( ...
                'Enabled',        {true,           true,           true,             true,  true}, ...
                'Category',       {'summary',      'summary',      'summary',        'summary', 'detail'}, ...
                'DisplayName',    {'Block image',  'Block box',   'Block box1', 'Block image linked', 'StackedSignal'}, ...
                'Definition', { ...
                'visviews.blockImagePlot', ...
                'visviews.blockBoxPlot', ...
                'visviews.blockBoxPlot', ... 
                'visviews.blockImagePlot', ...
                'visviews.signalStackedPlot' ...
                }, ...
                'Sources', { ...
                'None', ...
                'None', ...
                'None', ...
                'Block box, Block box1', ...
                'Master'}, ...
                'Description', { ...
                'Image of blocked value array', ...
                'Box plot of blocked values for groups of blocks', ...
                'Box plot of blocked values linked to previous box plots', ...
                'Image plot linked to both an image plot and box plot', ...
                'Stacked plot of raw signals in a time window' ...
                });
        end % getPlotsBlockImageMultipleLinked
        
       function pStruct = getDefaultPlotsSummaryOnly()
            % Structure specifying the individual visualizations used
            pStruct = struct( ...
                'Enabled',        {true,           true,           true}, ...
                'Category',       {'summary',      'summary',      'summary'}, ...
                'DisplayName',    {'Block image',  'Element box',  'Block box'}, ...
                'Definition', { ...
                'visviews.blockImagePlot', ...
                'visviews.elementBoxPlot', ...
                'visviews.blockBoxPlot' ... 
                }, ...
                'Sources', { ...
                'None', ...
                'Block image', ...
                'Block image, element box'}, ...
                'Description', { ...
                'Image of blocked value array', ...
                'Box plot of blocked values for each element', ...
                'Box plot of blocked values for groups of blocks' ...
                });
        end % getDefaultPlotsSummaryOnly
        
        function pStruct = getDefaultPlotsUnlinkedSummary()
            % Structure specifying the individual visualizations used
            pStruct = struct( ...
                'Enabled',        {true,           true,           true,      true}, ...
                'Category',       {'summary',      'summary',      'summary', 'detail'}, ...
                'DisplayName',    {'Block image',  'Element box',  'Block box', 'StackedSignal'}, ...
                'Definition', { ...
                'visviews.blockImagePlot', ...
                'visviews.elementBoxPlot', ...
                'visviews.blockBoxPlot', ... 
                'visviews.signalStackedPlot' ...
                }, ...
                'Sources', { ...
                'None', ...
                'None', ...
                'None', ...
                'Master'}, ...
                'Description', { ...
                'Image of blocked value array', ...
                'Box plot of blocked values for each element', ...
                'Box plot of blocked values for groups of blocks', ...
                'Stacked plot of raw signals in a time window' ...
                });
        end % getDefaultPlotsLinkedSummary

        function parser = getParser()
            % Create an inputparser for FileSelector
            parser = inputParser;
            parser.addParamValue('VisData', [], ...
                @(x) validateattributes(x, ...
                {'viscore.blockedData', 'numeric'}, {}));
            parser.addParamValue('Functions', [], ...
                @(x) validateattributes(x, ...
                {'struct', 'cell', 'viscore.dataManager'}, {}));
            parser.addParamValue('Plots', [], ...
                @(x) validateattributes(x, ...
                {'struct', 'cell', 'viscore.dataManager'}, {}));
            parser.addParamValue('Properties', [], ...
                @(x) validateattributes(x, ...
                {'cell', 'viscore.dataManager'}, {}));
        end % getParser()
        
    end % static methods
    
end % dualView

