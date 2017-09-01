classdef ModelViewer < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        stepNum;
        currentStep;
    end

    properties(GetAccess = public, SetAccess = private)
        filePath;
        model;
        modelClass;
        pd;
        pa;
        hViewer
        plotSetting;
        modelAgentFrames;
        subModel
    end

    properties(Dependent)
        frameRange;
    end

    properties(Access = private)
        modelSetting;
        preprocessingSetting;
        sliceRegion;
    end

    methods
        function obj = ModelViewer()
            obj.hViewer = viewer(obj);
            obj.preprocessingSetting = struct();
            obj.setInfoText('Welcome to model viewer');
            obj.sliceRegion = [];
            obj.plotSetting = struct();
            obj.stepNum = 0;
            obj.currentStep = [];
            obj.modelAgentFrames = [];
        end

        function fr = get.frameRange(obj)
            fr = obj.model.pd.frameRange;
        end

        function setInfoText(obj,str)
            obj.hViewer.txt_info.String = str;
        end

        function boolRes = setModel(obj,modelName)
            obj.modelClass = modelName;
            if strcmp(obj.modelClass,'Point Based Model')
                prompt = {'delta t(s):','window half length:'};
                dlg_title = 'PBM';
                num_lines = 1;
                defaultAns = {'0.1','5'};
                obj.modelSetting = inputdlg(prompt,dlg_title,num_lines,defaultAns);
                if isempty(obj.modelSetting)
                    boolRes = 0;
                    return;
                end
            elseif strcmp(obj.modelClass,'Grid Based Model')
                prompt = {'delta t(s):','resolution(um)','minSegLength:','segTolerance:'};
                dlg_title = 'GBM';
                num_lines = 1;
                defaultAns = {'0.1','0.5','6','1'};
                obj.modelSetting = inputdlg(prompt,dlg_title,num_lines,defaultAns);
                if isempty(obj.modelSetting)
                    boolRes = 0;
                    return;
                end
            end
            boolRes = 1;
        end

        function boolRes = onLoad(obj)
            [fn,fp,index] = uigetfile('*.csv','please select data file...');
            if index
                obj.filePath = strcat(fp,fn);
                obj.setInfoText(sprintf('Reading: %s...',obj.filePath));
                raw = importdata(obj.filePath);
                raw = raw.data;
                try
                    inAns = inputdlg('Padding(um):','Loading...',1,{'0'});
                    obj.preprocessingSetting.padding = str2double(inAns{1});
                    obj.setInfoText('Parsing data...');
                    obj.pd = ParData2D(raw,obj.preprocessingSetting.padding);
                    obj.pa = TrajAnalysis2D(obj.pd,str2double(obj.modelSetting{1}));

                    inAns = inputdlg({'threshold:','tolerance:','iterTime:'},...
                                      'Outlier filter',1,{'12','0.5','10'});
                    obj.preprocessingSetting.outlierThres = str2double(inAns{1});
                    obj.preprocessingSetting.outlierToler = str2double(inAns{2});
                    obj.preprocessingSetting.outlierIter = str2double(inAns{3});
                    obj.setInfoText('Filter out outlier velocity...');
                    obj.pa.filterOutlierVel(obj.preprocessingSetting.outlierThres,...
                                            obj.preprocessingSetting.outlierToler,...
                                            0,obj.preprocessingSetting.outlierIter);

                    inAns = inputdlg('tolerance:','Zero filter',1,{'0.7'});
                    obj.preprocessingSetting.zerosThres = str2double(inAns{1});
                    obj.setInfoText('Filter out zero velocity...');
                    obj.pa.filterZeroVel(obj.preprocessingSetting.zerosThres);
                    obj.setInfoText('Load Done!');

                    obj.hViewer.txt_frame.String = sprintf('%d : %d',...
                                                         obj.pd.frameRange(1),...
                                                         obj.pd.frameRange(2));

                    obj.setInfoText('Paring to model...');
                    if strcmp(obj.modelClass,'Point Based Model')
                        obj.model = PointBasedModel(obj.pd,str2double(obj.modelSetting{1}),...
                                                           str2double(obj.modelSetting{2}));
                    elseif strcmp(obj.modelClass,'Grid Based Model')
                        obj.model = GridBasedModel(obj.pd,str2double(obj.modelSetting{1}),...
                                                          str2double(obj.modelSetting{2}),...
                                                          str2double(obj.modelSetting{3}),...
                                                          str2double(obj.modelSetting{4}));
                    end
                    obj.pd.plotTrace(obj.hViewer.main_axes,obj.pd.ids,0);
                    boolRes = 1;
                    return;
                catch e
                    throw(e);
                end
            end
            boolRes = 0;
        end

        function onClear(obj)
            obj.preprocessingSetting = struct();
            obj.modelSetting = struct();
            obj.pd = [];
            obj.pd = [];
            obj.model = [];
            obj.modelClass = [];
        end

        function boolRes = onSliceEdit(obj,str)
            try
                number = strsplit(str,' ');
                obj.sliceRegion = [str2double(number{1}),str2double(number{2}),...
                                   str2double(number{3}),str2double(number{4})];
                boolRes = 1;
            catch
                boolRes = 0;
            end
        end

        function onSlice(obj)
            if isempty(obj.sliceRegion)
                return;
            end
            xlim(obj.hViewer.main_axes,obj.sliceRegion([1,3]));
            ylim(obj.hViewer.main_axes,obj.sliceRegion([2,4]));
        end

        function boolRes = onFieldNameSet(obj,str)
            try
                if isfield(obj.plotSetting,'fieldName')
                    obj.plotSetting.fieldName = str;
                    obj.onRefresh();
                else
                    obj.plotSetting.fieldName = str;
                end
                boolRes = 1;
            catch
                boolRes = 0;
            end
        end

        function boolRes = onMethodSet(obj,str)
            try
                if isfield(obj.plotSetting,'method')
                    obj.plotSetting.method = str;
                    obj.onRefresh();
                else
                    obj.plotSetting.method = str;
                end
                boolRes = 1;
            catch
                boolRes = 0;
            end
        end

        function boolRes = onStepNumberSet(obj,num)
          try
            obj.stepNum = str2double(num);
            if ~isempty(obj.currentStep)
                obj.currentStep(2) = obj.currentStep(1) + obj.stepNum;
            end
            if obj.currentStep(2) > obj.frameRange(2)
                obj.currentStep = [obj.frameRange(1),obj.frameRange(1)+obj.stepNum];
            end
            obj.hViewer.txt_current.String = sprintf('%d to %d',obj.currentStep(:));
            obj.updateSubModel();
            obj.onRefresh();
            boolRes = 1;
          catch
            boolRes = 0;
          end
        end

        function boolRes = onClimSet(obj,clim)
          str = strsplit(clim,' ');
          try
              if isfield(obj.plotSetting,'clim')
                  obj.plotSetting.clim = [str2double(str{1}),str2double(str{2})];
                  obj.onRefresh;
              else
                  obj.plotSetting.clim = [str2double(str{1}),str2double(str{2})];
              end
              boolRes = 1;
          catch
              boolRes = 0;
          end
        end

        function boolRes = onInterpSet(obj,interp)
          try
              if isfield(obj.plotSetting,'interp')
                  obj.plotSetting.interp = str2double(interp);
                  obj.onRefresh();
              else
                  obj.plotSetting.interp = str2double(interp);
              end
              boolRes = 1;
          catch
              boolRes = 0;
          end
        end

        function onRefresh(obj)
            L = length(fieldnames(obj.plotSetting));
            obj.hViewer.txt_info.String = 'Begin Drawing...';
            if strcmp(obj.modelClass,'Point Based Model')
                if L==5
                    obj.subModel.spatialPlot(obj.hViewer.main_axes,obj.plotSetting.resolution,...
                        obj.plotSetting.fieldName,obj.plotSetting.method,obj.plotSetting.interp,...
                        obj.plotSetting.clim);
                else
                    obj.pd.plotTrace(obj.hViewer.main_axes,obj.pd.ids);
                end
            elseif strcmp(obj.modelClass,'Grid Based Model')
                if L==4
                    obj.subModel.spatialPlot(obj.hViewer.main_axes,obj.plotSetting.fieldName,...
                        obj.plotSetting.method,obj.plotSetting.interp,obj.plotSetting.clim);
                else
                    obj.pd.plotTrace(obj.hViewer.main_axes,obj.pd.ids);
                end
            end
            obj.hViewer.txt_info.String = 'Drawing done';
        end

        function boolRes = onResSet(obj,res)
          try
              if isfield(obj.plotSetting,'resolution')
                  obj.plotSetting.resolution = str2double(res);
                  obj.onRefresh();
              else
                  obj.plotSetting.resolution = str2double(res);
              end
              boolRes = 1;
          catch
            boolRes = 0;
          end
        end

        function updatePAModel(obj)
          obj.pa = TrajAnalysis2D(obj.pd,str2double(obj.modelSetting{1}));
          if strcmp(obj.modelClass,'Point Based Model')
              obj.model = PointBasedModel(obj.pd,str2double(obj.modelSetting{1}),...
                                                 str2double(obj.modelSetting{2}));
          elseif strcmp(obj.modelClass,'Grid Based Model')
              obj.model = GridBasedModel(obj.pd,str2double(obj.modelSetting{1}),...
                                                str2double(obj.modelSetting{2}),...
                                                str2double(obj.modelSetting{3}),...
                                                str2double(obj.modelSetting{4}));
          end
        end

        function boolRes = onConfirm(obj)
            try
                outAns = inputdlg('estimate capacity:','Model Parse',1,{'1000'});
                obj.pd = obj.pd.copy(obj.pd.selectByRegion(obj.sliceRegion));
                obj.updatePAModel();
                obj.onRefresh();
                obj.model.parse(str2double(outAns{1}));
                obj.subModel = obj.model.childModel();
                boolRes = 1;
            catch e
                throw(e);
            end
        end

        function onNext(obj)
            if obj.stepNum
                if isempty(obj.currentStep)
                    obj.currentStep = [obj.frameRange(1),obj.frameRange(1)+obj.stepNum];
                else
                    obj.currentStep = obj.currentStep + 1;
                end
                if obj.currentStep(2) > obj.frameRange(2)
                    obj.currentStep = [obj.frameRange(1),obj.frameRange(1)+obj.stepNum];
                end
                obj.hViewer.txt_current.String = sprintf('%d to %d',obj.currentStep(:));
                obj.updateSubModel();
                obj.onRefresh();
            end
        end

        function onLast(obj)
            if obj.stepNum
                if isempty(obj.currentStep)
                    obj.currentStep = [obj.frameRange(1),obj.frameRange(1)+obj.stepNum];
                else
                    obj.currentStep = obj.currentStep - 1;
                end
                if obj.currentStep(1) < obj.frameRange(1)
                    obj.currentStep = [obj.frameRange(1)-obj.stepNum,obj.frameRange(2)];
                end
                obj.hViewer.txt_current.String = sprintf('%d to %d',obj.currentStep(:));
                obj.updateSubModel();
                obj.onRefresh();
            end
        end

    end

    methods(Access = private)
        function updateSubModel(obj)
            if isempty(obj.modelAgentFrames)
              obj.modelAgentFrames = obj.model.getProp('frame');
            end
            ids = 1:1:obj.model.agentNum;
            ids = ids(and(obj.modelAgentFrames>=obj.currentStep(1),...
                          obj.modelAgentFrames<=obj.currentStep(2)));
            obj.subModel = obj.model.childModel(ids);
        end
    end

end
