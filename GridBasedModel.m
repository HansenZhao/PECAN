classdef GridBasedModel < handle
    %GridBasedModel Summary of this class goes here
    %   Detailed explanation goes here
    properties
        pd;
    end

    properties(GetAccess = public, SetAccess = private)
        resolution;
        nWidth;
        minSegLength;
        deltaT;
        segTolerance;
    end

    properties(Access = private)
        collection;
    end

    properties(Dependent)
        agentNum;
        xRange;
        yRange;
    end

    methods
        function obj = GridBasedModel(pd,deltaT,resolution,minSegLength,segTolerance)
            obj.resolution = resolution;
            obj.segTolerance = segTolerance;
            obj.minSegLength = minSegLength;
            obj.deltaT = deltaT;
            obj.pd = pd;
            %obj.nWidth = ceil(range(pd.xRange)/obj.resolution);
            obj.nWidth = ceil(max(range(obj.xRange)/obj.resolution,range(obj.yRange)/obj.resolution));
        end

        function parse(obj,estCapacity)
            obj.collection = AgentCollection(estCapacity);
            h = waitbar(0,'begin parsing...');
            L = length(obj.pd.ids);
            for m = 1:1:L
                rawMat = obj.pd.getRawMatById(obj.pd.ids(m));
                obj.breakTrace(rawMat);
                waitbar(m/L,h,sprintf('parsing: %.2f%%',100*m/L));
            end
            close(h);
        end

        function aN = get.agentNum(obj)
            aN = obj.collection.agentNum;
        end

        function xR = get.xRange(obj)
            xR = obj.resolution * [floor(obj.pd.xRange(1)/obj.resolution),...
                                   ceil(obj.pd.xRange(2)/obj.resolution)];
        end

        function yR = get.yRange(obj)
            yR = obj.resolution * [floor(obj.pd.yRange(1)/obj.resolution),....
                                   ceil(obj.pd.yRange(2)/obj.resolution)];
        end

        function setCollection(obj,co)
            obj.collection = co;
        end

        function imMat = spatialPlot(obj,hAxes,fieldName,procValueFunc,resizeRate,clim)
            obj.nWidth = ceil(obj.nWidth);
            imMat = zeros(obj.nWidth);
            if ischar(procValueFunc)
                procValueFunc = GridBasedModel.parseProcValueName(procValueFunc);
            end
            filterFunc = @(flags,pos)and(flags(:,2)==pos(1),flags(:,3)==pos(2));
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
            imagesc(hAxes,imresize(imMat,resizeRate)); colormap(GlobalConfig.cmap);
            hAxes.CLim = clim;
            hAxes.YDir = 'normal';
            xlim([0.5,obj.nWidth*resizeRate+0.5]);
            ylim([0.5,obj.nWidth*resizeRate+0.5]);
            title(fieldName);
            axis off;
        end

        function plotSegInGrid(obj,posX,posY)
            filterFunc = @(flags,pos)and(flags(:,2)==pos(1),flags(:,3)==pos(2));
            ids = obj.collection.filterByFlag(filterFunc,[posX,posY]);
            if ~isempty(ids)
                values = obj.collection.getFieldByIds(ids,'traj');
                L = length(values);
                figure; hold on;
                for m = 1:1:L
                    plot(values{m}(:,1),values{m}(:,2),'LineWidth',2);
                end
                xlim([obj.resolution*(posX-1)+obj.xRange(1),obj.resolution*posX+obj.xRange(1)])
                ylim([obj.resolution*(posY-1)+obj.yRange(1),obj.resolution*posY+obj.yRange(1)])
                box on;
            else
                disp('Cannot find agents');
            end
        end

        function [X,Y,u,v] = piv(obj,hAxes,isNor)
            obj.nWidth = ceil(obj.nWidth);
            [X,Y] = meshgrid(1:obj.nWidth);
            [u,v] = deal(zeros(obj.nWidth));
            filterFunc = @(flags,pos)and(flags(:,2)==pos(1),flags(:,3)==pos(2));
            for x = 1:1:obj.nWidth
                for y = 1:1:obj.nWidth
                    ids = obj.collection.filterByFlag(filterFunc,[x,y]);
                    if ~isempty(ids)
                        values = obj.collection.getFieldByIds(ids,'dir');
                        [u(y,x),v(y,x)] = PointBasedModel.dirs2arrow(values,isNor);
                    end
                end
            end
            quiver(hAxes,X,Y,u,v);
        end

        function values = getProp(obj,fieldName)
            v = obj.collection.getFieldByIds(1:1:obj.agentNum,fieldName);
            values = cell2mat(v);
        end

        function instance = childModel(obj,ids)
            if nargin==1
                ids = 1:1:obj.collection.agentNum;
            end
            rangeContainer = struct;
            rangeContainer.xRange = obj.pd.xRange;
            rangeContainer.yRange = obj.pd.yRange;
            instance = GridBasedModel(rangeContainer,obj.deltaT,obj.resolution,...
                                      obj.minSegLength,obj.segTolerance);
            instance.setCollection(obj.collection.copy(ids));
        end
    end

    methods(Access=private)
        function findNum = breakTrace(obj,rawMat)
            searchFrom = ceil( (min(rawMat(:,2:3))-[obj.xRange(1),obj.yRange(1)])/obj.resolution );
            searchTo = ceil( (max(rawMat(:,2:3))-[obj.xRange(1),obj.yRange(1)])/obj.resolution );
            findNum = 0;
            for posX = searchFrom(1):1:searchTo(1)
                for posY = searchFrom(2):1:searchTo(2)
                    [segs,segNum] = obj.breakInGrid(rawMat,posX,posY);
                    if segNum > 0
                        for m = 1:1:segNum
                            segData = rawMat(segs(m,1):segs(m,2),:);
                            agent = TrajSegAgent(segData(:,2:3),segData(1,1),...
                                                 [segData(1,1),posX,posY],obj.deltaT);
                            agent.calSelf();
                            obj.collection.addAgent(agent,[posX,posY]);
                            findNum = findNum + 1;
                        end
                    end
                end
            end
        end

        function [Isegs,segNum] = breakInGrid(obj,rawMat,gridX,gridY)
            frame2indexOffset = 1 - rawMat(1,1);
            hitX = GridBasedModel.isInRange(rawMat(:,2),obj.resolution*(gridX-1)+obj.xRange(1),...
                                                      obj.resolution*gridX+obj.xRange(1));
            hitY = GridBasedModel.isInRange(rawMat(:,3),obj.resolution*(gridY-1)+obj.yRange(1),...
                                                      obj.resolution*gridY+obj.yRange(1));
            hitFrames = rawMat(and(hitX,hitY),1);
            %fprintf(1,'[%d,%d]:hit %d\n',gridX,gridY,length(hitFrames));
            hitFrames = [hitFrames;inf]; % better for segmentation search
            L = length(hitFrames);
            segNum = 0;
            if  L > obj.minSegLength
                Isegs = zeros(L,2);
                tmpStart = 1;
                for m = 2:1:L
                    if (hitFrames(m) - hitFrames(m-1)) > (1 + obj.segTolerance)
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
                case 'weightMean'
                    hFunc = @(x)GridBasedModel.weightMean(cell2mat(x));
                case 'count'
                    hFunc = @(x)length(x);
            end
        end

        function res = weightMean(x)
            if size(x,1) > 1
                x = x(~isnan(sum(x,2)),:);
                res = (x(:,1)' *  x(:,2))/sum(x(:,1));
            else
                res = x(2);
            end
        end
    end

end
