classdef TrajSegAgent < handle
    %TrajSegAgent Trajectory Segment Agent
    
    properties(GetAccess = public, SetAccess = private)
        traj;
        aveVel;
        dir;
        msdCurve;
        alpha;
        D;
        asym;
        Smss;
        gridPos;
        frame;
        deltaT;
        lag;
        maxP;
        mean_dir_change;
        parentID;
    end
    
    properties(Dependent)
        segLength;
        x;
        y;
        n_dir_x;
        n_dir_y;
        dir_x;
        dir_y;
    end
    
    methods
        function obj = TrajSegAgent(id,seg,frame,gridPos,deltaT,varargin)
            obj.parentID = id;
            obj.traj = seg;
            obj.frame = frame;
            obj.gridPos = gridPos;
            obj.deltaT = deltaT;
            if isempty(varargin)
                obj.lag = min(20,floor(obj.segLength/2)); obj.maxP = 6;
            elseif nargin == 5
                obj.maxP = varargin{1}; obj.lag = min(20,floor(obj.segLength/3));
            elseif nargin == 6
                obj.maxP = varargin{1}; obj.lag = varargin{2};
            end
        end
        
        function sL = get.segLength(obj)
            sL = size(obj.traj,1);
        end
        
        function posX = get.x(obj)
            posX = mean(obj.traj(:,1));
        end
        
        function posY = get.y(obj)
            posY = mean(obj.traj(:,2));
        end
        
        function ndx = get.n_dir_x(obj)
            ndx = obj.dir(1)/sqrt(obj.dir*(obj.dir'));
        end
        
        function ndy = get.n_dir_y(obj)
            ndy = obj.dir(2)/sqrt(obj.dir*(obj.dir'));
        end
        
        function dx = get.dir_x(obj)
            dx = obj.dir(1);
        end
        
        function dy = get.dir_y(obj)
            dy = obj.dir(2);
        end
        
        function calSelf(obj)
            obj.aveVel = mean(TrajAnalysis2D.xy2vel(obj.traj,obj.deltaT,0));
            obj.dir = obj.traj(end,:) - obj.traj(1,:);
            if obj.segLength > 2
                dxy = obj.traj(2:end,:) - obj.traj(1:(end-1),:);
                vec_a = dxy(2:end,:); vec_b = dxy(1:(end-1),:);
                cos_theta = sum((vec_a .* vec_b),2)./(sqrt(sum(vec_a.^2,2)) .* sqrt(sum(vec_b.^2,2)));
                obj.mean_dir_change = mean(cos_theta);
            else
                obj.mean_dir_change = nan;
            end
            
            if obj.segLength > 6           
                obj.msdCurve = [eps,TrajAnalysis2D.xy2msd(obj.traj,obj.lag,2)];
                t = [eps,(1:1:obj.lag)*obj.deltaT];
                %[obj.alpha,obj.D] = TrajAnalysis2D.fitMSDCurve(t,obj.msdCurve,0);
                fita = py.fit_curve.fit_msd(t(2:end),obj.msdCurve(2:end));
                obj.alpha = fita{2}; obj.D = fita{1};
                %obj.Smss = TrajAnalysis2D.xy2mss(seg,obj.lag,obj.maxP,0);  
            else
                obj.msdCurve = nan;
                obj.alpha = nan;
                obj.D = nan;
                obj.Smss = nan;
            end
            
            if obj.segLength > 3
                obj.asym = TrajAnalysis2D.xy2asym(obj.traj);
            else
                obj.asym = nan;
            end
        end
    end
    
end

