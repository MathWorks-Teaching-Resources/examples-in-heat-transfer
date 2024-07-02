classdef bh_sys_params_CLS  
    properties(SetAccess = protected)
        Filename
        Sheetname
        my_tab
        %----------------------------------
        k_A  
        k_B    
        k_C  
        h_ROOF 
        h_CEIL 
        T_ROOF 
        T_CEIL
        %----------------------------------
        xLA
        xLB
        xLC
        yLA
        yLB
        yLC      
        %----------------------------------
        Nx_A
        Nx_B
        Nx_C
        Ny_A
        Ny_B
        Ny_C
    end
    
    properties
        Delta_X  
        Delta_Y 
    end
    
    
    methods
        function OBJ = bh_sys_params_CLS(Filename, Sheetname)
            arguments
               Filename  (1,1) string 
               Sheetname (1,1) string
            end
            
            OBJ.Filename  = Filename;
            OBJ.Sheetname = Sheetname;
            
            OBJ.my_tab = LOC_read_EXCEL_file(OBJ);
            %----------------------------------------
            OBJ.k_A    =  OBJ.my_tab{"ceil_k" ,  "Value"};
            OBJ.k_B    =  OBJ.my_tab{"joist_k",  "Value"};
            OBJ.k_C    =  OBJ.my_tab{"batt_k" ,  "Value"};
            OBJ.h_ROOF =  OBJ.my_tab{"roof_h",   "Value"};
            OBJ.h_CEIL =  OBJ.my_tab{"ceil_h",   "Value"};
            OBJ.T_ROOF =  OBJ.my_tab{"roof_T",   "Value"};
            OBJ.T_CEIL =  OBJ.my_tab{"ceil_T",   "Value"};
            
            OBJ.xLB    =  0.5 * OBJ.my_tab{"joist_width",  "Value"};
            OBJ.xLC    =  0.5 * OBJ.my_tab{"batt_width",  "Value"};
            OBJ.xLA    =  OBJ.xLB + OBJ.xLC;
            OBJ.yLB    =        OBJ.my_tab{"joist_height",  "Value"};
            OBJ.yLC    =        OBJ.my_tab{"batt_height",  "Value"};
            OBJ.yLA    =        OBJ.my_tab{"ceil_height",  "Value"};
            
            %OBJ.my_tab.Name = 
        end % bh_sys_params_CLS
        %------------------------------------------------------------------
        function obj = set_deltas(obj, dx, dy)
            obj.Delta_X = dx;
            obj.Delta_Y = dy;
            
            obj.Nx_A = round(obj.xLA / dx);
            obj.Nx_B = round(obj.xLB / dx);
            obj.Nx_C = round(obj.xLC / dx);
            
            obj.Ny_A = round(obj.yLA / dy);
            obj.Ny_B = round(obj.yLB / dy);
            obj.Ny_C = round(obj.yLC / dy);
            
            my_TOL = 1.1e-3;
            
            NEW_xLA = obj.Nx_A * obj.Delta_X;  diff_xLA = abs(obj.xLA - NEW_xLA);
            NEW_xLB = obj.Nx_B * obj.Delta_X;  diff_xLB = abs(obj.xLB - NEW_xLB);
            NEW_xLC = obj.Nx_C * obj.Delta_X;  diff_xLC = abs(obj.xLC - NEW_xLC);
            
            NEW_yLA = obj.Ny_A * obj.Delta_Y;  diff_yLA = abs(obj.yLA - NEW_yLA);
            NEW_yLB = obj.Ny_B * obj.Delta_Y;  diff_yLB = abs(obj.yLB - NEW_yLB);
            NEW_yLC = obj.Ny_C * obj.Delta_Y;  diff_yLC = abs(obj.yLC - NEW_yLC);
            
            fprintf("\n%s\n TESTING discretization on component lengths \n%s", repmat('-',1,50), repmat('-',1,50) );
            fprintf("\n ... xLA diff = %7.4f (m), [%7.4f ---> %7.4f]", diff_xLA, obj.xLA, NEW_xLA);
            fprintf("\n ... xLB diff = %7.4f (m), [%7.4f ---> %7.4f]", diff_xLB, obj.xLB, NEW_xLB);
            fprintf("\n ... xLC diff = %7.4f (m), [%7.4f ---> %7.4f]", diff_xLC, obj.xLC, NEW_xLC);
            fprintf("\n ... yLA diff = %7.4f (m), [%7.4f ---> %7.4f]", diff_yLA, obj.yLA, NEW_yLA);
            fprintf("\n ... yLB diff = %7.4f (m), [%7.4f ---> %7.4f]", diff_yLB, obj.yLB, NEW_yLB);
            fprintf("\n ... yLC diff = %7.4f (m), [%7.4f ---> %7.4f]", diff_yLC, obj.yLC, NEW_yLC);
            fprintf("\n%s\n", repmat('-',1,50) );      
            
            % if the difference is too large then error out !
            assert(diff_xLA < my_TOL, "###_ERROR:  dx bad for xLA");
            assert(diff_xLB < my_TOL, "###_ERROR:  dx bad for xLB");
            assert(diff_xLC < my_TOL, "###_ERROR:  dx bad for xLC");
            assert(diff_yLA < my_TOL, "###_ERROR:  dy bad for yLA");
            assert(diff_yLB < my_TOL, "###_ERROR:  dy bad for yLB");
            assert(diff_yLC < my_TOL, "###_ERROR:  dy bad for yLC");
        end
        %------------------------------------------------------------------
    end % methods
end % classdef
%_#########################################################################
function my_tab = LOC_read_EXCEL_file(OBJ)

    opts = detectImportOptions(OBJ.Filename, "Sheet", OBJ.Sheetname);  
    
    opts = setvaropts(opts, ["Name", "Units", "Description", "Comments"], ...
                            'Type', 'string' );
    
    my_tab = readtable(OBJ.Filename, opts);
    
    % allow ROWNAMES to be usde as an index
    my_tab.Properties.RowNames = my_tab.Name;
end
