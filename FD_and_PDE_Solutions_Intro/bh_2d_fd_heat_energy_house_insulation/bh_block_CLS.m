%--------------------------------------------------------------------------
% Generate a block of nodes
%--------------------------------------------------------------------------
% Nodes count from ZERO and end at Nx or Ny
%  therefore Nx also represents the NUMBER of intervals in the X direction
%  therefore Ny also represents the NUMBER of intervals in the Y direction
% The block face and corners are labelled according to an observer
% at the center of the block, eg:
%    the SOUTH_WEST corner has the co-ordinates i=0, j=0
%    the WEST_FACE has an i node co-ordinate of 0
%    the EAST_FACE has an i node co-ordinate of NX
%    the NORTH_FACE has an j node co-ordinate of Ny
%    the SOUTH_FACE has an j node co-ordinate of 0
%
% The main data container in this class is a TABLE with the following
% columns:
%       obj.tab.i_local       = zeros(N,1);   % local  i ID
%       obj.tab.j_local       = zeros(N,1);   % local  j ID
%       obj.tab.i_global      = zeros(N,1);   % global i ID
%       obj.tab.j_global      = zeros(N,1);   % global j ID
%       obj.tab.is_active     = true(N,1);    % a LOGICAL
%       obj.tab.node_type_blk = strings(N,1); % a string conversion of bh_block_node_type_ENUM
%--------------------------------------------------------------------------
% TEST SCRIPT:
%   see <bh_test_block.mlx>
%--------------------------------------------------------------------------
% TYPICAL USAGE:
%     Nx       = 10;
%     Ny       = 4;
% 
%     i_offset = 5;
%     j_offset = 3;
% 
%     obj = bh_block_CLS(Nx, Ny,"i_offset",i_offset,"j_offset",j_offset);
%--------------------------------------------------------------------------
% HISTORY:
%   19-Jul-2021 : Created 
%--------------------------------------------------------------------------

classdef bh_block_CLS
    properties
        Name (1,1) string
    end
    
    properties (SetAccess = protected)
        Nx  (1,1) double
        Ny  (1,1) double
        tab (:,:) table
    end
