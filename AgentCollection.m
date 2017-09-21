classdef AgentCollection < handle
    %AgentCollection The collection of agents
    %   a general container
    
    properties
    end
    
    properties(GetAccess = public, SetAccess = private)
        agentNum;
        agentPool;
        flagPool;
    end
    
    properties(Access = private)
        capacity;
    end
    
    properties(Dependent)
    end
    
    methods
        function obj = AgentCollection(capacity)
            obj.capacity = capacity;
            obj.agentPool = cell(obj.capacity,1);
            obj.agentNum = 0;
            obj.flagPool = [];
        end
        
        function id = addAgent(obj,agent,mainFlag)
            nC = size(mainFlag,2);
            if isempty(obj.flagPool)
                obj.flagPool = zeros(obj.capacity,nC);
            elseif nC ~= size(obj.flagPool,2)
                disp('main flag width inconsist!'); id = [];
                return;
            end
            if obj.agentNum == obj.capacity
                obj.capacity = 2*obj.capacity;
                newPool = cell(obj.capacity,1);
                newPool(1:(obj.capacity/2)) = obj.agentPool;
                obj.agentPool = newPool;
                w = size(obj.flagPool,2);
                newFlag = zeros(obj.capacity,w);
                newFlag(1:(obj.capacity/2),:) = obj.flagPool;
                obj.flagPool = newFlag;
            end
            id = obj.agentNum + 1;
            obj.agentNum = obj.agentNum + 1;
            obj.agentPool{id} = agent;
            obj.flagPool(id,:) = mainFlag;    
        end
        
        function agent = getAgentById(obj,id)
            if id > 0 && id <= obj.agentNum
                agent = obj.agentPool{id};
            else
                disp('invalid id');
                agent = [];
                return;
            end
        end
        
        function setAgentById(obj,id,agent,varargin)
            if nargin == 4
                newFlag = varargin{1};
            end
            if id > 0 && id <= obj.agentNum
                obj.agentPool{id} = agent;
                if exist('newFlag','var')
                    if size(newFlag,2) == size(obj.flagPool,2)
                        obj.flagPool(id,:) = newFlag;
                    else
                        disp('new flag width is unconsist with the original one');
                    end
                end
            else
                disp('invalid id');
                return;
            end            
        end
        
        function values = getFieldByIds(obj,ids,fieldName)
            if ischar(fieldName)
                L = length(ids);
                names = strsplit(fieldName,',');
                nC = length(names);
                if all(and(ids>0,ids<=obj.agentNum))
                    agents = obj.agentPool(ids);
                    values = cell(L,nC);
                    for m = 1:1:L
                        for n = 1:1:nC
                            try
                                values{m,n} = eval(strcat('agents{m}.',names{n}));
                            catch
                                fprintf(1,'Cannot find %s in agent: %d\n',names{n},m);
                                values{m} = nan;
                            end
                        end
                    end
                else
                    disp('invalid ids');
                end
            else
                values = obj.getFieldByEnum(ids,fieldName);
            end
        end
        
        function values = getFieldByEnum(obj,ids,enum)
            L = length(ids);
            agents = obj.agentPool(ids);
            values = cell(L,1);
            switch(enum)
                case AgentProp.ALPHA
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.alpha;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.ASYM
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.asym;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.AVE_VEL
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.aveVel;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.D
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.D;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.DIR_X
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.dir_x;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.DIR_Y
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.dir_y;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.N_DIR_X
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.n_dir_x;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.N_DIR_Y
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.n_dir_y;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.X
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.x;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.Y
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.y;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.FRAME
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.frame;
                        catch
                            values{m} = nan;
                        end
                    end
                case AgentProp.MEAN_DIR_C
                    for m = 1:1:L
                        try
                            values{m} = agents{m}.mean_dir_change;
                        catch
                            values{m} = nan;
                        end
                    end
                otherwise
                    error('Cannot parse enum: %s',enum);
            end
        end
        
        function ids = filterByFlag(obj,filterFunc,funcParam,varargin)
            if nargin < 4
                region = 1:obj.agentNum; 
            elseif nargin < 5
                region = varargin{1};
            else
                if varargin{2}
                    region = varargin{1};
                else
                    region = setdiff(1:obj.agentNum,varargin{1});
                    if isempty(region)
                        ids = [];
                        return;
                    end
                end
            end
            index = filterFunc(obj.flagPool(region,:),funcParam);
            ids = region(logical(index));
        end
        
        function instance = copy(obj,ids)
            L = length(ids);
            instance = AgentCollection(L);
            for m = 1:1:L
                instance.addAgent(obj.agentPool{ids(m)},obj.flagPool(ids(m),:));
            end
        end
    end
    
end

