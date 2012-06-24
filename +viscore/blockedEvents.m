% viscore.blockedEvents   manages an array of events for block visualizations
%
% Usage:
%   >>  viscore.blockedEvents(events)
%   >>  obj = viscore.blockedEvents(events)
%   >>  obj = viscore.blockedEvents(..., 'Name1', 'Value1', ...)
%
% Description:
% viscore.blockedEvents(event) creates an object to hold events for
%    visualization. The event parameter is an array of structures.
%    The visualization is assumed to be divided into (potentially
%    overlapping) fixed length blocks that are used for summaries.
%
%
% viscore.blockedEvents(events, 'Name1', 'Value1', ...) specifies
%     optional name/value parameter pairs:
%
%   'BlockStartTimes'   optional vector of start times (in seconds) of blocks
%   'BlockTime'         length of block in seconds
%   'MaxTime'           maximum time in seconds to use
%
%
% The event order is alphabetical by default. The order is relevant for
% the order in which events occur in the visualization. The EventOrder
% parameter allows users to over-ride this behavior by specifying the
% types of events that should appear first (and hence are displayed more
% prominently). Any event types not mentioned are not displayed.
%
% obj = viscore.blockedEvents(...) returns a handle to the newly created
% object.
%
% Example 1:
% Create a blocked data object for a random array
%   data = random('normal', 0, 1, [32, 1000, 20]);
%   bd = viscore.blockedEvents(data);
%
% Example 2:
% Reblock a data object in blocks of 500 frames
%   data = random('normal', 0, 1, [32, 1000, 20]);
%   bd = viscore.blockedEvents(data, 'Normal(0, 1)');
%   bd.reblock(500);
%   [rows, cols, blks] = bd.getDataSize();
%
% Notes:
%  - Data that is initially epoched cannot be reblocked.
%  - An empty sampling rate implies that the data is not sampled at a fixed
%    sampling rate. This feature will be supported in the future in a child class.
%  - This data object has a version ID that changes each time the data
%    is modified. The version ID enables functions to know whether
%    to recompute their values.
%  - The events are sorted in increasing chronological order by start times
%
% The event structure array should contain the following fields fields:
%    type        a string identifying the type of event
%    startTime   double time in seconds of the start of the event from the
%                beginning
%    certainty  (optional) measure between 0 and 1 indicating how
%                certain this event is (for computed events).  If omitted, 
%                the certainty is 1
%    blocks     (optional) number of blocks in which the event is to be
%                placed (for epoched data)
% The event structure array may have other fields, which are ignored.
%
% Notes:
%   - the blocks field is needed windows may overlap and EEG duplicates
%     events in overlapping blocks so times can't always be used to
%     determine membership
%
% Class documentation:
% Execute the following in the MATLAB command window to view the class
% documentation for viscore.blockedEvents:
%
%    doc viscore.blockedEvents
%
% See also: viscore.blockData
%

%1234567890123456789012345678901234567890123456789012345678901234567890

% Copyright (C) Kay Robbins, UTSA, July 1, 2011, krobbins@cs.utsa.edu
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
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
%
% $Log: blockedEvents.m,v $
% $Revision: 1.00 04-Dec-2011 09:11:20 krobbins $
% $Initial version $
%

