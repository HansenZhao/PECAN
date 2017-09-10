classdef AgentProp < double
    enumeration
        AVE_VEL (1)
        D (2)
        ALPHA (3)
        ASYM (4)
        X (5)
        Y (6)
        DIR_X (7)
        DIR_Y (8)
        N_DIR_X (9)
        N_DIR_Y (10)
    end
    
    methods(Static)
        function enum = FieldName2Enum(fieldName)
            switch fieldName
                case 'ave_Vel'
                    enum = AgentProp.AVE_VEL;
                case 'D'
                    enum = AgentProp.D;
                case 'alpha'
                    enum = AgentProp.ALPHA;
                case 'asym'
                    enum = AgentProp.ASYM;
                case 'x'
                    enum = AgentProp.X;
                case 'y'
                    enum = AgentProp.Y;
                case 'dir_x'
                    enum = AgentProp.DIR_X;
                case 'dir_y'
                    enum = AgentProp.DIR_Y;
                case 'n_dir_x'
                    enum = AgentProp.N_DIR_X;
                case 'n_dir_y'
                    enum = AgentProp.N_DIR_Y;
                otherwise
                    enum = fieldName;
            end
        end        
    end
end

