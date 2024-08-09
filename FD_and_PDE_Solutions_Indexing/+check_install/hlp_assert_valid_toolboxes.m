function hlp_assert_valid_toolboxes()

    % what products do you have
    v_S                    = ver;
    installed_prod_list_CE = {v_S.Name}';

     % what products do we need for this DEMO
    required_prods_CE = ...
        {
          'MATLAB';
          'Symbolic Math Toolbox';  
          'Partial Differential Equation Toolbox';     
          };

      NUM_REQS = length(required_prods_CE);

      % check the current installation
      num_installed_required_products = 0;
      for kk=1:NUM_REQS
          the_prod_str   = required_prods_CE{kk,1};
          tf_i_have_prod = strcmp(installed_prod_list_CE, the_prod_str);

          fprintf("\n ... Confirming you have <%s> installed ---> ",the_prod_str);
          if(1==nnz(tf_i_have_prod))
              fprintf("[PASSED]");
              num_installed_required_products = num_installed_required_products + 1;
          else
              fprintf("[***_FAILED_***]");
          end
      end % for

      tf_has_all_required_prods = num_installed_required_products == NUM_REQS;

      assert( tf_has_all_required_prods, "###_PRODUCT_REQUIREMENTS: you do NOT have the required products to run this DEMO")

      fprintf("\n%s \n", repmat('-',1,50));
end