classdef blockedEvents < hgsetget
    
    properties (Access = private)
        BlockList = {};      % cell array indexing events in block
        BlockStartTimes;     % start time of each block in seconds
        BlockTime;           % time in seconds for one block
        Certainty;           % values between 0 and 1 indicating certainty
        EventBlocks;         % cell array of starting blocks by event
        EventCounts;         % type x blocks array with event counts
        EventStartTimes;     % double array of event start times
        EventTypeNumbers;    % cell array of event type numbers
        EventUniqueTypes;    % cell array of unique in desired order
        MaxTime;             % maximum time in seconds for events
        Preblocked;          % true if block start times are fixed (no reblocking)
        VersionID            % version ID of this event set
    end % private properties
    
    methods
        
        function obj = blockedEvents(event, varargin)
            % Constructor parses parameters and sets up initial data
            c = viscore.counter.getInstance();
            obj.VersionID = num2str(c.getNext());  % Get a unique ID
            obj.parseParameters(event, varargin{:});
        end % blockedEvents constructor
        
        function events = getBlocks(obj, startBlock, endBlock)
            % Return the row vector of doubles containing event numbers
            bStart = max(startBlock, 1);
            bEnd = min(endBlock, length(obj.BlockList));
            numEvents = 0;
            for k = bStart:bEnd
                numEvents = numEvents + length(obj.BlockList{k});
            end
            events = zeros(numEvents, 1);
            s = 1;
            for k = bStart:bEnd
                e = s + length(obj.BlockList{k}) - 1;
                events(s:e) = obj.BlockList{k};
                s = e + 1;
            end
            events = unique(events);
        end % getBlocks
        
        function blockStartTimes = getBlockStartTimes(obj, varargin)
            % Return a vector of the block or epoch start times
            if nargin == 1
                blockStartTimes = obj.BlockStartTimes;
            else
                blockStartTimes = obj.BlockStartTimes(varargin{1});
            end
        end % getBlockStartTimes
        
        function blocklist = getBlockList(obj)
            % Return the cell array of block event lists
            blocklist = obj.BlockList;
        end % getBlockList
        
        function blockTime = getBlockTime(obj)
            % Return the time in seconds of the length of a block
            blockTime = obj.BlockTime;
        end % getBlockTime
        
        function certainty = getCertainty(obj, varargin)
            % Return event start times - all or those specified by varargin
            if nargin == 1
                certainty = obj.Certainty;
            else
                certainty = obj.Certainty(varargin{1});
            end
        end % getCertainty

        function event = getEvent(obj, k)
            % Return event k as a structure or empty
            event = [];
            if k < 1 || k > length(obj.EventTypes)
                return;
            end
            event.type = obj.EventTypes{k};
            event.startTime = obj.EventStartTimes(k);
            event.blocks = obj.EventBlocks{k};
        end % getEvent
        
        function eBlocks = getEventBlocks(obj, varargin)
            % Return cell arrray of starting blocks by event
            if nargin == 1
                eBlocks = obj.EventBlocks;
            else
                eBlocks = obj.EventBlocks(varargin{1});
            end
        end % getStartTimes
        
        function counts = getEventCounts(obj, startBlock, endBlock) %#ok<MANU>
            % Return types x blocks array of counts
            counts = eval(['obj.EventCounts(:, ' ...
                num2str(startBlock) ':' num2str(endBlock) ')']);
        end % getEventCounts
        
        function numBlocks = getNumberBlocks(obj)
            % Return the number of blocks
            numBlocks = length(obj.BlockList);
        end % getNumberBlocks
        
        function numEvents = getNumberEvents(obj)
            % Return the number of events
            numEvents = length(obj.EventStartTimes);
        end % getNumberEvents
              
        function startTimes = getStartTimes(obj, varargin)
            % Return event start times - all or those specified by varargin
            if nargin == 1
                startTimes = obj.EventStartTimes;
            else
                startTimes = obj.EventStartTimes(varargin{1});
            end
        end % getStartTimes
        
        function types = getTypes(obj, varargin)
            % Return a cell array of event types in event order
            if nargin == 1
                types = obj.EventTypeNumbers;
            else
                types = obj.EventTypeNumbers(varargin{1});
            end
            types = obj.EventUniqueTypes(types);  % not correct
        end % getUniqueTypes
        
        
        function typeNumbers = getTypeNumbers(obj, varargin)
            % Return event type numbers - all or those specified by varargin
            if nargin == 1
                typeNumbers = obj.EventTypeNumbers;
            else
                typeNumbers = obj.EventTypeNumbers(varargin{1});
            end
        end % getTypeNumbers
        
        function uniqueTypes = getUniqueTypes(obj)
            % Return the unique event types
            uniqueTypes = obj.EventUniqueTypes;
        end % getUniqueTypes
        
        function version = getVersionID(obj)
            % Return version ID of this event set
            version = obj.VersionID;
        end % getVersionID
        
        function reblock(obj, blockTime, maxTime)
            % Reblock the event list to a new blocksize
            %
            % Inputs:
            %    blockSize    size to make the windows
            %    maxTime      optional time in seconds of end range
            %
            % Notes:
            %  - no action is taken if data is epoched or blockSize <= 0
            %
            if isempty(blockTime) || blockTime <= 0
                return;
            elseif nargin > 2 && ~isempty(maxTime)
                obj.MaxTime = maxTime;
            end
            if ~obj.Preblocked
                obj.BlockStartTimes = ...
                    (0:(ceil(obj.MaxTime/blockTime)-1)).*obj.BlockTime;
            end
            
            % Reblocking so the version changes
            c = viscore.counter.getInstance();
            obj.VersionID = num2str(c.getNext());  %
            obj.BlockTime = blockTime;
            
            % Calculate the event counts in each block
            numBlocks = length(obj.BlockStartTimes);
            obj.EventCounts = zeros(length(obj.EventUniqueTypes), numBlocks);
            obj.BlockList = cell(numBlocks, 1);
            for k = 1:length(obj.BlockList)
                obj.BlockList{k} = {};
            end;
            if ~obj.Preblocked
                obj.EventBlocks = ...
                    num2cell(floor(obj.EventStartTimes/obj.BlockTime) + 1);
            end
            for k = 1:length(obj.EventStartTimes)
                myBlocks = obj.EventBlocks{k};
                for j = 1:length(myBlocks);
                    s = myBlocks(j);
                    obj.BlockList{s}{length(obj.BlockList{s}) + 1} = k;
                    obj.EventCounts(obj.EventTypeNumbers(k), s) = ...
                        obj.EventCounts(obj.EventTypeNumbers(k), s) + 1;
                end
            end
            
            % Now fix BlockList elements to be arrays
            for k = 1:length(obj.BlockList)
                obj.BlockList{k} = cell2mat(obj.BlockList{k});
            end
        end % reblock
        
    end % public methods
    
    methods(Access = private)
        function parseParameters(obj, event, varargin)
            % Parse parameters provided by user in constructor
            parser = viscore.blockedEvents.getParser();
            parser.parse(event, varargin{:})
            % Get the parsed results
            p = parser.Results;
            
            % Set the events
            types = cellfun(@num2str, {p.event.type}', 'UniformOutput', false);
            obj.EventStartTimes = cell2mat({p.event.startTime})';
            if sum(isnan(obj.EventStartTimes)) > 0 || ...
                    sum(obj.EventStartTimes) < 0 > 0 || ...
                    sum(isnan(obj.EventStartTimes)) > 0
                error('blockedEvents:NonNegativeStart', ...
                    'Event start times must be non negative\n')
            end
            if isfield(p.event, 'certainty')
               obj.Certainty = cell2mat({p.event.certainty}');
               if sum(obj.Certainty < 0) + sum(obj.Certainty > 1) > 0
                   error('blockedEvents:CertaintyOutOfRange', ...
                       'Event certainties must be between 0 and 1 inclusive');
               end
            else
               obj.Certainty = ones(length(obj.EventStartTimes), 1);
            end
            
            % Process the event types
            [obj.EventUniqueTypes, ia, obj.EventTypeNumbers] = ...
                unique(types);        %#ok<ASGLU>
            if isempty(obj.EventUniqueTypes{1})
                error('blockedEvents:NonemptyType', ...
                    'Event types must be non empty\n');
            end
            
            % Figure out the maximum time
            obj.MaxTime = p.MaxTime;
            obj.BlockTime = p.BlockTime;
            if ~isempty(p.BlockStartTimes)
                obj.Preblocked = true;
                obj.BlockStartTimes = ...
                    reshape(p.BlockStartTimes, length(p.BlockStartTimes), 1);
                if isempty(obj.MaxTime)
                    obj.MaxTime = max(obj.BlockStartTimes) + obj.BlockTime;
                end
                if isfield(p.event, 'block')
                    obj.EventBlocks = {p.event.block}';
                else
                    obj.EventBlocks = cell(length(obj.EventStartTimes), 1);
                    for k = 1:length(obj.EventStartTimes)
                        obj.EventBlocks{k} = find( ...
                            obj.BlockStartTimes <= obj.EventStartTimes(k) && ...
                            obj.EventStartTimes(k) < ...
                            obj.BlockStartTimes + obj.BlockTime);
                    end
                end
            else
                obj.Preblocked = false;
                if isempty(obj.MaxTime)
                    obj.MaxTime = max(obj.EventStartTimes);
                end
                
            end
            
            obj.reblock(obj.BlockTime, obj.MaxTime);
        end % parseParameters
        
    end % private methods
    
    methods(Static = true)
        
        function [event, epochStarts, epochScale] = getEEGTimes(EEG)
            % Return epoch start times in seconds and time scale in ms
            event = [];
            epochStarts = [];
            epochScale = [];
            if ~isstruct(EEG) ||~isfield(EEG, 'event') || isempty(EEG.event)
                return;
            end
            
            % Construct the events
            types = {EEG.event.type}';
            if ~isfield(EEG.event, 'urevent')
                uEvents = (1:length(types))';
            else
                uEvents = cell2mat({EEG.event.urevent}');
            end
            eLatencies = double(cell2mat({EEG.urevent(uEvents).latency}'));
            startTimes = (round(eLatencies) - 1)./EEG.srate;
           
            % Now look at the epochs
            if ~isfield(EEG,'epoch') ||  isempty(EEG.epoch) % not epoched
                event = struct('type', types, 'startTime', num2cell(startTimes), ...
                    'certainty', ones(length(startTimes), 1));
                return;
            end
            epochList = {EEG.event.epoch}';
            event = struct('type', types, 'startTime', num2cell(startTimes), ...
                 'certainty', ones(length(startTimes), 1), 'block', epochList);
            if ~isstruct(EEG) ||~isfield(EEG, 'times')
                epochScale = (0:(length(EEG.epoch) - 1))'/EEG.srate;
            else
                epochScale = reshape(EEG.times, length(EEG.times), 1)./1000;
            end
            epochBase = epochScale(1);
            
            epochStarts = zeros(length(EEG.epoch), 1);
            for k = 1:length(EEG.epoch)
                u = EEG.event(EEG.epoch(k).event(1)).urevent;
                epochStarts(k) = epochBase + ...
                    (EEG.urevent(u).latency - 1)./EEG.srate - ...
                    EEG.epoch(k).eventlatency{1}./1000;
                epochStarts(k) = round(epochStarts(k)*EEG.srate)./EEG.srate;
            end
        end  % getEpochTimes
        
        function parser = getParser()
            % Create a parser for blockedEvents
            parser = inputParser;
            parser.StructExpand = true;
            parser.addRequired('event', ...
                @(x) (~isempty(x) && isstruct(x)) && ...
                sum(isfield(x, {'type', 'startTime', 'certainty'})) == 3);
            parser.addParamValue('BlockStartTimes', [], ...
                @(x)(isempty(x) || isnumeric(x)));
            parser.addParamValue('BlockTime', 1, ...
                @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
            parser.addParamValue('MaxTime', [], ...
                @(x) (isempty(x) || (isnumeric(x) && isscalar(x) && x > 0)));
        end % getParser
        
    end % static methods
    
end % blockedEvents
