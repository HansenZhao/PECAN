classdef SpatialModel
    %SpatialModel Summary of this class goes here
    %   Detailed explanation goes here
    properties
        pd;
    end
    
    properties(GetAccess = public, SetAccess = private)
        resolution;
        nWidth;
        minSegLength;
        deltaT;
    end
    
    properties(Access = private)
        collection;
    end
    
    properties(Dependent)
        agentNum;
    end
    
    methods
        function obj = SpatialModel(pd,deltaT,resolution,minSegLength,estCapacity)
            obj.resolution = resolution;
            obj.minSegLength = minSegLength;
            obj.deltaT = deltaT;
            obj.nWidth = ceil(pd.xRange/obj.resolution);
            obj.pd = pd;
            obj.collection = AgentCollection(estCapacity);
            h = waitbar(0,'begin parsing...');
            L = length(pd.ids);
            for m = 1:1:L
                rawMat = pd.getRawMatById(pd.ids(m));
                obj.breakTrace(rawMat);
                waitbar(m/L,h,sprintf('parsing: %.2f%%',100*m/L));
            end
            close(h);
        end
        
        function aN = get.agentNum(obj)
            aN = obj.collection.agentNum;
        end
        
        function spatialPlot(obj,hAxes,fieldName,procValueFunc)
            imMat = nan(obj.nWidth);
            if ischar(procValueFunc)
                procValueFunc = SpatialModel.parseProcValueName(procValueFunc);
            end
            filterFunc = @(flags,pos)and(flags(:,1)==pos(1),flags(:,2)==pos(2));
            for x = 1:1:obj.nWidth
                for y = 1:1:obj.nWidth
                    ids = obj.collection.filterByFlag(filterFunc,[x,y]);
                    if ~isempty(ids)
                        values = obj.collection.getFieldByIds(ids,fieldName);
                        %imMat(obj.nWidth-y+1,x) = procValueFunc(values);
                        imMat(y,x) = procValueFunc(values);
                    end
                end
            end
            imagesc(hAxes,imMat,'AlphaData',~isnan(imMat));
            hAxes.YDir = 'normal';
            xlim([0,ceil(obj.pd.xRange/obj.resolution)]+[obj.resolution,obj.resolution]);
            ylim([0,ceil(obj.pd.yRange/obj.resolution)]+[obj.resolution,obj.resolution]);
        end
        
        function plotSegInGrid(obj,posX,posY)
            filterFunc = @(flags,pos)and(flags(:,1)==pos(1),flags(:,2)==pos(2));
            ids = obj.collection.filterByFlag(filterFunc,[posX,posY]);
            if ~isempty(ids)
                values = obj.collection.getFieldByIds(ids,'traj');
                L = length(values);
                figure; hold on;
                for m = 1:1:L
                    plot(values{m}(:,1),values{m}(:,2));
                end
            else
                disp('Cannot find agents');
            end
        end
    end
    
    methods(Access=private)
        function findNum = breakTrace(obj,rawMat)
            searchFrom = ceil(min(rawMat(:,2:3))/obj.resolution);
            searchTo = ceil(max(rawMat(:,2:3))/obj.resolution);
            findNum = 0;
            for posX = searchFrom(1):1:searchTo(1)
                for posY = searchFrom(2):1:searchTo(2)
                    [segs,segNum] = obj.breakInGrid(rawMat,posX,posY);
                    if segNum > 0
                        for m = 1:1:segNum
                            segData = rawMat(segs(m,1):segs(m,2),:);
                            agent = TrajSegAgent(segData(:,2:3),segData(1,1),...
                                                 [posX,posY],obj.deltaT);
                            obj.collection.addAgent(agent,[posX,posY]);
                            findNum = findNum + 1;
                        end
                    end
                end
            end
        end
        
        function [Isegs,segNum] = breakInGrid(obj,rawMat,gridX,gridY)
            frame2indexOffset = 1 - rawMat(1,1);
            hitX = SpatialModel.isInRange(rawMat(:,2),obj.resolution*(gridX-1),obj.resolution*gridX);
            hitY = SpatialModel.isInRange(rawMat(:,3),obj.resolution*(gridY-1),obj.resolution*gridY);
            hitFrames = rawMat(and(hitX,hitY),1);
            %fprintf(1,'[%d,%d]:hit %d\n',gridX,gridY,length(hitFrames));
            hitFrames = [hitFrames;inf]; % better for segmentation search
            L = length(hitFrames);
            segNum = 0;
            if  L > obj.minSegLength
                Isegs = zeros(L,2);
                tmpStart = 1;
                for m = 2:1:L
                    if ~((hitFrames(m) - hitFrames(m-1)) == 1)
                        if (m - tmpStart) >= obj.minSegLength 
                            segNum = segNum + 1;
                            Isegs(segNum,:) = hitFrames([tmpStart,m-1]) + frame2indexOffset;
                        end
                        tmpStart = m;
                    end
                end               
            end
            if segNum == 0
                Isegs = [];
            else
                Isegs = Isegs(1:segNum,:);
            end
        end
    end
    
    methods(Static)
        function boolRes = isInRange(vec,startAt,endAt)
            boolRes = and(vec>=startAt,vec<=endAt);
        end
        
        function hFunc = parseProcValueName(funcName)
            switch funcName
                case 'mean'
                    hFunc = @(x)mean(cell2mat(x),'omitnan');
                case 'sum'
                    hFunc = @(x)sum(cell2mat(x),[],'omitnan');
                case 'max'
                    hFunc = @(x)max(cell2mat(x),[],'omitnan');
                case 'min'
                    hFunc = @(x)min(cell2mat(x),[],'omitnan');
            end
        end
    end
    
end

