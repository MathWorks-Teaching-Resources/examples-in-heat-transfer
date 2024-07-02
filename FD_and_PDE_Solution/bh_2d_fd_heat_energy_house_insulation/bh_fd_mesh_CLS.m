classdef bh_fd_mesh_CLS   
    properties(SetAccess = protected )
        tab
        T_list string
        A_sys 
        b_sys 
        x_sys 
    end
    
    methods
        function obj = bh_fd_mesh_CLS(block_A, block_B, block_C)
            arguments
                block_A (1,1) bh_block_CLS
                block_B (1,1) bh_block_CLS
                block_C (1,1) bh_block_CLS
            end
            
            [obj.tab, obj.T_list] = LOC_join(block_A, block_B, block_C);

        end
        %------------------------------------------------------------------
        function  plot(obj)
            LOC_plot_mesh(obj.tab)
        end
        %------------------------------------------------------------------
        function obj = assemble_sys_A_b(obj, obj_stencil)
            arguments
               obj         (1,1)
               obj_stencil (1,1) bh_fd_stencil_CLS
            end
          NUM_NODES = height(obj.tab);
          
          A_sys = sparse(NUM_NODES, NUM_NODES);
          b_sys = sparse(NUM_NODES, 1);
          
          for kk=1:NUM_NODES  
            
              m  = obj.tab.i_global(kk);
              n  = obj.tab.j_global(kk);
              node_type_str = obj.tab.node_type_fd(kk);
              
              % get the STENCIl for this node type
              [A, b, x_str] = obj_stencil.retrieve_Abx(node_type_str, m, n);
              
              assert(length(x_str) > 0, "###_ERROR:  bad !")
              
              %---------------------------
              % REALLY SLOW HERE
              % [~,ia,ib] = intersect(obj.T_list, x_str);               
              % A_sys(kk, ia) = A(1,ib);
              % b_sys(kk)     = b;
              %----------------------------
              ia = zeros(size(x_str));
              for ii=1:length(x_str)
                 ia(ii) = find(obj.T_list == x_str(ii) );
              end % for ii
              
              A_sys(kk, ia) = A(1,:);
              b_sys(kk)     = b;
              
              if(0==mod(kk,1000))
                  fprintf('\n ... completed kk=%6d of %d',kk,NUM_NODES);
              end
              
          end % for kk=1:NUM_NODES
          
          % take care of the internal results fields
          obj.A_sys = A_sys;
          obj.b_sys = b_sys;
          
        end
        %------------------------------------------------------------------
        function obj = solve(obj)
            % x = A \ b
            x_sys     =  obj.A_sys \ obj.b_sys   ;
            
            obj.x_sys = x_sys;
                               
        end
        %------------------------------------------------------------------
        function [T_col, mn_mat] = results_retrieve(obj)
           T_col  = full( obj.x_sys );
           mn_mat = [ obj.tab.i_global, obj.tab.j_global ];
           
        end
        %------------------------------------------------------------------
        function results_plot(obj, plot_style, options)
          arguments
             obj
             plot_style (1,1) string {mustBeMember(plot_style,["scatter", "surf"])}
             options.Parent = []
          end
          
          m_col = obj.tab.i_global; 
          n_col = obj.tab.j_global; 
          T_col = full( obj.x_sys );

          if(isempty(options.Parent))
              figure;
              hax = axes;
          else
              hax = options.Parent;
          end
          
          switch(plot_style)
              case "scatter"                  
                      scatter3(m_col, n_col, T_col, [], T_col, "filled")
                         xlabel('m (Node ID)'); ylabel('n (Node ID)'); 
                         grid('On')
                         colormap(jet(200))            
                         colorbar;
                         view(2)
                       % add contours
                       %hax = gca;
                       %NUM_LEVELS = 10;
                       %LOC_add_contours_to_plot(hax, m_col, n_col, T_col, NUM_LEVELS)
                         
              case "surf"
                   % uses Convex hull ... so don't like this
