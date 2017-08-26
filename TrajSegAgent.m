classdef TrajSegAgent < handle
    %TrajSegAgent Trajectory Segment Agent
    
    properties(GetAccess = public, SetAccess = private)
        traj;
        aveVel;
        dir;
        msdCurve;
        alpha;
        D;
        aysm;
        Smss;
        gridPos;
        frame;
        deltaT;
    end
    
    properties(Dependent)
        segLength;
    end
    
    methods
        function obj = TrajSegAgent(seg,frame,gridPos,deltaT,varargin)
            obj.traj = seg;
            obj.frame = frame;
            obj.gridPos = gridPos;
            obj.deltaT = deltaT;
            obj.aveVel = mean(TrajAnalysis2D.xy2vel(seg,obj.deltaT,0));
            obj.dir = seg(end,:) - seg(1,:);
            
            if obj.segLength > 6           
                if isempty(varargin)
                    lag = min(20,floor(obj.segLength/2)); maxP = 6;
                elseif nargin == 5
                    maxP = varargin{1}; lag = min(20,floor(obj.segLength/3));
                elseif nargin == 6
                    maxP = varargin{1}; lag = varargin{2};
                end

                obj.msdCurve = [eps,TrajAnalysis2D.xy2msd(seg,lag,2)];
                t = [eps,(1:1:lag)*obj.deltaT];
                [obj.alpha,obj.D] = TrajAnalysis2D.fitMSDCurve(t,obj.msdCurve,0);
                obj.Smss = TrajAnalysis2D.xy2mss(seg,lag,maxP,0);  
            else
                obj.msdCurve = nan;
                obj.alpha = nan;
                obj.D = nan;
                obj.Smss = nan;
            end
            
            if obj.segLength > 3
                obj.aysm = TrajAnalysis2D.xy2asym(seg);
            else
                obj.aysm = nan;
            end
        end
        
        function sL = get.segLength(obj)
            sL = size(obj.traj,1);
        end
    end
    
end