%==========================================================================
    methods
        function obj = bh_block_CLS(Nx,Ny, options)
          arguments
             Nx               (1,1) double
             Ny               (1,1) double
             options.dx       (1,1) double = 1
             options.dy       (1,1) double = 1
             options.i_offset (1,1) double = 0
             options.j_offset (1,1) double = 0              
          end
                        
          obj.Nx                = Nx;
          obj.Ny                = Ny;
          
          obj.tab               = table;
          N                     = (Nx+1) * (Ny+1);
          obj.tab.i_local       = zeros(N,1);
          obj.tab.j_local       = zeros(N,1);
          obj.tab.i_global      = zeros(N,1);
          obj.tab.j_global      = zeros(N,1);
          obj.tab.is_active     = true(N,1);
          obj.tab.node_type_blk = strings(N,1);
                     
          tmp_i_local          = zeros(N,1);
          tmp_j_local          = zeros(N,1);
          tmp_i_global         = zeros(N,1);
          tmp_j_global         = zeros(N,1);
          
            for jj = 1:(Ny+1)
                for ii = 1:(Nx+1)
                     n = (jj-1)*(Nx+1) + ii;
                     
                     tmp_i_local(n)       = ii-1;
                     tmp_j_local(n)       = jj-1;
                     tmp_i_global(n)      = tmp_i_local(n)  + options.i_offset;
                     tmp_j_global(n)      = tmp_j_local(n)  + options.j_offset; 
                     
                    % REALLy REALLY SLOW code
                    %---------------------------------------------------------------------------
                    %                     
                    %                     obj.tab.i_local(n) = ii-1;
                    %                     obj.tab.j_local(n) = jj-1;
                    %                     
                    %                     obj.tab.i_global(n) = obj.tab.i_local(n)  + options.i_offset;
                    %                     obj.tab.j_global(n) = obj.tab.j_local(n)  + options.j_offset; 
                    %---------------------------------------------------------------------------
                end % for ii
            end % for jj
            
            obj.tab.i_local       = tmp_i_local;
            obj.tab.j_local       = tmp_j_local;
            obj.tab.i_global      = tmp_i_global;
            obj.tab.j_global      = tmp_j_global;
               
            % Specify the ***** BLOCK_NODE_TYPE *****
            
            % Let everything be an INTERNAL node ... then correct the
            % BOUNDARY and CORNERS
            tf_ind = true(N,1);
            obj.tab.node_type_blk(tf_ind) = string(bh_block_node_type_ENUM.INTERNAL);
                       
            % take care of the BOUNDARIES of the block
            tf_ind =  obj.tab.i_local == 0;
             obj.tab.node_type_blk(tf_ind)     = string(bh_block_node_type_ENUM.BC_WEST);
             
            tf_ind =  obj.tab.i_local == Nx;
             obj.tab.node_type_blk(tf_ind)     = string(bh_block_node_type_ENUM.BC_EAST);
             
            tf_ind =  obj.tab.j_local == 0;
             obj.tab.node_type_blk(tf_ind)     = string(bh_block_node_type_ENUM.BC_SOUTH);
              
            tf_ind =  obj.tab.j_local == Ny;
             obj.tab.node_type_blk(tf_ind)     = string(bh_block_node_type_ENUM.BC_NORTH);
             
            % take care of the CORNERS of the block
            tf_ind = (obj.tab.i_local == 0) & (obj.tab.j_local == 0);
             obj.tab.node_type_blk(tf_ind) = string(bh_block_node_type_ENUM.BC_CORNER_SW);
                
            tf_ind = (obj.tab.i_local == 0) & (obj.tab.j_local == Ny);
             obj.tab.node_type_blk(tf_ind) = string(bh_block_node_type_ENUM.BC_CORNER_NW);
                
            tf_ind = (obj.tab.i_local == Nx) & (obj.tab.j_local == 0);
             obj.tab.node_type_blk(tf_ind)     = string(bh_block_node_type_ENUM.BC_CORNER_SE);
            
            tf_ind = (obj.tab.i_local == Nx) & (obj.tab.j_local == Ny);
             obj.tab.node_type_blk(tf_ind)     = string(bh_block_node_type_ENUM.BC_CORNER_NE);
                     
        end % bh_fd_block_CLS
        %------------------------------------------------------------------
        function plot(obj,type_str, options)
           arguments
               obj
               type_str (1,1) string {mustBeMember(type_str, ...
                       ["Local_ij", "Global_ij", "Local_ij_active","Global_ij_active"])} ...
                       = "Local_ij"
               options.Parent (1,1) = axes;
           end
            
           hax = options.Parent;
           axes(hax);
           hold(hax,'on');
           
           switch(upper(type_str))
               case "LOCAL_IJ"
                     T     = obj.tab;
                     x_min = min(T.i_local);
                     x_max = max(T.i_local);
                     y_min = min(T.j_local);
                     y_max = max(T.j_local);
                     
                     x_list = T.i_local;
                     y_list = T.j_local;
                     nodes  = T.node_type_blk;
               case "GLOBAL_IJ"
                     T     = obj.tab;
                     x_min = min(T.i_global);
                     x_max = max(T.i_global);
                     y_min = min(T.j_global);
                     y_max = max(T.j_global);
                     
                     x_list = T.i_global;
                     y_list = T.j_global;
                     nodes  = T.node_type_blk;
               case "LOCAL_IJ_ACTIVE"
                     tf_ind= obj.tab.is_active == true;
                     T     = obj.tab(tf_ind,:);
                     x_min = min(T.i_local);
                     x_max = max(T.i_local);
                     y_min = min(T.j_local);
                     y_max = max(T.j_local);
                     
                     x_list = T.i_local;
                     y_list = T.j_local;
                     nodes  = T.node_type_blk;
               case "GLOBAL_IJ_ACTIVE"
                     tf_ind= obj.tab.is_active == true;
                     T     = obj.tab(tf_ind,:);
                     x_min = min(T.i_global);
                     x_max = max(T.i_global);
                     y_min = min(T.j_global);
                     y_max = max(T.j_global);
                     
                     x_list = T.i_global;
                     y_list = T.j_global;
                     nodes  = T.node_type_blk;
               otherwise
                   error("###_ERROR:  UNknown plot type REQUESTED !");
           end
           
         % now plot ALL of the nodes 
         plot(x_list, y_list, '.b');

         % plot the block BOUNDARY nodes with BIGGER markers
         ind = nodes == string(bh_block_node_type_ENUM.BC_NORTH);                     
         plot(x_list(ind), y_list(ind), '.r', "MarkerSize",15);
         
         ind = nodes == string(bh_block_node_type_ENUM.BC_SOUTH);                     
         plot(x_list(ind), y_list(ind), '.c', "MarkerSize",15);
         
         ind = nodes == string(bh_block_node_type_ENUM.BC_EAST);                     
         plot(x_list(ind), y_list(ind), '.g', "MarkerSize",15);
         
         ind = nodes == string(bh_block_node_type_ENUM.BC_WEST);                     
         plot(x_list(ind), y_list(ind), '.k', "MarkerSize",15);

         % plot the block CORNER nodes with EVEN BIGGER markers
         ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_CORNER_SW);                     
         plot(x_list(ind), y_list(ind), '.y', "MarkerSize",30);
         
         ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_CORNER_SE);                     
         plot(x_list(ind), y_list(ind), '.m', "MarkerSize",30);
         
         ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_CORNER_NE);                     
         plot(x_list(ind), y_list(ind), '.k', "MarkerSize",30);
         
         ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_CORNER_NW);                     
         plot(x_list(ind), y_list(ind), '.b', "MarkerSize",30);
           
         % set limits
         xlim([0, x_max]);
         ylim([0, y_max]);
         grid("on");  
        end % plot
        %------------------------------------------------------------------
        function res_tab = get_subtable(obj, style_str)
           arguments
              obj
              style_str (1,1) string             
           end
            
           mustBeMember(style_str, ...
                 ["NODES_INTERNAL", ...
                  "NODES_NORTH_FACE_EXCLUDING_CORNERS", ...
                  "NODES_SOUTH_FACE_EXCLUDING_CORNERS", ...
                  "NODES_EAST_FACE_EXCLUDING_CORNERS", ...
                  "NODES_WEST_FACE_EXCLUDING_CORNERS", ...
                  "NODES_SW_CORNER", ...
                  "NODES_NW_CORNER", ...
                  "NODES_NE_CORNER", ...
                  "NODES_SE_CORNER", ])
              
              switch(style_str)
                 case "NODES_INTERNAL"
                     tf_ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.INTERNAL);
                 case "NODES_NORTH_FACE_EXCLUDING_CORNERS"
                     tf_ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_NORTH);
                 case "NODES_SOUTH_FACE_EXCLUDING_CORNERS"
                     tf_ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_SOUTH);
                 case "NODES_EAST_FACE_EXCLUDING_CORNERS"
                     tf_ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_EAST);
                 case "NODES_WEST_FACE_EXCLUDING_CORNERS"
                     tf_ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_WEST);
                 case "NODES_SW_CORNER"
                      tf_ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_CORNER_SW);
                      assert(1==nnz(tf_ind), "###_ERR:  why more than 1 of these corners ?")
                 case "NODES_NW_CORNER"
                      tf_ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_CORNER_NW);
                      assert(1==nnz(tf_ind), "###_ERR:  why more than 1 of these corners ?")
                 case "NODES_NE_CORNER"
                      tf_ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_CORNER_NE);
                      assert(1==nnz(tf_ind), "###_ERR:  why more than 1 of these corners ?")
                 case "NODES_SE_CORNER"
                      tf_ind = obj.tab.node_type_blk == string(bh_block_node_type_ENUM.BC_CORNER_SE);
                      assert(1==nnz(tf_ind), "###_ERR:  why more than 1 of these corners ?")
                  otherwise
                      error("###_ERROR:  Bad here !")
              end
              
           res_tab = obj.tab(tf_ind, :);
           
        end
        %------------------------------------------------------------------
    end % methods
%==========================================================================
end % classdef

