classdef PointBasedModel < handle
    %PointBasedModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pd;
    end
    
    properties(GetAccess = public, SetAccess = private)
        deltaT;
        halfWindowLength;
    end
    
    properties(Access = private)
        collection;
    end
    
    properties(Dependent)
        agentNum;
    end
    
    methods
        function obj = PointBasedModel(pd,deltaT,hWinLength)
            obj.deltaT = deltaT;
            obj.halfWindowLength = hWinLength;
            obj.pd = pd;
            obj.collection = [];
        end
        
        function parse(obj,estCapacity)
            obj.collection = AgentCollection(estCapacity);
            h = waitbar(0,'begin parsing...');
            L = length(obj.pd.ids);
            subNum = round(L/5);
            for m = 1:1:L
                rawMat = obj.pd.getRawMatById(obj.pd.ids(m));
                %tic
                obj.makeAgent(rawMat);
                %toc
                if mod(m,subNum)==0
                    waitbar(m/L,h,sprintf('parsing: %.2f%%',100*m/L));
                end
                %fprintf(1,'parsing: %d/%d',m,L);
            end
            waitbar(0,h,'Calculate agent...');
            subNum = round(obj.agentNum/10);
            for m = 1:1:obj.agentNum
                obj.collection.agentPool{m}.calSelf();
                if mod(m,subNum)==0
                    waitbar(m/obj.agentNum,h,sprintf('Calculate agent: %.2f%%',100*m/obj.agentNum));
                end
            end
            close(h);
        end
        
        function aN = get.agentNum(obj)
            aN = obj.collection.agentNum;
        end
        
        function setCollection(obj,co)
            obj.collection = co;
        end
        
        function ids = filterCollection(obj,func,x)
            ids = obj.collection.filterByFlag(func,x);
        end
        
        function imMat = spatialPlot(obj,hAxes,resolution,fieldName,procValueFunc,resizeRate,clim)
            [xR,yR,nWidth] = obj.resolution2range(resolution);
            imMat = zeros(nWidth);
            if ischar(procValueFunc)
                procValueFunc = GridBasedModel.parseProcValueName(procValueFunc);
            end
            filterFunc = @(flags,apos)(GridBasedModel.isInRange(flags(:,apos(1)),apos(2),apos(3)));
            recordCell = cell(nWidth,1);
            for m = 1:1:nWidth
                colRange = [2,xR(1)+resolution*(m-1),xR(1)+resolution*m];
                col_id = obj.collection.filterByFlag(filterFunc,colRange,cell2mat(recordCell),0);
                recordCell{m} = col_id(:);
                if isempty(col_id)
                    continue;
                end
                for n = 1:1:nWidth
                    rowRange = [3,yR(1)+resolution*(n-1),yR(1)+resolution*n];
                    ids = obj.collection.filterByFlag(filterFunc,rowRange,col_id);
                    if ~isempty(ids)
                        values = obj.collection.getFieldByIds(ids,fieldName);
                        imMat(n,m) = procValueFunc(values);
                    end
                end
            end
            imagesc(hAxes,imresize(imMat,resizeRate)); colormap('jet');
            hAxes.CLim = clim;
            hAxes.YDir = 'normal';
            xlim(hAxes,[0.5,nWidth*resizeRate+0.5]);
            ylim(hAxes,[0.5,nWidth*resizeRate+0.5]);
            title(hAxes,fieldName);
            hAxes.Visible = 'off';
        end
        
        function [x,y,u,v] = piv(obj,hAxes,resolution,isNor)
            [xR,yR,nWidth] = obj.resolution2range(resolution);
            [x,y] = meshgrid(1:nWidth);
            [u,v] = deal(zeros(nWidth));
            filterFunc = @(flags,apos)(GridBasedModel.isInRange(flags(:,apos(1)),apos(2),apos(3)));
            recordCell = cell(nWidth,1);
            for m = 1:1:nWidth
                colRange = [2,xR(1)+resolution*(m-1),xR(1)+resolution*m];
                col_id = obj.collection.filterByFlag(filterFunc,colRange,cell2mat(recordCell),0);
                recordCell{m} = col_id(:);
                if isempty(col_id)
                    continue;
                end
                for n = 1:1:nWidth
                    rowRange = [3,yR(1)+resolution*(n-1),yR(1)+resolution*n];
                    ids = obj.collection.filterByFlag(filterFunc,rowRange,col_id);
                    if ~isempty(ids)
                        values = obj.collection.getFieldByIds(ids,'dir');
                        [u(n,m),v(n,m)] = PointBasedModel.dirs2arrow(values,isNor);
                    end
                end
            end
            quiver(hAxes,x,y,u,v);
        end
        
        function [values] = getProp(obj,fieldName)
            v = obj.collection.getFieldByIds(1:1:obj.agentNum,fieldName);
            values = cell2mat(v);
        end
        
        function instance = childModel(obj,ids)
            rangeContainer = struct;
            rangeContainer.xRange = obj.pd.xRange;
            rangeContainer.yRange = obj.pd.yRange;
            instance = PointBasedModel(rangeContainer,obj.deltaT,obj.halfWindowLength);
            instance.setCollection(obj.collection.copy(ids));
        end
    end
    
    methods(Access = private)
        function makeAgent(obj,rawMat)
            L = size(rawMat,1);
            agNum = L - 2 * obj.halfWindowLength;
            indices = bsxfun(@plus,(1:1:(2*obj.halfWindowLength+1))',0:1:(agNum-1));
            for m = 1:1:agNum
                subMat = rawMat(indices(:,m),:);
                agent = TrajSegAgent(subMat(:,2:3),subMat(obj.halfWindowLength+1,1),...
                                     subMat(obj.halfWindowLength+1,[2,3]),obj.deltaT);
                obj.collection.addAgent(agent,subMat(obj.halfWindowLength+1,:));
            end
        end
        
        function [xR,yR,nWidth] = resolution2range(obj,resolution)
            xR = resolution * [floor(obj.pd.xRange(1)/resolution),ceil(obj.pd.xRange(2)/resolution)];
            yR = resolution * [floor(obj.pd.yRange(1)/resolution),ceil(obj.pd.yRange(2)/resolution)];
            nWidth = ceil(max(range(xR)/resolution,range(yR)/resolution));
        end
    end
    
    methods(Static)
        function [u,v] = dirs2arrow(dirCell,isNor)
            dirs = cell2mat(dirCell);
            if isNor
                dirs = dirs./repmat(sqrt(sum(dirs.^2,2)),1,2);
            end
            uv = mean(dirs,1);
            u = uv(1); v=uv(2);
        end
    end
    
end

