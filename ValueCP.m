classdef ValueCP < handle
    %ValueCP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        values;
        indices;
        Y;
        hAxes;
        length;
        vName;       
    end
    
    properties(GetAccess=public,SetAccess=private)
        vStyle;
    end
    
    properties(Access=private)
        capacity;
        vFunc;
    end
    
    methods
        function obj = ValueCP(hAxes,capacity)
            if nargin == 1
                obj.capacity = 100;
            elseif nargin == 2
                obj.capacity = capacity;
            end
            obj.hAxes = hAxes;
            obj.length = 0;
            obj.values = cell(obj.capacity,1);
            obj.Y = zeros(obj.capacity,1);
            obj.indices = zeros(obj.capacity,1);
            obj.vName = [];
            obj.vStyle = [];
        end
        
        function addValue(obj,I,v)
            if obj.length >= obj.capacity
                obj.indices = [obj.indices;zeros(obj.capcaity,1)];
                obj.Y = [obj.Y;zeros(obj.capcaity,1)];
                newCell = cell(obj.capcaity,1);
                obj.values = {obj.values{:};newCell{:}};
                obj.capacity = 2 * obj.capacity;
            end
            obj.length = obj.length + 1;
            obj.indices(obj.length) = I;  
            obj.values{obj.length} = v;
            if obj.vStyle
                obj.Y(obj.length) = obj.vFunc(v);
            end
        end
        
        function clear(obj)
            obj.length = 0;
            obj.indices = zeros(obj.capacity,1);
            obj.values = cell(obj.capacity,1);
            cla(obj.hAxes);
        end
        
        function vPlot(obj)
            if obj.length == 0
                return;
            end
            if obj.vStyle
                h  = plot(obj.hAxes,obj.indices(1:obj.length),obj.Y(1:obj.length),'LineWidth',1,'Marker','s');
            end
            if obj.vName
                h.DisplayName = obj.vName;
                legend(obj.hAxes,'show');
            end
        end  
        
        function boolRes = setStyle(obj,str)
            try
                obj.vFunc = str2func(str);
                for m = 1:1:obj.length
                    obj.Y(m) = obj.vFunc(obj.values{m});
                end
                obj.vStyle = str;
                boolRes = 1;
            catch
                boolRes = 0;
            end
        end
    end
end

