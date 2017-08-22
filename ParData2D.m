classdef ParData2D < handle
    %ParData2D Summary of this class goes here
    %   particle data container
    %   raw data should be in standard format n-by-4 matrix
    %   |particle_id|frame|x|y|
    
    properties
        ids;
    end
    
    properties(Access = private)
        parCell;
    end
    
    properties(Dependent)
        particleNum;
        minTraceLength;
    end
    
    methods
        % constrctor
        function obj = ParData2D(raw)   
            obj.ids = unique(raw(:,1));
            obj.parCell = cell(obj.particleNum,1);
            h = waitbar(0,'fixing dis-contunue trace...');
            for m = 1:1:obj.particleNum
                parTrace = raw(raw(:,1)==obj.ids(m),2:4);
                [bugNum,parTrace] = ParData2D.fixFrameDisContinue(parTrace,0);
                waitbar(m/obj.particleNum,h,sprintf('fix %d bugs',bugNum));
                obj.parCell{m} = parTrace;             
            end
            close(h);
        end
        
        function parNum = get.particleNum(obj)
            parNum = length(obj.ids);
        end
        
        function minTL = get.minTraceLength(obj)
            minTL = inf;
            for m = 1:1:obj.particleNum
                minTL = min(size(obj.parCell{m},1),minTL);
            end
        end
        
        function parMat = getRawMatById(obj,id,varargin)
            if isempty(varargin)
                colIndex = 1:1:3;
            else
                colIndex = varargin{1};
            end
            [~,I] = ismember(id,obj.ids);
            if I > 0
                parMat = obj.parCell{I}(:,colIndex);
            else
                fprintf(1,'Cannot find id: %s\n',id);
                parMat = [];
            end
        end
        
        function setDataById(obj,id,dataMat)
            [~,I] = ismember(id,obj.ids);
            if I > 0
                obj.parCell{I} = dataMat;
            else
                fprintf(1,'Cannot find id: %s\n',id);
            end
        end
    end
    
    methods(Access = private)
    end
    methods(Static)
        %|frame|x|y|
        function index = checkFrame(dataMat)
            [nRow,nCol] = size(dataMat);
            if nCol ~= 3
                disp('dataMat should in |frame|X|Y|');
            end
            index = 1:1:(nRow-1);
            index = index(dataMat(2:end,1) - dataMat(1:(end-1),1) ~= 1);
        end
        
        function [bugNum,fixedMat] = fixFrameDisContinue(dataMat,isDebug)
            bugIndices = ParData2D.checkFrame(dataMat);
            bugNum = length(bugIndices);
            while(~isempty(bugIndices))
                bugIndex = bugIndices(1);
                if bugIndex > 1
                    dataMat = [dataMat(1:(bugIndex-1),:);...
                               ParData2D.interpMat(dataMat(bugIndex:(bugIndex+1),:),isDebug);...
                               dataMat((bugIndex+2):end,:)];
                else
                    dataMat = [ParData2D.interpMat(dataMat(1:2,:),isDebug);...
                               dataMat(3:end,:)];
                end
                bugIndices = ParData2D.checkFrame(dataMat);
            end
            fixedMat = dataMat;
        end
        
        function res = interpMat(oriMat,isDebug)
            if isDebug
                disp('fix segment:');
                disp(oriMat);
            end
            startFrame = oriMat(1,1);
            endFrame = oriMat(2,1);
            interpMat = [(startFrame:1:endFrame)',zeros(endFrame-startFrame+1,2)];
            interpMat(:,2) = interp1(oriMat(:,1),oriMat(:,2),interpMat(:,1),'linear');
            interpMat(:,3) = interp1(oriMat(:,1),oriMat(:,3),interpMat(:,1),'linear');
            if isDebug       
                disp('to');
                disp(interpMat);
            end
            res = interpMat;
        end
    end
    
end

