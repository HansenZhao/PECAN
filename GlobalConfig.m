classdef GlobalConfig
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %default colormap
        cmap = jet;
        %matlab default color map
        %cmap = parula;
        %red-blue color map
        %cmap = [repmat(linspace(0.3,0.8,32)',1,2),linspace(1,0.8,32)';...
                %linspace(0.8,1,32)',repmat(linspace(0.8,0.3,32)',1,2)];
    end
    
    methods
    end
    
end

