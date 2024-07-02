%--------------------------------------------------------------------------
% Create stencils for our House insulation problem
%--------------------------------------------------------------------------
% This class invokes the <bh_get_node_stencils> function to compute a table
% of stencils for the DIFFERENT node types in or design.
%
% A numeric stencil can be retrieved for a given NODE type and the NODE IDs
%--------------------------------------------------------------------------
% TEST SCRIPT:
%   see <bh_test_stencil.mlx>
%--------------------------------------------------------------------------
% TYPICAL USAGE:
%
%   OBJ_fd_stencils = bh_fd_stencil_CLS(OBJ_params)
% 
%   OBJ_fd_stencils.show(bh_fd_node_type_ENUM.G_BLK_B_INTERNAL,"symbolic")
% 
%   OBJ_fd_stencils.tab
% 
%   [A, b, x_str] = OBJ_fd_stencils.retrieve_Abx("G_BLK_B_INTERNAL", 1, 2)
%--------------------------------------------------------------------------
% HISTORY:
%   19-Jul-2021 : Created 
%--------------------------------------------------------------------------

classdef bh_fd_stencil_CLS
    
    properties(SetAccess = protected)
        tab
    end
%==========================================================================
    methods
        function obj = bh_fd_stencil_CLS(my_params)
            arguments
                my_params (1,1) bh_sys_params_CLS
            end
            
            obj.tab = bh_get_node_stencils(my_params);
        end
        %------------------------------------------------------------------
        function show(obj, node_type_enum, display_style)
            arguments
               obj            (1,1) bh_fd_stencil_CLS
               node_type_enum (1,1) bh_fd_node_type_ENUM
               display_style  (1,1) string {mustBeMember(display_style, ["symbolic","numeric","both"])}
            end
            
            node_str = string(node_type_enum);
            the_row  = obj.tab(node_str,:);
            
            switch(display_style)
                case "symbolic"
                      fprintf("\n %s \n *** SYMBOLIC *** A.x = b", repmat('-',1,30));
                      fprintf("\n --->  x ");    the_row.s_x{1}
                      fprintf("\n --->  A ");    the_row.s_A{1}
                      fprintf("\n --->  b ");    the_row.s_b{1}
                case "numeric"
                      fprintf("\n %s \n *** NUMERIC *** A.x = b", repmat('-',1,30));
                      fprintf("\n --->  x ");    the_row.s_x{1}
                      fprintf("\n --->  A ");    A_num = the_row{1,string(the_row.s_x{1})}
                      fprintf("\n --->  b ");    the_row.b
                      the_row.b
                case "both"
                    obj.show(node_type_enum, "symbolic")
                    obj.show(node_type_enum, "numeric")
            end
        end
        %------------------------------------------------------------------
        function [A, b, x_str] = retrieve_Abx(obj, node_str, m, n)
            arguments 
               obj
               node_str (1,1) string
               m        (1,1) double
               n        (1,1) double
            end
            
            the_row    = obj.tab(node_str,:);   
            
            T_str_list = the_row{1,"str_x"}{1};
            A_num      = the_row{1, T_str_list};
            
            % Dismiss columns with ZERO values
            tf_ZERO_COLS = A_num == 0;

            T_str_list(tf_ZERO_COLS)  = [];
            A_num(tf_ZERO_COLS)       = [];
            % Produce the list with tokens replaced by the values for m and n
            res_str_list = strings(1, length(T_str_list) );

             for kk=1:length(T_str_list)

                    THE_STR = T_str_list(kk);

                    switch(THE_STR)
                        case "T_mM1_nP1" 
                                         res_str_list(kk) = "T_" + (m-1) + "_" + (n+1);
                        case "T_m_nP1" 
                                         res_str_list(kk) = "T_" + (m) + "_"   + (n+1);
                        case "T_mP1_nP1"
                                         res_str_list(kk) = "T_" + (m+1) + "_" + (n+1);
                        case "T_mM1_n"  
                                         res_str_list(kk) = "T_" + (m-1) + "_" + (n); 
                        case "T_m_n" 
                                         res_str_list(kk) = "T_" + (m) + "_"   + (n);
                        case "T_mP1_n"
                                         res_str_list(kk) = "T_" + (m+1) + "_" + (n); 
                        case "T_mM1_nM1"
                                         res_str_list(kk) = "T_" + (m-1) + "_" + (n-1);
                        case "T_m_nM1" 
                                         res_str_list(kk) = "T_" + (m) + "_"   + (n-1);
                        case "T_mP1_nM1" 
                                         res_str_list(kk) = "T_" + (m+1) + "_" + (n-1); 
                        otherwise
                            error("###_ERROR:  Bad ! ")
                    end            
             end % for kk=1:length(new_str_list)
             
             % take care of the outputs
             A     = A_num;
             b     = the_row.b;
             x_str = res_str_list;
             
        end % function retrieve
        %------------------------------------------------------------------
    end % methods
%==========================================================================
end % classdef

