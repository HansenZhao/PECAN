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
            L = length(ids);
            if all(and(ids>0,ids<=obj.agentNum))
                agents = obj.agentPool(ids);
                values = cell(L,1);
                for m = 1:1:L
                    try
                        values{m} = eval(strcat('agents{m}.',fieldName));
                    catch
                        fprintf(1,'Cannot find %s in agent: %d\n',fieldName,m);
                        values{m} = nan;
                    end
                end
            else
                disp('invalid ids');
            end
        end
        
        function ids = filterByFlag(obj,filterFunc,varargin)
            index = filterFunc(obj.flagPool,varargin{:});
            allIndices = 1:1:obj.agentNum;
            ids = allIndices(logical(index));
        end
    end
    
end