%                    F = scatteredInterpolant(m_col, n_col, T_col, ...
%                                   'linear', 'none');
%                   
%                    m_list = linspace(min(m_col), max(m_col), 200);
%                    n_list = linspace(min(n_col), max(n_col), 200);
%                    [M,N]  = meshgrid(m_list, n_list);
%                    T      = F(M,N);
%                    
%                    figure;
%                    surf(M,N,T,'EdgeColor','none');
%                          xlabel('X'); ylabel('Y'); 
%                          grid('On')
%                          colormap(jet(200))            
%                          colorbar;
          end % switch
        end
        %------------------------------------------------------------------
        function results_plot_slice(OBJ, slice_type, tgt_fract)
           arguments 
               OBJ
               slice_type (1,1) {mustBeMember(slice_type,["m_slice","n_slice"])}
               tgt_fract  (1,1) {mustBeInRange(tgt_fract,0,1)}
           end
           
           switch(slice_type)
               case "m_slice"
                     the_tgt = round(tgt_fract*max(OBJ.tab.i_global));
                     tf_ind  = OBJ.tab.i_global == the_tgt;
                     xy      = [OBJ.tab{tf_ind,["j_global"]},OBJ.x_sys(tf_ind)]; 
                     xy      = sortrows(xy,1);  
                     tit_str = "SLICE at m= " + the_tgt;
                     H_str   = "n (Node ID)";
                     H_lim   = [min(OBJ.tab.j_global), max(OBJ.tab.j_global)];
                     xyz_mat = [ the_tgt,  min(OBJ.tab.j_global), 1.1*max(OBJ.x_sys);
                                 the_tgt,  max(OBJ.tab.j_global), 1.1*max(OBJ.x_sys); ];
               case "n_slice"
                     the_tgt = round(tgt_fract*max(OBJ.tab.j_global));
                     tf_ind  = OBJ.tab.j_global == the_tgt;
                     xy      = [OBJ.tab{tf_ind,["i_global"]},OBJ.x_sys(tf_ind)];
                     xy      = sortrows(xy,1);
                     tit_str = "SLICE at n= " + the_tgt;
                     H_str   = "m (Node ID)";
                     H_lim   = [min(OBJ.tab.i_global), max(OBJ.tab.i_global)];
                     xyz_mat = [ min(OBJ.tab.i_global), the_tgt, 1.1*max(OBJ.x_sys);
                                 max(OBJ.tab.i_global), the_tgt, 1.1*max(OBJ.x_sys); ];
           end
           
           figure;
             hax(1) = subplot(1,2,1);
               plot(xy(:,1), xy(:,2), '-b', "LineWidth",2)
                   grid("on");
                   ylabel("T");
                   title(tit_str);
                   xlabel(H_str);
                   axis("tight")
                   xlim(H_lim)
                   ylim([min(OBJ.x_sys), max(OBJ.x_sys)]);
             hax(2) = subplot(1,2,2);
               OBJ.results_plot("scatter", "Parent", hax(2));
                  hold(hax(2), "on")
                  plot3(xyz_mat(:,1), xyz_mat(:,2), xyz_mat(:,3), '-m', "LineWidth",3)
        end
        %------------------------------------------------------------------
    end
end
%_#########################################################################
% LOCAL SUBFUNCTIONS
%_#########################################################################
function [res_tab, T_str_list] = LOC_join(block_A, block_B, block_C)

    A_in  = get_subtable(block_A, "NODES_INTERNAL");
    A_SW  = get_subtable(block_A, "NODES_SW_CORNER");
    A_W   = get_subtable(block_A, "NODES_WEST_FACE_EXCLUDING_CORNERS");
    A_S   = get_subtable(block_A, "NODES_SOUTH_FACE_EXCLUDING_CORNERS");
    A_SE  = get_subtable(block_A, "NODES_SE_CORNER");
    A_E   = get_subtable(block_A, "NODES_EAST_FACE_EXCLUDING_CORNERS");
    
    A_in{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_INTERNAL);
    A_SW{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_SW);
    A_W{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_W);
    A_S{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_S);
    A_SE{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_SE);
    A_E{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_E);
    
    A_tab     = [A_in; A_SW; A_W; A_S; A_SE; A_E];  
    %---------------------------------------------        
    B_in = get_subtable(block_B, "NODES_INTERNAL"); 
    B_NW = get_subtable(block_B, "NODES_NW_CORNER");     
    B_N  = get_subtable(block_B, "NODES_NORTH_FACE_EXCLUDING_CORNERS");        
    B_NE = get_subtable(block_B, "NODES_NE_CORNER");         
    B_E  = get_subtable(block_B, "NODES_EAST_FACE_EXCLUDING_CORNERS");        
    B_SE = get_subtable(block_B, "NODES_SE_CORNER");        
    B_S  = get_subtable(block_B, "NODES_SOUTH_FACE_EXCLUDING_CORNERS");        
    B_SW = get_subtable(block_B, "NODES_SW_CORNER");       
    B_W  = get_subtable(block_B, "NODES_WEST_FACE_EXCLUDING_CORNERS");       
         
    B_in{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_INTERNAL);  
    B_NW{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_NW);      
    B_N{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_N);          
    B_NE{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_NE);          
    B_E{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_E);        
    B_SE{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_SE);       
    B_S{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_S);          
    B_SW{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_SW);        
    B_W{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_W);         
       
    B_tab = [B_in; B_NW; B_N; B_NE; B_E; B_SE; B_S; B_SW; B_W];
    %---------------------------------------------        
    C_in = get_subtable(block_C, "NODES_INTERNAL"); 
    C_NW = get_subtable(block_C, "NODES_NW_CORNER");     
    C_N  = get_subtable(block_C, "NODES_NORTH_FACE_EXCLUDING_CORNERS");        
    C_NE = get_subtable(block_C, "NODES_NE_CORNER");         
    C_E  = get_subtable(block_C, "NODES_EAST_FACE_EXCLUDING_CORNERS");        
    C_SE = get_subtable(block_C, "NODES_SE_CORNER");        
    C_S  = get_subtable(block_C, "NODES_SOUTH_FACE_EXCLUDING_CORNERS");        
    C_W  = get_subtable(block_C, "NODES_WEST_FACE_EXCLUDING_CORNERS");       
         
    % now delete nodes that join the B-block boundary
    tf_ind =  (C_W.i_local) == 0 &  (C_W.j_local <= block_B.Ny);
    C_W(tf_ind,:) = [];
        
    C_in{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_INTERNAL);  
    C_NW{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_NW);      
    C_N{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_N);          
    C_NE{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_NE);          
    C_E{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_E);        
    C_SE{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_SE);       
    C_S{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_S);          
    C_W{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_W);         
       
    C_tab = [C_in; C_NW; C_N; C_NE; C_E; C_SE; C_S; C_W];
    %---------------------------------------------        
    res_tab =  [A_tab;
                B_tab;
                C_tab ];
            
    res_tab.NODE_NAME = "NODE_" + res_tab.i_global + "_" + res_tab.j_global;
    %----------------------------------------------
    % allow the table ROW index to be the NODE_ID
    res_tab.Properties.RowNames = res_tab.NODE_NAME;
    %----------------------------------------------
    % Create a list of strings associatde with the node TEMPERATURES
    T_str_list = "T_" + res_tab.i_global + "_" + res_tab.j_global;
    %----------------------------------------------
    % ASSERT that our system table has UNIQUE rows for GLOBAL i,j
    tmp_tab = unique( res_tab(:, ["i_global", "j_global"]) );
    assert(height(tmp_tab)==height(res_tab), "###_ERROR: your joined SYSTEM table has duplicate rows for GLOBAL i,j ! ")
    
end % LOC_join()
%--------------------------------------------------------------------------
function LOC_plot_mesh(tab)

    unq_node_types = unique(tab.node_type_fd);

    N              = length(unq_node_types);
    RGB_mat        = jet(N);

    figure
    hax = axes;
    hold(hax,"on");
    for kk=1:N
        THE_node_type = unq_node_types(kk);

        tf_ind  = tab.node_type_fd == THE_node_type;

        sub_tab = tab(tf_ind,:);

        x_list  = sub_tab.i_global;
        y_list  = sub_tab.j_global;

        if( contains(THE_node_type, "NE") | contains(THE_node_type, "NW") | ...
            contains(THE_node_type, "SE") | contains(THE_node_type, "SW") )
            tmp_mkr_size = 30;
        else
            tmp_mkr_size = 10;
        end

        plot(hax, x_list, y_list, '.', "Color", RGB_mat(kk,:), "MarkerSize",tmp_mkr_size);
    end

    grid(hax,'on');
end
%--------------------------------------------------------------------------
function LOC_add_contours_to_plot(hax, m_col, n_col, T_col, NUM_LEVELS)

    T_min = min(T_col);
    T_max = max(T_col);
    TOL   = (T_max - T_min) * 0.005;

    hold(hax,"on");

    dT_level = (T_max - T_min) / (NUM_LEVELS);

    for kk = 1:NUM_LEVELS

        T_tgt = T_min + (kk-1)*dT_level

        tf_ind = abs( T_col - T_tgt ) <= TOL;

        if(nnz(tf_ind)>0)
           x = m_col(tf_ind);
           y = n_col(tf_ind);
           %T = T_col(tf_ind);
           T = 1.1*T_max*ones(size(x));
           scatter3(hax, x, y, T, [], "k", ".")
        end
    end % for
end

