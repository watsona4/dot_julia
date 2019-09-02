try: from . import _mskpreload
except ImportError: pass

from . import _msk
import codecs
import array
import re

class MSKException(Exception):
    pass
class SCoptException(Exception):
    pass
class MosekException(MSKException):
    def __init__(self,res,msg):
        MSKException.__init__(self,msg)
        self.msg   = msg
        self.errno = res
    def __str__(self):
        return "(%d) %s" % (self.errno,self.msg)

class Error(MosekException):
    pass

class EnumBase(int):
    """
    Base class for enums.
    """
    enumnamere = re.compile(r'[a-zA-Z][a-zA-Z0-9_]*$')
    def __new__(cls,value):
        if isinstance(value,int):
            return cls._valdict[value]
        elif isinstance(value,str):
            return cls._namedict[value.split('.')[-1]]
        else:
            raise TypeError("Invalid type for enum construction")
    def __str__(self):
        return '%s.%s' % (self.__class__.__name__,self.__name__)
    def __repr__(self):
        return self.__name__

    @classmethod
    def members(cls):
        return iter(cls._values)

    @classmethod
    def _initialize(cls, names,values=None):
        for n in names:
            if not cls.enumnamere.match(n):
                raise ValueError("Invalid enum item name '%s' in %s" % (n,cls.__name__))
        if values is None:
            values = range(len(names))
        if len(values) != len(names):
            raise ValueError("Lengths of names and values do not match")

        items = []
        for (n,v) in zip(names,values):
            item = int.__new__(cls,v)
            item.__name__ = n
            setattr(cls,n,item)
            items.append(item)

        cls._values   = items
        cls.values    = items
        cls._namedict = dict([ (v.__name__,v) for v in items ])
        cls._valdict  = dict([ (v,v) for v in items ]) # map int -> enum value (sneaky, eh?)

def Enum(name,names,values=None):
    """
    Create a new enum class with the given names and values.

    Parameters:
     [name]   A string denoting the name of the enum.
     [names]  A list of strings denoting the names of the individual enum values.
     [values] (optional) A list of integer values of the enums. If given, the
       list must have same length as the [names] parameter. If not given, the
       default values 0, 1, ... will be used.
    """
    e = type(name,(EnumBase,),{})
    e._initialize(names,values)
    return e

scopr = Enum("scopr", ["ent","exp","log","pow"], [ 0, 1, 2, 3 ])

solveform = Enum("solveform", ["dual","free","primal"], [2,0,1])
problemitem = Enum("problemitem", ["con","cone","var"], [1,2,0])
accmode = Enum("accmode", ["con","var"], [1,0])
sensitivitytype = Enum("sensitivitytype", ["basis","optimal_partition"], [0,1])
uplo = Enum("uplo", ["lo","up"], [0,1])
intpnthotstart = Enum("intpnthotstart", ["dual","none","primal","primal_dual"], [2,0,1,3])
sparam = Enum("sparam", ["bas_sol_file_name","data_file_name","debug_file_name","int_sol_file_name","itr_sol_file_name","mio_debug_string","param_comment_sign","param_read_file_name","param_write_file_name","read_mps_bou_name","read_mps_obj_name","read_mps_ran_name","read_mps_rhs_name","remote_access_token","sensitivity_file_name","sensitivity_res_file_name","sol_filter_xc_low","sol_filter_xc_upr","sol_filter_xx_low","sol_filter_xx_upr","stat_file_name","stat_key","stat_name","write_lp_gen_var_name"], [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23])
iparam = Enum("iparam", ["ana_sol_basis","ana_sol_print_violated","auto_sort_a_before_opt","auto_update_sol_info","basis_solve_use_plus_one","bi_clean_optimizer","bi_ignore_max_iter","bi_ignore_num_error","bi_max_iterations","cache_license","check_convexity","compress_statfile","infeas_generic_names","infeas_prefer_primal","infeas_report_auto","infeas_report_level","intpnt_basis","intpnt_diff_step","intpnt_hotstart","intpnt_max_iterations","intpnt_max_num_cor","intpnt_max_num_refinement_steps","intpnt_multi_thread","intpnt_off_col_trh","intpnt_order_method","intpnt_regularization_use","intpnt_scaling","intpnt_solve_form","intpnt_starting_point","license_debug","license_pause_time","license_suppress_expire_wrns","license_trh_expiry_wrn","license_wait","log","log_ana_pro","log_bi","log_bi_freq","log_check_convexity","log_cut_second_opt","log_expand","log_feas_repair","log_file","log_infeas_ana","log_intpnt","log_mio","log_mio_freq","log_order","log_presolve","log_response","log_sensitivity","log_sensitivity_opt","log_sim","log_sim_freq","log_sim_minor","log_storage","max_num_warnings","mio_branch_dir","mio_construct_sol","mio_cut_clique","mio_cut_cmir","mio_cut_gmi","mio_cut_implied_bound","mio_cut_knapsack_cover","mio_cut_selection_level","mio_heuristic_level","mio_max_num_branches","mio_max_num_relaxs","mio_max_num_solutions","mio_mode","mio_mt_user_cb","mio_node_optimizer","mio_node_selection","mio_perspective_reformulate","mio_probing_level","mio_rins_max_nodes","mio_root_optimizer","mio_root_repeat_presolve_level","mio_vb_detection_level","mt_spincount","num_threads","opf_max_terms_per_line","opf_write_header","opf_write_hints","opf_write_parameters","opf_write_problem","opf_write_sol_bas","opf_write_sol_itg","opf_write_sol_itr","opf_write_solutions","optimizer","param_read_case_name","param_read_ign_error","presolve_eliminator_max_fill","presolve_eliminator_max_num_tries","presolve_level","presolve_lindep_abs_work_trh","presolve_lindep_rel_work_trh","presolve_lindep_use","presolve_max_num_reductions","presolve_use","primal_repair_optimizer","read_data_compressed","read_data_format","read_debug","read_keep_free_con","read_lp_drop_new_vars_in_bou","read_lp_quoted_names","read_mps_format","read_mps_width","read_task_ignore_param","remove_unused_solutions","sensitivity_all","sensitivity_optimizer","sensitivity_type","sim_basis_factor_use","sim_degen","sim_dual_crash","sim_dual_phaseone_method","sim_dual_restrict_selection","sim_dual_selection","sim_exploit_dupvec","sim_hotstart","sim_hotstart_lu","sim_max_iterations","sim_max_num_setbacks","sim_non_singular","sim_primal_crash","sim_primal_phaseone_method","sim_primal_restrict_selection","sim_primal_selection","sim_refactor_freq","sim_reformulation","sim_save_lu","sim_scaling","sim_scaling_method","sim_solve_form","sim_stability_priority","sim_switch_optimizer","sol_filter_keep_basic","sol_filter_keep_ranged","sol_read_name_width","sol_read_width","solution_callback","timing_level","write_bas_constraints","write_bas_head","write_bas_variables","write_data_compressed","write_data_format","write_data_param","write_free_con","write_generic_names","write_generic_names_io","write_ignore_incompatible_items","write_int_constraints","write_int_head","write_int_variables","write_lp_full_obj","write_lp_line_width","write_lp_quoted_names","write_lp_strict_format","write_lp_terms_per_line","write_mps_format","write_mps_int","write_precision","write_sol_barvariables","write_sol_constraints","write_sol_head","write_sol_ignore_invalid_names","write_sol_variables","write_task_inc_sol","write_xml_mode"], [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172])
solsta = Enum("solsta", ["dual_feas","dual_illposed_cer","dual_infeas_cer","integer_optimal","near_dual_feas","near_dual_infeas_cer","near_integer_optimal","near_optimal","near_prim_and_dual_feas","near_prim_feas","near_prim_infeas_cer","optimal","prim_and_dual_feas","prim_feas","prim_illposed_cer","prim_infeas_cer","unknown"], [3,14,6,15,9,12,16,7,10,8,11,1,4,2,13,5,0])
objsense = Enum("objsense", ["maximize","minimize"], [1,0])
solitem = Enum("solitem", ["slc","slx","snx","suc","sux","xc","xx","y"], [3,5,7,4,6,0,1,2])
boundkey = Enum("boundkey", ["fr","fx","lo","ra","up"], [3,2,0,4,1])
basindtype = Enum("basindtype", ["always","if_feasible","never","no_error","reservered"], [1,3,0,2,4])
branchdir = Enum("branchdir", ["down","far","free","guided","near","pseudocost","root_lp","up"], [2,4,0,6,3,7,5,1])
liinfitem = Enum("liinfitem", ["bi_clean_dual_deg_iter","bi_clean_dual_iter","bi_clean_primal_deg_iter","bi_clean_primal_iter","bi_dual_iter","bi_primal_iter","intpnt_factor_num_nz","mio_intpnt_iter","mio_presolved_anz","mio_sim_maxiter_setbacks","mio_simplex_iter","rd_numanz","rd_numqnz"], [0,1,2,3,4,5,6,7,8,9,10,11,12])
simhotstart = Enum("simhotstart", ["free","none","status_keys"], [1,0,2])
callbackcode = Enum("callbackcode", ["begin_bi","begin_conic","begin_dual_bi","begin_dual_sensitivity","begin_dual_setup_bi","begin_dual_simplex","begin_dual_simplex_bi","begin_full_convexity_check","begin_infeas_ana","begin_intpnt","begin_license_wait","begin_mio","begin_optimizer","begin_presolve","begin_primal_bi","begin_primal_repair","begin_primal_sensitivity","begin_primal_setup_bi","begin_primal_simplex","begin_primal_simplex_bi","begin_qcqo_reformulate","begin_read","begin_root_cutgen","begin_simplex","begin_simplex_bi","begin_to_conic","begin_write","conic","dual_simplex","end_bi","end_conic","end_dual_bi","end_dual_sensitivity","end_dual_setup_bi","end_dual_simplex","end_dual_simplex_bi","end_full_convexity_check","end_infeas_ana","end_intpnt","end_license_wait","end_mio","end_optimizer","end_presolve","end_primal_bi","end_primal_repair","end_primal_sensitivity","end_primal_setup_bi","end_primal_simplex","end_primal_simplex_bi","end_qcqo_reformulate","end_read","end_root_cutgen","end_simplex","end_simplex_bi","end_to_conic","end_write","im_bi","im_conic","im_dual_bi","im_dual_sensivity","im_dual_simplex","im_full_convexity_check","im_intpnt","im_license_wait","im_lu","im_mio","im_mio_dual_simplex","im_mio_intpnt","im_mio_primal_simplex","im_order","im_presolve","im_primal_bi","im_primal_sensivity","im_primal_simplex","im_qo_reformulate","im_read","im_root_cutgen","im_simplex","im_simplex_bi","intpnt","new_int_mio","primal_simplex","read_opf","read_opf_section","solving_remote","update_dual_bi","update_dual_simplex","update_dual_simplex_bi","update_presolve","update_primal_bi","update_primal_simplex","update_primal_simplex_bi","write_opf"], [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92])
symmattype = Enum("symmattype", ["sparse"], [0])
feature = Enum("feature", ["pton","pts"], [1,0])
mark = Enum("mark", ["lo","up"], [0,1])
conetype = Enum("conetype", ["quad","rquad"], [0,1])
streamtype = Enum("streamtype", ["err","log","msg","wrn"], [2,0,1,3])
iomode = Enum("iomode", ["read","readwrite","write"], [0,2,1])
simseltype = Enum("simseltype", ["ase","devex","free","full","partial","se"], [2,3,0,1,5,4])
xmlwriteroutputtype = Enum("xmlwriteroutputtype", ["col","row"], [1,0])
miomode = Enum("miomode", ["ignored","satisfied"], [0,1])
dinfitem = Enum("dinfitem", ["bi_clean_dual_time","bi_clean_primal_time","bi_clean_time","bi_dual_time","bi_primal_time","bi_time","intpnt_dual_feas","intpnt_dual_obj","intpnt_factor_num_flops","intpnt_opt_status","intpnt_order_time","intpnt_primal_feas","intpnt_primal_obj","intpnt_time","mio_clique_separation_time","mio_cmir_separation_time","mio_construct_solution_obj","mio_dual_bound_after_presolve","mio_gmi_separation_time","mio_heuristic_time","mio_implied_bound_time","mio_knapsack_cover_separation_time","mio_obj_abs_gap","mio_obj_bound","mio_obj_int","mio_obj_rel_gap","mio_optimizer_time","mio_probing_time","mio_root_cutgen_time","mio_root_optimizer_time","mio_root_presolve_time","mio_time","mio_user_obj_cut","optimizer_time","presolve_eli_time","presolve_lindep_time","presolve_time","primal_repair_penalty_obj","qcqo_reformulate_max_perturbation","qcqo_reformulate_time","qcqo_reformulate_worst_cholesky_column_scaling","qcqo_reformulate_worst_cholesky_diag_scaling","rd_time","sim_dual_time","sim_feas","sim_obj","sim_primal_time","sim_time","sol_bas_dual_obj","sol_bas_dviolcon","sol_bas_dviolvar","sol_bas_nrm_barx","sol_bas_nrm_slc","sol_bas_nrm_slx","sol_bas_nrm_suc","sol_bas_nrm_sux","sol_bas_nrm_xc","sol_bas_nrm_xx","sol_bas_nrm_y","sol_bas_primal_obj","sol_bas_pviolcon","sol_bas_pviolvar","sol_itg_nrm_barx","sol_itg_nrm_xc","sol_itg_nrm_xx","sol_itg_primal_obj","sol_itg_pviolbarvar","sol_itg_pviolcon","sol_itg_pviolcones","sol_itg_pviolitg","sol_itg_pviolvar","sol_itr_dual_obj","sol_itr_dviolbarvar","sol_itr_dviolcon","sol_itr_dviolcones","sol_itr_dviolvar","sol_itr_nrm_bars","sol_itr_nrm_barx","sol_itr_nrm_slc","sol_itr_nrm_slx","sol_itr_nrm_snx","sol_itr_nrm_suc","sol_itr_nrm_sux","sol_itr_nrm_xc","sol_itr_nrm_xx","sol_itr_nrm_y","sol_itr_primal_obj","sol_itr_pviolbarvar","sol_itr_pviolcon","sol_itr_pviolcones","sol_itr_pviolvar","to_conic_time"], [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91])
parametertype = Enum("parametertype", ["dou_type","int_type","invalid_type","str_type"], [1,2,0,3])
rescodetype = Enum("rescodetype", ["err","ok","trm","unk","wrn"], [3,0,2,4,1])
prosta = Enum("prosta", ["dual_feas","dual_infeas","ill_posed","near_dual_feas","near_prim_and_dual_feas","near_prim_feas","prim_and_dual_feas","prim_and_dual_infeas","prim_feas","prim_infeas","prim_infeas_or_unbounded","unknown"], [3,5,7,10,8,9,1,6,2,4,11,0])
scalingtype = Enum("scalingtype", ["aggressive","free","moderate","none"], [3,0,2,1])
rescode = Enum("rescode", ["err_ad_invalid_codelist","err_api_array_too_small","err_api_cb_connect","err_api_fatal_error","err_api_internal","err_arg_is_too_large","err_arg_is_too_small","err_argument_dimension","err_argument_is_too_large","err_argument_lenneq","err_argument_perm_array","err_argument_type","err_bar_var_dim","err_basis","err_basis_factor","err_basis_singular","err_blank_name","err_cannot_clone_nl","err_cannot_handle_nl","err_cbf_duplicate_acoord","err_cbf_duplicate_bcoord","err_cbf_duplicate_con","err_cbf_duplicate_int","err_cbf_duplicate_obj","err_cbf_duplicate_objacoord","err_cbf_duplicate_psdvar","err_cbf_duplicate_var","err_cbf_invalid_con_type","err_cbf_invalid_domain_dimension","err_cbf_invalid_int_index","err_cbf_invalid_psdvar_dimension","err_cbf_invalid_var_type","err_cbf_no_variables","err_cbf_no_version_specified","err_cbf_obj_sense","err_cbf_parse","err_cbf_syntax","err_cbf_too_few_constraints","err_cbf_too_few_ints","err_cbf_too_few_psdvar","err_cbf_too_few_variables","err_cbf_too_many_constraints","err_cbf_too_many_ints","err_cbf_too_many_variables","err_cbf_unsupported","err_con_q_not_nsd","err_con_q_not_psd","err_cone_index","err_cone_overlap","err_cone_overlap_append","err_cone_rep_var","err_cone_size","err_cone_type","err_cone_type_str","err_data_file_ext","err_dup_name","err_duplicate_aij","err_duplicate_barvariable_names","err_duplicate_cone_names","err_duplicate_constraint_names","err_duplicate_variable_names","err_end_of_file","err_factor","err_feasrepair_cannot_relax","err_feasrepair_inconsistent_bound","err_feasrepair_solving_relaxed","err_file_license","err_file_open","err_file_read","err_file_write","err_final_solution","err_first","err_firsti","err_firstj","err_fixed_bound_values","err_flexlm","err_global_inv_conic_problem","err_huge_aij","err_huge_c","err_identical_tasks","err_in_argument","err_index","err_index_arr_is_too_large","err_index_arr_is_too_small","err_index_is_too_large","err_index_is_too_small","err_inf_dou_index","err_inf_dou_name","err_inf_int_index","err_inf_int_name","err_inf_lint_index","err_inf_lint_name","err_inf_type","err_infeas_undefined","err_infinite_bound","err_int64_to_int32_cast","err_internal","err_internal_test_failed","err_inv_aptre","err_inv_bk","err_inv_bkc","err_inv_bkx","err_inv_cone_type","err_inv_cone_type_str","err_inv_marki","err_inv_markj","err_inv_name_item","err_inv_numi","err_inv_numj","err_inv_optimizer","err_inv_problem","err_inv_qcon_subi","err_inv_qcon_subj","err_inv_qcon_subk","err_inv_qcon_val","err_inv_qobj_subi","err_inv_qobj_subj","err_inv_qobj_val","err_inv_sk","err_inv_sk_str","err_inv_skc","err_inv_skn","err_inv_skx","err_inv_var_type","err_invalid_accmode","err_invalid_aij","err_invalid_ampl_stub","err_invalid_barvar_name","err_invalid_compression","err_invalid_con_name","err_invalid_cone_name","err_invalid_file_format_for_cones","err_invalid_file_format_for_general_nl","err_invalid_file_format_for_sym_mat","err_invalid_file_name","err_invalid_format_type","err_invalid_idx","err_invalid_iomode","err_invalid_max_num","err_invalid_name_in_sol_file","err_invalid_obj_name","err_invalid_objective_sense","err_invalid_problem_type","err_invalid_sol_file_name","err_invalid_stream","err_invalid_surplus","err_invalid_sym_mat_dim","err_invalid_task","err_invalid_utf8","err_invalid_var_name","err_invalid_wchar","err_invalid_whichsol","err_json_data","err_json_format","err_json_missing_data","err_json_number_overflow","err_json_string","err_json_syntax","err_last","err_lasti","err_lastj","err_lau_arg_k","err_lau_arg_m","err_lau_arg_n","err_lau_arg_trans","err_lau_arg_transa","err_lau_arg_transb","err_lau_arg_uplo","err_lau_invalid_lower_triangular_matrix","err_lau_invalid_sparse_symmetric_matrix","err_lau_not_positive_definite","err_lau_singular_matrix","err_lau_unknown","err_license","err_license_cannot_allocate","err_license_cannot_connect","err_license_expired","err_license_feature","err_license_invalid_hostid","err_license_max","err_license_moseklm_daemon","err_license_no_server_line","err_license_no_server_support","err_license_server","err_license_server_version","err_license_version","err_link_file_dll","err_living_tasks","err_lower_bound_is_a_nan","err_lp_dup_slack_name","err_lp_empty","err_lp_file_format","err_lp_format","err_lp_free_constraint","err_lp_incompatible","err_lp_invalid_con_name","err_lp_invalid_var_name","err_lp_write_conic_problem","err_lp_write_geco_problem","err_lu_max_num_tries","err_max_len_is_too_small","err_maxnumbarvar","err_maxnumcon","err_maxnumcone","err_maxnumqnz","err_maxnumvar","err_mio_internal","err_mio_invalid_node_optimizer","err_mio_invalid_root_optimizer","err_mio_no_optimizer","err_missing_license_file","err_mixed_conic_and_nl","err_mps_cone_overlap","err_mps_cone_repeat","err_mps_cone_type","err_mps_duplicate_q_element","err_mps_file","err_mps_inv_bound_key","err_mps_inv_con_key","err_mps_inv_field","err_mps_inv_marker","err_mps_inv_sec_name","err_mps_inv_sec_order","err_mps_invalid_obj_name","err_mps_invalid_objsense","err_mps_mul_con_name","err_mps_mul_csec","err_mps_mul_qobj","err_mps_mul_qsec","err_mps_no_objective","err_mps_non_symmetric_q","err_mps_null_con_name","err_mps_null_var_name","err_mps_splitted_var","err_mps_tab_in_field2","err_mps_tab_in_field3","err_mps_tab_in_field5","err_mps_undef_con_name","err_mps_undef_var_name","err_mul_a_element","err_name_is_null","err_name_max_len","err_nan_in_blc","err_nan_in_blx","err_nan_in_buc","err_nan_in_bux","err_nan_in_c","err_nan_in_double_data","err_negative_append","err_negative_surplus","err_newer_dll","err_no_bars_for_solution","err_no_barx_for_solution","err_no_basis_sol","err_no_dual_for_itg_sol","err_no_dual_infeas_cer","err_no_init_env","err_no_optimizer_var_type","err_no_primal_infeas_cer","err_no_snx_for_bas_sol","err_no_solution_in_callback","err_non_unique_array","err_nonconvex","err_nonlinear_equality","err_nonlinear_functions_not_allowed","err_nonlinear_ranged","err_nr_arguments","err_null_env","err_null_pointer","err_null_task","err_numconlim","err_numvarlim","err_obj_q_not_nsd","err_obj_q_not_psd","err_objective_range","err_older_dll","err_open_dl","err_opf_format","err_opf_new_variable","err_opf_premature_eof","err_optimizer_license","err_overflow","err_param_index","err_param_is_too_large","err_param_is_too_small","err_param_name","err_param_name_dou","err_param_name_int","err_param_name_str","err_param_type","err_param_value_str","err_platform_not_licensed","err_postsolve","err_pro_item","err_prob_license","err_qcon_subi_too_large","err_qcon_subi_too_small","err_qcon_upper_triangle","err_qobj_upper_triangle","err_read_format","err_read_lp_missing_end_tag","err_read_lp_nonexisting_name","err_remove_cone_variable","err_repair_invalid_problem","err_repair_optimization_failed","err_sen_bound_invalid_lo","err_sen_bound_invalid_up","err_sen_format","err_sen_index_invalid","err_sen_index_range","err_sen_invalid_regexp","err_sen_numerical","err_sen_solution_status","err_sen_undef_name","err_sen_unhandled_problem_type","err_server_connect","err_server_protocol","err_server_status","err_server_token","err_size_license","err_size_license_con","err_size_license_intvar","err_size_license_numcores","err_size_license_var","err_sol_file_invalid_number","err_solitem","err_solver_probtype","err_space","err_space_leaking","err_space_no_info","err_sym_mat_duplicate","err_sym_mat_huge","err_sym_mat_invalid","err_sym_mat_invalid_col_index","err_sym_mat_invalid_row_index","err_sym_mat_invalid_value","err_sym_mat_not_lower_tringular","err_task_incompatible","err_task_invalid","err_task_write","err_thread_cond_init","err_thread_create","err_thread_mutex_init","err_thread_mutex_lock","err_thread_mutex_unlock","err_toconic_constr_not_conic","err_toconic_constr_q_not_psd","err_toconic_constraint_fx","err_toconic_constraint_ra","err_toconic_objective_not_psd","err_too_small_max_num_nz","err_too_small_maxnumanz","err_unb_step_size","err_undef_solution","err_undefined_objective_sense","err_unhandled_solution_status","err_unknown","err_upper_bound_is_a_nan","err_upper_triangle","err_user_func_ret","err_user_func_ret_data","err_user_nlo_eval","err_user_nlo_eval_hessubi","err_user_nlo_eval_hessubj","err_user_nlo_func","err_whichitem_not_allowed","err_whichsol","err_write_lp_format","err_write_lp_non_unique_name","err_write_mps_invalid_name","err_write_opf_invalid_var_name","err_writing_file","err_xml_invalid_problem_type","err_y_is_undefined","ok","trm_internal","trm_internal_stop","trm_max_iterations","trm_max_num_setbacks","trm_max_time","trm_mio_near_abs_gap","trm_mio_near_rel_gap","trm_mio_num_branches","trm_mio_num_relaxs","trm_num_max_num_int_solutions","trm_numerical_problem","trm_objective_range","trm_stall","trm_user_callback","wrn_ana_almost_int_bounds","wrn_ana_c_zero","wrn_ana_close_bounds","wrn_ana_empty_cols","wrn_ana_large_bounds","wrn_construct_invalid_sol_itg","wrn_construct_no_sol_itg","wrn_construct_solution_infeas","wrn_dropped_nz_qobj","wrn_duplicate_barvariable_names","wrn_duplicate_cone_names","wrn_duplicate_constraint_names","wrn_duplicate_variable_names","wrn_eliminator_space","wrn_empty_name","wrn_ignore_integer","wrn_incomplete_linear_dependency_check","wrn_large_aij","wrn_large_bound","wrn_large_cj","wrn_large_con_fx","wrn_large_lo_bound","wrn_large_up_bound","wrn_license_expire","wrn_license_feature_expire","wrn_license_server","wrn_lp_drop_variable","wrn_lp_old_quad_format","wrn_mio_infeasible_final","wrn_mps_split_bou_vector","wrn_mps_split_ran_vector","wrn_mps_split_rhs_vector","wrn_name_max_len","wrn_no_dualizer","wrn_no_global_optimizer","wrn_no_nonlinear_function_write","wrn_nz_in_upr_tri","wrn_open_param_file","wrn_param_ignored_cmio","wrn_param_name_dou","wrn_param_name_int","wrn_param_name_str","wrn_param_str_value","wrn_presolve_outofspace","wrn_quad_cones_with_root_fixed_at_zero","wrn_rquad_cones_with_root_fixed_at_zero","wrn_sol_file_ignored_con","wrn_sol_file_ignored_var","wrn_sol_filter","wrn_spar_max_len","wrn_sym_mat_large","wrn_too_few_basis_vars","wrn_too_many_basis_vars","wrn_undef_sol_file_name","wrn_using_generic_names","wrn_write_changed_names","wrn_write_discarded_cfix","wrn_zero_aij","wrn_zeros_in_sparse_col","wrn_zeros_in_sparse_row"], [3102,3001,3002,3005,3999,1227,1226,1201,5005,1197,1299,1198,3920,1266,1610,1615,1070,2505,2506,7116,7115,7108,7110,7107,7114,7123,7109,7112,7113,7121,7124,7111,7102,7105,7101,7100,7106,7118,7119,7125,7117,7103,7120,7104,7122,1294,1293,1300,1302,1307,1303,1301,1305,1306,1055,1071,1385,4502,4503,4500,4501,1059,1650,1700,1702,1701,1007,1052,1053,1054,1560,1261,1285,1287,1425,1014,1503,1380,1375,3101,1200,1235,1222,1221,1204,1203,1219,1230,1220,1231,1225,1234,1232,3910,1400,3800,3000,3500,1253,1255,1256,1257,1272,1271,2501,2502,1280,2503,2504,1550,1500,1405,1406,1404,1407,1401,1402,1403,1270,1269,1267,1274,1268,1258,2520,1473,3700,1079,1800,1076,1078,4005,4010,4000,1056,1283,1246,1801,1247,1170,1075,1445,6000,1057,1062,1275,3950,1064,2900,1077,2901,1228,1179,1178,1180,1177,1176,1175,1262,1286,1288,7012,7010,7011,7018,7015,7016,7017,7002,7019,7001,7000,7005,1000,1020,1021,1001,1018,1025,1016,1017,1028,1027,1015,1026,1002,1040,1066,1390,1152,1151,1157,1160,1155,1150,1171,1154,1163,1164,2800,1289,1242,1240,1304,1243,1241,5010,7131,7130,1551,1008,1501,1118,1119,1117,1121,1100,1108,1107,1101,1102,1109,1115,1128,1122,1112,1116,1114,1113,1110,1120,1103,1104,1111,1125,1126,1127,1105,1106,1254,1760,1750,1461,1471,1462,1472,1470,1450,1264,1263,1036,3916,3915,1600,2950,2001,1063,1552,2000,2953,2500,5000,1291,1290,1428,1292,1199,1060,1065,1061,1250,1251,1296,1295,1260,1035,1030,1168,1169,1172,1013,1590,1210,1215,1216,1205,1206,1207,1208,1218,1217,1019,1580,1281,1006,1409,1408,1417,1415,1090,1159,1162,1310,1710,1711,3054,3053,3050,3055,3052,3056,3058,3057,3051,3080,8000,8001,8002,8003,1005,1010,1012,3900,1011,1350,1237,1259,1051,1080,1081,3944,1482,1480,3941,3940,3943,3942,2560,2561,2562,1049,1048,1045,1046,1047,7153,7150,7151,7152,7155,1245,1252,3100,1265,1446,6010,1050,1391,6020,1430,1431,1433,1440,1441,1432,1238,1236,1158,1161,1153,1156,1166,3600,1449,0,10030,10031,10000,10020,10001,10004,10003,10009,10008,10015,10025,10002,10006,10007,904,901,903,902,900,807,810,805,201,852,853,850,851,801,502,250,800,62,51,57,54,52,53,500,505,501,85,80,270,72,71,70,65,950,251,450,200,50,516,510,511,512,515,802,930,931,351,352,300,66,960,400,405,350,503,803,804,63,710,705])
mionodeseltype = Enum("mionodeseltype", ["best","first","free","hybrid","pseudo","worst"], [2,1,0,4,5,3])
transpose = Enum("transpose", ["no","yes"], [0,1])
onoffkey = Enum("onoffkey", ["off","on"], [0,1])
simdegen = Enum("simdegen", ["aggressive","free","minimum","moderate","none"], [2,1,4,3,0])
dataformat = Enum("dataformat", ["cb","extension","free_mps","json_task","lp","mps","op","task","xml"], [7,0,5,8,2,1,3,6,4])
orderingtype = Enum("orderingtype", ["appminloc","experimental","force_graphpar","free","none","try_graphpar"], [1,2,4,0,5,3])
problemtype = Enum("problemtype", ["conic","geco","lo","mixed","qcqo","qo"], [4,3,0,5,2,1])
inftype = Enum("inftype", ["dou_type","int_type","lint_type"], [0,1,2])
dparam = Enum("dparam", ["ana_sol_infeas_tol","basis_rel_tol_s","basis_tol_s","basis_tol_x","check_convexity_rel_tol","data_sym_mat_tol","data_sym_mat_tol_huge","data_sym_mat_tol_large","data_tol_aij","data_tol_aij_huge","data_tol_aij_large","data_tol_bound_inf","data_tol_bound_wrn","data_tol_c_huge","data_tol_cj_large","data_tol_qij","data_tol_x","intpnt_co_tol_dfeas","intpnt_co_tol_infeas","intpnt_co_tol_mu_red","intpnt_co_tol_near_rel","intpnt_co_tol_pfeas","intpnt_co_tol_rel_gap","intpnt_nl_merit_bal","intpnt_nl_tol_dfeas","intpnt_nl_tol_mu_red","intpnt_nl_tol_near_rel","intpnt_nl_tol_pfeas","intpnt_nl_tol_rel_gap","intpnt_nl_tol_rel_step","intpnt_qo_tol_dfeas","intpnt_qo_tol_infeas","intpnt_qo_tol_mu_red","intpnt_qo_tol_near_rel","intpnt_qo_tol_pfeas","intpnt_qo_tol_rel_gap","intpnt_tol_dfeas","intpnt_tol_dsafe","intpnt_tol_infeas","intpnt_tol_mu_red","intpnt_tol_path","intpnt_tol_pfeas","intpnt_tol_psafe","intpnt_tol_rel_gap","intpnt_tol_rel_step","intpnt_tol_step_size","lower_obj_cut","lower_obj_cut_finite_trh","mio_disable_term_time","mio_max_time","mio_near_tol_abs_gap","mio_near_tol_rel_gap","mio_rel_gap_const","mio_tol_abs_gap","mio_tol_abs_relax_int","mio_tol_feas","mio_tol_rel_dual_bound_improvement","mio_tol_rel_gap","optimizer_max_time","presolve_tol_abs_lindep","presolve_tol_aij","presolve_tol_rel_lindep","presolve_tol_s","presolve_tol_x","qcqo_reformulate_rel_drop_tol","semidefinite_tol_approx","sim_lu_tol_rel_piv","simplex_abs_tol_piv","upper_obj_cut","upper_obj_cut_finite_trh"], [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69])
simdupvec = Enum("simdupvec", ["free","off","on"], [2,0,1])
compresstype = Enum("compresstype", ["free","gzip","none"], [1,2,0])
nametype = Enum("nametype", ["gen","lp","mps"], [0,2,1])
mpsformat = Enum("mpsformat", ["cplex","free","relaxed","strict"], [3,2,1,0])
variabletype = Enum("variabletype", ["type_cont","type_int"], [0,1])
checkconvexitytype = Enum("checkconvexitytype", ["full","none","simple"], [2,0,1])
language = Enum("language", ["dan","eng"], [1,0])
startpointtype = Enum("startpointtype", ["constant","free","guess","satisfy_bounds"], [2,0,1,3])
soltype = Enum("soltype", ["bas","itg","itr"], [1,2,0])
scalingmethod = Enum("scalingmethod", ["free","pow2"], [1,0])
value = Enum("value", ["license_buffer_length","max_str_len"], [21,1024])
simreform = Enum("simreform", ["aggressive","free","off","on"], [3,2,0,1])
iinfitem = Enum("iinfitem", ["ana_pro_num_con","ana_pro_num_con_eq","ana_pro_num_con_fr","ana_pro_num_con_lo","ana_pro_num_con_ra","ana_pro_num_con_up","ana_pro_num_var","ana_pro_num_var_bin","ana_pro_num_var_cont","ana_pro_num_var_eq","ana_pro_num_var_fr","ana_pro_num_var_int","ana_pro_num_var_lo","ana_pro_num_var_ra","ana_pro_num_var_up","intpnt_factor_dim_dense","intpnt_iter","intpnt_num_threads","intpnt_solve_dual","mio_absgap_satisfied","mio_clique_table_size","mio_construct_num_roundings","mio_construct_solution","mio_initial_solution","mio_near_absgap_satisfied","mio_near_relgap_satisfied","mio_node_depth","mio_num_active_nodes","mio_num_branch","mio_num_clique_cuts","mio_num_cmir_cuts","mio_num_gomory_cuts","mio_num_implied_bound_cuts","mio_num_int_solutions","mio_num_knapsack_cover_cuts","mio_num_relax","mio_num_repeated_presolve","mio_numcon","mio_numint","mio_numvar","mio_obj_bound_defined","mio_presolved_numbin","mio_presolved_numcon","mio_presolved_numcont","mio_presolved_numint","mio_presolved_numvar","mio_relgap_satisfied","mio_total_num_cuts","mio_user_obj_cut","opt_numcon","opt_numvar","optimize_response","rd_numbarvar","rd_numcon","rd_numcone","rd_numintvar","rd_numq","rd_numvar","rd_protype","sim_dual_deg_iter","sim_dual_hotstart","sim_dual_hotstart_lu","sim_dual_inf_iter","sim_dual_iter","sim_numcon","sim_numvar","sim_primal_deg_iter","sim_primal_hotstart","sim_primal_hotstart_lu","sim_primal_inf_iter","sim_primal_iter","sim_solve_dual","sol_bas_prosta","sol_bas_solsta","sol_itg_prosta","sol_itg_solsta","sol_itr_prosta","sol_itr_solsta","sto_num_a_realloc"], [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78])
stakey = Enum("stakey", ["bas","fix","inf","low","supbas","unk","upr"], [1,5,6,3,2,0,4])
optimizertype = Enum("optimizertype", ["conic","dual_simplex","free","free_simplex","intpnt","mixed_int","primal_simplex"], [0,1,2,3,4,5,6])
presolvemode = Enum("presolvemode", ["free","off","on"], [2,0,1])
miocontsoltype = Enum("miocontsoltype", ["itg","itg_rel","none","root"], [2,3,0,1])



class Env:
    def __init__(self,licensefile=None,debugfile=None):
        self.__obj = _msk.Env() if debugfile is None else _msk.Env(debugfile)

        if licensefile is not None:
            if isinstance(licensefile,str):
                res = self.__obj.putlicensepath(licensefile.encode('utf-8', errors='replace'))
                if res != 0:
                    self.__del__()
                    raise Error(rescode(res),"Error %d" % res)

        self.__obj.enablegarcolenv()

    def set_Stream(self,whichstream,func):
        if isinstance(whichstream, streamtype):
            if func is None:
                self.__obj.remove_Stream(whichstream)
            else:
                self.__obj.set_Stream(whichstream,func)
            pass

        else:
            raise TypeError("Invalid stream %s" % whichstream)

    def __del__(self):
        try:
            o = self.__obj
        except AttributeError:
            pass
        else:
            o.dispose()
            del self.__obj

    def __enter__(self):
        return self

    def __exit__(self,exc_type,exc_value,traceback):
        self.__del__()

    def Task(self,numcon=0,numvar=0):
        return Task(self,numcon,numvar)

    def checkoutlicense(self,feature_): # 3
      """
      Check out a license feature from the license server ahead of time.
    
      checkoutlicense(self,feature_)
        feature: mosek.feature. Feature to check out from the license system.
      """
      if not isinstance(feature_,feature): raise TypeError("Argument feature has wrong type")
      res = self.__obj.checkoutlicense(feature_)
      if res != 0:
        raise Error(rescode(res),"")
    
    def checkinlicense(self,feature_): # 3
      """
      Check in a license feature back to the license server ahead of time.
    
      checkinlicense(self,feature_)
        feature: mosek.feature. Feature to check in to the license system.
      """
      if not isinstance(feature_,feature): raise TypeError("Argument feature has wrong type")
      res = self.__obj.checkinlicense(feature_)
      if res != 0:
        raise Error(rescode(res),"")
    
    def checkinall(self): # 3
      """
      Check in all unused license features to the license token server.
    
      checkinall(self)
      """
      res = self.__obj.checkinall()
      if res != 0:
        raise Error(rescode(res),"")
    
    def echointro(self,longver_): # 3
      """
      Prints an intro to message stream.
    
      echointro(self,longver_)
        longver: int. If non-zero, then the intro is slightly longer.
      """
      res = self.__obj.echointro(longver_)
      if res != 0:
        raise Error(rescode(res),"")
    
    @staticmethod
    def getcodedesc(code_): # 3
      """
      Obtains a short description of a response code.
    
      getcodedesc(code_)
        code: mosek.rescode. A valid response code.
      returns: symname,str
        symname: str. Symbolic name corresponding to the code.
        str: str. Obtains a short description of a response code.
      """
      if not isinstance(code_,rescode): raise TypeError("Argument code has wrong type")
      arr_symname = array.array("b",[0]*(value.max_str_len))
      memview_arr_symname = memoryview(arr_symname)
      arr_str = array.array("b",[0]*(value.max_str_len))
      memview_arr_str = memoryview(arr_str)
      res,resargs = _msk.Env.getcodedesc(code_,memview_arr_symname,memview_arr_str)
      if res != 0:
        raise Error(rescode(res),"")
      retarg_symname,retarg_str = resargs
      retarg_str = arr_str.tobytes()[:-1].decode("utf-8",errors="ignore")
      retarg_symname = arr_symname.tobytes()[:-1].decode("utf-8",errors="ignore")
      return retarg_symname,retarg_str
    
    @staticmethod
    def getversion(): # 3
      """
      Obtains MOSEK version information.
    
      getversion()
      returns: major,minor,build,revision
        major: int. Major version number.
        minor: int. Minor version number.
        build: int. Build number.
        revision: int. Revision number.
      """
      res,resargs = _msk.Env.getversion()
      if res != 0:
        raise Error(rescode(res),"")
      _major_return_value,_minor_return_value,_build_return_value,_revision_return_value = resargs
      return _major_return_value,_minor_return_value,_build_return_value,_revision_return_value
    
    def linkfiletostream(self,whichstream_,filename_,append_): # 3
      """
      Directs all output from a stream to a file.
    
      linkfiletostream(self,whichstream_,filename_,append_)
        whichstream: mosek.streamtype. Index of the stream.
        filename: str. A valid file name.
        append: int. If this argument is 0 the file will be overwritten, otherwise it will be appended to.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      res = self.__obj.linkfiletoenvstream(whichstream_,filename_,append_)
      if res != 0:
        raise Error(rescode(res),"")
    
    def putlicensedebug(self,licdebug_): # 3
      """
      Enables debug information for the license system.
    
      putlicensedebug(self,licdebug_)
        licdebug: int. Enable output of license check-out debug information.
      """
      res = self.__obj.putlicensedebug(licdebug_)
      if res != 0:
        raise Error(rescode(res),"")
    
    def putlicensecode(self,code): # 3
      """
      Input a runtime license code.
    
      putlicensecode(self,code)
        code: array of int. A license key string.
      """
      if code is None:
        code_ = None
      else:
        try:
          code_ = memoryview(code)
        except TypeError:
          try:
            _tmparr_code = array.array("i",code)
          except TypeError:
            raise TypeError("Argument code has wrong type")
          else:
            code_ = memoryview(_tmparr_code)
      
        else:
          if code_.format != "i":
            code_ = memoryview(array.array("i",code))
      
      if code_ is not None and len(code_) != value.license_buffer_length:
        raise ValueError("Array argument code has wrong length")
      res = self.__obj.putlicensecode(code_)
      if res != 0:
        raise Error(rescode(res),"")
    
    def putlicensewait(self,licwait_): # 3
      """
      Control whether mosek should wait for an available license if no license is available.
    
      putlicensewait(self,licwait_)
        licwait: int. Enable waiting for a license.
      """
      res = self.__obj.putlicensewait(licwait_)
      if res != 0:
        raise Error(rescode(res),"")
    
    def putlicensepath(self,licensepath_): # 3
      """
      Set the path to the license file.
    
      putlicensepath(self,licensepath_)
        licensepath: str. A path specifying where to search for the license.
      """
      res = self.__obj.putlicensepath(licensepath_)
      if res != 0:
        raise Error(rescode(res),"")
    
    def axpy(self,n_,alpha_,x,y): # 3
      """
      Computes vector addition and multiplication by a scalar.
    
      axpy(self,n_,alpha_,x,y)
        n: int. Length of the vectors.
        alpha: double. The scalar that multiplies x.
        x: array of double. The x vector.
        y: array of double. The y vector.
      """
      if x is None: raise TypeError("Invalid type for argument x")
      if x is None:
        x_ = None
      else:
        try:
          x_ = memoryview(x)
        except TypeError:
          try:
            _tmparr_x = array.array("d",x)
          except TypeError:
            raise TypeError("Argument x has wrong type")
          else:
            x_ = memoryview(_tmparr_x)
      
        else:
          if x_.format != "d":
            x_ = memoryview(array.array("d",x))
      
      if x_ is not None and len(x_) != (n_):
        raise ValueError("Array argument x has wrong length")
      if y is None: raise TypeError("Invalid type for argument y")
      _copyback_y = False
      if y is None:
        y_ = None
      else:
        try:
          y_ = memoryview(y)
        except TypeError:
          try:
            _tmparr_y = array.array("d",y)
          except TypeError:
            raise TypeError("Argument y has wrong type")
          else:
            y_ = memoryview(_tmparr_y)
            _copyback_y = True
        else:
          if y_.format != "d":
            y_ = memoryview(array.array("d",y))
            _copyback_y = True
      if y_ is not None and len(y_) != (n_):
        raise ValueError("Array argument y has wrong length")
      res = self.__obj.axpy(n_,alpha_,x_,y_)
      if res != 0:
        raise Error(rescode(res),"")
      if _copyback_y:
        y[:] = _tmparr_y
    
    def dot(self,n_,x,y): # 3
      """
      Computes the inner product of two vectors.
    
      dot(self,n_,x,y)
        n: int. Length of the vectors.
        x: array of double. The x vector.
        y: array of double. The y vector.
      returns: xty
        xty: double. The result of the inner product.
      """
      if x is None: raise TypeError("Invalid type for argument x")
      if x is None:
        x_ = None
      else:
        try:
          x_ = memoryview(x)
        except TypeError:
          try:
            _tmparr_x = array.array("d",x)
          except TypeError:
            raise TypeError("Argument x has wrong type")
          else:
            x_ = memoryview(_tmparr_x)
      
        else:
          if x_.format != "d":
            x_ = memoryview(array.array("d",x))
      
      if x_ is not None and len(x_) != (n_):
        raise ValueError("Array argument x has wrong length")
      if y is None: raise TypeError("Invalid type for argument y")
      if y is None:
        y_ = None
      else:
        try:
          y_ = memoryview(y)
        except TypeError:
          try:
            _tmparr_y = array.array("d",y)
          except TypeError:
            raise TypeError("Argument y has wrong type")
          else:
            y_ = memoryview(_tmparr_y)
      
        else:
          if y_.format != "d":
            y_ = memoryview(array.array("d",y))
      
      if y_ is not None and len(y_) != (n_):
        raise ValueError("Array argument y has wrong length")
      res,resargs = self.__obj.dot(n_,x_,y_)
      if res != 0:
        raise Error(rescode(res),"")
      _xty_return_value = resargs
      return _xty_return_value
    
    def gemv(self,transa_,m_,n_,alpha_,a,x,beta_,y): # 3
      """
      Computes dense matrix times a dense vector product.
    
      gemv(self,transa_,m_,n_,alpha_,a,x,beta_,y)
        transa: mosek.transpose. Indicates whether the matrix A must be transposed.
        m: int. Specifies the number of rows of the matrix A.
        n: int. Specifies the number of columns of the matrix A.
        alpha: double. A scalar value multiplying the matrix A.
        a: array of double. A pointer to the array storing matrix A in a column-major format.
        x: array of double. A pointer to the array storing the vector x.
        beta: double. A scalar value multiplying the vector y.
        y: array of double. A pointer to the array storing the vector y.
      """
      if not isinstance(transa_,transpose): raise TypeError("Argument transa has wrong type")
      if a is None: raise TypeError("Invalid type for argument a")
      if a is None:
        a_ = None
      else:
        try:
          a_ = memoryview(a)
        except TypeError:
          try:
            _tmparr_a = array.array("d",a)
          except TypeError:
            raise TypeError("Argument a has wrong type")
          else:
            a_ = memoryview(_tmparr_a)
      
        else:
          if a_.format != "d":
            a_ = memoryview(array.array("d",a))
      
      if a_ is not None and len(a_) != ((n_) * (m_)):
        raise ValueError("Array argument a has wrong length")
      if x is None: raise TypeError("Invalid type for argument x")
      if x is None:
        x_ = None
      else:
        try:
          x_ = memoryview(x)
        except TypeError:
          try:
            _tmparr_x = array.array("d",x)
          except TypeError:
            raise TypeError("Argument x has wrong type")
          else:
            x_ = memoryview(_tmparr_x)
      
        else:
          if x_.format != "d":
            x_ = memoryview(array.array("d",x))
      
      if ((transa_) == transpose.no):
        __tmp_var_0 = (n_);
      else:
        __tmp_var_0 = (m_);
      if x_ is not None and len(x_) != __tmp_var_0:
        raise ValueError("Array argument x has wrong length")
      if y is None: raise TypeError("Invalid type for argument y")
      _copyback_y = False
      if y is None:
        y_ = None
      else:
        try:
          y_ = memoryview(y)
        except TypeError:
          try:
            _tmparr_y = array.array("d",y)
          except TypeError:
            raise TypeError("Argument y has wrong type")
          else:
            y_ = memoryview(_tmparr_y)
            _copyback_y = True
        else:
          if y_.format != "d":
            y_ = memoryview(array.array("d",y))
            _copyback_y = True
      if ((transa_) == transpose.no):
        __tmp_var_1 = (m_);
      else:
        __tmp_var_1 = (n_);
      if y_ is not None and len(y_) != __tmp_var_1:
        raise ValueError("Array argument y has wrong length")
      res = self.__obj.gemv(transa_,m_,n_,alpha_,a_,x_,beta_,y_)
      if res != 0:
        raise Error(rescode(res),"")
      if _copyback_y:
        y[:] = _tmparr_y
    
    def gemm(self,transa_,transb_,m_,n_,k_,alpha_,a,b,beta_,c): # 3
      """
      Performs a dense matrix multiplication.
    
      gemm(self,transa_,transb_,m_,n_,k_,alpha_,a,b,beta_,c)
        transa: mosek.transpose. Indicates whether the matrix A must be transposed.
        transb: mosek.transpose. Indicates whether the matrix B must be transposed.
        m: int. Indicates the number of rows of matrix C.
        n: int. Indicates the number of columns of matrix C.
        k: int. Specifies the common dimension along which op(A) and op(B) are multiplied.
        alpha: double. A scalar value multiplying the result of the matrix multiplication.
        a: array of double. The pointer to the array storing matrix A in a column-major format.
        b: array of double. The pointer to the array storing matrix B in a column-major format.
        beta: double. A scalar value that multiplies C.
        c: array of double. The pointer to the array storing matrix C in a column-major format.
      """
      if not isinstance(transa_,transpose): raise TypeError("Argument transa has wrong type")
      if not isinstance(transb_,transpose): raise TypeError("Argument transb has wrong type")
      if a is None: raise TypeError("Invalid type for argument a")
      if a is None:
        a_ = None
      else:
        try:
          a_ = memoryview(a)
        except TypeError:
          try:
            _tmparr_a = array.array("d",a)
          except TypeError:
            raise TypeError("Argument a has wrong type")
          else:
            a_ = memoryview(_tmparr_a)
      
        else:
          if a_.format != "d":
            a_ = memoryview(array.array("d",a))
      
      if a_ is not None and len(a_) != ((m_) * (k_)):
        raise ValueError("Array argument a has wrong length")
      if b is None: raise TypeError("Invalid type for argument b")
      if b is None:
        b_ = None
      else:
        try:
          b_ = memoryview(b)
        except TypeError:
          try:
            _tmparr_b = array.array("d",b)
          except TypeError:
            raise TypeError("Argument b has wrong type")
          else:
            b_ = memoryview(_tmparr_b)
      
        else:
          if b_.format != "d":
            b_ = memoryview(array.array("d",b))
      
      if b_ is not None and len(b_) != ((k_) * (n_)):
        raise ValueError("Array argument b has wrong length")
      if c is None: raise TypeError("Invalid type for argument c")
      _copyback_c = False
      if c is None:
        c_ = None
      else:
        try:
          c_ = memoryview(c)
        except TypeError:
          try:
            _tmparr_c = array.array("d",c)
          except TypeError:
            raise TypeError("Argument c has wrong type")
          else:
            c_ = memoryview(_tmparr_c)
            _copyback_c = True
        else:
          if c_.format != "d":
            c_ = memoryview(array.array("d",c))
            _copyback_c = True
      if c_ is not None and len(c_) != ((m_) * (n_)):
        raise ValueError("Array argument c has wrong length")
      res = self.__obj.gemm(transa_,transb_,m_,n_,k_,alpha_,a_,b_,beta_,c_)
      if res != 0:
        raise Error(rescode(res),"")
      if _copyback_c:
        c[:] = _tmparr_c
    
    def syrk(self,uplo_,trans_,n_,k_,alpha_,a,beta_,c): # 3
      """
      Performs a rank-k update of a symmetric matrix.
    
      syrk(self,uplo_,trans_,n_,k_,alpha_,a,beta_,c)
        uplo: mosek.uplo. Indicates whether the upper or lower triangular part of C is used.
        trans: mosek.transpose. Indicates whether the matrix A must be transposed.
        n: int. Specifies the order of C.
        k: int. Indicates the number of rows or columns of A, and its rank.
        alpha: double. A scalar value multiplying the result of the matrix multiplication.
        a: array of double. The pointer to the array storing matrix A in a column-major format.
        beta: double. A scalar value that multiplies C.
        c: array of double. The pointer to the array storing matrix C in a column-major format.
      """
      if not isinstance(uplo_,uplo): raise TypeError("Argument uplo has wrong type")
      if not isinstance(trans_,transpose): raise TypeError("Argument trans has wrong type")
      if a is None: raise TypeError("Invalid type for argument a")
      if a is None:
        a_ = None
      else:
        try:
          a_ = memoryview(a)
        except TypeError:
          try:
            _tmparr_a = array.array("d",a)
          except TypeError:
            raise TypeError("Argument a has wrong type")
          else:
            a_ = memoryview(_tmparr_a)
      
        else:
          if a_.format != "d":
            a_ = memoryview(array.array("d",a))
      
      if a_ is not None and len(a_) != ((n_) * (k_)):
        raise ValueError("Array argument a has wrong length")
      if c is None: raise TypeError("Invalid type for argument c")
      _copyback_c = False
      if c is None:
        c_ = None
      else:
        try:
          c_ = memoryview(c)
        except TypeError:
          try:
            _tmparr_c = array.array("d",c)
          except TypeError:
            raise TypeError("Argument c has wrong type")
          else:
            c_ = memoryview(_tmparr_c)
            _copyback_c = True
        else:
          if c_.format != "d":
            c_ = memoryview(array.array("d",c))
            _copyback_c = True
      if c_ is not None and len(c_) != ((n_) * (n_)):
        raise ValueError("Array argument c has wrong length")
      res = self.__obj.syrk(uplo_,trans_,n_,k_,alpha_,a_,beta_,c_)
      if res != 0:
        raise Error(rescode(res),"")
      if _copyback_c:
        c[:] = _tmparr_c
    
    def computesparsecholesky(self,multithread_,ordermethod_,tolsingular_,anzc,aptrc,asubc,avalc): # 3
      """
      Computes a Cholesky factorization of sparse matrix.
    
      computesparsecholesky(self,multithread_,ordermethod_,tolsingular_,anzc,aptrc,asubc,avalc)
        multithread: int. If nonzero then the function may exploit multiple threads.
        ordermethod: int. If nonzero, then a sparsity preserving ordering will be employed.
        tolsingular: double. A positive parameter controlling when a pivot is declared zero.
        anzc: array of int. anzc[j] is the number of nonzeros in the jth column of A.
        aptrc: array of long. aptrc[j] is a pointer to the first element in column j.
        asubc: array of int. Row indexes for each column stored in increasing order.
        avalc: array of double. The value corresponding to row indexed stored in asubc.
      returns: lensubnval
        lensubnval: long. Number of elements in lsubc and lvalc.
      """
      n_ = None
      if n_ is None:
        n_ = len(anzc)
      elif n_ != len(anzc):
        raise IndexError("Inconsistent length of array anzc")
      if n_ is None:
        n_ = len(aptrc)
      elif n_ != len(aptrc):
        raise IndexError("Inconsistent length of array aptrc")
      if n_ is None: n_ = 0
      if anzc is None: raise TypeError("Invalid type for argument anzc")
      if anzc is None:
        anzc_ = None
      else:
        try:
          anzc_ = memoryview(anzc)
        except TypeError:
          try:
            _tmparr_anzc = array.array("i",anzc)
          except TypeError:
            raise TypeError("Argument anzc has wrong type")
          else:
            anzc_ = memoryview(_tmparr_anzc)
      
        else:
          if anzc_.format != "i":
            anzc_ = memoryview(array.array("i",anzc))
      
      if aptrc is None: raise TypeError("Invalid type for argument aptrc")
      if aptrc is None:
        aptrc_ = None
      else:
        try:
          aptrc_ = memoryview(aptrc)
        except TypeError:
          try:
            _tmparr_aptrc = array.array("q",aptrc)
          except TypeError:
            raise TypeError("Argument aptrc has wrong type")
          else:
            aptrc_ = memoryview(_tmparr_aptrc)
      
        else:
          if aptrc_.format != "q":
            aptrc_ = memoryview(array.array("q",aptrc))
      
      if asubc is None: raise TypeError("Invalid type for argument asubc")
      if asubc is None:
        asubc_ = None
      else:
        try:
          asubc_ = memoryview(asubc)
        except TypeError:
          try:
            _tmparr_asubc = array.array("i",asubc)
          except TypeError:
            raise TypeError("Argument asubc has wrong type")
          else:
            asubc_ = memoryview(_tmparr_asubc)
      
        else:
          if asubc_.format != "i":
            asubc_ = memoryview(array.array("i",asubc))
      
      if avalc is None: raise TypeError("Invalid type for argument avalc")
      if avalc is None:
        avalc_ = None
      else:
        try:
          avalc_ = memoryview(avalc)
        except TypeError:
          try:
            _tmparr_avalc = array.array("d",avalc)
          except TypeError:
            raise TypeError("Argument avalc has wrong type")
          else:
            avalc_ = memoryview(_tmparr_avalc)
      
        else:
          if avalc_.format != "d":
            avalc_ = memoryview(array.array("d",avalc))
      
      res,resargs = self.__obj.computesparsecholesky(multithread_,ordermethod_,tolsingular_,n_,anzc_,aptrc_,asubc_,avalc_)
      if res != 0:
        raise Error(rescode(res),"")
      _perm,_diag,_lnzc,_lptrc,_lensubnval_return_value,_lsubc,_lvalc = resargs
      return _perm,_diag,_lnzc,_lptrc,_lensubnval_return_value,_lsubc,_lvalc
    
    def sparsetriangularsolvedense(self,transposed_,lnzc,lptrc,lsubc,lvalc,b): # 3
      """
      Solves a sparse triangular system of linear equations.
    
      sparsetriangularsolvedense(self,transposed_,lnzc,lptrc,lsubc,lvalc,b)
        transposed: mosek.transpose. Controls whether the solve is with L or the transposed L.
        lnzc: array of int. lnzc[j] is the number of nonzeros in column j.
        lptrc: array of long. lptrc[j] is a pointer to the first row index and value in column j.
        lsubc: array of int. Row indexes for each column stored sequentially.
        lvalc: array of double. The value corresponding to row indexed stored lsubc.
        b: array of double. The right-hand side of linear equation system to be solved as a dense vector.
      """
      if not isinstance(transposed_,transpose): raise TypeError("Argument transposed has wrong type")
      n_ = None
      if n_ is None:
        n_ = len(b)
      elif n_ != len(b):
        raise IndexError("Inconsistent length of array b")
      if n_ is None:
        n_ = len(lnzc)
      elif n_ != len(lnzc):
        raise IndexError("Inconsistent length of array lnzc")
      if n_ is None:
        n_ = len(lptrc)
      elif n_ != len(lptrc):
        raise IndexError("Inconsistent length of array lptrc")
      if n_ is None: n_ = 0
      if lnzc is None: raise TypeError("Invalid type for argument lnzc")
      if lnzc is None:
        lnzc_ = None
      else:
        try:
          lnzc_ = memoryview(lnzc)
        except TypeError:
          try:
            _tmparr_lnzc = array.array("i",lnzc)
          except TypeError:
            raise TypeError("Argument lnzc has wrong type")
          else:
            lnzc_ = memoryview(_tmparr_lnzc)
      
        else:
          if lnzc_.format != "i":
            lnzc_ = memoryview(array.array("i",lnzc))
      
      if lnzc_ is not None and len(lnzc_) != (n_):
        raise ValueError("Array argument lnzc has wrong length")
      if lptrc is None: raise TypeError("Invalid type for argument lptrc")
      if lptrc is None:
        lptrc_ = None
      else:
        try:
          lptrc_ = memoryview(lptrc)
        except TypeError:
          try:
            _tmparr_lptrc = array.array("q",lptrc)
          except TypeError:
            raise TypeError("Argument lptrc has wrong type")
          else:
            lptrc_ = memoryview(_tmparr_lptrc)
      
        else:
          if lptrc_.format != "q":
            lptrc_ = memoryview(array.array("q",lptrc))
      
      if lptrc_ is not None and len(lptrc_) != (n_):
        raise ValueError("Array argument lptrc has wrong length")
      lensubnval_ = None
      if lensubnval_ is None:
        lensubnval_ = len(lsubc)
      elif lensubnval_ != len(lsubc):
        raise IndexError("Inconsistent length of array lsubc")
      if lensubnval_ is None:
        lensubnval_ = len(lvalc)
      elif lensubnval_ != len(lvalc):
        raise IndexError("Inconsistent length of array lvalc")
      if lensubnval_ is None: lensubnval_ = 0
      if lsubc is None: raise TypeError("Invalid type for argument lsubc")
      if lsubc is None:
        lsubc_ = None
      else:
        try:
          lsubc_ = memoryview(lsubc)
        except TypeError:
          try:
            _tmparr_lsubc = array.array("i",lsubc)
          except TypeError:
            raise TypeError("Argument lsubc has wrong type")
          else:
            lsubc_ = memoryview(_tmparr_lsubc)
      
        else:
          if lsubc_.format != "i":
            lsubc_ = memoryview(array.array("i",lsubc))
      
      if lsubc_ is not None and len(lsubc_) != (lensubnval_):
        raise ValueError("Array argument lsubc has wrong length")
      if lvalc is None: raise TypeError("Invalid type for argument lvalc")
      if lvalc is None:
        lvalc_ = None
      else:
        try:
          lvalc_ = memoryview(lvalc)
        except TypeError:
          try:
            _tmparr_lvalc = array.array("d",lvalc)
          except TypeError:
            raise TypeError("Argument lvalc has wrong type")
          else:
            lvalc_ = memoryview(_tmparr_lvalc)
      
        else:
          if lvalc_.format != "d":
            lvalc_ = memoryview(array.array("d",lvalc))
      
      if lvalc_ is not None and len(lvalc_) != (lensubnval_):
        raise ValueError("Array argument lvalc has wrong length")
      if b is None: raise TypeError("Invalid type for argument b")
      _copyback_b = False
      if b is None:
        b_ = None
      else:
        try:
          b_ = memoryview(b)
        except TypeError:
          try:
            _tmparr_b = array.array("d",b)
          except TypeError:
            raise TypeError("Argument b has wrong type")
          else:
            b_ = memoryview(_tmparr_b)
            _copyback_b = True
        else:
          if b_.format != "d":
            b_ = memoryview(array.array("d",b))
            _copyback_b = True
      if b_ is not None and len(b_) != (n_):
        raise ValueError("Array argument b has wrong length")
      res = self.__obj.sparsetriangularsolvedense(transposed_,n_,lnzc_,lptrc_,lensubnval_,lsubc_,lvalc_,b_)
      if res != 0:
        raise Error(rescode(res),"")
      if _copyback_b:
        b[:] = _tmparr_b
    
    def potrf(self,uplo_,n_,a): # 3
      """
      Computes a Cholesky factorization of a dense matrix.
    
      potrf(self,uplo_,n_,a)
        uplo: mosek.uplo. Indicates whether the upper or lower triangular part of the matrix is stored.
        n: int. Dimension of the symmetric matrix.
        a: array of double. A symmetric matrix stored in column-major order.
      """
      if not isinstance(uplo_,uplo): raise TypeError("Argument uplo has wrong type")
      if a is None: raise TypeError("Invalid type for argument a")
      _copyback_a = False
      if a is None:
        a_ = None
      else:
        try:
          a_ = memoryview(a)
        except TypeError:
          try:
            _tmparr_a = array.array("d",a)
          except TypeError:
            raise TypeError("Argument a has wrong type")
          else:
            a_ = memoryview(_tmparr_a)
            _copyback_a = True
        else:
          if a_.format != "d":
            a_ = memoryview(array.array("d",a))
            _copyback_a = True
      if a_ is not None and len(a_) != ((n_) * (n_)):
        raise ValueError("Array argument a has wrong length")
      res = self.__obj.potrf(uplo_,n_,a_)
      if res != 0:
        raise Error(rescode(res),"")
      if _copyback_a:
        a[:] = _tmparr_a
    
    def syeig(self,uplo_,n_,a,w): # 3
      """
      Computes all eigenvalues of a symmetric dense matrix.
    
      syeig(self,uplo_,n_,a,w)
        uplo: mosek.uplo. Indicates whether the upper or lower triangular part is used.
        n: int. Dimension of the symmetric input matrix.
        a: array of double. Input matrix A.
        w: array of double. Array of length at least n containing the eigenvalues of A.
      """
      if not isinstance(uplo_,uplo): raise TypeError("Argument uplo has wrong type")
      if a is None: raise TypeError("Invalid type for argument a")
      if a is None:
        a_ = None
      else:
        try:
          a_ = memoryview(a)
        except TypeError:
          try:
            _tmparr_a = array.array("d",a)
          except TypeError:
            raise TypeError("Argument a has wrong type")
          else:
            a_ = memoryview(_tmparr_a)
      
        else:
          if a_.format != "d":
            a_ = memoryview(array.array("d",a))
      
      if a_ is not None and len(a_) != ((n_) * (n_)):
        raise ValueError("Array argument a has wrong length")
      if w is None: raise TypeError("Invalid type for argument w")
      _copyback_w = False
      if w is None:
        w_ = None
      else:
        try:
          w_ = memoryview(w)
        except TypeError:
          try:
            _tmparr_w = array.array("d",w)
          except TypeError:
            raise TypeError("Argument w has wrong type")
          else:
            w_ = memoryview(_tmparr_w)
            _copyback_w = True
        else:
          if w_.format != "d":
            w_ = memoryview(array.array("d",w))
            _copyback_w = True
      if w_ is not None and len(w_) != (n_):
        raise ValueError("Array argument w has wrong length")
      res = self.__obj.syeig(uplo_,n_,a_,w_)
      if res != 0:
        raise Error(rescode(res),"")
      if _copyback_w:
        w[:] = _tmparr_w
    
    def syevd(self,uplo_,n_,a,w): # 3
      """
      Computes all the eigenvalues and eigenvectors of a symmetric dense matrix, and thus its eigenvalue decomposition.
    
      syevd(self,uplo_,n_,a,w)
        uplo: mosek.uplo. Indicates whether the upper or lower triangular part is used.
        n: int. Dimension of the symmetric input matrix.
        a: array of double. Input matrix A.
        w: array of double. Array of length at least n containing the eigenvalues of A.
      """
      if not isinstance(uplo_,uplo): raise TypeError("Argument uplo has wrong type")
      if a is None: raise TypeError("Invalid type for argument a")
      _copyback_a = False
      if a is None:
        a_ = None
      else:
        try:
          a_ = memoryview(a)
        except TypeError:
          try:
            _tmparr_a = array.array("d",a)
          except TypeError:
            raise TypeError("Argument a has wrong type")
          else:
            a_ = memoryview(_tmparr_a)
            _copyback_a = True
        else:
          if a_.format != "d":
            a_ = memoryview(array.array("d",a))
            _copyback_a = True
      if a_ is not None and len(a_) != ((n_) * (n_)):
        raise ValueError("Array argument a has wrong length")
      if w is None: raise TypeError("Invalid type for argument w")
      _copyback_w = False
      if w is None:
        w_ = None
      else:
        try:
          w_ = memoryview(w)
        except TypeError:
          try:
            _tmparr_w = array.array("d",w)
          except TypeError:
            raise TypeError("Argument w has wrong type")
          else:
            w_ = memoryview(_tmparr_w)
            _copyback_w = True
        else:
          if w_.format != "d":
            w_ = memoryview(array.array("d",w))
            _copyback_w = True
      if w_ is not None and len(w_) != (n_):
        raise ValueError("Array argument w has wrong length")
      res = self.__obj.syevd(uplo_,n_,a_,w_)
      if res != 0:
        raise Error(rescode(res),"")
      if _copyback_w:
        w[:] = _tmparr_w
      if _copyback_a:
        a[:] = _tmparr_a
    
    @staticmethod
    def licensecleanup(): # 3
      """
      Stops all threads and delete all handles used by the license system.
    
      licensecleanup()
      """
      res = _msk.Env.licensecleanup()
      if res != 0:
        raise Error(rescode(res),"")
    

class Task:
    def __init__(self,env,numcon=0,numvar=0):
        if isinstance(env,Task):
            self.__obj = _msk.Task(None,numcon,numvar,other=env._Task__obj)
        else:
            self.__obj = _msk.Task(env._Env__obj,numcon,numvar)

    def __del__(self):
        try:
            o = self.__obj
        except AttributeError:
            pass
        else:
            o.dispose()
            del self.__obj

    def __enter__(self):
        return self

    def __exit__(self,exc_type,exc_value,traceback):
        self.__del__()

    def __getlasterror(self,res):
        res,msg = self.__obj.getlasterror()
        return rescode(res),msg

    def set_Stream(self,whichstream,func):
        if isinstance(whichstream, streamtype):
            if func is None:
                self.__obj.remove_Stream(whichstream)
            else:
                self.__obj.set_Stream(whichstream,func)
        else:
            raise TypeError("Invalid stream %s" % whichstream)

    def set_Progress(self,func):
        """
        Set the progress callback function. If func is None, progress callbacks are detached and disabled.
        """
        self.__obj.set_Progress(func)

    def set_InfoCallback(self,func):
        """
        Set the progress callback function. If func is None, progress callbacks are detached and disabled.
        """
        self.__obj.set_InfoCallback(func)


    def writeSC(self,scfile,taskfile):
        self.__obj.writeSC(scfile,taskfile)
        
    def removeSCeval(self):
        self.__obj.removeSCeval()

    def putSCeval(self,
                  opro  = None,
                  oprjo = None,
                  oprfo = None,
                  oprgo = None,
                  oprho = None,
                  oprc  = None,
                  opric = None,
                  oprjc = None,
                  oprfc = None,
                  oprgc = None,
                  oprhc = None):
        """
        Input data for SCopt. If other SCopt data was inputted before, the new data replaces the old.

        Defining a non-liner objective requires that all of the arguments opro,
        oprjo, oprfo, oprgo and oprho are defined. If present, all these arrays
        must have the same length.
        Defining non-linear constraints requires that all of the arguments oprc,
        opric, oprjc, oprfc, oprgc and oprhc are defined. If present, all these
        arrays must have the same length.

        Parameters:
          [opro]  Array of mosek.scopr values. Defines the functions used for the objective.
          [oprjo] Array of indexes. Defines the variable indexes used in non-linear objective function.
          [oprfo] Array of coefficients. Defines constants used in the objective.
          [oprgo] Array of coefficients. Defines constants used in the objective.
          [oprho] Array of coefficients. Defines constants used in the objective.
          [oprc]  Array of mosek.scopr values. Defines the functions used for the constraints.
          [opric] Array of indexes. Defines the variable indexes used in the non-linear constraint functions.
          [oprjc] Array of indexes. Defines the constraint indexes where non-linear functions appear.
          [oprfc] Array of coefficients. Defines constants used in the non-linear constraints.
          [oprgc] Array of coefficients. Defines constants used in the non-linear constraints.
          [oprhc] Array of coefficients. Defines constants used in the non-linear constraints.
        """

        if (    opro  is not None
            and oprjo is not None
            and oprfo is not None
            and oprgo is not None
            and oprho is not None):
            # we have objective.
            try:
                numnlov = len(opro)
                if (   numnlov != len(oprjo)
                    or numnlov != len(oprfo)
                    or numnlov != len(oprgo)
                    or numnlov != len(oprho)):
                    raise SCoptException("Arguments opro, oprjo, oprfo, oprgo and oprho have different lengths")
                if not all([ isinstance(i,scopr) for i in opro ]):
                    raise SCoptException("Argument opro must be an array of mosek.scopr")

                _opro  = array.array('i',opro)
                _oprjo = array.array('i',oprjo)
                _oprfo = array.array('d',oprfo)
                _oprgo = array.array('d',oprgo)
                _oprho = array.array('d',oprho)
            except TypeError:
                raise ValueError("Arguments opro, oprjo, oprfo, oprgo and oprho must be arrays")
        else:
            numnlov = 0

        if (    oprc  is not None
            and opric is not None
            and oprjc is not None
            and oprfc is not None
            and oprgc is not None
            and oprhc is not None):
            # we have objective.
            try:
                numnlcv = len(oprc)
                if (   numnlcv != len(opric)
                    or numnlcv != len(oprjc)
                    or numnlcv != len(oprfc)
                    or numnlcv != len(oprgc)
                    or numnlcv != len(oprhc)):
                    raise ValueError("Arguments oprc, opric, oprjc, oprfc, oprgc and oprhc have different lengths") 
                if not all([isinstance(i,scopr) for i in oprc]):
                    raise ValieError("Argument oprc must be an array of mosek.scopr")
                _oprc  = array.array('i',oprc)
                _opric = array.array('i',opric)
                _oprjc = array.array('i',oprjc)
                _oprfc = array.array('d',oprfc)
                _oprgc = array.array('d',oprgc)
                _oprhc = array.array('d',oprhc)
            except TypeError:
                # not 'len' operation
                raise ValueError("Arguments oprc, opric, oprjc, oprfc, oprgc and oprhc must be arrays") 
        else:
            numnlcv = 0

        if numnlov > 0 or numnlcv > 0:
            args = []
            if numnlov > 0:
                args.append(memoryview(_opro))
                args.append(memoryview(_oprjo))
                args.append(memoryview(_oprfo))
                args.append(memoryview(_oprgo))
                args.append(memoryview(_oprho))
            else:
                args.extend([ None, None, None, None, None ])

            if numnlcv > 0:
                args.append(memoryview(_oprc))
                args.append(memoryview(_opric))
                args.append(memoryview(_oprjc))
                args.append(memoryview(_oprfc))
                args.append(memoryview(_oprgc))
                args.append(memoryview(_oprhc))
            else:
                args.extend([ None, None, None, None, None, None ])

            print(len(args))
            res = self.__obj.putSCeval(*args)

    def analyzeproblem(self,whichstream_): # 3
      """
      Analyze the data of a task.
    
      analyzeproblem(self,whichstream_)
        whichstream: mosek.streamtype. Index of the stream.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      res = self.__obj.analyzeproblem(whichstream_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def analyzenames(self,whichstream_,nametype_): # 3
      """
      Analyze the names and issue an error for the first invalid name.
    
      analyzenames(self,whichstream_,nametype_)
        whichstream: mosek.streamtype. Index of the stream.
        nametype: mosek.nametype. The type of names e.g. valid in MPS or LP files.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      if not isinstance(nametype_,nametype): raise TypeError("Argument nametype has wrong type")
      res = self.__obj.analyzenames(whichstream_,nametype_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def analyzesolution(self,whichstream_,whichsol_): # 3
      """
      Print information related to the quality of the solution.
    
      analyzesolution(self,whichstream_,whichsol_)
        whichstream: mosek.streamtype. Index of the stream.
        whichsol: mosek.soltype. Selects a solution.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res = self.__obj.analyzesolution(whichstream_,whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def initbasissolve(self,basis): # 3
      """
      Prepare a task for basis solver.
    
      initbasissolve(self,basis)
        basis: array of int. The array of basis indexes to use.
      """
      _copyback_basis = False
      if basis is None:
        basis_ = None
      else:
        try:
          basis_ = memoryview(basis)
        except TypeError:
          try:
            _tmparr_basis = array.array("i",basis)
          except TypeError:
            raise TypeError("Argument basis has wrong type")
          else:
            basis_ = memoryview(_tmparr_basis)
            _copyback_basis = True
        else:
          if basis_.format != "i":
            basis_ = memoryview(array.array("i",basis))
            _copyback_basis = True
      if basis_ is not None and len(basis_) != self.getnumcon():
        raise ValueError("Array argument basis has wrong length")
      res = self.__obj.initbasissolve(basis_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_basis:
        basis[:] = _tmparr_basis
    
    def solvewithbasis(self,transp_,numnz_,sub,val): # 3
      """
      Solve a linear equation system involving a basis matrix.
    
      solvewithbasis(self,transp_,numnz_,sub,val)
        transp: int. Controls which problem formulation is solved.
        numnz: int. Input (number of non-zeros in right-hand side) and output (number of non-zeros in solution vector).
        sub: array of int. Input (indexes of non-zeros in right-hand side) and output (indexes of non-zeros in solution vector).
        val: array of double. Input (right-hand side values) and output (solution vector values).
      returns: numnz
        numnz: int. Input (number of non-zeros in right-hand side) and output (number of non-zeros in solution vector).
      """
      _copyback_sub = False
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
            _copyback_sub = True
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
            _copyback_sub = True
      if sub_ is not None and len(sub_) != self.getnumcon():
        raise ValueError("Array argument sub has wrong length")
      _copyback_val = False
      if val is None:
        val_ = None
      else:
        try:
          val_ = memoryview(val)
        except TypeError:
          try:
            _tmparr_val = array.array("d",val)
          except TypeError:
            raise TypeError("Argument val has wrong type")
          else:
            val_ = memoryview(_tmparr_val)
            _copyback_val = True
        else:
          if val_.format != "d":
            val_ = memoryview(array.array("d",val))
            _copyback_val = True
      if val_ is not None and len(val_) != self.getnumcon():
        raise ValueError("Array argument val has wrong length")
      res,resargs = self.__obj.solvewithbasis(transp_,numnz_,sub_,val_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numnz_return_value = resargs
      if _copyback_val:
        val[:] = _tmparr_val
      if _copyback_sub:
        sub[:] = _tmparr_sub
      return _numnz_return_value
    
    def basiscond(self): # 3
      """
      Computes conditioning information for the basis matrix.
    
      basiscond(self)
      returns: nrmbasis,nrminvbasis
        nrmbasis: double. An estimate for the 1-norm of the basis.
        nrminvbasis: double. An estimate for the 1-norm of the inverse of the basis.
      """
      res,resargs = self.__obj.basiscond()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _nrmbasis_return_value,_nrminvbasis_return_value = resargs
      return _nrmbasis_return_value,_nrminvbasis_return_value
    
    def appendcons(self,num_): # 3
      """
      Appends a number of constraints to the optimization task.
    
      appendcons(self,num_)
        num: int. Number of constraints which should be appended.
      """
      res = self.__obj.appendcons(num_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def appendvars(self,num_): # 3
      """
      Appends a number of variables to the optimization task.
    
      appendvars(self,num_)
        num: int. Number of variables which should be appended.
      """
      res = self.__obj.appendvars(num_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def removecons(self,subset): # 3
      """
      Removes a number of constraints.
    
      removecons(self,subset)
        subset: array of int. Indexes of constraints which should be removed.
      """
      num_ = None
      if num_ is None:
        num_ = len(subset)
      elif num_ != len(subset):
        raise IndexError("Inconsistent length of array subset")
      if num_ is None: num_ = 0
      if subset is None: raise TypeError("Invalid type for argument subset")
      if subset is None:
        subset_ = None
      else:
        try:
          subset_ = memoryview(subset)
        except TypeError:
          try:
            _tmparr_subset = array.array("i",subset)
          except TypeError:
            raise TypeError("Argument subset has wrong type")
          else:
            subset_ = memoryview(_tmparr_subset)
      
        else:
          if subset_.format != "i":
            subset_ = memoryview(array.array("i",subset))
      
      res = self.__obj.removecons(num_,subset_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def removevars(self,subset): # 3
      """
      Removes a number of variables.
    
      removevars(self,subset)
        subset: array of int. Indexes of variables which should be removed.
      """
      num_ = None
      if num_ is None:
        num_ = len(subset)
      elif num_ != len(subset):
        raise IndexError("Inconsistent length of array subset")
      if num_ is None: num_ = 0
      if subset is None: raise TypeError("Invalid type for argument subset")
      if subset is None:
        subset_ = None
      else:
        try:
          subset_ = memoryview(subset)
        except TypeError:
          try:
            _tmparr_subset = array.array("i",subset)
          except TypeError:
            raise TypeError("Argument subset has wrong type")
          else:
            subset_ = memoryview(_tmparr_subset)
      
        else:
          if subset_.format != "i":
            subset_ = memoryview(array.array("i",subset))
      
      res = self.__obj.removevars(num_,subset_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def removebarvars(self,subset): # 3
      """
      Removes a number of symmetric matrices.
    
      removebarvars(self,subset)
        subset: array of int. Indexes of symmetric matrices which should be removed.
      """
      num_ = None
      if num_ is None:
        num_ = len(subset)
      elif num_ != len(subset):
        raise IndexError("Inconsistent length of array subset")
      if num_ is None: num_ = 0
      if subset is None: raise TypeError("Invalid type for argument subset")
      if subset is None:
        subset_ = None
      else:
        try:
          subset_ = memoryview(subset)
        except TypeError:
          try:
            _tmparr_subset = array.array("i",subset)
          except TypeError:
            raise TypeError("Argument subset has wrong type")
          else:
            subset_ = memoryview(_tmparr_subset)
      
        else:
          if subset_.format != "i":
            subset_ = memoryview(array.array("i",subset))
      
      res = self.__obj.removebarvars(num_,subset_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def removecones(self,subset): # 3
      """
      Removes a number of conic constraints from the problem.
    
      removecones(self,subset)
        subset: array of int. Indexes of cones which should be removed.
      """
      num_ = None
      if num_ is None:
        num_ = len(subset)
      elif num_ != len(subset):
        raise IndexError("Inconsistent length of array subset")
      if num_ is None: num_ = 0
      if subset is None: raise TypeError("Invalid type for argument subset")
      if subset is None:
        subset_ = None
      else:
        try:
          subset_ = memoryview(subset)
        except TypeError:
          try:
            _tmparr_subset = array.array("i",subset)
          except TypeError:
            raise TypeError("Argument subset has wrong type")
          else:
            subset_ = memoryview(_tmparr_subset)
      
        else:
          if subset_.format != "i":
            subset_ = memoryview(array.array("i",subset))
      
      res = self.__obj.removecones(num_,subset_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def appendbarvars(self,dim): # 3
      """
      Appends semidefinite variables to the problem.
    
      appendbarvars(self,dim)
        dim: array of int. Dimensions of symmetric matrix variables to be added.
      """
      num_ = None
      if num_ is None:
        num_ = len(dim)
      elif num_ != len(dim):
        raise IndexError("Inconsistent length of array dim")
      if num_ is None: num_ = 0
      if dim is None: raise TypeError("Invalid type for argument dim")
      if dim is None:
        dim_ = None
      else:
        try:
          dim_ = memoryview(dim)
        except TypeError:
          try:
            _tmparr_dim = array.array("i",dim)
          except TypeError:
            raise TypeError("Argument dim has wrong type")
          else:
            dim_ = memoryview(_tmparr_dim)
      
        else:
          if dim_.format != "i":
            dim_ = memoryview(array.array("i",dim))
      
      res = self.__obj.appendbarvars(num_,dim_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def appendcone(self,ct_,conepar_,submem): # 3
      """
      Appends a new conic constraint to the problem.
    
      appendcone(self,ct_,conepar_,submem)
        ct: mosek.conetype. Specifies the type of the cone.
        conepar: double. This argument is currently not used. It can be set to 0
        submem: array of int. Variable subscripts of the members in the cone.
      """
      if not isinstance(ct_,conetype): raise TypeError("Argument ct has wrong type")
      nummem_ = None
      if nummem_ is None:
        nummem_ = len(submem)
      elif nummem_ != len(submem):
        raise IndexError("Inconsistent length of array submem")
      if nummem_ is None: nummem_ = 0
      if submem is None: raise TypeError("Invalid type for argument submem")
      if submem is None:
        submem_ = None
      else:
        try:
          submem_ = memoryview(submem)
        except TypeError:
          try:
            _tmparr_submem = array.array("i",submem)
          except TypeError:
            raise TypeError("Argument submem has wrong type")
          else:
            submem_ = memoryview(_tmparr_submem)
      
        else:
          if submem_.format != "i":
            submem_ = memoryview(array.array("i",submem))
      
      res = self.__obj.appendcone(ct_,conepar_,nummem_,submem_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def appendconeseq(self,ct_,conepar_,nummem_,j_): # 3
      """
      Appends a new conic constraint to the problem.
    
      appendconeseq(self,ct_,conepar_,nummem_,j_)
        ct: mosek.conetype. Specifies the type of the cone.
        conepar: double. This argument is currently not used. It can be set to 0
        nummem: int. Number of member variables in the cone.
        j: int. Index of the first variable in the conic constraint.
      """
      if not isinstance(ct_,conetype): raise TypeError("Argument ct has wrong type")
      res = self.__obj.appendconeseq(ct_,conepar_,nummem_,j_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def appendconesseq(self,ct,conepar,nummem,j_): # 3
      """
      Appends multiple conic constraints to the problem.
    
      appendconesseq(self,ct,conepar,nummem,j_)
        ct: array of mosek.conetype. Specifies the type of the cone.
        conepar: array of double. This argument is currently not used. It can be set to 0
        nummem: array of int. Numbers of member variables in the cones.
        j: int. Index of the first variable in the first cone to be appended.
      """
      num_ = None
      if num_ is None:
        num_ = len(ct)
      elif num_ != len(ct):
        raise IndexError("Inconsistent length of array ct")
      if num_ is None:
        num_ = len(conepar)
      elif num_ != len(conepar):
        raise IndexError("Inconsistent length of array conepar")
      if num_ is None:
        num_ = len(nummem)
      elif num_ != len(nummem):
        raise IndexError("Inconsistent length of array nummem")
      if num_ is None: num_ = 0
      if ct is None: raise TypeError("Invalid type for argument ct")
      if ct is None:
        ct_ = None
      else:
        try:
          ct_ = memoryview(ct)
        except TypeError:
          try:
            _tmparr_ct = array.array("i",ct)
          except TypeError:
            raise TypeError("Argument ct has wrong type")
          else:
            ct_ = memoryview(_tmparr_ct)
      
        else:
          if ct_.format != "i":
            ct_ = memoryview(array.array("i",ct))
      
      if conepar is None: raise TypeError("Invalid type for argument conepar")
      if conepar is None:
        conepar_ = None
      else:
        try:
          conepar_ = memoryview(conepar)
        except TypeError:
          try:
            _tmparr_conepar = array.array("d",conepar)
          except TypeError:
            raise TypeError("Argument conepar has wrong type")
          else:
            conepar_ = memoryview(_tmparr_conepar)
      
        else:
          if conepar_.format != "d":
            conepar_ = memoryview(array.array("d",conepar))
      
      if nummem is None: raise TypeError("Invalid type for argument nummem")
      if nummem is None:
        nummem_ = None
      else:
        try:
          nummem_ = memoryview(nummem)
        except TypeError:
          try:
            _tmparr_nummem = array.array("i",nummem)
          except TypeError:
            raise TypeError("Argument nummem has wrong type")
          else:
            nummem_ = memoryview(_tmparr_nummem)
      
        else:
          if nummem_.format != "i":
            nummem_ = memoryview(array.array("i",nummem))
      
      res = self.__obj.appendconesseq(num_,ct_,conepar_,nummem_,j_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def chgbound(self,accmode_,i_,lower_,finite_,value_): # 3
      """
      Changes the bounds for one constraint or variable.
    
      chgbound(self,accmode_,i_,lower_,finite_,value_)
        accmode: mosek.accmode. Defines if operations are performed row-wise (constraint-oriented) or column-wise (variable-oriented).
        i: int. Index of the constraint or variable for which the bounds should be changed.
        lower: int. If non-zero, then the lower bound is changed, otherwise the upper bound is changed.
        finite: int. If non-zero, then the given value is assumed to be finite.
        value: double. New value for the bound.
      """
      if not isinstance(accmode_,accmode): raise TypeError("Argument accmode has wrong type")
      res = self.__obj.chgbound(accmode_,i_,lower_,finite_,value_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def chgconbound(self,i_,lower_,finite_,value_): # 3
      """
      Changes the bounds for one constraint.
    
      chgconbound(self,i_,lower_,finite_,value_)
        i: int. Index of the constraint for which the bounds should be changed.
        lower: int. If non-zero, then the lower bound is changed, otherwise the upper bound is changed.
        finite: int. If non-zero, then the given value is assumed to be finite.
        value: double. New value for the bound.
      """
      res = self.__obj.chgconbound(i_,lower_,finite_,value_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def chgvarbound(self,j_,lower_,finite_,value_): # 3
      """
      Changes the bounds for one variable.
    
      chgvarbound(self,j_,lower_,finite_,value_)
        j: int. Index of the variable for which the bounds should be changed.
        lower: int. If non-zero, then the lower bound is changed, otherwise the upper bound is changed.
        finite: int. If non-zero, then the given value is assumed to be finite.
        value: double. New value for the bound.
      """
      res = self.__obj.chgvarbound(j_,lower_,finite_,value_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getaij(self,i_,j_): # 3
      """
      Obtains a single coefficient in linear constraint matrix.
    
      getaij(self,i_,j_)
        i: int. Row index of the coefficient to be returned.
        j: int. Column index of the coefficient to be returned.
      returns: aij
        aij: double. Returns the requested coefficient.
      """
      res,resargs = self.__obj.getaij(i_,j_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _aij_return_value = resargs
      return _aij_return_value
    
    def getapiecenumnz(self,firsti_,lasti_,firstj_,lastj_): # 3
      """
      Obtains the number non-zeros in a rectangular piece of the linear constraint matrix.
    
      getapiecenumnz(self,firsti_,lasti_,firstj_,lastj_)
        firsti: int. Index of the first row in the rectangular piece.
        lasti: int. Index of the last row plus one in the rectangular piece.
        firstj: int. Index of the first column in the rectangular piece.
        lastj: int. Index of the last column plus one in the rectangular piece.
      returns: numnz
        numnz: int. Number of non-zero elements in the rectangular piece of the linear constraint matrix.
      """
      res,resargs = self.__obj.getapiecenumnz(firsti_,lasti_,firstj_,lastj_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numnz_return_value = resargs
      return _numnz_return_value
    
    def getacolnumnz(self,i_): # 3
      """
      Obtains the number of non-zero elements in one column of the linear constraint matrix
    
      getacolnumnz(self,i_)
        i: int. Index of the column.
      returns: nzj
        nzj: int. Number of non-zeros in the j'th column of (A).
      """
      res,resargs = self.__obj.getacolnumnz(i_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _nzj_return_value = resargs
      return _nzj_return_value
    
    def getacol(self,j_,subj,valj): # 3
      """
      Obtains one column of the linear constraint matrix.
    
      getacol(self,j_,subj,valj)
        j: int. Index of the column.
        subj: array of int. Row indices of the non-zeros in the column obtained.
        valj: array of double. Numerical values in the column obtained.
      returns: nzj
        nzj: int. Number of non-zeros in the column obtained.
      """
      if subj is None: raise TypeError("Invalid type for argument subj")
      _copyback_subj = False
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
            _copyback_subj = True
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
            _copyback_subj = True
      if subj_ is not None and len(subj_) != self.getacolnumnz((j_)):
        raise ValueError("Array argument subj has wrong length")
      if valj is None: raise TypeError("Invalid type for argument valj")
      _copyback_valj = False
      if valj is None:
        valj_ = None
      else:
        try:
          valj_ = memoryview(valj)
        except TypeError:
          try:
            _tmparr_valj = array.array("d",valj)
          except TypeError:
            raise TypeError("Argument valj has wrong type")
          else:
            valj_ = memoryview(_tmparr_valj)
            _copyback_valj = True
        else:
          if valj_.format != "d":
            valj_ = memoryview(array.array("d",valj))
            _copyback_valj = True
      if valj_ is not None and len(valj_) != self.getacolnumnz((j_)):
        raise ValueError("Array argument valj has wrong length")
      res,resargs = self.__obj.getacol(j_,subj_,valj_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _nzj_return_value = resargs
      if _copyback_valj:
        valj[:] = _tmparr_valj
      if _copyback_subj:
        subj[:] = _tmparr_subj
      return _nzj_return_value
    
    def getarownumnz(self,i_): # 3
      """
      Obtains the number of non-zero elements in one row of the linear constraint matrix
    
      getarownumnz(self,i_)
        i: int. Index of the row.
      returns: nzi
        nzi: int. Number of non-zeros in the i'th row of `A`.
      """
      res,resargs = self.__obj.getarownumnz(i_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _nzi_return_value = resargs
      return _nzi_return_value
    
    def getarow(self,i_,subi,vali): # 3
      """
      Obtains one row of the linear constraint matrix.
    
      getarow(self,i_,subi,vali)
        i: int. Index of the row.
        subi: array of int. Column indices of the non-zeros in the row obtained.
        vali: array of double. Numerical values of the row obtained.
      returns: nzi
        nzi: int. Number of non-zeros in the row obtained.
      """
      if subi is None: raise TypeError("Invalid type for argument subi")
      _copyback_subi = False
      if subi is None:
        subi_ = None
      else:
        try:
          subi_ = memoryview(subi)
        except TypeError:
          try:
            _tmparr_subi = array.array("i",subi)
          except TypeError:
            raise TypeError("Argument subi has wrong type")
          else:
            subi_ = memoryview(_tmparr_subi)
            _copyback_subi = True
        else:
          if subi_.format != "i":
            subi_ = memoryview(array.array("i",subi))
            _copyback_subi = True
      if subi_ is not None and len(subi_) != self.getarownumnz((i_)):
        raise ValueError("Array argument subi has wrong length")
      if vali is None: raise TypeError("Invalid type for argument vali")
      _copyback_vali = False
      if vali is None:
        vali_ = None
      else:
        try:
          vali_ = memoryview(vali)
        except TypeError:
          try:
            _tmparr_vali = array.array("d",vali)
          except TypeError:
            raise TypeError("Argument vali has wrong type")
          else:
            vali_ = memoryview(_tmparr_vali)
            _copyback_vali = True
        else:
          if vali_.format != "d":
            vali_ = memoryview(array.array("d",vali))
            _copyback_vali = True
      if vali_ is not None and len(vali_) != self.getarownumnz((i_)):
        raise ValueError("Array argument vali has wrong length")
      res,resargs = self.__obj.getarow(i_,subi_,vali_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _nzi_return_value = resargs
      if _copyback_vali:
        vali[:] = _tmparr_vali
      if _copyback_subi:
        subi[:] = _tmparr_subi
      return _nzi_return_value
    
    def getaslicenumnz(self,accmode_,first_,last_): # 3
      """
      Obtains the number of non-zeros in a slice of rows or columns of the coefficient matrix.
    
      getaslicenumnz(self,accmode_,first_,last_)
        accmode: mosek.accmode. Defines whether non-zeros are counted in a column slice or a row slice.
        first: int. Index of the first row or column in the sequence.
        last: int. Index of the last row or column plus one in the sequence.
      returns: numnz
        numnz: long. Number of non-zeros in the slice.
      """
      if not isinstance(accmode_,accmode): raise TypeError("Argument accmode has wrong type")
      res,resargs = self.__obj.getaslicenumnz64(accmode_,first_,last_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numnz_return_value = resargs
      return _numnz_return_value
    
    def getaslice(self,accmode_,first_,last_,ptrb,ptre,sub,val): # 3
      """
      Obtains a sequence of rows or columns from the coefficient matrix.
    
      getaslice(self,accmode_,first_,last_,ptrb,ptre,sub,val)
        accmode: mosek.accmode. Defines whether a column slice or a row slice is requested.
        first: int. Index of the first row or column in the sequence.
        last: int. Index of the last row or column in the sequence plus one.
        ptrb: array of long. Row or column start pointers.
        ptre: array of long. Row or column end pointers.
        sub: array of int. Contains the row or column subscripts.
        val: array of double. Contains the coefficient values.
      """
      if not isinstance(accmode_,accmode): raise TypeError("Argument accmode has wrong type")
      maxnumnz_ = self.getaslicenumnz((accmode_),(first_),(last_))
      _copyback_ptrb = False
      if ptrb is None:
        ptrb_ = None
      else:
        try:
          ptrb_ = memoryview(ptrb)
        except TypeError:
          try:
            _tmparr_ptrb = array.array("q",ptrb)
          except TypeError:
            raise TypeError("Argument ptrb has wrong type")
          else:
            ptrb_ = memoryview(_tmparr_ptrb)
            _copyback_ptrb = True
        else:
          if ptrb_.format != "q":
            ptrb_ = memoryview(array.array("q",ptrb))
            _copyback_ptrb = True
      if ptrb_ is not None and len(ptrb_) != ((last_) - (first_)):
        raise ValueError("Array argument ptrb has wrong length")
      _copyback_ptre = False
      if ptre is None:
        ptre_ = None
      else:
        try:
          ptre_ = memoryview(ptre)
        except TypeError:
          try:
            _tmparr_ptre = array.array("q",ptre)
          except TypeError:
            raise TypeError("Argument ptre has wrong type")
          else:
            ptre_ = memoryview(_tmparr_ptre)
            _copyback_ptre = True
        else:
          if ptre_.format != "q":
            ptre_ = memoryview(array.array("q",ptre))
            _copyback_ptre = True
      if ptre_ is not None and len(ptre_) != ((last_) - (first_)):
        raise ValueError("Array argument ptre has wrong length")
      _copyback_sub = False
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
            _copyback_sub = True
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
            _copyback_sub = True
      if sub_ is not None and len(sub_) != (maxnumnz_):
        raise ValueError("Array argument sub has wrong length")
      _copyback_val = False
      if val is None:
        val_ = None
      else:
        try:
          val_ = memoryview(val)
        except TypeError:
          try:
            _tmparr_val = array.array("d",val)
          except TypeError:
            raise TypeError("Argument val has wrong type")
          else:
            val_ = memoryview(_tmparr_val)
            _copyback_val = True
        else:
          if val_.format != "d":
            val_ = memoryview(array.array("d",val))
            _copyback_val = True
      if val_ is not None and len(val_) != (maxnumnz_):
        raise ValueError("Array argument val has wrong length")
      res = self.__obj.getaslice64(accmode_,first_,last_,maxnumnz_,len(sub),ptrb_,ptre_,sub_,val_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_val:
        val[:] = _tmparr_val
      if _copyback_sub:
        sub[:] = _tmparr_sub
      if _copyback_ptre:
        ptre[:] = _tmparr_ptre
      if _copyback_ptrb:
        ptrb[:] = _tmparr_ptrb
    
    def getarowslicetrip(self,first_,last_,subi,subj,val): # 3
      """
      Obtains a sequence of rows from the coefficient matrix in sparse triplet format.
    
      getarowslicetrip(self,first_,last_,subi,subj,val)
        first: int. Index of the first row in the sequence.
        last: int. Index of the last row in the sequence plus one.
        subi: array of int. Constraint subscripts.
        subj: array of int. Column subscripts.
        val: array of double. Values.
      """
      maxnumnz_ = self.getaslicenumnz(accmode.con,(first_),(last_))
      _copyback_subi = False
      if subi is None:
        subi_ = None
      else:
        try:
          subi_ = memoryview(subi)
        except TypeError:
          try:
            _tmparr_subi = array.array("i",subi)
          except TypeError:
            raise TypeError("Argument subi has wrong type")
          else:
            subi_ = memoryview(_tmparr_subi)
            _copyback_subi = True
        else:
          if subi_.format != "i":
            subi_ = memoryview(array.array("i",subi))
            _copyback_subi = True
      if subi_ is not None and len(subi_) != (maxnumnz_):
        raise ValueError("Array argument subi has wrong length")
      _copyback_subj = False
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
            _copyback_subj = True
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
            _copyback_subj = True
      if subj_ is not None and len(subj_) != (maxnumnz_):
        raise ValueError("Array argument subj has wrong length")
      _copyback_val = False
      if val is None:
        val_ = None
      else:
        try:
          val_ = memoryview(val)
        except TypeError:
          try:
            _tmparr_val = array.array("d",val)
          except TypeError:
            raise TypeError("Argument val has wrong type")
          else:
            val_ = memoryview(_tmparr_val)
            _copyback_val = True
        else:
          if val_.format != "d":
            val_ = memoryview(array.array("d",val))
            _copyback_val = True
      if val_ is not None and len(val_) != (maxnumnz_):
        raise ValueError("Array argument val has wrong length")
      res = self.__obj.getarowslicetrip(first_,last_,maxnumnz_,len(subi),subi_,subj_,val_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_val:
        val[:] = _tmparr_val
      if _copyback_subj:
        subj[:] = _tmparr_subj
      if _copyback_subi:
        subi[:] = _tmparr_subi
    
    def getacolslicetrip(self,first_,last_,subi,subj,val): # 3
      """
      Obtains a sequence of columns from the coefficient matrix in triplet format.
    
      getacolslicetrip(self,first_,last_,subi,subj,val)
        first: int. Index of the first column in the sequence.
        last: int. Index of the last column in the sequence plus one.
        subi: array of int. Constraint subscripts.
        subj: array of int. Column subscripts.
        val: array of double. Values.
      """
      maxnumnz_ = self.getaslicenumnz(accmode.var,(first_),(last_))
      _copyback_subi = False
      if subi is None:
        subi_ = None
      else:
        try:
          subi_ = memoryview(subi)
        except TypeError:
          try:
            _tmparr_subi = array.array("i",subi)
          except TypeError:
            raise TypeError("Argument subi has wrong type")
          else:
            subi_ = memoryview(_tmparr_subi)
            _copyback_subi = True
        else:
          if subi_.format != "i":
            subi_ = memoryview(array.array("i",subi))
            _copyback_subi = True
      if subi_ is not None and len(subi_) != (maxnumnz_):
        raise ValueError("Array argument subi has wrong length")
      _copyback_subj = False
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
            _copyback_subj = True
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
            _copyback_subj = True
      if subj_ is not None and len(subj_) != (maxnumnz_):
        raise ValueError("Array argument subj has wrong length")
      _copyback_val = False
      if val is None:
        val_ = None
      else:
        try:
          val_ = memoryview(val)
        except TypeError:
          try:
            _tmparr_val = array.array("d",val)
          except TypeError:
            raise TypeError("Argument val has wrong type")
          else:
            val_ = memoryview(_tmparr_val)
            _copyback_val = True
        else:
          if val_.format != "d":
            val_ = memoryview(array.array("d",val))
            _copyback_val = True
      if val_ is not None and len(val_) != (maxnumnz_):
        raise ValueError("Array argument val has wrong length")
      res = self.__obj.getacolslicetrip(first_,last_,maxnumnz_,len(subi),subi_,subj_,val_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_val:
        val[:] = _tmparr_val
      if _copyback_subj:
        subj[:] = _tmparr_subj
      if _copyback_subi:
        subi[:] = _tmparr_subi
    
    def getconbound(self,i_): # 3
      """
      Obtains bound information for one constraint.
    
      getconbound(self,i_)
        i: int. Index of the constraint for which the bound information should be obtained.
      returns: bk,bl,bu
        bk: mosek.boundkey. Bound keys.
        bl: double. Values for lower bounds.
        bu: double. Values for upper bounds.
      """
      res,resargs = self.__obj.getconbound(i_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _bk_return_value,_bl_return_value,_bu_return_value = resargs
      _bk_return_value = boundkey(_bk_return_value)
      return _bk_return_value,_bl_return_value,_bu_return_value
    
    def getvarbound(self,i_): # 3
      """
      Obtains bound information for one variable.
    
      getvarbound(self,i_)
        i: int. Index of the variable for which the bound information should be obtained.
      returns: bk,bl,bu
        bk: mosek.boundkey. Bound keys.
        bl: double. Values for lower bounds.
        bu: double. Values for upper bounds.
      """
      res,resargs = self.__obj.getvarbound(i_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _bk_return_value,_bl_return_value,_bu_return_value = resargs
      _bk_return_value = boundkey(_bk_return_value)
      return _bk_return_value,_bl_return_value,_bu_return_value
    
    def getbound(self,accmode_,i_): # 3
      """
      Obtains bound information for one constraint or variable.
    
      getbound(self,accmode_,i_)
        accmode: mosek.accmode. Defines if operations are performed row-wise (constraint-oriented) or column-wise (variable-oriented).
        i: int. Index of the constraint or variable for which the bound information should be obtained.
      returns: bk,bl,bu
        bk: mosek.boundkey. Bound keys.
        bl: double. Values for lower bounds.
        bu: double. Values for upper bounds.
      """
      if not isinstance(accmode_,accmode): raise TypeError("Argument accmode has wrong type")
      res,resargs = self.__obj.getbound(accmode_,i_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _bk_return_value,_bl_return_value,_bu_return_value = resargs
      _bk_return_value = boundkey(_bk_return_value)
      return _bk_return_value,_bl_return_value,_bu_return_value
    
    def getconboundslice(self,first_,last_,bk,bl,bu): # 3
      """
      Obtains bounds information for a slice of the constraints.
    
      getconboundslice(self,first_,last_,bk,bl,bu)
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        bk: array of mosek.boundkey. Bound keys.
        bl: array of double. Values for lower bounds.
        bu: array of double. Values for upper bounds.
      """
      _copyback_bk = False
      if bk is None:
        bk_ = None
      else:
        try:
          bk_ = memoryview(bk)
        except TypeError:
          try:
            _tmparr_bk = array.array("i",bk)
          except TypeError:
            raise TypeError("Argument bk has wrong type")
          else:
            bk_ = memoryview(_tmparr_bk)
            _copyback_bk = True
        else:
          if bk_.format != "i":
            bk_ = memoryview(array.array("i",bk))
            _copyback_bk = True
      if bk_ is not None and len(bk_) != ((last_) - (first_)):
        raise ValueError("Array argument bk has wrong length")
      _copyback_bl = False
      if bl is None:
        bl_ = None
      else:
        try:
          bl_ = memoryview(bl)
        except TypeError:
          try:
            _tmparr_bl = array.array("d",bl)
          except TypeError:
            raise TypeError("Argument bl has wrong type")
          else:
            bl_ = memoryview(_tmparr_bl)
            _copyback_bl = True
        else:
          if bl_.format != "d":
            bl_ = memoryview(array.array("d",bl))
            _copyback_bl = True
      if bl_ is not None and len(bl_) != ((last_) - (first_)):
        raise ValueError("Array argument bl has wrong length")
      _copyback_bu = False
      if bu is None:
        bu_ = None
      else:
        try:
          bu_ = memoryview(bu)
        except TypeError:
          try:
            _tmparr_bu = array.array("d",bu)
          except TypeError:
            raise TypeError("Argument bu has wrong type")
          else:
            bu_ = memoryview(_tmparr_bu)
            _copyback_bu = True
        else:
          if bu_.format != "d":
            bu_ = memoryview(array.array("d",bu))
            _copyback_bu = True
      if bu_ is not None and len(bu_) != ((last_) - (first_)):
        raise ValueError("Array argument bu has wrong length")
      res = self.__obj.getconboundslice(first_,last_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_bu:
        bu[:] = _tmparr_bu
      if _copyback_bl:
        bl[:] = _tmparr_bl
      if _copyback_bk:
        for __tmp_var_0 in range(len(bk_)): bk[__tmp_var_0] = boundkey(_tmparr_bk[__tmp_var_0])
    
    def getvarboundslice(self,first_,last_,bk,bl,bu): # 3
      """
      Obtains bounds information for a slice of the variables.
    
      getvarboundslice(self,first_,last_,bk,bl,bu)
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        bk: array of mosek.boundkey. Bound keys.
        bl: array of double. Values for lower bounds.
        bu: array of double. Values for upper bounds.
      """
      _copyback_bk = False
      if bk is None:
        bk_ = None
      else:
        try:
          bk_ = memoryview(bk)
        except TypeError:
          try:
            _tmparr_bk = array.array("i",bk)
          except TypeError:
            raise TypeError("Argument bk has wrong type")
          else:
            bk_ = memoryview(_tmparr_bk)
            _copyback_bk = True
        else:
          if bk_.format != "i":
            bk_ = memoryview(array.array("i",bk))
            _copyback_bk = True
      if bk_ is not None and len(bk_) != ((last_) - (first_)):
        raise ValueError("Array argument bk has wrong length")
      _copyback_bl = False
      if bl is None:
        bl_ = None
      else:
        try:
          bl_ = memoryview(bl)
        except TypeError:
          try:
            _tmparr_bl = array.array("d",bl)
          except TypeError:
            raise TypeError("Argument bl has wrong type")
          else:
            bl_ = memoryview(_tmparr_bl)
            _copyback_bl = True
        else:
          if bl_.format != "d":
            bl_ = memoryview(array.array("d",bl))
            _copyback_bl = True
      if bl_ is not None and len(bl_) != ((last_) - (first_)):
        raise ValueError("Array argument bl has wrong length")
      _copyback_bu = False
      if bu is None:
        bu_ = None
      else:
        try:
          bu_ = memoryview(bu)
        except TypeError:
          try:
            _tmparr_bu = array.array("d",bu)
          except TypeError:
            raise TypeError("Argument bu has wrong type")
          else:
            bu_ = memoryview(_tmparr_bu)
            _copyback_bu = True
        else:
          if bu_.format != "d":
            bu_ = memoryview(array.array("d",bu))
            _copyback_bu = True
      if bu_ is not None and len(bu_) != ((last_) - (first_)):
        raise ValueError("Array argument bu has wrong length")
      res = self.__obj.getvarboundslice(first_,last_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_bu:
        bu[:] = _tmparr_bu
      if _copyback_bl:
        bl[:] = _tmparr_bl
      if _copyback_bk:
        for __tmp_var_0 in range(len(bk_)): bk[__tmp_var_0] = boundkey(_tmparr_bk[__tmp_var_0])
    
    def getboundslice(self,accmode_,first_,last_,bk,bl,bu): # 3
      """
      Obtains bounds information for a slice of variables or constraints.
    
      getboundslice(self,accmode_,first_,last_,bk,bl,bu)
        accmode: mosek.accmode. Defines if operations are performed row-wise (constraint-oriented) or column-wise (variable-oriented).
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        bk: array of mosek.boundkey. Bound keys.
        bl: array of double. Values for lower bounds.
        bu: array of double. Values for upper bounds.
      """
      if not isinstance(accmode_,accmode): raise TypeError("Argument accmode has wrong type")
      _copyback_bk = False
      if bk is None:
        bk_ = None
      else:
        try:
          bk_ = memoryview(bk)
        except TypeError:
          try:
            _tmparr_bk = array.array("i",bk)
          except TypeError:
            raise TypeError("Argument bk has wrong type")
          else:
            bk_ = memoryview(_tmparr_bk)
            _copyback_bk = True
        else:
          if bk_.format != "i":
            bk_ = memoryview(array.array("i",bk))
            _copyback_bk = True
      if bk_ is not None and len(bk_) != ((last_) - (first_)):
        raise ValueError("Array argument bk has wrong length")
      _copyback_bl = False
      if bl is None:
        bl_ = None
      else:
        try:
          bl_ = memoryview(bl)
        except TypeError:
          try:
            _tmparr_bl = array.array("d",bl)
          except TypeError:
            raise TypeError("Argument bl has wrong type")
          else:
            bl_ = memoryview(_tmparr_bl)
            _copyback_bl = True
        else:
          if bl_.format != "d":
            bl_ = memoryview(array.array("d",bl))
            _copyback_bl = True
      if bl_ is not None and len(bl_) != ((last_) - (first_)):
        raise ValueError("Array argument bl has wrong length")
      _copyback_bu = False
      if bu is None:
        bu_ = None
      else:
        try:
          bu_ = memoryview(bu)
        except TypeError:
          try:
            _tmparr_bu = array.array("d",bu)
          except TypeError:
            raise TypeError("Argument bu has wrong type")
          else:
            bu_ = memoryview(_tmparr_bu)
            _copyback_bu = True
        else:
          if bu_.format != "d":
            bu_ = memoryview(array.array("d",bu))
            _copyback_bu = True
      if bu_ is not None and len(bu_) != ((last_) - (first_)):
        raise ValueError("Array argument bu has wrong length")
      res = self.__obj.getboundslice(accmode_,first_,last_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_bu:
        bu[:] = _tmparr_bu
      if _copyback_bl:
        bl[:] = _tmparr_bl
      if _copyback_bk:
        for __tmp_var_0 in range(len(bk_)): bk[__tmp_var_0] = boundkey(_tmparr_bk[__tmp_var_0])
    
    def putboundslice(self,con_,first_,last_,bk,bl,bu): # 3
      """
      Changes the bounds for a slice of constraints or variables.
    
      putboundslice(self,con_,first_,last_,bk,bl,bu)
        con: mosek.accmode. Determines whether variables or constraints are modified.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        bk: array of mosek.boundkey. Bound keys.
        bl: array of double. Values for lower bounds.
        bu: array of double. Values for upper bounds.
      """
      if not isinstance(con_,accmode): raise TypeError("Argument con has wrong type")
      if bk is None: raise TypeError("Invalid type for argument bk")
      if bk is None:
        bk_ = None
      else:
        try:
          bk_ = memoryview(bk)
        except TypeError:
          try:
            _tmparr_bk = array.array("i",bk)
          except TypeError:
            raise TypeError("Argument bk has wrong type")
          else:
            bk_ = memoryview(_tmparr_bk)
      
        else:
          if bk_.format != "i":
            bk_ = memoryview(array.array("i",bk))
      
      if bk_ is not None and len(bk_) != ((last_) - (first_)):
        raise ValueError("Array argument bk has wrong length")
      if bl is None: raise TypeError("Invalid type for argument bl")
      if bl is None:
        bl_ = None
      else:
        try:
          bl_ = memoryview(bl)
        except TypeError:
          try:
            _tmparr_bl = array.array("d",bl)
          except TypeError:
            raise TypeError("Argument bl has wrong type")
          else:
            bl_ = memoryview(_tmparr_bl)
      
        else:
          if bl_.format != "d":
            bl_ = memoryview(array.array("d",bl))
      
      if bl_ is not None and len(bl_) != ((last_) - (first_)):
        raise ValueError("Array argument bl has wrong length")
      if bu is None: raise TypeError("Invalid type for argument bu")
      if bu is None:
        bu_ = None
      else:
        try:
          bu_ = memoryview(bu)
        except TypeError:
          try:
            _tmparr_bu = array.array("d",bu)
          except TypeError:
            raise TypeError("Argument bu has wrong type")
          else:
            bu_ = memoryview(_tmparr_bu)
      
        else:
          if bu_.format != "d":
            bu_ = memoryview(array.array("d",bu))
      
      if bu_ is not None and len(bu_) != ((last_) - (first_)):
        raise ValueError("Array argument bu has wrong length")
      res = self.__obj.putboundslice(con_,first_,last_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getcj(self,j_): # 3
      """
      Obtains one objective coefficient.
    
      getcj(self,j_)
        j: int. Index of the variable for which the c coefficient should be obtained.
      returns: cj
        cj: double. The c coefficient value.
      """
      res,resargs = self.__obj.getcj(j_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _cj_return_value = resargs
      return _cj_return_value
    
    def getc(self,c): # 3
      """
      Obtains all objective coefficients.
    
      getc(self,c)
        c: array of double. Linear terms of the objective as a dense vector. The length is the number of variables.
      """
      _copyback_c = False
      if c is None:
        c_ = None
      else:
        try:
          c_ = memoryview(c)
        except TypeError:
          try:
            _tmparr_c = array.array("d",c)
          except TypeError:
            raise TypeError("Argument c has wrong type")
          else:
            c_ = memoryview(_tmparr_c)
            _copyback_c = True
        else:
          if c_.format != "d":
            c_ = memoryview(array.array("d",c))
            _copyback_c = True
      if c_ is not None and len(c_) != self.getnumvar():
        raise ValueError("Array argument c has wrong length")
      res = self.__obj.getc(c_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_c:
        c[:] = _tmparr_c
    
    def getcfix(self): # 3
      """
      Obtains the fixed term in the objective.
    
      getcfix(self)
      returns: cfix
        cfix: double. Fixed term in the objective.
      """
      res,resargs = self.__obj.getcfix()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _cfix_return_value = resargs
      return _cfix_return_value
    
    def getcone(self,k_,submem): # 3
      """
      Obtains a cone.
    
      getcone(self,k_,submem)
        k: int. Index of the cone.
        submem: array of int. Variable subscripts of the members in the cone.
      returns: ct,conepar,nummem
        ct: mosek.conetype. Specifies the type of the cone.
        conepar: double. This argument is currently not used. It can be set to 0
        nummem: int. Number of member variables in the cone.
      """
      _copyback_submem = False
      if submem is None:
        submem_ = None
      else:
        try:
          submem_ = memoryview(submem)
        except TypeError:
          try:
            _tmparr_submem = array.array("i",submem)
          except TypeError:
            raise TypeError("Argument submem has wrong type")
          else:
            submem_ = memoryview(_tmparr_submem)
            _copyback_submem = True
        else:
          if submem_.format != "i":
            submem_ = memoryview(array.array("i",submem))
            _copyback_submem = True
      if submem_ is not None and len(submem_) != self.getconeinfo((k_))[2]:
        raise ValueError("Array argument submem has wrong length")
      res,resargs = self.__obj.getcone(k_,submem_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _ct_return_value,_conepar_return_value,_nummem_return_value = resargs
      if _copyback_submem:
        submem[:] = _tmparr_submem
      _ct_return_value = conetype(_ct_return_value)
      return _ct_return_value,_conepar_return_value,_nummem_return_value
    
    def getconeinfo(self,k_): # 3
      """
      Obtains information about a cone.
    
      getconeinfo(self,k_)
        k: int. Index of the cone.
      returns: ct,conepar,nummem
        ct: mosek.conetype. Specifies the type of the cone.
        conepar: double. This argument is currently not used. It can be set to 0
        nummem: int. Number of member variables in the cone.
      """
      res,resargs = self.__obj.getconeinfo(k_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _ct_return_value,_conepar_return_value,_nummem_return_value = resargs
      _ct_return_value = conetype(_ct_return_value)
      return _ct_return_value,_conepar_return_value,_nummem_return_value
    
    def getcslice(self,first_,last_,c): # 3
      """
      Obtains a sequence of coefficients from the objective.
    
      getcslice(self,first_,last_,c)
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        c: array of double. Linear terms of the requested slice of the objective as a dense vector.
      """
      _copyback_c = False
      if c is None:
        c_ = None
      else:
        try:
          c_ = memoryview(c)
        except TypeError:
          try:
            _tmparr_c = array.array("d",c)
          except TypeError:
            raise TypeError("Argument c has wrong type")
          else:
            c_ = memoryview(_tmparr_c)
            _copyback_c = True
        else:
          if c_.format != "d":
            c_ = memoryview(array.array("d",c))
            _copyback_c = True
      if c_ is not None and len(c_) != ((last_) - (first_)):
        raise ValueError("Array argument c has wrong length")
      res = self.__obj.getcslice(first_,last_,c_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_c:
        c[:] = _tmparr_c
    
    def getdouinf(self,whichdinf_): # 3
      """
      Obtains a double information item.
    
      getdouinf(self,whichdinf_)
        whichdinf: mosek.dinfitem. Specifies a double information item.
      returns: dvalue
        dvalue: double. The value of the required double information item.
      """
      if not isinstance(whichdinf_,dinfitem): raise TypeError("Argument whichdinf has wrong type")
      res,resargs = self.__obj.getdouinf(whichdinf_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _dvalue_return_value = resargs
      return _dvalue_return_value
    
    def getdouparam(self,param_): # 3
      """
      Obtains a double parameter.
    
      getdouparam(self,param_)
        param: mosek.dparam. Which parameter.
      returns: parvalue
        parvalue: double. Parameter value.
      """
      if not isinstance(param_,dparam): raise TypeError("Argument param has wrong type")
      res,resargs = self.__obj.getdouparam(param_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _parvalue_return_value = resargs
      return _parvalue_return_value
    
    def getdualobj(self,whichsol_): # 3
      """
      Computes the dual objective value associated with the solution.
    
      getdualobj(self,whichsol_)
        whichsol: mosek.soltype. Selects a solution.
      returns: dualobj
        dualobj: double. Objective value corresponding to the dual solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res,resargs = self.__obj.getdualobj(whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _dualobj_return_value = resargs
      return _dualobj_return_value
    
    def getintinf(self,whichiinf_): # 3
      """
      Obtains an integer information item.
    
      getintinf(self,whichiinf_)
        whichiinf: mosek.iinfitem. Specifies an integer information item.
      returns: ivalue
        ivalue: int. The value of the required integer information item.
      """
      if not isinstance(whichiinf_,iinfitem): raise TypeError("Argument whichiinf has wrong type")
      res,resargs = self.__obj.getintinf(whichiinf_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _ivalue_return_value = resargs
      return _ivalue_return_value
    
    def getlintinf(self,whichliinf_): # 3
      """
      Obtains a long integer information item.
    
      getlintinf(self,whichliinf_)
        whichliinf: mosek.liinfitem. Specifies a long information item.
      returns: ivalue
        ivalue: long. The value of the required long integer information item.
      """
      if not isinstance(whichliinf_,liinfitem): raise TypeError("Argument whichliinf has wrong type")
      res,resargs = self.__obj.getlintinf(whichliinf_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _ivalue_return_value = resargs
      return _ivalue_return_value
    
    def getintparam(self,param_): # 3
      """
      Obtains an integer parameter.
    
      getintparam(self,param_)
        param: mosek.iparam. Which parameter.
      returns: parvalue
        parvalue: int. Parameter value.
      """
      if not isinstance(param_,iparam): raise TypeError("Argument param has wrong type")
      res,resargs = self.__obj.getintparam(param_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _parvalue_return_value = resargs
      return _parvalue_return_value
    
    def getmaxnumanz(self): # 3
      """
      Obtains number of preallocated non-zeros in the linear constraint matrix.
    
      getmaxnumanz(self)
      returns: maxnumanz
        maxnumanz: long. Number of preallocated non-zero linear matrix elements.
      """
      res,resargs = self.__obj.getmaxnumanz64()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _maxnumanz_return_value = resargs
      return _maxnumanz_return_value
    
    def getmaxnumcon(self): # 3
      """
      Obtains the number of preallocated constraints in the optimization task.
    
      getmaxnumcon(self)
      returns: maxnumcon
        maxnumcon: int. Number of preallocated constraints in the optimization task.
      """
      res,resargs = self.__obj.getmaxnumcon()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _maxnumcon_return_value = resargs
      return _maxnumcon_return_value
    
    def getmaxnumvar(self): # 3
      """
      Obtains the maximum number variables allowed.
    
      getmaxnumvar(self)
      returns: maxnumvar
        maxnumvar: int. Number of preallocated variables in the optimization task.
      """
      res,resargs = self.__obj.getmaxnumvar()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _maxnumvar_return_value = resargs
      return _maxnumvar_return_value
    
    def getbarvarnamelen(self,i_): # 3
      """
      Obtains the length of the name of a semidefinite variable.
    
      getbarvarnamelen(self,i_)
        i: int. Index of the variable.
      returns: len
        len: int. Returns the length of the indicated name.
      """
      res,resargs = self.__obj.getbarvarnamelen(i_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _len_return_value = resargs
      return _len_return_value
    
    def getbarvarname(self,i_): # 3
      """
      Obtains the name of a semidefinite variable.
    
      getbarvarname(self,i_)
        i: int. Index of the variable.
      returns: name
        name: str. The requested name is copied to this buffer.
      """
      sizename_ = (1 + self.getbarvarnamelen((i_)))
      arr_name = array.array("b",[0]*((sizename_)))
      memview_arr_name = memoryview(arr_name)
      res,resargs = self.__obj.getbarvarname(i_,sizename_,memview_arr_name)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      retarg_name = resargs
      retarg_name = arr_name.tobytes()[:-1].decode("utf-8",errors="ignore")
      return retarg_name
    
    def getbarvarnameindex(self,somename_): # 3
      """
      Obtains the index of semidefinite variable from its name.
    
      getbarvarnameindex(self,somename_)
        somename: str. The name of the variable.
      returns: asgn,index
        asgn: int. Non-zero if the name somename is assigned to some semidefinite variable.
        index: int. The index of a semidefinite variable with the name somename (if one exists).
      """
      res,resargs = self.__obj.getbarvarnameindex(somename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _asgn_return_value,_index_return_value = resargs
      return _asgn_return_value,_index_return_value
    
    def putconname(self,i_,name_): # 3
      """
      Sets the name of a constraint.
    
      putconname(self,i_,name_)
        i: int. Index of the constraint.
        name: str. The name of the constraint.
      """
      res = self.__obj.putconname(i_,name_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putvarname(self,j_,name_): # 3
      """
      Sets the name of a variable.
    
      putvarname(self,j_,name_)
        j: int. Index of the variable.
        name: str. The variable name.
      """
      res = self.__obj.putvarname(j_,name_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putconename(self,j_,name_): # 3
      """
      Sets the name of a cone.
    
      putconename(self,j_,name_)
        j: int. Index of the cone.
        name: str. The name of the cone.
      """
      res = self.__obj.putconename(j_,name_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putbarvarname(self,j_,name_): # 3
      """
      Sets the name of a semidefinite variable.
    
      putbarvarname(self,j_,name_)
        j: int. Index of the variable.
        name: str. The variable name.
      """
      res = self.__obj.putbarvarname(j_,name_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getvarnamelen(self,i_): # 3
      """
      Obtains the length of the name of a variable.
    
      getvarnamelen(self,i_)
        i: int. Index of a variable.
      returns: len
        len: int. Returns the length of the indicated name.
      """
      res,resargs = self.__obj.getvarnamelen(i_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _len_return_value = resargs
      return _len_return_value
    
    def getvarname(self,j_): # 3
      """
      Obtains the name of a variable.
    
      getvarname(self,j_)
        j: int. Index of a variable.
      returns: name
        name: str. Returns the required name.
      """
      sizename_ = (1 + self.getvarnamelen((j_)))
      arr_name = array.array("b",[0]*((sizename_)))
      memview_arr_name = memoryview(arr_name)
      res,resargs = self.__obj.getvarname(j_,sizename_,memview_arr_name)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      retarg_name = resargs
      retarg_name = arr_name.tobytes()[:-1].decode("utf-8",errors="ignore")
      return retarg_name
    
    def getconnamelen(self,i_): # 3
      """
      Obtains the length of the name of a constraint.
    
      getconnamelen(self,i_)
        i: int. Index of the constraint.
      returns: len
        len: int. Returns the length of the indicated name.
      """
      res,resargs = self.__obj.getconnamelen(i_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _len_return_value = resargs
      return _len_return_value
    
    def getconname(self,i_): # 3
      """
      Obtains the name of a constraint.
    
      getconname(self,i_)
        i: int. Index of the constraint.
      returns: name
        name: str. The required name.
      """
      sizename_ = (1 + self.getconnamelen((i_)))
      arr_name = array.array("b",[0]*((sizename_)))
      memview_arr_name = memoryview(arr_name)
      res,resargs = self.__obj.getconname(i_,sizename_,memview_arr_name)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      retarg_name = resargs
      retarg_name = arr_name.tobytes()[:-1].decode("utf-8",errors="ignore")
      return retarg_name
    
    def getconnameindex(self,somename_): # 3
      """
      Checks whether the name has been assigned to any constraint.
    
      getconnameindex(self,somename_)
        somename: str. The name which should be checked.
      returns: asgn,index
        asgn: int. Is non-zero if the name somename is assigned to some constraint.
        index: int. If the name somename is assigned to a constraint, then return the index of the constraint.
      """
      res,resargs = self.__obj.getconnameindex(somename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _asgn_return_value,_index_return_value = resargs
      return _asgn_return_value,_index_return_value
    
    def getvarnameindex(self,somename_): # 3
      """
      Checks whether the name has been assigned to any variable.
    
      getvarnameindex(self,somename_)
        somename: str. The name which should be checked.
      returns: asgn,index
        asgn: int. Is non-zero if the name somename is assigned to a variable.
        index: int. If the name somename is assigned to a variable, then return the index of the variable.
      """
      res,resargs = self.__obj.getvarnameindex(somename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _asgn_return_value,_index_return_value = resargs
      return _asgn_return_value,_index_return_value
    
    def getconenamelen(self,i_): # 3
      """
      Obtains the length of the name of a cone.
    
      getconenamelen(self,i_)
        i: int. Index of the cone.
      returns: len
        len: int. Returns the length of the indicated name.
      """
      res,resargs = self.__obj.getconenamelen(i_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _len_return_value = resargs
      return _len_return_value
    
    def getconename(self,i_): # 3
      """
      Obtains the name of a cone.
    
      getconename(self,i_)
        i: int. Index of the cone.
      returns: name
        name: str. The required name.
      """
      sizename_ = (1 + self.getconenamelen((i_)))
      arr_name = array.array("b",[0]*((sizename_)))
      memview_arr_name = memoryview(arr_name)
      res,resargs = self.__obj.getconename(i_,sizename_,memview_arr_name)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      retarg_name = resargs
      retarg_name = arr_name.tobytes()[:-1].decode("utf-8",errors="ignore")
      return retarg_name
    
    def getconenameindex(self,somename_): # 3
      """
      Checks whether the name has been assigned to any cone.
    
      getconenameindex(self,somename_)
        somename: str. The name which should be checked.
      returns: asgn,index
        asgn: int. Is non-zero if the name somename is assigned to some cone.
        index: int. If the name somename is assigned to some cone, this is the index of the cone.
      """
      res,resargs = self.__obj.getconenameindex(somename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _asgn_return_value,_index_return_value = resargs
      return _asgn_return_value,_index_return_value
    
    def getnumanz(self): # 3
      """
      Obtains the number of non-zeros in the coefficient matrix.
    
      getnumanz(self)
      returns: numanz
        numanz: int. Number of non-zero elements in the linear constraint matrix.
      """
      res,resargs = self.__obj.getnumanz()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numanz_return_value = resargs
      return _numanz_return_value
    
    def getnumanz64(self): # 3
      """
      Obtains the number of non-zeros in the coefficient matrix.
    
      getnumanz64(self)
      returns: numanz
        numanz: long. Number of non-zero elements in the linear constraint matrix.
      """
      res,resargs = self.__obj.getnumanz64()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numanz_return_value = resargs
      return _numanz_return_value
    
    def getnumcon(self): # 3
      """
      Obtains the number of constraints.
    
      getnumcon(self)
      returns: numcon
        numcon: int. Number of constraints.
      """
      res,resargs = self.__obj.getnumcon()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numcon_return_value = resargs
      return _numcon_return_value
    
    def getnumcone(self): # 3
      """
      Obtains the number of cones.
    
      getnumcone(self)
      returns: numcone
        numcone: int. Number of conic constraints.
      """
      res,resargs = self.__obj.getnumcone()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numcone_return_value = resargs
      return _numcone_return_value
    
    def getnumconemem(self,k_): # 3
      """
      Obtains the number of members in a cone.
    
      getnumconemem(self,k_)
        k: int. Index of the cone.
      returns: nummem
        nummem: int. Number of member variables in the cone.
      """
      res,resargs = self.__obj.getnumconemem(k_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _nummem_return_value = resargs
      return _nummem_return_value
    
    def getnumintvar(self): # 3
      """
      Obtains the number of integer-constrained variables.
    
      getnumintvar(self)
      returns: numintvar
        numintvar: int. Number of integer variables.
      """
      res,resargs = self.__obj.getnumintvar()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numintvar_return_value = resargs
      return _numintvar_return_value
    
    def getnumparam(self,partype_): # 3
      """
      Obtains the number of parameters of a given type.
    
      getnumparam(self,partype_)
        partype: mosek.parametertype. Parameter type.
      returns: numparam
        numparam: int. Returns the number of parameters of the requested type.
      """
      if not isinstance(partype_,parametertype): raise TypeError("Argument partype has wrong type")
      res,resargs = self.__obj.getnumparam(partype_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numparam_return_value = resargs
      return _numparam_return_value
    
    def getnumqconknz(self,k_): # 3
      """
      Obtains the number of non-zero quadratic terms in a constraint.
    
      getnumqconknz(self,k_)
        k: int. Index of the constraint for which the number quadratic terms should be obtained.
      returns: numqcnz
        numqcnz: long. Number of quadratic terms.
      """
      res,resargs = self.__obj.getnumqconknz64(k_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numqcnz_return_value = resargs
      return _numqcnz_return_value
    
    def getnumqobjnz(self): # 3
      """
      Obtains the number of non-zero quadratic terms in the objective.
    
      getnumqobjnz(self)
      returns: numqonz
        numqonz: long. Number of non-zero elements in the quadratic objective terms.
      """
      res,resargs = self.__obj.getnumqobjnz64()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numqonz_return_value = resargs
      return _numqonz_return_value
    
    def getnumvar(self): # 3
      """
      Obtains the number of variables.
    
      getnumvar(self)
      returns: numvar
        numvar: int. Number of variables.
      """
      res,resargs = self.__obj.getnumvar()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numvar_return_value = resargs
      return _numvar_return_value
    
    def getnumbarvar(self): # 3
      """
      Obtains the number of semidefinite variables.
    
      getnumbarvar(self)
      returns: numbarvar
        numbarvar: int. Number of semidefinite variables in the problem.
      """
      res,resargs = self.__obj.getnumbarvar()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numbarvar_return_value = resargs
      return _numbarvar_return_value
    
    def getmaxnumbarvar(self): # 3
      """
      Obtains maximum number of symmetric matrix variables for which space is currently preallocated.
    
      getmaxnumbarvar(self)
      returns: maxnumbarvar
        maxnumbarvar: int. Maximum number of symmetric matrix variables for which space is currently preallocated.
      """
      res,resargs = self.__obj.getmaxnumbarvar()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _maxnumbarvar_return_value = resargs
      return _maxnumbarvar_return_value
    
    def getdimbarvarj(self,j_): # 3
      """
      Obtains the dimension of a symmetric matrix variable.
    
      getdimbarvarj(self,j_)
        j: int. Index of the semidefinite variable whose dimension is requested.
      returns: dimbarvarj
        dimbarvarj: int. The dimension of the j'th semidefinite variable.
      """
      res,resargs = self.__obj.getdimbarvarj(j_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _dimbarvarj_return_value = resargs
      return _dimbarvarj_return_value
    
    def getlenbarvarj(self,j_): # 3
      """
      Obtains the length of one semidefinite variable.
    
      getlenbarvarj(self,j_)
        j: int. Index of the semidefinite variable whose length if requested.
      returns: lenbarvarj
        lenbarvarj: long. Number of scalar elements in the lower triangular part of the semidefinite variable.
      """
      res,resargs = self.__obj.getlenbarvarj(j_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _lenbarvarj_return_value = resargs
      return _lenbarvarj_return_value
    
    def getobjname(self): # 3
      """
      Obtains the name assigned to the objective function.
    
      getobjname(self)
      returns: objname
        objname: str. Assigned the objective name.
      """
      sizeobjname_ = (1 + self.getobjnamelen())
      arr_objname = array.array("b",[0]*((sizeobjname_)))
      memview_arr_objname = memoryview(arr_objname)
      res,resargs = self.__obj.getobjname(sizeobjname_,memview_arr_objname)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      retarg_objname = resargs
      retarg_objname = arr_objname.tobytes()[:-1].decode("utf-8",errors="ignore")
      return retarg_objname
    
    def getobjnamelen(self): # 3
      """
      Obtains the length of the name assigned to the objective function.
    
      getobjnamelen(self)
      returns: len
        len: int. Assigned the length of the objective name.
      """
      res,resargs = self.__obj.getobjnamelen()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _len_return_value = resargs
      return _len_return_value
    
    def getprimalobj(self,whichsol_): # 3
      """
      Computes the primal objective value for the desired solution.
    
      getprimalobj(self,whichsol_)
        whichsol: mosek.soltype. Selects a solution.
      returns: primalobj
        primalobj: double. Objective value corresponding to the primal solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res,resargs = self.__obj.getprimalobj(whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _primalobj_return_value = resargs
      return _primalobj_return_value
    
    def getprobtype(self): # 3
      """
      Obtains the problem type.
    
      getprobtype(self)
      returns: probtype
        probtype: mosek.problemtype. The problem type.
      """
      res,resargs = self.__obj.getprobtype()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _probtype_return_value = resargs
      _probtype_return_value = problemtype(_probtype_return_value)
      return _probtype_return_value
    
    def getqconk(self,k_,qcsubi,qcsubj,qcval): # 3
      """
      Obtains all the quadratic terms in a constraint.
    
      getqconk(self,k_,qcsubi,qcsubj,qcval)
        k: int. Which constraint.
        qcsubi: array of int. Row subscripts for quadratic constraint matrix.
        qcsubj: array of int. Column subscripts for quadratic constraint matrix.
        qcval: array of double. Quadratic constraint coefficient values.
      returns: numqcnz
        numqcnz: long. Number of quadratic terms.
      """
      maxnumqcnz_ = self.getnumqconknz((k_))
      if qcsubi is None: raise TypeError("Invalid type for argument qcsubi")
      _copyback_qcsubi = False
      if qcsubi is None:
        qcsubi_ = None
      else:
        try:
          qcsubi_ = memoryview(qcsubi)
        except TypeError:
          try:
            _tmparr_qcsubi = array.array("i",qcsubi)
          except TypeError:
            raise TypeError("Argument qcsubi has wrong type")
          else:
            qcsubi_ = memoryview(_tmparr_qcsubi)
            _copyback_qcsubi = True
        else:
          if qcsubi_.format != "i":
            qcsubi_ = memoryview(array.array("i",qcsubi))
            _copyback_qcsubi = True
      if qcsubi_ is not None and len(qcsubi_) != self.getnumqconknz((k_)):
        raise ValueError("Array argument qcsubi has wrong length")
      if qcsubj is None: raise TypeError("Invalid type for argument qcsubj")
      _copyback_qcsubj = False
      if qcsubj is None:
        qcsubj_ = None
      else:
        try:
          qcsubj_ = memoryview(qcsubj)
        except TypeError:
          try:
            _tmparr_qcsubj = array.array("i",qcsubj)
          except TypeError:
            raise TypeError("Argument qcsubj has wrong type")
          else:
            qcsubj_ = memoryview(_tmparr_qcsubj)
            _copyback_qcsubj = True
        else:
          if qcsubj_.format != "i":
            qcsubj_ = memoryview(array.array("i",qcsubj))
            _copyback_qcsubj = True
      if qcsubj_ is not None and len(qcsubj_) != self.getnumqconknz((k_)):
        raise ValueError("Array argument qcsubj has wrong length")
      if qcval is None: raise TypeError("Invalid type for argument qcval")
      _copyback_qcval = False
      if qcval is None:
        qcval_ = None
      else:
        try:
          qcval_ = memoryview(qcval)
        except TypeError:
          try:
            _tmparr_qcval = array.array("d",qcval)
          except TypeError:
            raise TypeError("Argument qcval has wrong type")
          else:
            qcval_ = memoryview(_tmparr_qcval)
            _copyback_qcval = True
        else:
          if qcval_.format != "d":
            qcval_ = memoryview(array.array("d",qcval))
            _copyback_qcval = True
      if qcval_ is not None and len(qcval_) != self.getnumqconknz((k_)):
        raise ValueError("Array argument qcval has wrong length")
      res,resargs = self.__obj.getqconk64(k_,maxnumqcnz_,len(qcsubi),qcsubi_,qcsubj_,qcval_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numqcnz_return_value = resargs
      if _copyback_qcval:
        qcval[:] = _tmparr_qcval
      if _copyback_qcsubj:
        qcsubj[:] = _tmparr_qcsubj
      if _copyback_qcsubi:
        qcsubi[:] = _tmparr_qcsubi
      return _numqcnz_return_value
    
    def getqobj(self,qosubi,qosubj,qoval): # 3
      """
      Obtains all the quadratic terms in the objective.
    
      getqobj(self,qosubi,qosubj,qoval)
        qosubi: array of int. Row subscripts for quadratic objective coefficients.
        qosubj: array of int. Column subscripts for quadratic objective coefficients.
        qoval: array of double. Quadratic objective coefficient values.
      returns: numqonz
        numqonz: long. Number of non-zero elements in the quadratic objective terms.
      """
      maxnumqonz_ = self.getnumqobjnz()
      if qosubi is None: raise TypeError("Invalid type for argument qosubi")
      _copyback_qosubi = False
      if qosubi is None:
        qosubi_ = None
      else:
        try:
          qosubi_ = memoryview(qosubi)
        except TypeError:
          try:
            _tmparr_qosubi = array.array("i",qosubi)
          except TypeError:
            raise TypeError("Argument qosubi has wrong type")
          else:
            qosubi_ = memoryview(_tmparr_qosubi)
            _copyback_qosubi = True
        else:
          if qosubi_.format != "i":
            qosubi_ = memoryview(array.array("i",qosubi))
            _copyback_qosubi = True
      if qosubi_ is not None and len(qosubi_) != (maxnumqonz_):
        raise ValueError("Array argument qosubi has wrong length")
      if qosubj is None: raise TypeError("Invalid type for argument qosubj")
      _copyback_qosubj = False
      if qosubj is None:
        qosubj_ = None
      else:
        try:
          qosubj_ = memoryview(qosubj)
        except TypeError:
          try:
            _tmparr_qosubj = array.array("i",qosubj)
          except TypeError:
            raise TypeError("Argument qosubj has wrong type")
          else:
            qosubj_ = memoryview(_tmparr_qosubj)
            _copyback_qosubj = True
        else:
          if qosubj_.format != "i":
            qosubj_ = memoryview(array.array("i",qosubj))
            _copyback_qosubj = True
      if qosubj_ is not None and len(qosubj_) != (maxnumqonz_):
        raise ValueError("Array argument qosubj has wrong length")
      if qoval is None: raise TypeError("Invalid type for argument qoval")
      _copyback_qoval = False
      if qoval is None:
        qoval_ = None
      else:
        try:
          qoval_ = memoryview(qoval)
        except TypeError:
          try:
            _tmparr_qoval = array.array("d",qoval)
          except TypeError:
            raise TypeError("Argument qoval has wrong type")
          else:
            qoval_ = memoryview(_tmparr_qoval)
            _copyback_qoval = True
        else:
          if qoval_.format != "d":
            qoval_ = memoryview(array.array("d",qoval))
            _copyback_qoval = True
      if qoval_ is not None and len(qoval_) != (maxnumqonz_):
        raise ValueError("Array argument qoval has wrong length")
      res,resargs = self.__obj.getqobj64(maxnumqonz_,len(qosubi),qosubi_,qosubj_,qoval_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numqonz_return_value = resargs
      if _copyback_qoval:
        qoval[:] = _tmparr_qoval
      if _copyback_qosubj:
        qosubj[:] = _tmparr_qosubj
      if _copyback_qosubi:
        qosubi[:] = _tmparr_qosubi
      return _numqonz_return_value
    
    def getqobjij(self,i_,j_): # 3
      """
      Obtains one coefficient from the quadratic term of the objective
    
      getqobjij(self,i_,j_)
        i: int. Row index of the coefficient.
        j: int. Column index of coefficient.
      returns: qoij
        qoij: double. The required coefficient.
      """
      res,resargs = self.__obj.getqobjij(i_,j_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _qoij_return_value = resargs
      return _qoij_return_value
    
    def getsolution(self,whichsol_,skc,skx,skn,xc,xx,y,slc,suc,slx,sux,snx): # 3
      """
      Obtains the complete solution.
    
      getsolution(self,whichsol_,skc,skx,skn,xc,xx,y,slc,suc,slx,sux,snx)
        whichsol: mosek.soltype. Selects a solution.
        skc: array of mosek.stakey. Status keys for the constraints.
        skx: array of mosek.stakey. Status keys for the variables.
        skn: array of mosek.stakey. Status keys for the conic constraints.
        xc: array of double. Primal constraint solution.
        xx: array of double. Primal variable solution.
        y: array of double. Vector of dual variables corresponding to the constraints.
        slc: array of double. Dual variables corresponding to the lower bounds on the constraints.
        suc: array of double. Dual variables corresponding to the upper bounds on the constraints.
        slx: array of double. Dual variables corresponding to the lower bounds on the variables.
        sux: array of double. Dual variables corresponding to the upper bounds on the variables.
        snx: array of double. Dual variables corresponding to the conic constraints on the variables.
      returns: prosta,solsta
        prosta: mosek.prosta. Problem status.
        solsta: mosek.solsta. Solution status.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_skc = False
      if skc is None:
        skc_ = None
      else:
        try:
          skc_ = memoryview(skc)
        except TypeError:
          try:
            _tmparr_skc = array.array("i",skc)
          except TypeError:
            raise TypeError("Argument skc has wrong type")
          else:
            skc_ = memoryview(_tmparr_skc)
            _copyback_skc = True
        else:
          if skc_.format != "i":
            skc_ = memoryview(array.array("i",skc))
            _copyback_skc = True
      if skc_ is not None and len(skc_) != self.getnumcon():
        raise ValueError("Array argument skc has wrong length")
      _copyback_skx = False
      if skx is None:
        skx_ = None
      else:
        try:
          skx_ = memoryview(skx)
        except TypeError:
          try:
            _tmparr_skx = array.array("i",skx)
          except TypeError:
            raise TypeError("Argument skx has wrong type")
          else:
            skx_ = memoryview(_tmparr_skx)
            _copyback_skx = True
        else:
          if skx_.format != "i":
            skx_ = memoryview(array.array("i",skx))
            _copyback_skx = True
      if skx_ is not None and len(skx_) != self.getnumvar():
        raise ValueError("Array argument skx has wrong length")
      _copyback_skn = False
      if skn is None:
        skn_ = None
      else:
        try:
          skn_ = memoryview(skn)
        except TypeError:
          try:
            _tmparr_skn = array.array("i",skn)
          except TypeError:
            raise TypeError("Argument skn has wrong type")
          else:
            skn_ = memoryview(_tmparr_skn)
            _copyback_skn = True
        else:
          if skn_.format != "i":
            skn_ = memoryview(array.array("i",skn))
            _copyback_skn = True
      if skn_ is not None and len(skn_) != self.getnumcone():
        raise ValueError("Array argument skn has wrong length")
      _copyback_xc = False
      if xc is None:
        xc_ = None
      else:
        try:
          xc_ = memoryview(xc)
        except TypeError:
          try:
            _tmparr_xc = array.array("d",xc)
          except TypeError:
            raise TypeError("Argument xc has wrong type")
          else:
            xc_ = memoryview(_tmparr_xc)
            _copyback_xc = True
        else:
          if xc_.format != "d":
            xc_ = memoryview(array.array("d",xc))
            _copyback_xc = True
      if xc_ is not None and len(xc_) != self.getnumcon():
        raise ValueError("Array argument xc has wrong length")
      _copyback_xx = False
      if xx is None:
        xx_ = None
      else:
        try:
          xx_ = memoryview(xx)
        except TypeError:
          try:
            _tmparr_xx = array.array("d",xx)
          except TypeError:
            raise TypeError("Argument xx has wrong type")
          else:
            xx_ = memoryview(_tmparr_xx)
            _copyback_xx = True
        else:
          if xx_.format != "d":
            xx_ = memoryview(array.array("d",xx))
            _copyback_xx = True
      if xx_ is not None and len(xx_) != self.getnumvar():
        raise ValueError("Array argument xx has wrong length")
      _copyback_y = False
      if y is None:
        y_ = None
      else:
        try:
          y_ = memoryview(y)
        except TypeError:
          try:
            _tmparr_y = array.array("d",y)
          except TypeError:
            raise TypeError("Argument y has wrong type")
          else:
            y_ = memoryview(_tmparr_y)
            _copyback_y = True
        else:
          if y_.format != "d":
            y_ = memoryview(array.array("d",y))
            _copyback_y = True
      if y_ is not None and len(y_) != self.getnumcon():
        raise ValueError("Array argument y has wrong length")
      _copyback_slc = False
      if slc is None:
        slc_ = None
      else:
        try:
          slc_ = memoryview(slc)
        except TypeError:
          try:
            _tmparr_slc = array.array("d",slc)
          except TypeError:
            raise TypeError("Argument slc has wrong type")
          else:
            slc_ = memoryview(_tmparr_slc)
            _copyback_slc = True
        else:
          if slc_.format != "d":
            slc_ = memoryview(array.array("d",slc))
            _copyback_slc = True
      if slc_ is not None and len(slc_) != self.getnumcon():
        raise ValueError("Array argument slc has wrong length")
      _copyback_suc = False
      if suc is None:
        suc_ = None
      else:
        try:
          suc_ = memoryview(suc)
        except TypeError:
          try:
            _tmparr_suc = array.array("d",suc)
          except TypeError:
            raise TypeError("Argument suc has wrong type")
          else:
            suc_ = memoryview(_tmparr_suc)
            _copyback_suc = True
        else:
          if suc_.format != "d":
            suc_ = memoryview(array.array("d",suc))
            _copyback_suc = True
      if suc_ is not None and len(suc_) != self.getnumcon():
        raise ValueError("Array argument suc has wrong length")
      _copyback_slx = False
      if slx is None:
        slx_ = None
      else:
        try:
          slx_ = memoryview(slx)
        except TypeError:
          try:
            _tmparr_slx = array.array("d",slx)
          except TypeError:
            raise TypeError("Argument slx has wrong type")
          else:
            slx_ = memoryview(_tmparr_slx)
            _copyback_slx = True
        else:
          if slx_.format != "d":
            slx_ = memoryview(array.array("d",slx))
            _copyback_slx = True
      if slx_ is not None and len(slx_) != self.getnumvar():
        raise ValueError("Array argument slx has wrong length")
      _copyback_sux = False
      if sux is None:
        sux_ = None
      else:
        try:
          sux_ = memoryview(sux)
        except TypeError:
          try:
            _tmparr_sux = array.array("d",sux)
          except TypeError:
            raise TypeError("Argument sux has wrong type")
          else:
            sux_ = memoryview(_tmparr_sux)
            _copyback_sux = True
        else:
          if sux_.format != "d":
            sux_ = memoryview(array.array("d",sux))
            _copyback_sux = True
      if sux_ is not None and len(sux_) != self.getnumvar():
        raise ValueError("Array argument sux has wrong length")
      _copyback_snx = False
      if snx is None:
        snx_ = None
      else:
        try:
          snx_ = memoryview(snx)
        except TypeError:
          try:
            _tmparr_snx = array.array("d",snx)
          except TypeError:
            raise TypeError("Argument snx has wrong type")
          else:
            snx_ = memoryview(_tmparr_snx)
            _copyback_snx = True
        else:
          if snx_.format != "d":
            snx_ = memoryview(array.array("d",snx))
            _copyback_snx = True
      if snx_ is not None and len(snx_) != self.getnumvar():
        raise ValueError("Array argument snx has wrong length")
      res,resargs = self.__obj.getsolution(whichsol_,skc_,skx_,skn_,xc_,xx_,y_,slc_,suc_,slx_,sux_,snx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _prosta_return_value,_solsta_return_value = resargs
      if _copyback_snx:
        snx[:] = _tmparr_snx
      if _copyback_sux:
        sux[:] = _tmparr_sux
      if _copyback_slx:
        slx[:] = _tmparr_slx
      if _copyback_suc:
        suc[:] = _tmparr_suc
      if _copyback_slc:
        slc[:] = _tmparr_slc
      if _copyback_y:
        y[:] = _tmparr_y
      if _copyback_xx:
        xx[:] = _tmparr_xx
      if _copyback_xc:
        xc[:] = _tmparr_xc
      if _copyback_skn:
        for __tmp_var_2 in range(len(skn_)): skn[__tmp_var_2] = stakey(_tmparr_skn[__tmp_var_2])
      if _copyback_skx:
        for __tmp_var_1 in range(len(skx_)): skx[__tmp_var_1] = stakey(_tmparr_skx[__tmp_var_1])
      if _copyback_skc:
        for __tmp_var_0 in range(len(skc_)): skc[__tmp_var_0] = stakey(_tmparr_skc[__tmp_var_0])
      _solsta_return_value = solsta(_solsta_return_value)
      _prosta_return_value = prosta(_prosta_return_value)
      return _prosta_return_value,_solsta_return_value
    
    def getsolutioni(self,accmode_,i_,whichsol_): # 3
      """
      Obtains the solution for a single constraint or variable.
    
      getsolutioni(self,accmode_,i_,whichsol_)
        accmode: mosek.accmode. Defines whether solution information for a constraint or for a variable is retrieved.
        i: int. Index of the constraint or variable.
        whichsol: mosek.soltype. Selects a solution.
      returns: sk,x,sl,su,sn
        sk: mosek.stakey. Status key of the constraint of variable.
        x: double. Solution value of the primal variable.
        sl: double. Solution value of the dual variable associated with the lower bound.
        su: double. Solution value of the dual variable associated with the upper bound.
        sn: double. Solution value of the dual variable associated with the cone constraint.
      """
      if not isinstance(accmode_,accmode): raise TypeError("Argument accmode has wrong type")
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res,resargs = self.__obj.getsolutioni(accmode_,i_,whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _sk_return_value,_x_return_value,_sl_return_value,_su_return_value,_sn_return_value = resargs
      _sk_return_value = stakey(_sk_return_value)
      return _sk_return_value,_x_return_value,_sl_return_value,_su_return_value,_sn_return_value
    
    def getsolsta(self,whichsol_): # 3
      """
      Obtains the solution status.
    
      getsolsta(self,whichsol_)
        whichsol: mosek.soltype. Selects a solution.
      returns: solsta
        solsta: mosek.solsta. Solution status.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res,resargs = self.__obj.getsolsta(whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _solsta_return_value = resargs
      _solsta_return_value = solsta(_solsta_return_value)
      return _solsta_return_value
    
    def getprosta(self,whichsol_): # 3
      """
      Obtains the problem status.
    
      getprosta(self,whichsol_)
        whichsol: mosek.soltype. Selects a solution.
      returns: prosta
        prosta: mosek.prosta. Problem status.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res,resargs = self.__obj.getprosta(whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _prosta_return_value = resargs
      _prosta_return_value = prosta(_prosta_return_value)
      return _prosta_return_value
    
    def getskc(self,whichsol_,skc): # 3
      """
      Obtains the status keys for the constraints.
    
      getskc(self,whichsol_,skc)
        whichsol: mosek.soltype. Selects a solution.
        skc: array of mosek.stakey. Status keys for the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_skc = False
      if skc is None:
        skc_ = None
      else:
        try:
          skc_ = memoryview(skc)
        except TypeError:
          try:
            _tmparr_skc = array.array("i",skc)
          except TypeError:
            raise TypeError("Argument skc has wrong type")
          else:
            skc_ = memoryview(_tmparr_skc)
            _copyback_skc = True
        else:
          if skc_.format != "i":
            skc_ = memoryview(array.array("i",skc))
            _copyback_skc = True
      if skc_ is not None and len(skc_) != self.getnumcon():
        raise ValueError("Array argument skc has wrong length")
      res = self.__obj.getskc(whichsol_,skc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_skc:
        for __tmp_var_0 in range(len(skc_)): skc[__tmp_var_0] = stakey(_tmparr_skc[__tmp_var_0])
    
    def getskx(self,whichsol_,skx): # 3
      """
      Obtains the status keys for the scalar variables.
    
      getskx(self,whichsol_,skx)
        whichsol: mosek.soltype. Selects a solution.
        skx: array of mosek.stakey. Status keys for the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_skx = False
      if skx is None:
        skx_ = None
      else:
        try:
          skx_ = memoryview(skx)
        except TypeError:
          try:
            _tmparr_skx = array.array("i",skx)
          except TypeError:
            raise TypeError("Argument skx has wrong type")
          else:
            skx_ = memoryview(_tmparr_skx)
            _copyback_skx = True
        else:
          if skx_.format != "i":
            skx_ = memoryview(array.array("i",skx))
            _copyback_skx = True
      if skx_ is not None and len(skx_) != self.getnumvar():
        raise ValueError("Array argument skx has wrong length")
      res = self.__obj.getskx(whichsol_,skx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_skx:
        for __tmp_var_0 in range(len(skx_)): skx[__tmp_var_0] = stakey(_tmparr_skx[__tmp_var_0])
    
    def getxc(self,whichsol_,xc): # 3
      """
      Obtains the xc vector for a solution.
    
      getxc(self,whichsol_,xc)
        whichsol: mosek.soltype. Selects a solution.
        xc: array of double. Primal constraint solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if xc is None: raise TypeError("Invalid type for argument xc")
      _copyback_xc = False
      if xc is None:
        xc_ = None
      else:
        try:
          xc_ = memoryview(xc)
        except TypeError:
          try:
            _tmparr_xc = array.array("d",xc)
          except TypeError:
            raise TypeError("Argument xc has wrong type")
          else:
            xc_ = memoryview(_tmparr_xc)
            _copyback_xc = True
        else:
          if xc_.format != "d":
            xc_ = memoryview(array.array("d",xc))
            _copyback_xc = True
      if xc_ is not None and len(xc_) != self.getnumcon():
        raise ValueError("Array argument xc has wrong length")
      res = self.__obj.getxc(whichsol_,xc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_xc:
        xc[:] = _tmparr_xc
    
    def getxx(self,whichsol_,xx): # 3
      """
      Obtains the xx vector for a solution.
    
      getxx(self,whichsol_,xx)
        whichsol: mosek.soltype. Selects a solution.
        xx: array of double. Primal variable solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if xx is None: raise TypeError("Invalid type for argument xx")
      _copyback_xx = False
      if xx is None:
        xx_ = None
      else:
        try:
          xx_ = memoryview(xx)
        except TypeError:
          try:
            _tmparr_xx = array.array("d",xx)
          except TypeError:
            raise TypeError("Argument xx has wrong type")
          else:
            xx_ = memoryview(_tmparr_xx)
            _copyback_xx = True
        else:
          if xx_.format != "d":
            xx_ = memoryview(array.array("d",xx))
            _copyback_xx = True
      if xx_ is not None and len(xx_) != self.getnumvar():
        raise ValueError("Array argument xx has wrong length")
      res = self.__obj.getxx(whichsol_,xx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_xx:
        xx[:] = _tmparr_xx
    
    def gety(self,whichsol_,y): # 3
      """
      Obtains the y vector for a solution.
    
      gety(self,whichsol_,y)
        whichsol: mosek.soltype. Selects a solution.
        y: array of double. Vector of dual variables corresponding to the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if y is None: raise TypeError("Invalid type for argument y")
      _copyback_y = False
      if y is None:
        y_ = None
      else:
        try:
          y_ = memoryview(y)
        except TypeError:
          try:
            _tmparr_y = array.array("d",y)
          except TypeError:
            raise TypeError("Argument y has wrong type")
          else:
            y_ = memoryview(_tmparr_y)
            _copyback_y = True
        else:
          if y_.format != "d":
            y_ = memoryview(array.array("d",y))
            _copyback_y = True
      if y_ is not None and len(y_) != self.getnumcon():
        raise ValueError("Array argument y has wrong length")
      res = self.__obj.gety(whichsol_,y_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_y:
        y[:] = _tmparr_y
    
    def getslc(self,whichsol_,slc): # 3
      """
      Obtains the slc vector for a solution.
    
      getslc(self,whichsol_,slc)
        whichsol: mosek.soltype. Selects a solution.
        slc: array of double. Dual variables corresponding to the lower bounds on the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if slc is None: raise TypeError("Invalid type for argument slc")
      _copyback_slc = False
      if slc is None:
        slc_ = None
      else:
        try:
          slc_ = memoryview(slc)
        except TypeError:
          try:
            _tmparr_slc = array.array("d",slc)
          except TypeError:
            raise TypeError("Argument slc has wrong type")
          else:
            slc_ = memoryview(_tmparr_slc)
            _copyback_slc = True
        else:
          if slc_.format != "d":
            slc_ = memoryview(array.array("d",slc))
            _copyback_slc = True
      if slc_ is not None and len(slc_) != self.getnumcon():
        raise ValueError("Array argument slc has wrong length")
      res = self.__obj.getslc(whichsol_,slc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_slc:
        slc[:] = _tmparr_slc
    
    def getsuc(self,whichsol_,suc): # 3
      """
      Obtains the suc vector for a solution.
    
      getsuc(self,whichsol_,suc)
        whichsol: mosek.soltype. Selects a solution.
        suc: array of double. Dual variables corresponding to the upper bounds on the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if suc is None: raise TypeError("Invalid type for argument suc")
      _copyback_suc = False
      if suc is None:
        suc_ = None
      else:
        try:
          suc_ = memoryview(suc)
        except TypeError:
          try:
            _tmparr_suc = array.array("d",suc)
          except TypeError:
            raise TypeError("Argument suc has wrong type")
          else:
            suc_ = memoryview(_tmparr_suc)
            _copyback_suc = True
        else:
          if suc_.format != "d":
            suc_ = memoryview(array.array("d",suc))
            _copyback_suc = True
      if suc_ is not None and len(suc_) != self.getnumcon():
        raise ValueError("Array argument suc has wrong length")
      res = self.__obj.getsuc(whichsol_,suc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_suc:
        suc[:] = _tmparr_suc
    
    def getslx(self,whichsol_,slx): # 3
      """
      Obtains the slx vector for a solution.
    
      getslx(self,whichsol_,slx)
        whichsol: mosek.soltype. Selects a solution.
        slx: array of double. Dual variables corresponding to the lower bounds on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if slx is None: raise TypeError("Invalid type for argument slx")
      _copyback_slx = False
      if slx is None:
        slx_ = None
      else:
        try:
          slx_ = memoryview(slx)
        except TypeError:
          try:
            _tmparr_slx = array.array("d",slx)
          except TypeError:
            raise TypeError("Argument slx has wrong type")
          else:
            slx_ = memoryview(_tmparr_slx)
            _copyback_slx = True
        else:
          if slx_.format != "d":
            slx_ = memoryview(array.array("d",slx))
            _copyback_slx = True
      if slx_ is not None and len(slx_) != self.getnumvar():
        raise ValueError("Array argument slx has wrong length")
      res = self.__obj.getslx(whichsol_,slx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_slx:
        slx[:] = _tmparr_slx
    
    def getsux(self,whichsol_,sux): # 3
      """
      Obtains the sux vector for a solution.
    
      getsux(self,whichsol_,sux)
        whichsol: mosek.soltype. Selects a solution.
        sux: array of double. Dual variables corresponding to the upper bounds on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if sux is None: raise TypeError("Invalid type for argument sux")
      _copyback_sux = False
      if sux is None:
        sux_ = None
      else:
        try:
          sux_ = memoryview(sux)
        except TypeError:
          try:
            _tmparr_sux = array.array("d",sux)
          except TypeError:
            raise TypeError("Argument sux has wrong type")
          else:
            sux_ = memoryview(_tmparr_sux)
            _copyback_sux = True
        else:
          if sux_.format != "d":
            sux_ = memoryview(array.array("d",sux))
            _copyback_sux = True
      if sux_ is not None and len(sux_) != self.getnumvar():
        raise ValueError("Array argument sux has wrong length")
      res = self.__obj.getsux(whichsol_,sux_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_sux:
        sux[:] = _tmparr_sux
    
    def getsnx(self,whichsol_,snx): # 3
      """
      Obtains the snx vector for a solution.
    
      getsnx(self,whichsol_,snx)
        whichsol: mosek.soltype. Selects a solution.
        snx: array of double. Dual variables corresponding to the conic constraints on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if snx is None: raise TypeError("Invalid type for argument snx")
      _copyback_snx = False
      if snx is None:
        snx_ = None
      else:
        try:
          snx_ = memoryview(snx)
        except TypeError:
          try:
            _tmparr_snx = array.array("d",snx)
          except TypeError:
            raise TypeError("Argument snx has wrong type")
          else:
            snx_ = memoryview(_tmparr_snx)
            _copyback_snx = True
        else:
          if snx_.format != "d":
            snx_ = memoryview(array.array("d",snx))
            _copyback_snx = True
      if snx_ is not None and len(snx_) != self.getnumvar():
        raise ValueError("Array argument snx has wrong length")
      res = self.__obj.getsnx(whichsol_,snx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_snx:
        snx[:] = _tmparr_snx
    
    def getskcslice(self,whichsol_,first_,last_,skc): # 3
      """
      Obtains the status keys for a slice of the constraints.
    
      getskcslice(self,whichsol_,first_,last_,skc)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        skc: array of mosek.stakey. Status keys for the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_skc = False
      if skc is None:
        skc_ = None
      else:
        try:
          skc_ = memoryview(skc)
        except TypeError:
          try:
            _tmparr_skc = array.array("i",skc)
          except TypeError:
            raise TypeError("Argument skc has wrong type")
          else:
            skc_ = memoryview(_tmparr_skc)
            _copyback_skc = True
        else:
          if skc_.format != "i":
            skc_ = memoryview(array.array("i",skc))
            _copyback_skc = True
      if skc_ is not None and len(skc_) != ((last_) - (first_)):
        raise ValueError("Array argument skc has wrong length")
      res = self.__obj.getskcslice(whichsol_,first_,last_,skc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_skc:
        for __tmp_var_0 in range(len(skc_)): skc[__tmp_var_0] = stakey(_tmparr_skc[__tmp_var_0])
    
    def getskxslice(self,whichsol_,first_,last_,skx): # 3
      """
      Obtains the status keys for a slice of the scalar variables.
    
      getskxslice(self,whichsol_,first_,last_,skx)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        skx: array of mosek.stakey. Status keys for the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_skx = False
      if skx is None:
        skx_ = None
      else:
        try:
          skx_ = memoryview(skx)
        except TypeError:
          try:
            _tmparr_skx = array.array("i",skx)
          except TypeError:
            raise TypeError("Argument skx has wrong type")
          else:
            skx_ = memoryview(_tmparr_skx)
            _copyback_skx = True
        else:
          if skx_.format != "i":
            skx_ = memoryview(array.array("i",skx))
            _copyback_skx = True
      if skx_ is not None and len(skx_) != ((last_) - (first_)):
        raise ValueError("Array argument skx has wrong length")
      res = self.__obj.getskxslice(whichsol_,first_,last_,skx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_skx:
        for __tmp_var_0 in range(len(skx_)): skx[__tmp_var_0] = stakey(_tmparr_skx[__tmp_var_0])
    
    def getxcslice(self,whichsol_,first_,last_,xc): # 3
      """
      Obtains a slice of the xc vector for a solution.
    
      getxcslice(self,whichsol_,first_,last_,xc)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        xc: array of double. Primal constraint solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_xc = False
      if xc is None:
        xc_ = None
      else:
        try:
          xc_ = memoryview(xc)
        except TypeError:
          try:
            _tmparr_xc = array.array("d",xc)
          except TypeError:
            raise TypeError("Argument xc has wrong type")
          else:
            xc_ = memoryview(_tmparr_xc)
            _copyback_xc = True
        else:
          if xc_.format != "d":
            xc_ = memoryview(array.array("d",xc))
            _copyback_xc = True
      if xc_ is not None and len(xc_) != ((last_) - (first_)):
        raise ValueError("Array argument xc has wrong length")
      res = self.__obj.getxcslice(whichsol_,first_,last_,xc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_xc:
        xc[:] = _tmparr_xc
    
    def getxxslice(self,whichsol_,first_,last_,xx): # 3
      """
      Obtains a slice of the xx vector for a solution.
    
      getxxslice(self,whichsol_,first_,last_,xx)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        xx: array of double. Primal variable solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_xx = False
      if xx is None:
        xx_ = None
      else:
        try:
          xx_ = memoryview(xx)
        except TypeError:
          try:
            _tmparr_xx = array.array("d",xx)
          except TypeError:
            raise TypeError("Argument xx has wrong type")
          else:
            xx_ = memoryview(_tmparr_xx)
            _copyback_xx = True
        else:
          if xx_.format != "d":
            xx_ = memoryview(array.array("d",xx))
            _copyback_xx = True
      if xx_ is not None and len(xx_) != ((last_) - (first_)):
        raise ValueError("Array argument xx has wrong length")
      res = self.__obj.getxxslice(whichsol_,first_,last_,xx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_xx:
        xx[:] = _tmparr_xx
    
    def getyslice(self,whichsol_,first_,last_,y): # 3
      """
      Obtains a slice of the y vector for a solution.
    
      getyslice(self,whichsol_,first_,last_,y)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        y: array of double. Vector of dual variables corresponding to the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_y = False
      if y is None:
        y_ = None
      else:
        try:
          y_ = memoryview(y)
        except TypeError:
          try:
            _tmparr_y = array.array("d",y)
          except TypeError:
            raise TypeError("Argument y has wrong type")
          else:
            y_ = memoryview(_tmparr_y)
            _copyback_y = True
        else:
          if y_.format != "d":
            y_ = memoryview(array.array("d",y))
            _copyback_y = True
      if y_ is not None and len(y_) != ((last_) - (first_)):
        raise ValueError("Array argument y has wrong length")
      res = self.__obj.getyslice(whichsol_,first_,last_,y_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_y:
        y[:] = _tmparr_y
    
    def getslcslice(self,whichsol_,first_,last_,slc): # 3
      """
      Obtains a slice of the slc vector for a solution.
    
      getslcslice(self,whichsol_,first_,last_,slc)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        slc: array of double. Dual variables corresponding to the lower bounds on the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_slc = False
      if slc is None:
        slc_ = None
      else:
        try:
          slc_ = memoryview(slc)
        except TypeError:
          try:
            _tmparr_slc = array.array("d",slc)
          except TypeError:
            raise TypeError("Argument slc has wrong type")
          else:
            slc_ = memoryview(_tmparr_slc)
            _copyback_slc = True
        else:
          if slc_.format != "d":
            slc_ = memoryview(array.array("d",slc))
            _copyback_slc = True
      if slc_ is not None and len(slc_) != ((last_) - (first_)):
        raise ValueError("Array argument slc has wrong length")
      res = self.__obj.getslcslice(whichsol_,first_,last_,slc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_slc:
        slc[:] = _tmparr_slc
    
    def getsucslice(self,whichsol_,first_,last_,suc): # 3
      """
      Obtains a slice of the suc vector for a solution.
    
      getsucslice(self,whichsol_,first_,last_,suc)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        suc: array of double. Dual variables corresponding to the upper bounds on the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_suc = False
      if suc is None:
        suc_ = None
      else:
        try:
          suc_ = memoryview(suc)
        except TypeError:
          try:
            _tmparr_suc = array.array("d",suc)
          except TypeError:
            raise TypeError("Argument suc has wrong type")
          else:
            suc_ = memoryview(_tmparr_suc)
            _copyback_suc = True
        else:
          if suc_.format != "d":
            suc_ = memoryview(array.array("d",suc))
            _copyback_suc = True
      if suc_ is not None and len(suc_) != ((last_) - (first_)):
        raise ValueError("Array argument suc has wrong length")
      res = self.__obj.getsucslice(whichsol_,first_,last_,suc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_suc:
        suc[:] = _tmparr_suc
    
    def getslxslice(self,whichsol_,first_,last_,slx): # 3
      """
      Obtains a slice of the slx vector for a solution.
    
      getslxslice(self,whichsol_,first_,last_,slx)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        slx: array of double. Dual variables corresponding to the lower bounds on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_slx = False
      if slx is None:
        slx_ = None
      else:
        try:
          slx_ = memoryview(slx)
        except TypeError:
          try:
            _tmparr_slx = array.array("d",slx)
          except TypeError:
            raise TypeError("Argument slx has wrong type")
          else:
            slx_ = memoryview(_tmparr_slx)
            _copyback_slx = True
        else:
          if slx_.format != "d":
            slx_ = memoryview(array.array("d",slx))
            _copyback_slx = True
      if slx_ is not None and len(slx_) != ((last_) - (first_)):
        raise ValueError("Array argument slx has wrong length")
      res = self.__obj.getslxslice(whichsol_,first_,last_,slx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_slx:
        slx[:] = _tmparr_slx
    
    def getsuxslice(self,whichsol_,first_,last_,sux): # 3
      """
      Obtains a slice of the sux vector for a solution.
    
      getsuxslice(self,whichsol_,first_,last_,sux)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        sux: array of double. Dual variables corresponding to the upper bounds on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_sux = False
      if sux is None:
        sux_ = None
      else:
        try:
          sux_ = memoryview(sux)
        except TypeError:
          try:
            _tmparr_sux = array.array("d",sux)
          except TypeError:
            raise TypeError("Argument sux has wrong type")
          else:
            sux_ = memoryview(_tmparr_sux)
            _copyback_sux = True
        else:
          if sux_.format != "d":
            sux_ = memoryview(array.array("d",sux))
            _copyback_sux = True
      if sux_ is not None and len(sux_) != ((last_) - (first_)):
        raise ValueError("Array argument sux has wrong length")
      res = self.__obj.getsuxslice(whichsol_,first_,last_,sux_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_sux:
        sux[:] = _tmparr_sux
    
    def getsnxslice(self,whichsol_,first_,last_,snx): # 3
      """
      Obtains a slice of the snx vector for a solution.
    
      getsnxslice(self,whichsol_,first_,last_,snx)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        snx: array of double. Dual variables corresponding to the conic constraints on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_snx = False
      if snx is None:
        snx_ = None
      else:
        try:
          snx_ = memoryview(snx)
        except TypeError:
          try:
            _tmparr_snx = array.array("d",snx)
          except TypeError:
            raise TypeError("Argument snx has wrong type")
          else:
            snx_ = memoryview(_tmparr_snx)
            _copyback_snx = True
        else:
          if snx_.format != "d":
            snx_ = memoryview(array.array("d",snx))
            _copyback_snx = True
      if snx_ is not None and len(snx_) != ((last_) - (first_)):
        raise ValueError("Array argument snx has wrong length")
      res = self.__obj.getsnxslice(whichsol_,first_,last_,snx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_snx:
        snx[:] = _tmparr_snx
    
    def getbarxj(self,whichsol_,j_,barxj): # 3
      """
      Obtains the primal solution for a semidefinite variable.
    
      getbarxj(self,whichsol_,j_,barxj)
        whichsol: mosek.soltype. Selects a solution.
        j: int. Index of the semidefinite variable.
        barxj: array of double. Value of the j'th variable of barx.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if barxj is None: raise TypeError("Invalid type for argument barxj")
      _copyback_barxj = False
      if barxj is None:
        barxj_ = None
      else:
        try:
          barxj_ = memoryview(barxj)
        except TypeError:
          try:
            _tmparr_barxj = array.array("d",barxj)
          except TypeError:
            raise TypeError("Argument barxj has wrong type")
          else:
            barxj_ = memoryview(_tmparr_barxj)
            _copyback_barxj = True
        else:
          if barxj_.format != "d":
            barxj_ = memoryview(array.array("d",barxj))
            _copyback_barxj = True
      if barxj_ is not None and len(barxj_) != self.getlenbarvarj((j_)):
        raise ValueError("Array argument barxj has wrong length")
      res = self.__obj.getbarxj(whichsol_,j_,barxj_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_barxj:
        barxj[:] = _tmparr_barxj
    
    def getbarsj(self,whichsol_,j_,barsj): # 3
      """
      Obtains the dual solution for a semidefinite variable.
    
      getbarsj(self,whichsol_,j_,barsj)
        whichsol: mosek.soltype. Selects a solution.
        j: int. Index of the semidefinite variable.
        barsj: array of double. Value of the j'th dual variable of barx.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if barsj is None: raise TypeError("Invalid type for argument barsj")
      _copyback_barsj = False
      if barsj is None:
        barsj_ = None
      else:
        try:
          barsj_ = memoryview(barsj)
        except TypeError:
          try:
            _tmparr_barsj = array.array("d",barsj)
          except TypeError:
            raise TypeError("Argument barsj has wrong type")
          else:
            barsj_ = memoryview(_tmparr_barsj)
            _copyback_barsj = True
        else:
          if barsj_.format != "d":
            barsj_ = memoryview(array.array("d",barsj))
            _copyback_barsj = True
      if barsj_ is not None and len(barsj_) != self.getlenbarvarj((j_)):
        raise ValueError("Array argument barsj has wrong length")
      res = self.__obj.getbarsj(whichsol_,j_,barsj_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_barsj:
        barsj[:] = _tmparr_barsj
    
    def putskc(self,whichsol_,skc): # 3
      """
      Sets the status keys for the constraints.
    
      putskc(self,whichsol_,skc)
        whichsol: mosek.soltype. Selects a solution.
        skc: array of mosek.stakey. Status keys for the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if skc is None: raise TypeError("Invalid type for argument skc")
      if skc is None:
        skc_ = None
      else:
        try:
          skc_ = memoryview(skc)
        except TypeError:
          try:
            _tmparr_skc = array.array("i",skc)
          except TypeError:
            raise TypeError("Argument skc has wrong type")
          else:
            skc_ = memoryview(_tmparr_skc)
      
        else:
          if skc_.format != "i":
            skc_ = memoryview(array.array("i",skc))
      
      if skc_ is not None and len(skc_) != self.getnumcon():
        raise ValueError("Array argument skc has wrong length")
      res = self.__obj.putskc(whichsol_,skc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putskx(self,whichsol_,skx): # 3
      """
      Sets the status keys for the scalar variables.
    
      putskx(self,whichsol_,skx)
        whichsol: mosek.soltype. Selects a solution.
        skx: array of mosek.stakey. Status keys for the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if skx is None: raise TypeError("Invalid type for argument skx")
      if skx is None:
        skx_ = None
      else:
        try:
          skx_ = memoryview(skx)
        except TypeError:
          try:
            _tmparr_skx = array.array("i",skx)
          except TypeError:
            raise TypeError("Argument skx has wrong type")
          else:
            skx_ = memoryview(_tmparr_skx)
      
        else:
          if skx_.format != "i":
            skx_ = memoryview(array.array("i",skx))
      
      if skx_ is not None and len(skx_) != self.getnumvar():
        raise ValueError("Array argument skx has wrong length")
      res = self.__obj.putskx(whichsol_,skx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putxc(self,whichsol_,xc): # 3
      """
      Sets the xc vector for a solution.
    
      putxc(self,whichsol_,xc)
        whichsol: mosek.soltype. Selects a solution.
        xc: array of double. Primal constraint solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if xc is None: raise TypeError("Invalid type for argument xc")
      _copyback_xc = False
      if xc is None:
        xc_ = None
      else:
        try:
          xc_ = memoryview(xc)
        except TypeError:
          try:
            _tmparr_xc = array.array("d",xc)
          except TypeError:
            raise TypeError("Argument xc has wrong type")
          else:
            xc_ = memoryview(_tmparr_xc)
            _copyback_xc = True
        else:
          if xc_.format != "d":
            xc_ = memoryview(array.array("d",xc))
            _copyback_xc = True
      if xc_ is not None and len(xc_) != self.getnumcon():
        raise ValueError("Array argument xc has wrong length")
      res = self.__obj.putxc(whichsol_,xc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_xc:
        xc[:] = _tmparr_xc
    
    def putxx(self,whichsol_,xx): # 3
      """
      Sets the xx vector for a solution.
    
      putxx(self,whichsol_,xx)
        whichsol: mosek.soltype. Selects a solution.
        xx: array of double. Primal variable solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if xx is None: raise TypeError("Invalid type for argument xx")
      if xx is None:
        xx_ = None
      else:
        try:
          xx_ = memoryview(xx)
        except TypeError:
          try:
            _tmparr_xx = array.array("d",xx)
          except TypeError:
            raise TypeError("Argument xx has wrong type")
          else:
            xx_ = memoryview(_tmparr_xx)
      
        else:
          if xx_.format != "d":
            xx_ = memoryview(array.array("d",xx))
      
      if xx_ is not None and len(xx_) != self.getnumvar():
        raise ValueError("Array argument xx has wrong length")
      res = self.__obj.putxx(whichsol_,xx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def puty(self,whichsol_,y): # 3
      """
      Sets the y vector for a solution.
    
      puty(self,whichsol_,y)
        whichsol: mosek.soltype. Selects a solution.
        y: array of double. Vector of dual variables corresponding to the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if y is None: raise TypeError("Invalid type for argument y")
      if y is None:
        y_ = None
      else:
        try:
          y_ = memoryview(y)
        except TypeError:
          try:
            _tmparr_y = array.array("d",y)
          except TypeError:
            raise TypeError("Argument y has wrong type")
          else:
            y_ = memoryview(_tmparr_y)
      
        else:
          if y_.format != "d":
            y_ = memoryview(array.array("d",y))
      
      if y_ is not None and len(y_) != self.getnumcon():
        raise ValueError("Array argument y has wrong length")
      res = self.__obj.puty(whichsol_,y_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putslc(self,whichsol_,slc): # 3
      """
      Sets the slc vector for a solution.
    
      putslc(self,whichsol_,slc)
        whichsol: mosek.soltype. Selects a solution.
        slc: array of double. Dual variables corresponding to the lower bounds on the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if slc is None: raise TypeError("Invalid type for argument slc")
      if slc is None:
        slc_ = None
      else:
        try:
          slc_ = memoryview(slc)
        except TypeError:
          try:
            _tmparr_slc = array.array("d",slc)
          except TypeError:
            raise TypeError("Argument slc has wrong type")
          else:
            slc_ = memoryview(_tmparr_slc)
      
        else:
          if slc_.format != "d":
            slc_ = memoryview(array.array("d",slc))
      
      if slc_ is not None and len(slc_) != self.getnumcon():
        raise ValueError("Array argument slc has wrong length")
      res = self.__obj.putslc(whichsol_,slc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putsuc(self,whichsol_,suc): # 3
      """
      Sets the suc vector for a solution.
    
      putsuc(self,whichsol_,suc)
        whichsol: mosek.soltype. Selects a solution.
        suc: array of double. Dual variables corresponding to the upper bounds on the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if suc is None: raise TypeError("Invalid type for argument suc")
      if suc is None:
        suc_ = None
      else:
        try:
          suc_ = memoryview(suc)
        except TypeError:
          try:
            _tmparr_suc = array.array("d",suc)
          except TypeError:
            raise TypeError("Argument suc has wrong type")
          else:
            suc_ = memoryview(_tmparr_suc)
      
        else:
          if suc_.format != "d":
            suc_ = memoryview(array.array("d",suc))
      
      if suc_ is not None and len(suc_) != self.getnumcon():
        raise ValueError("Array argument suc has wrong length")
      res = self.__obj.putsuc(whichsol_,suc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putslx(self,whichsol_,slx): # 3
      """
      Sets the slx vector for a solution.
    
      putslx(self,whichsol_,slx)
        whichsol: mosek.soltype. Selects a solution.
        slx: array of double. Dual variables corresponding to the lower bounds on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if slx is None: raise TypeError("Invalid type for argument slx")
      if slx is None:
        slx_ = None
      else:
        try:
          slx_ = memoryview(slx)
        except TypeError:
          try:
            _tmparr_slx = array.array("d",slx)
          except TypeError:
            raise TypeError("Argument slx has wrong type")
          else:
            slx_ = memoryview(_tmparr_slx)
      
        else:
          if slx_.format != "d":
            slx_ = memoryview(array.array("d",slx))
      
      if slx_ is not None and len(slx_) != self.getnumvar():
        raise ValueError("Array argument slx has wrong length")
      res = self.__obj.putslx(whichsol_,slx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putsux(self,whichsol_,sux): # 3
      """
      Sets the sux vector for a solution.
    
      putsux(self,whichsol_,sux)
        whichsol: mosek.soltype. Selects a solution.
        sux: array of double. Dual variables corresponding to the upper bounds on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if sux is None: raise TypeError("Invalid type for argument sux")
      if sux is None:
        sux_ = None
      else:
        try:
          sux_ = memoryview(sux)
        except TypeError:
          try:
            _tmparr_sux = array.array("d",sux)
          except TypeError:
            raise TypeError("Argument sux has wrong type")
          else:
            sux_ = memoryview(_tmparr_sux)
      
        else:
          if sux_.format != "d":
            sux_ = memoryview(array.array("d",sux))
      
      if sux_ is not None and len(sux_) != self.getnumvar():
        raise ValueError("Array argument sux has wrong length")
      res = self.__obj.putsux(whichsol_,sux_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putsnx(self,whichsol_,sux): # 3
      """
      Sets the snx vector for a solution.
    
      putsnx(self,whichsol_,sux)
        whichsol: mosek.soltype. Selects a solution.
        sux: array of double. Dual variables corresponding to the upper bounds on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if sux is None: raise TypeError("Invalid type for argument sux")
      if sux is None:
        sux_ = None
      else:
        try:
          sux_ = memoryview(sux)
        except TypeError:
          try:
            _tmparr_sux = array.array("d",sux)
          except TypeError:
            raise TypeError("Argument sux has wrong type")
          else:
            sux_ = memoryview(_tmparr_sux)
      
        else:
          if sux_.format != "d":
            sux_ = memoryview(array.array("d",sux))
      
      if sux_ is not None and len(sux_) != self.getnumvar():
        raise ValueError("Array argument sux has wrong length")
      res = self.__obj.putsnx(whichsol_,sux_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putskcslice(self,whichsol_,first_,last_,skc): # 3
      """
      Sets the status keys for a slice of the constraints.
    
      putskcslice(self,whichsol_,first_,last_,skc)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        skc: array of mosek.stakey. Status keys for the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if skc is None:
        skc_ = None
      else:
        try:
          skc_ = memoryview(skc)
        except TypeError:
          try:
            _tmparr_skc = array.array("i",skc)
          except TypeError:
            raise TypeError("Argument skc has wrong type")
          else:
            skc_ = memoryview(_tmparr_skc)
      
        else:
          if skc_.format != "i":
            skc_ = memoryview(array.array("i",skc))
      
      if skc_ is not None and len(skc_) != ((last_) - (first_)):
        raise ValueError("Array argument skc has wrong length")
      res = self.__obj.putskcslice(whichsol_,first_,last_,skc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putskxslice(self,whichsol_,first_,last_,skx): # 3
      """
      Sets the status keys for a slice of the variables.
    
      putskxslice(self,whichsol_,first_,last_,skx)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        skx: array of mosek.stakey. Status keys for the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if skx is None: raise TypeError("Invalid type for argument skx")
      if skx is None:
        skx_ = None
      else:
        try:
          skx_ = memoryview(skx)
        except TypeError:
          try:
            _tmparr_skx = array.array("i",skx)
          except TypeError:
            raise TypeError("Argument skx has wrong type")
          else:
            skx_ = memoryview(_tmparr_skx)
      
        else:
          if skx_.format != "i":
            skx_ = memoryview(array.array("i",skx))
      
      if skx_ is not None and len(skx_) != ((last_) - (first_)):
        raise ValueError("Array argument skx has wrong length")
      res = self.__obj.putskxslice(whichsol_,first_,last_,skx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putxcslice(self,whichsol_,first_,last_,xc): # 3
      """
      Sets a slice of the xc vector for a solution.
    
      putxcslice(self,whichsol_,first_,last_,xc)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        xc: array of double. Primal constraint solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if xc is None: raise TypeError("Invalid type for argument xc")
      if xc is None:
        xc_ = None
      else:
        try:
          xc_ = memoryview(xc)
        except TypeError:
          try:
            _tmparr_xc = array.array("d",xc)
          except TypeError:
            raise TypeError("Argument xc has wrong type")
          else:
            xc_ = memoryview(_tmparr_xc)
      
        else:
          if xc_.format != "d":
            xc_ = memoryview(array.array("d",xc))
      
      if xc_ is not None and len(xc_) != ((last_) - (first_)):
        raise ValueError("Array argument xc has wrong length")
      res = self.__obj.putxcslice(whichsol_,first_,last_,xc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putxxslice(self,whichsol_,first_,last_,xx): # 3
      """
      Obtains a slice of the xx vector for a solution.
    
      putxxslice(self,whichsol_,first_,last_,xx)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        xx: array of double. Primal variable solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if xx is None: raise TypeError("Invalid type for argument xx")
      if xx is None:
        xx_ = None
      else:
        try:
          xx_ = memoryview(xx)
        except TypeError:
          try:
            _tmparr_xx = array.array("d",xx)
          except TypeError:
            raise TypeError("Argument xx has wrong type")
          else:
            xx_ = memoryview(_tmparr_xx)
      
        else:
          if xx_.format != "d":
            xx_ = memoryview(array.array("d",xx))
      
      if xx_ is not None and len(xx_) != ((last_) - (first_)):
        raise ValueError("Array argument xx has wrong length")
      res = self.__obj.putxxslice(whichsol_,first_,last_,xx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putyslice(self,whichsol_,first_,last_,y): # 3
      """
      Sets a slice of the y vector for a solution.
    
      putyslice(self,whichsol_,first_,last_,y)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        y: array of double. Vector of dual variables corresponding to the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if y is None: raise TypeError("Invalid type for argument y")
      if y is None:
        y_ = None
      else:
        try:
          y_ = memoryview(y)
        except TypeError:
          try:
            _tmparr_y = array.array("d",y)
          except TypeError:
            raise TypeError("Argument y has wrong type")
          else:
            y_ = memoryview(_tmparr_y)
      
        else:
          if y_.format != "d":
            y_ = memoryview(array.array("d",y))
      
      if y_ is not None and len(y_) != ((last_) - (first_)):
        raise ValueError("Array argument y has wrong length")
      res = self.__obj.putyslice(whichsol_,first_,last_,y_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putslcslice(self,whichsol_,first_,last_,slc): # 3
      """
      Sets a slice of the slc vector for a solution.
    
      putslcslice(self,whichsol_,first_,last_,slc)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        slc: array of double. Dual variables corresponding to the lower bounds on the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if slc is None: raise TypeError("Invalid type for argument slc")
      if slc is None:
        slc_ = None
      else:
        try:
          slc_ = memoryview(slc)
        except TypeError:
          try:
            _tmparr_slc = array.array("d",slc)
          except TypeError:
            raise TypeError("Argument slc has wrong type")
          else:
            slc_ = memoryview(_tmparr_slc)
      
        else:
          if slc_.format != "d":
            slc_ = memoryview(array.array("d",slc))
      
      if slc_ is not None and len(slc_) != ((last_) - (first_)):
        raise ValueError("Array argument slc has wrong length")
      res = self.__obj.putslcslice(whichsol_,first_,last_,slc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putsucslice(self,whichsol_,first_,last_,suc): # 3
      """
      Sets a slice of the suc vector for a solution.
    
      putsucslice(self,whichsol_,first_,last_,suc)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        suc: array of double. Dual variables corresponding to the upper bounds on the constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if suc is None: raise TypeError("Invalid type for argument suc")
      if suc is None:
        suc_ = None
      else:
        try:
          suc_ = memoryview(suc)
        except TypeError:
          try:
            _tmparr_suc = array.array("d",suc)
          except TypeError:
            raise TypeError("Argument suc has wrong type")
          else:
            suc_ = memoryview(_tmparr_suc)
      
        else:
          if suc_.format != "d":
            suc_ = memoryview(array.array("d",suc))
      
      if suc_ is not None and len(suc_) != ((last_) - (first_)):
        raise ValueError("Array argument suc has wrong length")
      res = self.__obj.putsucslice(whichsol_,first_,last_,suc_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putslxslice(self,whichsol_,first_,last_,slx): # 3
      """
      Sets a slice of the slx vector for a solution.
    
      putslxslice(self,whichsol_,first_,last_,slx)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        slx: array of double. Dual variables corresponding to the lower bounds on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if slx is None: raise TypeError("Invalid type for argument slx")
      if slx is None:
        slx_ = None
      else:
        try:
          slx_ = memoryview(slx)
        except TypeError:
          try:
            _tmparr_slx = array.array("d",slx)
          except TypeError:
            raise TypeError("Argument slx has wrong type")
          else:
            slx_ = memoryview(_tmparr_slx)
      
        else:
          if slx_.format != "d":
            slx_ = memoryview(array.array("d",slx))
      
      if slx_ is not None and len(slx_) != ((last_) - (first_)):
        raise ValueError("Array argument slx has wrong length")
      res = self.__obj.putslxslice(whichsol_,first_,last_,slx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putsuxslice(self,whichsol_,first_,last_,sux): # 3
      """
      Sets a slice of the sux vector for a solution.
    
      putsuxslice(self,whichsol_,first_,last_,sux)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        sux: array of double. Dual variables corresponding to the upper bounds on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if sux is None: raise TypeError("Invalid type for argument sux")
      if sux is None:
        sux_ = None
      else:
        try:
          sux_ = memoryview(sux)
        except TypeError:
          try:
            _tmparr_sux = array.array("d",sux)
          except TypeError:
            raise TypeError("Argument sux has wrong type")
          else:
            sux_ = memoryview(_tmparr_sux)
      
        else:
          if sux_.format != "d":
            sux_ = memoryview(array.array("d",sux))
      
      if sux_ is not None and len(sux_) != ((last_) - (first_)):
        raise ValueError("Array argument sux has wrong length")
      res = self.__obj.putsuxslice(whichsol_,first_,last_,sux_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putsnxslice(self,whichsol_,first_,last_,snx): # 3
      """
      Sets a slice of the snx vector for a solution.
    
      putsnxslice(self,whichsol_,first_,last_,snx)
        whichsol: mosek.soltype. Selects a solution.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        snx: array of double. Dual variables corresponding to the conic constraints on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if snx is None: raise TypeError("Invalid type for argument snx")
      if snx is None:
        snx_ = None
      else:
        try:
          snx_ = memoryview(snx)
        except TypeError:
          try:
            _tmparr_snx = array.array("d",snx)
          except TypeError:
            raise TypeError("Argument snx has wrong type")
          else:
            snx_ = memoryview(_tmparr_snx)
      
        else:
          if snx_.format != "d":
            snx_ = memoryview(array.array("d",snx))
      
      if snx_ is not None and len(snx_) != ((last_) - (first_)):
        raise ValueError("Array argument snx has wrong length")
      res = self.__obj.putsnxslice(whichsol_,first_,last_,snx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putbarxj(self,whichsol_,j_,barxj): # 3
      """
      Sets the primal solution for a semidefinite variable.
    
      putbarxj(self,whichsol_,j_,barxj)
        whichsol: mosek.soltype. Selects a solution.
        j: int. Index of the semidefinite variable.
        barxj: array of double. Value of the j'th variable of barx.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if barxj is None: raise TypeError("Invalid type for argument barxj")
      if barxj is None:
        barxj_ = None
      else:
        try:
          barxj_ = memoryview(barxj)
        except TypeError:
          try:
            _tmparr_barxj = array.array("d",barxj)
          except TypeError:
            raise TypeError("Argument barxj has wrong type")
          else:
            barxj_ = memoryview(_tmparr_barxj)
      
        else:
          if barxj_.format != "d":
            barxj_ = memoryview(array.array("d",barxj))
      
      if barxj_ is not None and len(barxj_) != self.getlenbarvarj((j_)):
        raise ValueError("Array argument barxj has wrong length")
      res = self.__obj.putbarxj(whichsol_,j_,barxj_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putbarsj(self,whichsol_,j_,barsj): # 3
      """
      Sets the dual solution for a semidefinite variable.
    
      putbarsj(self,whichsol_,j_,barsj)
        whichsol: mosek.soltype. Selects a solution.
        j: int. Index of the semidefinite variable.
        barsj: array of double. Value of the j'th variable of barx.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if barsj is None: raise TypeError("Invalid type for argument barsj")
      if barsj is None:
        barsj_ = None
      else:
        try:
          barsj_ = memoryview(barsj)
        except TypeError:
          try:
            _tmparr_barsj = array.array("d",barsj)
          except TypeError:
            raise TypeError("Argument barsj has wrong type")
          else:
            barsj_ = memoryview(_tmparr_barsj)
      
        else:
          if barsj_.format != "d":
            barsj_ = memoryview(array.array("d",barsj))
      
      if barsj_ is not None and len(barsj_) != self.getlenbarvarj((j_)):
        raise ValueError("Array argument barsj has wrong length")
      res = self.__obj.putbarsj(whichsol_,j_,barsj_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getpviolcon(self,whichsol_,sub,viol): # 3
      """
      Computes the violation of a primal solution associated to a constraint.
    
      getpviolcon(self,whichsol_,sub,viol)
        whichsol: mosek.soltype. Selects a solution.
        sub: array of int. An array of indexes of constraints.
        viol: array of double. List of violations corresponding to sub.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if viol is None: raise TypeError("Invalid type for argument viol")
      _copyback_viol = False
      if viol is None:
        viol_ = None
      else:
        try:
          viol_ = memoryview(viol)
        except TypeError:
          try:
            _tmparr_viol = array.array("d",viol)
          except TypeError:
            raise TypeError("Argument viol has wrong type")
          else:
            viol_ = memoryview(_tmparr_viol)
            _copyback_viol = True
        else:
          if viol_.format != "d":
            viol_ = memoryview(array.array("d",viol))
            _copyback_viol = True
      if viol_ is not None and len(viol_) != (num_):
        raise ValueError("Array argument viol has wrong length")
      res = self.__obj.getpviolcon(whichsol_,num_,sub_,viol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_viol:
        viol[:] = _tmparr_viol
    
    def getpviolvar(self,whichsol_,sub,viol): # 3
      """
      Computes the violation of a primal solution for a list of scalar variables.
    
      getpviolvar(self,whichsol_,sub,viol)
        whichsol: mosek.soltype. Selects a solution.
        sub: array of int. An array of indexes of x variables.
        viol: array of double. List of violations corresponding to sub.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if viol is None: raise TypeError("Invalid type for argument viol")
      _copyback_viol = False
      if viol is None:
        viol_ = None
      else:
        try:
          viol_ = memoryview(viol)
        except TypeError:
          try:
            _tmparr_viol = array.array("d",viol)
          except TypeError:
            raise TypeError("Argument viol has wrong type")
          else:
            viol_ = memoryview(_tmparr_viol)
            _copyback_viol = True
        else:
          if viol_.format != "d":
            viol_ = memoryview(array.array("d",viol))
            _copyback_viol = True
      if viol_ is not None and len(viol_) != (num_):
        raise ValueError("Array argument viol has wrong length")
      res = self.__obj.getpviolvar(whichsol_,num_,sub_,viol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_viol:
        viol[:] = _tmparr_viol
    
    def getpviolbarvar(self,whichsol_,sub,viol): # 3
      """
      Computes the violation of a primal solution for a list of semidefinite variables.
    
      getpviolbarvar(self,whichsol_,sub,viol)
        whichsol: mosek.soltype. Selects a solution.
        sub: array of int. An array of indexes of barX variables.
        viol: array of double. List of violations corresponding to sub.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if viol is None: raise TypeError("Invalid type for argument viol")
      _copyback_viol = False
      if viol is None:
        viol_ = None
      else:
        try:
          viol_ = memoryview(viol)
        except TypeError:
          try:
            _tmparr_viol = array.array("d",viol)
          except TypeError:
            raise TypeError("Argument viol has wrong type")
          else:
            viol_ = memoryview(_tmparr_viol)
            _copyback_viol = True
        else:
          if viol_.format != "d":
            viol_ = memoryview(array.array("d",viol))
            _copyback_viol = True
      if viol_ is not None and len(viol_) != (num_):
        raise ValueError("Array argument viol has wrong length")
      res = self.__obj.getpviolbarvar(whichsol_,num_,sub_,viol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_viol:
        viol[:] = _tmparr_viol
    
    def getpviolcones(self,whichsol_,sub,viol): # 3
      """
      Computes the violation of a solution for set of conic constraints.
    
      getpviolcones(self,whichsol_,sub,viol)
        whichsol: mosek.soltype. Selects a solution.
        sub: array of int. An array of indexes of conic constraints.
        viol: array of double. List of violations corresponding to sub.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if viol is None: raise TypeError("Invalid type for argument viol")
      _copyback_viol = False
      if viol is None:
        viol_ = None
      else:
        try:
          viol_ = memoryview(viol)
        except TypeError:
          try:
            _tmparr_viol = array.array("d",viol)
          except TypeError:
            raise TypeError("Argument viol has wrong type")
          else:
            viol_ = memoryview(_tmparr_viol)
            _copyback_viol = True
        else:
          if viol_.format != "d":
            viol_ = memoryview(array.array("d",viol))
            _copyback_viol = True
      if viol_ is not None and len(viol_) != (num_):
        raise ValueError("Array argument viol has wrong length")
      res = self.__obj.getpviolcones(whichsol_,num_,sub_,viol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_viol:
        viol[:] = _tmparr_viol
    
    def getdviolcon(self,whichsol_,sub,viol): # 3
      """
      Computes the violation of a dual solution associated with a set of constraints.
    
      getdviolcon(self,whichsol_,sub,viol)
        whichsol: mosek.soltype. Selects a solution.
        sub: array of int. An array of indexes of constraints.
        viol: array of double. List of violations corresponding to sub.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if viol is None: raise TypeError("Invalid type for argument viol")
      _copyback_viol = False
      if viol is None:
        viol_ = None
      else:
        try:
          viol_ = memoryview(viol)
        except TypeError:
          try:
            _tmparr_viol = array.array("d",viol)
          except TypeError:
            raise TypeError("Argument viol has wrong type")
          else:
            viol_ = memoryview(_tmparr_viol)
            _copyback_viol = True
        else:
          if viol_.format != "d":
            viol_ = memoryview(array.array("d",viol))
            _copyback_viol = True
      if viol_ is not None and len(viol_) != (num_):
        raise ValueError("Array argument viol has wrong length")
      res = self.__obj.getdviolcon(whichsol_,num_,sub_,viol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_viol:
        viol[:] = _tmparr_viol
    
    def getdviolvar(self,whichsol_,sub,viol): # 3
      """
      Computes the violation of a dual solution associated with a set of scalar variables.
    
      getdviolvar(self,whichsol_,sub,viol)
        whichsol: mosek.soltype. Selects a solution.
        sub: array of int. An array of indexes of x variables.
        viol: array of double. List of violations corresponding to sub.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if viol is None: raise TypeError("Invalid type for argument viol")
      _copyback_viol = False
      if viol is None:
        viol_ = None
      else:
        try:
          viol_ = memoryview(viol)
        except TypeError:
          try:
            _tmparr_viol = array.array("d",viol)
          except TypeError:
            raise TypeError("Argument viol has wrong type")
          else:
            viol_ = memoryview(_tmparr_viol)
            _copyback_viol = True
        else:
          if viol_.format != "d":
            viol_ = memoryview(array.array("d",viol))
            _copyback_viol = True
      if viol_ is not None and len(viol_) != (num_):
        raise ValueError("Array argument viol has wrong length")
      res = self.__obj.getdviolvar(whichsol_,num_,sub_,viol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_viol:
        viol[:] = _tmparr_viol
    
    def getdviolbarvar(self,whichsol_,sub,viol): # 3
      """
      Computes the violation of dual solution for a set of semidefinite variables.
    
      getdviolbarvar(self,whichsol_,sub,viol)
        whichsol: mosek.soltype. Selects a solution.
        sub: array of int. An array of indexes of barx variables.
        viol: array of double. List of violations corresponding to sub.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if viol is None: raise TypeError("Invalid type for argument viol")
      _copyback_viol = False
      if viol is None:
        viol_ = None
      else:
        try:
          viol_ = memoryview(viol)
        except TypeError:
          try:
            _tmparr_viol = array.array("d",viol)
          except TypeError:
            raise TypeError("Argument viol has wrong type")
          else:
            viol_ = memoryview(_tmparr_viol)
            _copyback_viol = True
        else:
          if viol_.format != "d":
            viol_ = memoryview(array.array("d",viol))
            _copyback_viol = True
      if viol_ is not None and len(viol_) != (num_):
        raise ValueError("Array argument viol has wrong length")
      res = self.__obj.getdviolbarvar(whichsol_,num_,sub_,viol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_viol:
        viol[:] = _tmparr_viol
    
    def getdviolcones(self,whichsol_,sub,viol): # 3
      """
      Computes the violation of a solution for set of dual conic constraints.
    
      getdviolcones(self,whichsol_,sub,viol)
        whichsol: mosek.soltype. Selects a solution.
        sub: array of int. An array of indexes of conic constraints.
        viol: array of double. List of violations corresponding to sub.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if viol is None: raise TypeError("Invalid type for argument viol")
      _copyback_viol = False
      if viol is None:
        viol_ = None
      else:
        try:
          viol_ = memoryview(viol)
        except TypeError:
          try:
            _tmparr_viol = array.array("d",viol)
          except TypeError:
            raise TypeError("Argument viol has wrong type")
          else:
            viol_ = memoryview(_tmparr_viol)
            _copyback_viol = True
        else:
          if viol_.format != "d":
            viol_ = memoryview(array.array("d",viol))
            _copyback_viol = True
      if viol_ is not None and len(viol_) != (num_):
        raise ValueError("Array argument viol has wrong length")
      res = self.__obj.getdviolcones(whichsol_,num_,sub_,viol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_viol:
        viol[:] = _tmparr_viol
    
    def getsolutioninfo(self,whichsol_): # 3
      """
      Obtains information about of a solution.
    
      getsolutioninfo(self,whichsol_)
        whichsol: mosek.soltype. Selects a solution.
      returns: pobj,pviolcon,pviolvar,pviolbarvar,pviolcone,pviolitg,dobj,dviolcon,dviolvar,dviolbarvar,dviolcone
        pobj: double. The primal objective value.
        pviolcon: double. Maximal primal bound violation for a xc variable.
        pviolvar: double. Maximal primal bound violation for a xx variable.
        pviolbarvar: double. Maximal primal bound violation for a barx variable.
        pviolcone: double. Maximal primal violation of the solution with respect to the conic constraints.
        pviolitg: double. Maximal violation in the integer constraints.
        dobj: double. Dual objective value.
        dviolcon: double. Maximal dual bound violation for a xc variable.
        dviolvar: double. Maximal dual bound violation for a xx variable.
        dviolbarvar: double. Maximal dual bound violation for a bars variable.
        dviolcone: double. Maximum violation of the dual solution in the dual conic constraints.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res,resargs = self.__obj.getsolutioninfo(whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _pobj_return_value,_pviolcon_return_value,_pviolvar_return_value,_pviolbarvar_return_value,_pviolcone_return_value,_pviolitg_return_value,_dobj_return_value,_dviolcon_return_value,_dviolvar_return_value,_dviolbarvar_return_value,_dviolcone_return_value = resargs
      return _pobj_return_value,_pviolcon_return_value,_pviolvar_return_value,_pviolbarvar_return_value,_pviolcone_return_value,_pviolitg_return_value,_dobj_return_value,_dviolcon_return_value,_dviolvar_return_value,_dviolbarvar_return_value,_dviolcone_return_value
    
    def getdualsolutionnorms(self,whichsol_): # 3
      """
      Compute norms of the dual solution.
    
      getdualsolutionnorms(self,whichsol_)
        whichsol: mosek.soltype. Selects a solution.
      returns: nrmy,nrmslc,nrmsuc,nrmslx,nrmsux,nrmsnx,nrmbars
        nrmy: double. The norm of the y vector.
        nrmslc: double. The norm of the slc vector.
        nrmsuc: double. The norm of the suc vector.
        nrmslx: double. The norm of the slx vector.
        nrmsux: double. The norm of the sux vector.
        nrmsnx: double. The norm of the snx vector.
        nrmbars: double. The norm of the bars vector.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res,resargs = self.__obj.getdualsolutionnorms(whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _nrmy_return_value,_nrmslc_return_value,_nrmsuc_return_value,_nrmslx_return_value,_nrmsux_return_value,_nrmsnx_return_value,_nrmbars_return_value = resargs
      return _nrmy_return_value,_nrmslc_return_value,_nrmsuc_return_value,_nrmslx_return_value,_nrmsux_return_value,_nrmsnx_return_value,_nrmbars_return_value
    
    def getprimalsolutionnorms(self,whichsol_): # 3
      """
      Compute norms of the primal solution.
    
      getprimalsolutionnorms(self,whichsol_)
        whichsol: mosek.soltype. Selects a solution.
      returns: nrmxc,nrmxx,nrmbarx
        nrmxc: double. The norm of the xc vector.
        nrmxx: double. The norm of the xx vector.
        nrmbarx: double. The norm of the barX vector.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res,resargs = self.__obj.getprimalsolutionnorms(whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _nrmxc_return_value,_nrmxx_return_value,_nrmbarx_return_value = resargs
      return _nrmxc_return_value,_nrmxx_return_value,_nrmbarx_return_value
    
    def getsolutionslice(self,whichsol_,solitem_,first_,last_,values): # 3
      """
      Obtains a slice of the solution.
    
      getsolutionslice(self,whichsol_,solitem_,first_,last_,values)
        whichsol: mosek.soltype. Selects a solution.
        solitem: mosek.solitem. Which part of the solution is required.
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        values: array of double. The values of the requested solution elements.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if not isinstance(solitem_,solitem): raise TypeError("Argument solitem has wrong type")
      _copyback_values = False
      if values is None:
        values_ = None
      else:
        try:
          values_ = memoryview(values)
        except TypeError:
          try:
            _tmparr_values = array.array("d",values)
          except TypeError:
            raise TypeError("Argument values has wrong type")
          else:
            values_ = memoryview(_tmparr_values)
            _copyback_values = True
        else:
          if values_.format != "d":
            values_ = memoryview(array.array("d",values))
            _copyback_values = True
      if values_ is not None and len(values_) != ((last_) - (first_)):
        raise ValueError("Array argument values has wrong length")
      res = self.__obj.getsolutionslice(whichsol_,solitem_,first_,last_,values_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_values:
        values[:] = _tmparr_values
    
    def getreducedcosts(self,whichsol_,first_,last_,redcosts): # 3
      """
      Obtains the reduced costs for a sequence of variables.
    
      getreducedcosts(self,whichsol_,first_,last_,redcosts)
        whichsol: mosek.soltype. Selects a solution.
        first: int. The index of the first variable in the sequence.
        last: int. The index of the last variable in the sequence plus 1.
        redcosts: array of double. Returns the requested reduced costs.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      _copyback_redcosts = False
      if redcosts is None:
        redcosts_ = None
      else:
        try:
          redcosts_ = memoryview(redcosts)
        except TypeError:
          try:
            _tmparr_redcosts = array.array("d",redcosts)
          except TypeError:
            raise TypeError("Argument redcosts has wrong type")
          else:
            redcosts_ = memoryview(_tmparr_redcosts)
            _copyback_redcosts = True
        else:
          if redcosts_.format != "d":
            redcosts_ = memoryview(array.array("d",redcosts))
            _copyback_redcosts = True
      if redcosts_ is not None and len(redcosts_) != ((last_) - (first_)):
        raise ValueError("Array argument redcosts has wrong length")
      res = self.__obj.getreducedcosts(whichsol_,first_,last_,redcosts_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_redcosts:
        redcosts[:] = _tmparr_redcosts
    
    def getstrparam(self,param_): # 3
      """
      Obtains the value of a string parameter.
    
      getstrparam(self,param_)
        param: mosek.sparam. Which parameter.
      returns: len,parvalue
        len: int. The length of the parameter value.
        parvalue: str. If this is not a null pointer, the parameter value is stored here.
      """
      if not isinstance(param_,sparam): raise TypeError("Argument param has wrong type")
      maxlen_ = (1 + self.getstrparamlen((param_)))
      arr_parvalue = array.array("b",[0]*((maxlen_)))
      memview_arr_parvalue = memoryview(arr_parvalue)
      res,resargs = self.__obj.getstrparam(param_,maxlen_,memview_arr_parvalue)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _len_return_value,retarg_parvalue = resargs
      retarg_parvalue = arr_parvalue.tobytes()[:-1].decode("utf-8",errors="ignore")
      return _len_return_value,retarg_parvalue
    
    def getstrparamlen(self,param_): # 3
      """
      Obtains the length of a string parameter.
    
      getstrparamlen(self,param_)
        param: mosek.sparam. Which parameter.
      returns: len
        len: int. The length of the parameter value.
      """
      if not isinstance(param_,sparam): raise TypeError("Argument param has wrong type")
      res,resargs = self.__obj.getstrparamlen(param_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _len_return_value = resargs
      return _len_return_value
    
    def gettasknamelen(self): # 3
      """
      Obtains the length the task name.
    
      gettasknamelen(self)
      returns: len
        len: int. Returns the length of the task name.
      """
      res,resargs = self.__obj.gettasknamelen()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _len_return_value = resargs
      return _len_return_value
    
    def gettaskname(self): # 3
      """
      Obtains the task name.
    
      gettaskname(self)
      returns: taskname
        taskname: str. Returns the task name.
      """
      sizetaskname_ = (1 + self.gettasknamelen())
      arr_taskname = array.array("b",[0]*((sizetaskname_)))
      memview_arr_taskname = memoryview(arr_taskname)
      res,resargs = self.__obj.gettaskname(sizetaskname_,memview_arr_taskname)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      retarg_taskname = resargs
      retarg_taskname = arr_taskname.tobytes()[:-1].decode("utf-8",errors="ignore")
      return retarg_taskname
    
    def getvartype(self,j_): # 3
      """
      Gets the variable type of one variable.
    
      getvartype(self,j_)
        j: int. Index of the variable.
      returns: vartype
        vartype: mosek.variabletype. Variable type of variable index j.
      """
      res,resargs = self.__obj.getvartype(j_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _vartype_return_value = resargs
      _vartype_return_value = variabletype(_vartype_return_value)
      return _vartype_return_value
    
    def getvartypelist(self,subj,vartype): # 3
      """
      Obtains the variable type for one or more variables.
    
      getvartypelist(self,subj,vartype)
        subj: array of int. A list of variable indexes.
        vartype: array of mosek.variabletype. Returns the variables types corresponding the variable indexes requested.
      """
      num_ = None
      if num_ is None:
        num_ = len(subj)
      elif num_ != len(subj):
        raise IndexError("Inconsistent length of array subj")
      if num_ is None: num_ = 0
      if subj is None: raise TypeError("Invalid type for argument subj")
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
      
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
      
      _copyback_vartype = False
      if vartype is None:
        vartype_ = None
      else:
        try:
          vartype_ = memoryview(vartype)
        except TypeError:
          try:
            _tmparr_vartype = array.array("i",vartype)
          except TypeError:
            raise TypeError("Argument vartype has wrong type")
          else:
            vartype_ = memoryview(_tmparr_vartype)
            _copyback_vartype = True
        else:
          if vartype_.format != "i":
            vartype_ = memoryview(array.array("i",vartype))
            _copyback_vartype = True
      if vartype_ is not None and len(vartype_) != (num_):
        raise ValueError("Array argument vartype has wrong length")
      res = self.__obj.getvartypelist(num_,subj_,vartype_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_vartype:
        for __tmp_var_0 in range(len(vartype_)): vartype[__tmp_var_0] = variabletype(_tmparr_vartype[__tmp_var_0])
    
    def inputdata(self,maxnumcon_,maxnumvar_,c,cfix_,aptrb,aptre,asub,aval,bkc,blc,buc,bkx,blx,bux): # 3
      """
      Input the linear part of an optimization task in one function call.
    
      inputdata(self,maxnumcon_,maxnumvar_,c,cfix_,aptrb,aptre,asub,aval,bkc,blc,buc,bkx,blx,bux)
        maxnumcon: int. Number of preallocated constraints in the optimization task.
        maxnumvar: int. Number of preallocated variables in the optimization task.
        c: array of double. Linear terms of the objective as a dense vector. The length is the number of variables.
        cfix: double. Fixed term in the objective.
        aptrb: array of long. Row or column start pointers.
        aptre: array of long. Row or column end pointers.
        asub: array of int. Coefficient subscripts.
        aval: array of double. Coefficient values.
        bkc: array of mosek.boundkey. Bound keys for the constraints.
        blc: array of double. Lower bounds for the constraints.
        buc: array of double. Upper bounds for the constraints.
        bkx: array of mosek.boundkey. Bound keys for the variables.
        blx: array of double. Lower bounds for the variables.
        bux: array of double. Upper bounds for the variables.
      """
      numcon_ = None
      if numcon_ is None:
        numcon_ = len(buc)
      elif numcon_ != len(buc):
        raise IndexError("Inconsistent length of array buc")
      if numcon_ is None:
        numcon_ = len(blc)
      elif numcon_ != len(blc):
        raise IndexError("Inconsistent length of array blc")
      if numcon_ is None:
        numcon_ = len(bkc)
      elif numcon_ != len(bkc):
        raise IndexError("Inconsistent length of array bkc")
      if numcon_ is None: numcon_ = 0
      numvar_ = None
      if numvar_ is None:
        numvar_ = len(c)
      elif numvar_ != len(c):
        raise IndexError("Inconsistent length of array c")
      if numvar_ is None:
        numvar_ = len(bux)
      elif numvar_ != len(bux):
        raise IndexError("Inconsistent length of array bux")
      if numvar_ is None:
        numvar_ = len(blx)
      elif numvar_ != len(blx):
        raise IndexError("Inconsistent length of array blx")
      if numvar_ is None:
        numvar_ = len(bkx)
      elif numvar_ != len(bkx):
        raise IndexError("Inconsistent length of array bkx")
      if numvar_ is None:
        numvar_ = len(aptrb)
      elif numvar_ != len(aptrb):
        raise IndexError("Inconsistent length of array aptrb")
      if numvar_ is None:
        numvar_ = len(aptre)
      elif numvar_ != len(aptre):
        raise IndexError("Inconsistent length of array aptre")
      if numvar_ is None: numvar_ = 0
      if c is None:
        c_ = None
      else:
        try:
          c_ = memoryview(c)
        except TypeError:
          try:
            _tmparr_c = array.array("d",c)
          except TypeError:
            raise TypeError("Argument c has wrong type")
          else:
            c_ = memoryview(_tmparr_c)
      
        else:
          if c_.format != "d":
            c_ = memoryview(array.array("d",c))
      
      if aptrb is None: raise TypeError("Invalid type for argument aptrb")
      if aptrb is None:
        aptrb_ = None
      else:
        try:
          aptrb_ = memoryview(aptrb)
        except TypeError:
          try:
            _tmparr_aptrb = array.array("q",aptrb)
          except TypeError:
            raise TypeError("Argument aptrb has wrong type")
          else:
            aptrb_ = memoryview(_tmparr_aptrb)
      
        else:
          if aptrb_.format != "q":
            aptrb_ = memoryview(array.array("q",aptrb))
      
      if aptre is None: raise TypeError("Invalid type for argument aptre")
      if aptre is None:
        aptre_ = None
      else:
        try:
          aptre_ = memoryview(aptre)
        except TypeError:
          try:
            _tmparr_aptre = array.array("q",aptre)
          except TypeError:
            raise TypeError("Argument aptre has wrong type")
          else:
            aptre_ = memoryview(_tmparr_aptre)
      
        else:
          if aptre_.format != "q":
            aptre_ = memoryview(array.array("q",aptre))
      
      if asub is None: raise TypeError("Invalid type for argument asub")
      if asub is None:
        asub_ = None
      else:
        try:
          asub_ = memoryview(asub)
        except TypeError:
          try:
            _tmparr_asub = array.array("i",asub)
          except TypeError:
            raise TypeError("Argument asub has wrong type")
          else:
            asub_ = memoryview(_tmparr_asub)
      
        else:
          if asub_.format != "i":
            asub_ = memoryview(array.array("i",asub))
      
      if aval is None: raise TypeError("Invalid type for argument aval")
      if aval is None:
        aval_ = None
      else:
        try:
          aval_ = memoryview(aval)
        except TypeError:
          try:
            _tmparr_aval = array.array("d",aval)
          except TypeError:
            raise TypeError("Argument aval has wrong type")
          else:
            aval_ = memoryview(_tmparr_aval)
      
        else:
          if aval_.format != "d":
            aval_ = memoryview(array.array("d",aval))
      
      if bkc is None: raise TypeError("Invalid type for argument bkc")
      if bkc is None:
        bkc_ = None
      else:
        try:
          bkc_ = memoryview(bkc)
        except TypeError:
          try:
            _tmparr_bkc = array.array("i",bkc)
          except TypeError:
            raise TypeError("Argument bkc has wrong type")
          else:
            bkc_ = memoryview(_tmparr_bkc)
      
        else:
          if bkc_.format != "i":
            bkc_ = memoryview(array.array("i",bkc))
      
      if blc is None: raise TypeError("Invalid type for argument blc")
      if blc is None:
        blc_ = None
      else:
        try:
          blc_ = memoryview(blc)
        except TypeError:
          try:
            _tmparr_blc = array.array("d",blc)
          except TypeError:
            raise TypeError("Argument blc has wrong type")
          else:
            blc_ = memoryview(_tmparr_blc)
      
        else:
          if blc_.format != "d":
            blc_ = memoryview(array.array("d",blc))
      
      if buc is None: raise TypeError("Invalid type for argument buc")
      if buc is None:
        buc_ = None
      else:
        try:
          buc_ = memoryview(buc)
        except TypeError:
          try:
            _tmparr_buc = array.array("d",buc)
          except TypeError:
            raise TypeError("Argument buc has wrong type")
          else:
            buc_ = memoryview(_tmparr_buc)
      
        else:
          if buc_.format != "d":
            buc_ = memoryview(array.array("d",buc))
      
      if bkx is None: raise TypeError("Invalid type for argument bkx")
      if bkx is None:
        bkx_ = None
      else:
        try:
          bkx_ = memoryview(bkx)
        except TypeError:
          try:
            _tmparr_bkx = array.array("i",bkx)
          except TypeError:
            raise TypeError("Argument bkx has wrong type")
          else:
            bkx_ = memoryview(_tmparr_bkx)
      
        else:
          if bkx_.format != "i":
            bkx_ = memoryview(array.array("i",bkx))
      
      if blx is None: raise TypeError("Invalid type for argument blx")
      if blx is None:
        blx_ = None
      else:
        try:
          blx_ = memoryview(blx)
        except TypeError:
          try:
            _tmparr_blx = array.array("d",blx)
          except TypeError:
            raise TypeError("Argument blx has wrong type")
          else:
            blx_ = memoryview(_tmparr_blx)
      
        else:
          if blx_.format != "d":
            blx_ = memoryview(array.array("d",blx))
      
      if bux is None: raise TypeError("Invalid type for argument bux")
      if bux is None:
        bux_ = None
      else:
        try:
          bux_ = memoryview(bux)
        except TypeError:
          try:
            _tmparr_bux = array.array("d",bux)
          except TypeError:
            raise TypeError("Argument bux has wrong type")
          else:
            bux_ = memoryview(_tmparr_bux)
      
        else:
          if bux_.format != "d":
            bux_ = memoryview(array.array("d",bux))
      
      res = self.__obj.inputdata64(maxnumcon_,maxnumvar_,numcon_,numvar_,c_,cfix_,aptrb_,aptre_,asub_,aval_,bkc_,blc_,buc_,bkx_,blx_,bux_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def isdouparname(self,parname_): # 3
      """
      Checks a double parameter name.
    
      isdouparname(self,parname_)
        parname: str. Parameter name.
      returns: param
        param: mosek.dparam. Returns the parameter corresponding to the name, if one exists.
      """
      res,resargs = self.__obj.isdouparname(parname_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _param_return_value = resargs
      _param_return_value = dparam(_param_return_value)
      return _param_return_value
    
    def isintparname(self,parname_): # 3
      """
      Checks an integer parameter name.
    
      isintparname(self,parname_)
        parname: str. Parameter name.
      returns: param
        param: mosek.iparam. Returns the parameter corresponding to the name, if one exists.
      """
      res,resargs = self.__obj.isintparname(parname_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _param_return_value = resargs
      _param_return_value = iparam(_param_return_value)
      return _param_return_value
    
    def isstrparname(self,parname_): # 3
      """
      Checks a string parameter name.
    
      isstrparname(self,parname_)
        parname: str. Parameter name.
      returns: param
        param: mosek.sparam. Returns the parameter corresponding to the name, if one exists.
      """
      res,resargs = self.__obj.isstrparname(parname_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _param_return_value = resargs
      _param_return_value = sparam(_param_return_value)
      return _param_return_value
    
    def linkfiletostream(self,whichstream_,filename_,append_): # 3
      """
      Directs all output from a task stream to a file.
    
      linkfiletostream(self,whichstream_,filename_,append_)
        whichstream: mosek.streamtype. Index of the stream.
        filename: str. A valid file name.
        append: int. If this argument is 0 the output file will be overwritten, otherwise it will be appended to.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      res = self.__obj.linkfiletotaskstream(whichstream_,filename_,append_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def primalrepair(self,wlc,wuc,wlx,wux): # 3
      """
      Repairs a primal infeasible optimization problem by adjusting the bounds on the constraints and variables.
    
      primalrepair(self,wlc,wuc,wlx,wux)
        wlc: array of double. Weights associated with relaxing lower bounds on the constraints.
        wuc: array of double. Weights associated with relaxing the upper bound on the constraints.
        wlx: array of double. Weights associated with relaxing the lower bounds of the variables.
        wux: array of double. Weights associated with relaxing the upper bounds of variables.
      """
      if wlc is None:
        wlc_ = None
      else:
        try:
          wlc_ = memoryview(wlc)
        except TypeError:
          try:
            _tmparr_wlc = array.array("d",wlc)
          except TypeError:
            raise TypeError("Argument wlc has wrong type")
          else:
            wlc_ = memoryview(_tmparr_wlc)
      
        else:
          if wlc_.format != "d":
            wlc_ = memoryview(array.array("d",wlc))
      
      if wlc_ is not None and len(wlc_) != self.getnumcon():
        raise ValueError("Array argument wlc has wrong length")
      if wuc is None:
        wuc_ = None
      else:
        try:
          wuc_ = memoryview(wuc)
        except TypeError:
          try:
            _tmparr_wuc = array.array("d",wuc)
          except TypeError:
            raise TypeError("Argument wuc has wrong type")
          else:
            wuc_ = memoryview(_tmparr_wuc)
      
        else:
          if wuc_.format != "d":
            wuc_ = memoryview(array.array("d",wuc))
      
      if wuc_ is not None and len(wuc_) != self.getnumcon():
        raise ValueError("Array argument wuc has wrong length")
      if wlx is None:
        wlx_ = None
      else:
        try:
          wlx_ = memoryview(wlx)
        except TypeError:
          try:
            _tmparr_wlx = array.array("d",wlx)
          except TypeError:
            raise TypeError("Argument wlx has wrong type")
          else:
            wlx_ = memoryview(_tmparr_wlx)
      
        else:
          if wlx_.format != "d":
            wlx_ = memoryview(array.array("d",wlx))
      
      if wlx_ is not None and len(wlx_) != self.getnumvar():
        raise ValueError("Array argument wlx has wrong length")
      if wux is None:
        wux_ = None
      else:
        try:
          wux_ = memoryview(wux)
        except TypeError:
          try:
            _tmparr_wux = array.array("d",wux)
          except TypeError:
            raise TypeError("Argument wux has wrong type")
          else:
            wux_ = memoryview(_tmparr_wux)
      
        else:
          if wux_.format != "d":
            wux_ = memoryview(array.array("d",wux))
      
      if wux_ is not None and len(wux_) != self.getnumvar():
        raise ValueError("Array argument wux has wrong length")
      res = self.__obj.primalrepair(wlc_,wuc_,wlx_,wux_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def toconic(self): # 3
      """
      In-place reformulation of a QCQP to a COP
    
      toconic(self)
      """
      res = self.__obj.toconic()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def optimize(self): # 3
      """
      Optimizes the problem.
    
      optimize(self)
      returns: trmcode
        trmcode: mosek.rescode. Is either OK or a termination response code.
      """
      res,resargs = self.__obj.optimizetrm()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _trmcode_return_value = resargs
      _trmcode_return_value = rescode(_trmcode_return_value)
      return _trmcode_return_value
    
    def printdata(self,whichstream_,firsti_,lasti_,firstj_,lastj_,firstk_,lastk_,c_,qo_,a_,qc_,bc_,bx_,vartype_,cones_): # 3
      """
      Prints a part of the problem data to a stream.
    
      printdata(self,whichstream_,firsti_,lasti_,firstj_,lastj_,firstk_,lastk_,c_,qo_,a_,qc_,bc_,bx_,vartype_,cones_)
        whichstream: mosek.streamtype. Index of the stream.
        firsti: int. Index of first constraint for which data should be printed.
        lasti: int. Index of last constraint plus 1 for which data should be printed.
        firstj: int. Index of first variable for which data should be printed.
        lastj: int. Index of last variable plus 1 for which data should be printed.
        firstk: int. Index of first cone for which data should be printed.
        lastk: int. Index of last cone plus 1 for which data should be printed.
        c: int. If non-zero the linear objective terms are printed.
        qo: int. If non-zero the quadratic objective terms are printed.
        a: int. If non-zero the linear constraint matrix is printed.
        qc: int. If non-zero q'th     quadratic constraint terms are printed for the relevant constraints.
        bc: int. If non-zero the constraint bounds are printed.
        bx: int. If non-zero the variable bounds are printed.
        vartype: int. If non-zero the variable types are printed.
        cones: int. If non-zero the  conic data is printed.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      res = self.__obj.printdata(whichstream_,firsti_,lasti_,firstj_,lastj_,firstk_,lastk_,c_,qo_,a_,qc_,bc_,bx_,vartype_,cones_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def commitchanges(self): # 3
      """
      Commits all cached problem changes.
    
      commitchanges(self)
      """
      res = self.__obj.commitchanges()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putaij(self,i_,j_,aij_): # 3
      """
      Changes a single value in the linear coefficient matrix.
    
      putaij(self,i_,j_,aij_)
        i: int. Constraint (row) index.
        j: int. Variable (column) index.
        aij: double. New coefficient.
      """
      res = self.__obj.putaij(i_,j_,aij_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putaijlist(self,subi,subj,valij): # 3
      """
      Changes one or more coefficients in the linear constraint matrix.
    
      putaijlist(self,subi,subj,valij)
        subi: array of int. Constraint (row) indices.
        subj: array of int. Variable (column) indices.
        valij: array of double. New coefficient values.
      """
      num_ = None
      if num_ is None:
        num_ = len(subi)
      elif num_ != len(subi):
        raise IndexError("Inconsistent length of array subi")
      if num_ is None:
        num_ = len(subj)
      elif num_ != len(subj):
        raise IndexError("Inconsistent length of array subj")
      if num_ is None:
        num_ = len(valij)
      elif num_ != len(valij):
        raise IndexError("Inconsistent length of array valij")
      if num_ is None: num_ = 0
      if subi is None: raise TypeError("Invalid type for argument subi")
      if subi is None:
        subi_ = None
      else:
        try:
          subi_ = memoryview(subi)
        except TypeError:
          try:
            _tmparr_subi = array.array("i",subi)
          except TypeError:
            raise TypeError("Argument subi has wrong type")
          else:
            subi_ = memoryview(_tmparr_subi)
      
        else:
          if subi_.format != "i":
            subi_ = memoryview(array.array("i",subi))
      
      if subj is None: raise TypeError("Invalid type for argument subj")
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
      
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
      
      if valij is None: raise TypeError("Invalid type for argument valij")
      if valij is None:
        valij_ = None
      else:
        try:
          valij_ = memoryview(valij)
        except TypeError:
          try:
            _tmparr_valij = array.array("d",valij)
          except TypeError:
            raise TypeError("Argument valij has wrong type")
          else:
            valij_ = memoryview(_tmparr_valij)
      
        else:
          if valij_.format != "d":
            valij_ = memoryview(array.array("d",valij))
      
      res = self.__obj.putaijlist64(num_,subi_,subj_,valij_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putacol(self,j_,subj,valj): # 3
      """
      Replaces all elements in one column of the linear constraint matrix.
    
      putacol(self,j_,subj,valj)
        j: int. Column index.
        subj: array of int. Row indexes of non-zero values in column.
        valj: array of double. New non-zero values of column.
      """
      nzj_ = None
      if nzj_ is None:
        nzj_ = len(subj)
      elif nzj_ != len(subj):
        raise IndexError("Inconsistent length of array subj")
      if nzj_ is None:
        nzj_ = len(valj)
      elif nzj_ != len(valj):
        raise IndexError("Inconsistent length of array valj")
      if nzj_ is None: nzj_ = 0
      if subj is None: raise TypeError("Invalid type for argument subj")
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
      
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
      
      if valj is None: raise TypeError("Invalid type for argument valj")
      if valj is None:
        valj_ = None
      else:
        try:
          valj_ = memoryview(valj)
        except TypeError:
          try:
            _tmparr_valj = array.array("d",valj)
          except TypeError:
            raise TypeError("Argument valj has wrong type")
          else:
            valj_ = memoryview(_tmparr_valj)
      
        else:
          if valj_.format != "d":
            valj_ = memoryview(array.array("d",valj))
      
      res = self.__obj.putacol(j_,nzj_,subj_,valj_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putarow(self,i_,subi,vali): # 3
      """
      Replaces all elements in one row of the linear constraint matrix.
    
      putarow(self,i_,subi,vali)
        i: int. Row index.
        subi: array of int. Column indexes of non-zero values in row.
        vali: array of double. New non-zero values of row.
      """
      nzi_ = None
      if nzi_ is None:
        nzi_ = len(subi)
      elif nzi_ != len(subi):
        raise IndexError("Inconsistent length of array subi")
      if nzi_ is None:
        nzi_ = len(vali)
      elif nzi_ != len(vali):
        raise IndexError("Inconsistent length of array vali")
      if nzi_ is None: nzi_ = 0
      if subi is None: raise TypeError("Invalid type for argument subi")
      if subi is None:
        subi_ = None
      else:
        try:
          subi_ = memoryview(subi)
        except TypeError:
          try:
            _tmparr_subi = array.array("i",subi)
          except TypeError:
            raise TypeError("Argument subi has wrong type")
          else:
            subi_ = memoryview(_tmparr_subi)
      
        else:
          if subi_.format != "i":
            subi_ = memoryview(array.array("i",subi))
      
      if vali is None: raise TypeError("Invalid type for argument vali")
      if vali is None:
        vali_ = None
      else:
        try:
          vali_ = memoryview(vali)
        except TypeError:
          try:
            _tmparr_vali = array.array("d",vali)
          except TypeError:
            raise TypeError("Argument vali has wrong type")
          else:
            vali_ = memoryview(_tmparr_vali)
      
        else:
          if vali_.format != "d":
            vali_ = memoryview(array.array("d",vali))
      
      res = self.__obj.putarow(i_,nzi_,subi_,vali_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putarowslice(self,first_,last_,ptrb,ptre,asub,aval): # 3
      """
      Replaces all elements in several rows the linear constraint matrix.
    
      putarowslice(self,first_,last_,ptrb,ptre,asub,aval)
        first: int. First row in the slice.
        last: int. Last row plus one in the slice.
        ptrb: array of long. Array of pointers to the first element in the rows.
        ptre: array of long. Array of pointers to the last element plus one in the rows.
        asub: array of int. Column indexes of new elements.
        aval: array of double. Coefficient values.
      """
      if ptrb is None: raise TypeError("Invalid type for argument ptrb")
      if ptrb is None:
        ptrb_ = None
      else:
        try:
          ptrb_ = memoryview(ptrb)
        except TypeError:
          try:
            _tmparr_ptrb = array.array("q",ptrb)
          except TypeError:
            raise TypeError("Argument ptrb has wrong type")
          else:
            ptrb_ = memoryview(_tmparr_ptrb)
      
        else:
          if ptrb_.format != "q":
            ptrb_ = memoryview(array.array("q",ptrb))
      
      if ptrb_ is not None and len(ptrb_) != ((last_) - (first_)):
        raise ValueError("Array argument ptrb has wrong length")
      if ptre is None: raise TypeError("Invalid type for argument ptre")
      if ptre is None:
        ptre_ = None
      else:
        try:
          ptre_ = memoryview(ptre)
        except TypeError:
          try:
            _tmparr_ptre = array.array("q",ptre)
          except TypeError:
            raise TypeError("Argument ptre has wrong type")
          else:
            ptre_ = memoryview(_tmparr_ptre)
      
        else:
          if ptre_.format != "q":
            ptre_ = memoryview(array.array("q",ptre))
      
      if ptre_ is not None and len(ptre_) != ((last_) - (first_)):
        raise ValueError("Array argument ptre has wrong length")
      if asub is None: raise TypeError("Invalid type for argument asub")
      if asub is None:
        asub_ = None
      else:
        try:
          asub_ = memoryview(asub)
        except TypeError:
          try:
            _tmparr_asub = array.array("i",asub)
          except TypeError:
            raise TypeError("Argument asub has wrong type")
          else:
            asub_ = memoryview(_tmparr_asub)
      
        else:
          if asub_.format != "i":
            asub_ = memoryview(array.array("i",asub))
      
      if aval is None: raise TypeError("Invalid type for argument aval")
      if aval is None:
        aval_ = None
      else:
        try:
          aval_ = memoryview(aval)
        except TypeError:
          try:
            _tmparr_aval = array.array("d",aval)
          except TypeError:
            raise TypeError("Argument aval has wrong type")
          else:
            aval_ = memoryview(_tmparr_aval)
      
        else:
          if aval_.format != "d":
            aval_ = memoryview(array.array("d",aval))
      
      res = self.__obj.putarowslice64(first_,last_,ptrb_,ptre_,asub_,aval_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putarowlist(self,sub,ptrb,ptre,asub,aval): # 3
      """
      Replaces all elements in several rows of the linear constraint matrix.
    
      putarowlist(self,sub,ptrb,ptre,asub,aval)
        sub: array of int. Indexes of rows or columns that should be replaced.
        ptrb: array of long. Array of pointers to the first element in the rows.
        ptre: array of long. Array of pointers to the last element plus one in the rows.
        asub: array of int. Variable indexes.
        aval: array of double. Coefficient values.
      """
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None:
        num_ = len(ptrb)
      elif num_ != len(ptrb):
        raise IndexError("Inconsistent length of array ptrb")
      if num_ is None:
        num_ = len(ptre)
      elif num_ != len(ptre):
        raise IndexError("Inconsistent length of array ptre")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if ptrb is None: raise TypeError("Invalid type for argument ptrb")
      if ptrb is None:
        ptrb_ = None
      else:
        try:
          ptrb_ = memoryview(ptrb)
        except TypeError:
          try:
            _tmparr_ptrb = array.array("q",ptrb)
          except TypeError:
            raise TypeError("Argument ptrb has wrong type")
          else:
            ptrb_ = memoryview(_tmparr_ptrb)
      
        else:
          if ptrb_.format != "q":
            ptrb_ = memoryview(array.array("q",ptrb))
      
      if ptre is None: raise TypeError("Invalid type for argument ptre")
      if ptre is None:
        ptre_ = None
      else:
        try:
          ptre_ = memoryview(ptre)
        except TypeError:
          try:
            _tmparr_ptre = array.array("q",ptre)
          except TypeError:
            raise TypeError("Argument ptre has wrong type")
          else:
            ptre_ = memoryview(_tmparr_ptre)
      
        else:
          if ptre_.format != "q":
            ptre_ = memoryview(array.array("q",ptre))
      
      if asub is None: raise TypeError("Invalid type for argument asub")
      if asub is None:
        asub_ = None
      else:
        try:
          asub_ = memoryview(asub)
        except TypeError:
          try:
            _tmparr_asub = array.array("i",asub)
          except TypeError:
            raise TypeError("Argument asub has wrong type")
          else:
            asub_ = memoryview(_tmparr_asub)
      
        else:
          if asub_.format != "i":
            asub_ = memoryview(array.array("i",asub))
      
      if aval is None: raise TypeError("Invalid type for argument aval")
      if aval is None:
        aval_ = None
      else:
        try:
          aval_ = memoryview(aval)
        except TypeError:
          try:
            _tmparr_aval = array.array("d",aval)
          except TypeError:
            raise TypeError("Argument aval has wrong type")
          else:
            aval_ = memoryview(_tmparr_aval)
      
        else:
          if aval_.format != "d":
            aval_ = memoryview(array.array("d",aval))
      
      res = self.__obj.putarowlist64(num_,sub_,ptrb_,ptre_,asub_,aval_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putacolslice(self,first_,last_,ptrb,ptre,asub,aval): # 3
      """
      Replaces all elements in a sequence of columns the linear constraint matrix.
    
      putacolslice(self,first_,last_,ptrb,ptre,asub,aval)
        first: int. First column in the slice.
        last: int. Last column plus one in the slice.
        ptrb: array of long. Array of pointers to the first element in the columns.
        ptre: array of long. Array of pointers to the last element plus one in the columns.
        asub: array of int. Row indexes
        aval: array of double. Coefficient values.
      """
      if ptrb is None: raise TypeError("Invalid type for argument ptrb")
      if ptrb is None:
        ptrb_ = None
      else:
        try:
          ptrb_ = memoryview(ptrb)
        except TypeError:
          try:
            _tmparr_ptrb = array.array("q",ptrb)
          except TypeError:
            raise TypeError("Argument ptrb has wrong type")
          else:
            ptrb_ = memoryview(_tmparr_ptrb)
      
        else:
          if ptrb_.format != "q":
            ptrb_ = memoryview(array.array("q",ptrb))
      
      if ptre is None: raise TypeError("Invalid type for argument ptre")
      if ptre is None:
        ptre_ = None
      else:
        try:
          ptre_ = memoryview(ptre)
        except TypeError:
          try:
            _tmparr_ptre = array.array("q",ptre)
          except TypeError:
            raise TypeError("Argument ptre has wrong type")
          else:
            ptre_ = memoryview(_tmparr_ptre)
      
        else:
          if ptre_.format != "q":
            ptre_ = memoryview(array.array("q",ptre))
      
      if asub is None: raise TypeError("Invalid type for argument asub")
      if asub is None:
        asub_ = None
      else:
        try:
          asub_ = memoryview(asub)
        except TypeError:
          try:
            _tmparr_asub = array.array("i",asub)
          except TypeError:
            raise TypeError("Argument asub has wrong type")
          else:
            asub_ = memoryview(_tmparr_asub)
      
        else:
          if asub_.format != "i":
            asub_ = memoryview(array.array("i",asub))
      
      if aval is None: raise TypeError("Invalid type for argument aval")
      if aval is None:
        aval_ = None
      else:
        try:
          aval_ = memoryview(aval)
        except TypeError:
          try:
            _tmparr_aval = array.array("d",aval)
          except TypeError:
            raise TypeError("Argument aval has wrong type")
          else:
            aval_ = memoryview(_tmparr_aval)
      
        else:
          if aval_.format != "d":
            aval_ = memoryview(array.array("d",aval))
      
      res = self.__obj.putacolslice64(first_,last_,ptrb_,ptre_,asub_,aval_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putacollist(self,sub,ptrb,ptre,asub,aval): # 3
      """
      Replaces all elements in several columns the linear constraint matrix.
    
      putacollist(self,sub,ptrb,ptre,asub,aval)
        sub: array of int. Indexes of columns that should be replaced.
        ptrb: array of long. Array of pointers to the first element in the columns.
        ptre: array of long. Array of pointers to the last element plus one in the columns.
        asub: array of int. Row indexes
        aval: array of double. Coefficient values.
      """
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None:
        num_ = len(ptrb)
      elif num_ != len(ptrb):
        raise IndexError("Inconsistent length of array ptrb")
      if num_ is None:
        num_ = len(ptre)
      elif num_ != len(ptre):
        raise IndexError("Inconsistent length of array ptre")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if ptrb is None: raise TypeError("Invalid type for argument ptrb")
      if ptrb is None:
        ptrb_ = None
      else:
        try:
          ptrb_ = memoryview(ptrb)
        except TypeError:
          try:
            _tmparr_ptrb = array.array("q",ptrb)
          except TypeError:
            raise TypeError("Argument ptrb has wrong type")
          else:
            ptrb_ = memoryview(_tmparr_ptrb)
      
        else:
          if ptrb_.format != "q":
            ptrb_ = memoryview(array.array("q",ptrb))
      
      if ptre is None: raise TypeError("Invalid type for argument ptre")
      if ptre is None:
        ptre_ = None
      else:
        try:
          ptre_ = memoryview(ptre)
        except TypeError:
          try:
            _tmparr_ptre = array.array("q",ptre)
          except TypeError:
            raise TypeError("Argument ptre has wrong type")
          else:
            ptre_ = memoryview(_tmparr_ptre)
      
        else:
          if ptre_.format != "q":
            ptre_ = memoryview(array.array("q",ptre))
      
      if asub is None: raise TypeError("Invalid type for argument asub")
      if asub is None:
        asub_ = None
      else:
        try:
          asub_ = memoryview(asub)
        except TypeError:
          try:
            _tmparr_asub = array.array("i",asub)
          except TypeError:
            raise TypeError("Argument asub has wrong type")
          else:
            asub_ = memoryview(_tmparr_asub)
      
        else:
          if asub_.format != "i":
            asub_ = memoryview(array.array("i",asub))
      
      if aval is None: raise TypeError("Invalid type for argument aval")
      if aval is None:
        aval_ = None
      else:
        try:
          aval_ = memoryview(aval)
        except TypeError:
          try:
            _tmparr_aval = array.array("d",aval)
          except TypeError:
            raise TypeError("Argument aval has wrong type")
          else:
            aval_ = memoryview(_tmparr_aval)
      
        else:
          if aval_.format != "d":
            aval_ = memoryview(array.array("d",aval))
      
      res = self.__obj.putacollist64(num_,sub_,ptrb_,ptre_,asub_,aval_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putbaraij(self,i_,j_,sub,weights): # 3
      """
      Inputs an element of barA.
    
      putbaraij(self,i_,j_,sub,weights)
        i: int. Row index of barA.
        j: int. Column index of barA.
        sub: array of long. Element indexes in matrix storage.
        weights: array of double. Weights in the weighted sum.
      """
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None:
        num_ = len(weights)
      elif num_ != len(weights):
        raise IndexError("Inconsistent length of array weights")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("q",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "q":
            sub_ = memoryview(array.array("q",sub))
      
      if weights is None: raise TypeError("Invalid type for argument weights")
      if weights is None:
        weights_ = None
      else:
        try:
          weights_ = memoryview(weights)
        except TypeError:
          try:
            _tmparr_weights = array.array("d",weights)
          except TypeError:
            raise TypeError("Argument weights has wrong type")
          else:
            weights_ = memoryview(_tmparr_weights)
      
        else:
          if weights_.format != "d":
            weights_ = memoryview(array.array("d",weights))
      
      res = self.__obj.putbaraij(i_,j_,num_,sub_,weights_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getnumbarcnz(self): # 3
      """
      Obtains the number of nonzero elements in barc.
    
      getnumbarcnz(self)
      returns: nz
        nz: long. The number of nonzero elements in barc.
      """
      res,resargs = self.__obj.getnumbarcnz()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _nz_return_value = resargs
      return _nz_return_value
    
    def getnumbaranz(self): # 3
      """
      Get the number of nonzero elements in barA.
    
      getnumbaranz(self)
      returns: nz
        nz: long. The number of nonzero block elements in barA.
      """
      res,resargs = self.__obj.getnumbaranz()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _nz_return_value = resargs
      return _nz_return_value
    
    def getbarcsparsity(self,idxj): # 3
      """
      Get the positions of the nonzero elements in barc.
    
      getbarcsparsity(self,idxj)
        idxj: array of long. Internal positions of the nonzeros elements in barc.
      returns: numnz
        numnz: long. Number of nonzero elements in barc.
      """
      maxnumnz_ = self.getnumbarcnz()
      if idxj is None: raise TypeError("Invalid type for argument idxj")
      _copyback_idxj = False
      if idxj is None:
        idxj_ = None
      else:
        try:
          idxj_ = memoryview(idxj)
        except TypeError:
          try:
            _tmparr_idxj = array.array("q",idxj)
          except TypeError:
            raise TypeError("Argument idxj has wrong type")
          else:
            idxj_ = memoryview(_tmparr_idxj)
            _copyback_idxj = True
        else:
          if idxj_.format != "q":
            idxj_ = memoryview(array.array("q",idxj))
            _copyback_idxj = True
      if idxj_ is not None and len(idxj_) != (maxnumnz_):
        raise ValueError("Array argument idxj has wrong length")
      res,resargs = self.__obj.getbarcsparsity(maxnumnz_,idxj_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numnz_return_value = resargs
      if _copyback_idxj:
        idxj[:] = _tmparr_idxj
      return _numnz_return_value
    
    def getbarasparsity(self,idxij): # 3
      """
      Obtains the sparsity pattern of the barA matrix.
    
      getbarasparsity(self,idxij)
        idxij: array of long. Position of each nonzero element in the vector representation of barA.
      returns: numnz
        numnz: long. Number of nonzero elements in barA.
      """
      maxnumnz_ = self.getnumbaranz()
      if idxij is None: raise TypeError("Invalid type for argument idxij")
      _copyback_idxij = False
      if idxij is None:
        idxij_ = None
      else:
        try:
          idxij_ = memoryview(idxij)
        except TypeError:
          try:
            _tmparr_idxij = array.array("q",idxij)
          except TypeError:
            raise TypeError("Argument idxij has wrong type")
          else:
            idxij_ = memoryview(_tmparr_idxij)
            _copyback_idxij = True
        else:
          if idxij_.format != "q":
            idxij_ = memoryview(array.array("q",idxij))
            _copyback_idxij = True
      if idxij_ is not None and len(idxij_) != (maxnumnz_):
        raise ValueError("Array argument idxij has wrong length")
      res,resargs = self.__obj.getbarasparsity(maxnumnz_,idxij_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _numnz_return_value = resargs
      if _copyback_idxij:
        idxij[:] = _tmparr_idxij
      return _numnz_return_value
    
    def getbarcidxinfo(self,idx_): # 3
      """
      Obtains information about an element in barc.
    
      getbarcidxinfo(self,idx_)
        idx: long. Index of the element for which information should be obtained. The value is an index of a symmetric sparse variable.
      returns: num
        num: long. Number of terms that appear in the weighted sum that forms the requested element.
      """
      res,resargs = self.__obj.getbarcidxinfo(idx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _num_return_value = resargs
      return _num_return_value
    
    def getbarcidxj(self,idx_): # 3
      """
      Obtains the row index of an element in barc.
    
      getbarcidxj(self,idx_)
        idx: long. Index of the element for which information should be obtained.
      returns: j
        j: int. Row index in barc.
      """
      res,resargs = self.__obj.getbarcidxj(idx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _j_return_value = resargs
      return _j_return_value
    
    def getbarcidx(self,idx_,sub,weights): # 3
      """
      Obtains information about an element in barc.
    
      getbarcidx(self,idx_,sub,weights)
        idx: long. Index of the element for which information should be obtained.
        sub: array of long. Elements appearing the weighted sum.
        weights: array of double. Weights of terms in the weighted sum.
      returns: j,num
        j: int. Row index in barc.
        num: long. Number of terms in the weighted sum.
      """
      maxnum_ = self.getbarcidxinfo((idx_))
      if sub is None: raise TypeError("Invalid type for argument sub")
      _copyback_sub = False
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("q",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
            _copyback_sub = True
        else:
          if sub_.format != "q":
            sub_ = memoryview(array.array("q",sub))
            _copyback_sub = True
      if sub_ is not None and len(sub_) != (maxnum_):
        raise ValueError("Array argument sub has wrong length")
      if weights is None: raise TypeError("Invalid type for argument weights")
      _copyback_weights = False
      if weights is None:
        weights_ = None
      else:
        try:
          weights_ = memoryview(weights)
        except TypeError:
          try:
            _tmparr_weights = array.array("d",weights)
          except TypeError:
            raise TypeError("Argument weights has wrong type")
          else:
            weights_ = memoryview(_tmparr_weights)
            _copyback_weights = True
        else:
          if weights_.format != "d":
            weights_ = memoryview(array.array("d",weights))
            _copyback_weights = True
      if weights_ is not None and len(weights_) != (maxnum_):
        raise ValueError("Array argument weights has wrong length")
      res,resargs = self.__obj.getbarcidx(idx_,maxnum_,sub_,weights_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _j_return_value,_num_return_value = resargs
      if _copyback_weights:
        weights[:] = _tmparr_weights
      if _copyback_sub:
        sub[:] = _tmparr_sub
      return _j_return_value,_num_return_value
    
    def getbaraidxinfo(self,idx_): # 3
      """
      Obtains the number of terms in the weighted sum that form a particular element in barA.
    
      getbaraidxinfo(self,idx_)
        idx: long. The internal position of the element for which information should be obtained.
      returns: num
        num: long. Number of terms in the weighted sum that form the specified element in barA.
      """
      res,resargs = self.__obj.getbaraidxinfo(idx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _num_return_value = resargs
      return _num_return_value
    
    def getbaraidxij(self,idx_): # 3
      """
      Obtains information about an element in barA.
    
      getbaraidxij(self,idx_)
        idx: long. Position of the element in the vectorized form.
      returns: i,j
        i: int. Row index of the element at position idx.
        j: int. Column index of the element at position idx.
      """
      res,resargs = self.__obj.getbaraidxij(idx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _i_return_value,_j_return_value = resargs
      return _i_return_value,_j_return_value
    
    def getbaraidx(self,idx_,sub,weights): # 3
      """
      Obtains information about an element in barA.
    
      getbaraidx(self,idx_,sub,weights)
        idx: long. Position of the element in the vectorized form.
        sub: array of long. A list indexes of the elements from symmetric matrix storage that appear in the weighted sum.
        weights: array of double. The weights associated with each term in the weighted sum.
      returns: i,j,num
        i: int. Row index of the element at position idx.
        j: int. Column index of the element at position idx.
        num: long. Number of terms in weighted sum that forms the element.
      """
      maxnum_ = self.getbaraidxinfo((idx_))
      if sub is None: raise TypeError("Invalid type for argument sub")
      _copyback_sub = False
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("q",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
            _copyback_sub = True
        else:
          if sub_.format != "q":
            sub_ = memoryview(array.array("q",sub))
            _copyback_sub = True
      if sub_ is not None and len(sub_) != (maxnum_):
        raise ValueError("Array argument sub has wrong length")
      if weights is None: raise TypeError("Invalid type for argument weights")
      _copyback_weights = False
      if weights is None:
        weights_ = None
      else:
        try:
          weights_ = memoryview(weights)
        except TypeError:
          try:
            _tmparr_weights = array.array("d",weights)
          except TypeError:
            raise TypeError("Argument weights has wrong type")
          else:
            weights_ = memoryview(_tmparr_weights)
            _copyback_weights = True
        else:
          if weights_.format != "d":
            weights_ = memoryview(array.array("d",weights))
            _copyback_weights = True
      if weights_ is not None and len(weights_) != (maxnum_):
        raise ValueError("Array argument weights has wrong length")
      res,resargs = self.__obj.getbaraidx(idx_,maxnum_,sub_,weights_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _i_return_value,_j_return_value,_num_return_value = resargs
      if _copyback_weights:
        weights[:] = _tmparr_weights
      if _copyback_sub:
        sub[:] = _tmparr_sub
      return _i_return_value,_j_return_value,_num_return_value
    
    def getnumbarcblocktriplets(self): # 3
      """
      Obtains an upper bound on the number of elements in the block triplet form of barc.
    
      getnumbarcblocktriplets(self)
      returns: num
        num: long. An upper bound on the number of elements in the block triplet form of barc.
      """
      res,resargs = self.__obj.getnumbarcblocktriplets()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _num_return_value = resargs
      return _num_return_value
    
    def putbarcblocktriplet(self,num_,subj,subk,subl,valjkl): # 3
      """
      Inputs barC in block triplet form.
    
      putbarcblocktriplet(self,num_,subj,subk,subl,valjkl)
        num: long. Number of elements in the block triplet form.
        subj: array of int. Symmetric matrix variable index.
        subk: array of int. Block row index.
        subl: array of int. Block column index.
        valjkl: array of double. The numerical value associated with each block triplet.
      """
      if subj is None: raise TypeError("Invalid type for argument subj")
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
      
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
      
      if subj_ is not None and len(subj_) != (num_):
        raise ValueError("Array argument subj has wrong length")
      if subk is None: raise TypeError("Invalid type for argument subk")
      if subk is None:
        subk_ = None
      else:
        try:
          subk_ = memoryview(subk)
        except TypeError:
          try:
            _tmparr_subk = array.array("i",subk)
          except TypeError:
            raise TypeError("Argument subk has wrong type")
          else:
            subk_ = memoryview(_tmparr_subk)
      
        else:
          if subk_.format != "i":
            subk_ = memoryview(array.array("i",subk))
      
      if subk_ is not None and len(subk_) != (num_):
        raise ValueError("Array argument subk has wrong length")
      if subl is None: raise TypeError("Invalid type for argument subl")
      if subl is None:
        subl_ = None
      else:
        try:
          subl_ = memoryview(subl)
        except TypeError:
          try:
            _tmparr_subl = array.array("i",subl)
          except TypeError:
            raise TypeError("Argument subl has wrong type")
          else:
            subl_ = memoryview(_tmparr_subl)
      
        else:
          if subl_.format != "i":
            subl_ = memoryview(array.array("i",subl))
      
      if subl_ is not None and len(subl_) != (num_):
        raise ValueError("Array argument subl has wrong length")
      if valjkl is None: raise TypeError("Invalid type for argument valjkl")
      if valjkl is None:
        valjkl_ = None
      else:
        try:
          valjkl_ = memoryview(valjkl)
        except TypeError:
          try:
            _tmparr_valjkl = array.array("d",valjkl)
          except TypeError:
            raise TypeError("Argument valjkl has wrong type")
          else:
            valjkl_ = memoryview(_tmparr_valjkl)
      
        else:
          if valjkl_.format != "d":
            valjkl_ = memoryview(array.array("d",valjkl))
      
      if valjkl_ is not None and len(valjkl_) != (num_):
        raise ValueError("Array argument valjkl has wrong length")
      res = self.__obj.putbarcblocktriplet(num_,subj_,subk_,subl_,valjkl_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getbarcblocktriplet(self,subj,subk,subl,valjkl): # 3
      """
      Obtains barC in block triplet form.
    
      getbarcblocktriplet(self,subj,subk,subl,valjkl)
        subj: array of int. Symmetric matrix variable index.
        subk: array of int. Block row index.
        subl: array of int. Block column index.
        valjkl: array of double. The numerical value associated with each block triplet.
      returns: num
        num: long. Number of elements in the block triplet form.
      """
      maxnum_ = self.getnumbarcblocktriplets()
      if subj is None: raise TypeError("Invalid type for argument subj")
      _copyback_subj = False
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
            _copyback_subj = True
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
            _copyback_subj = True
      if subj_ is not None and len(subj_) != (maxnum_):
        raise ValueError("Array argument subj has wrong length")
      if subk is None: raise TypeError("Invalid type for argument subk")
      _copyback_subk = False
      if subk is None:
        subk_ = None
      else:
        try:
          subk_ = memoryview(subk)
        except TypeError:
          try:
            _tmparr_subk = array.array("i",subk)
          except TypeError:
            raise TypeError("Argument subk has wrong type")
          else:
            subk_ = memoryview(_tmparr_subk)
            _copyback_subk = True
        else:
          if subk_.format != "i":
            subk_ = memoryview(array.array("i",subk))
            _copyback_subk = True
      if subk_ is not None and len(subk_) != (maxnum_):
        raise ValueError("Array argument subk has wrong length")
      if subl is None: raise TypeError("Invalid type for argument subl")
      _copyback_subl = False
      if subl is None:
        subl_ = None
      else:
        try:
          subl_ = memoryview(subl)
        except TypeError:
          try:
            _tmparr_subl = array.array("i",subl)
          except TypeError:
            raise TypeError("Argument subl has wrong type")
          else:
            subl_ = memoryview(_tmparr_subl)
            _copyback_subl = True
        else:
          if subl_.format != "i":
            subl_ = memoryview(array.array("i",subl))
            _copyback_subl = True
      if subl_ is not None and len(subl_) != (maxnum_):
        raise ValueError("Array argument subl has wrong length")
      if valjkl is None: raise TypeError("Invalid type for argument valjkl")
      _copyback_valjkl = False
      if valjkl is None:
        valjkl_ = None
      else:
        try:
          valjkl_ = memoryview(valjkl)
        except TypeError:
          try:
            _tmparr_valjkl = array.array("d",valjkl)
          except TypeError:
            raise TypeError("Argument valjkl has wrong type")
          else:
            valjkl_ = memoryview(_tmparr_valjkl)
            _copyback_valjkl = True
        else:
          if valjkl_.format != "d":
            valjkl_ = memoryview(array.array("d",valjkl))
            _copyback_valjkl = True
      if valjkl_ is not None and len(valjkl_) != (maxnum_):
        raise ValueError("Array argument valjkl has wrong length")
      res,resargs = self.__obj.getbarcblocktriplet(maxnum_,subj_,subk_,subl_,valjkl_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _num_return_value = resargs
      if _copyback_valjkl:
        valjkl[:] = _tmparr_valjkl
      if _copyback_subl:
        subl[:] = _tmparr_subl
      if _copyback_subk:
        subk[:] = _tmparr_subk
      if _copyback_subj:
        subj[:] = _tmparr_subj
      return _num_return_value
    
    def putbarablocktriplet(self,num_,subi,subj,subk,subl,valijkl): # 3
      """
      Inputs barA in block triplet form.
    
      putbarablocktriplet(self,num_,subi,subj,subk,subl,valijkl)
        num: long. Number of elements in the block triplet form.
        subi: array of int. Constraint index.
        subj: array of int. Symmetric matrix variable index.
        subk: array of int. Block row index.
        subl: array of int. Block column index.
        valijkl: array of double. The numerical value associated with each block triplet.
      """
      if subi is None: raise TypeError("Invalid type for argument subi")
      if subi is None:
        subi_ = None
      else:
        try:
          subi_ = memoryview(subi)
        except TypeError:
          try:
            _tmparr_subi = array.array("i",subi)
          except TypeError:
            raise TypeError("Argument subi has wrong type")
          else:
            subi_ = memoryview(_tmparr_subi)
      
        else:
          if subi_.format != "i":
            subi_ = memoryview(array.array("i",subi))
      
      if subi_ is not None and len(subi_) != (num_):
        raise ValueError("Array argument subi has wrong length")
      if subj is None: raise TypeError("Invalid type for argument subj")
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
      
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
      
      if subj_ is not None and len(subj_) != (num_):
        raise ValueError("Array argument subj has wrong length")
      if subk is None: raise TypeError("Invalid type for argument subk")
      if subk is None:
        subk_ = None
      else:
        try:
          subk_ = memoryview(subk)
        except TypeError:
          try:
            _tmparr_subk = array.array("i",subk)
          except TypeError:
            raise TypeError("Argument subk has wrong type")
          else:
            subk_ = memoryview(_tmparr_subk)
      
        else:
          if subk_.format != "i":
            subk_ = memoryview(array.array("i",subk))
      
      if subk_ is not None and len(subk_) != (num_):
        raise ValueError("Array argument subk has wrong length")
      if subl is None: raise TypeError("Invalid type for argument subl")
      if subl is None:
        subl_ = None
      else:
        try:
          subl_ = memoryview(subl)
        except TypeError:
          try:
            _tmparr_subl = array.array("i",subl)
          except TypeError:
            raise TypeError("Argument subl has wrong type")
          else:
            subl_ = memoryview(_tmparr_subl)
      
        else:
          if subl_.format != "i":
            subl_ = memoryview(array.array("i",subl))
      
      if subl_ is not None and len(subl_) != (num_):
        raise ValueError("Array argument subl has wrong length")
      if valijkl is None: raise TypeError("Invalid type for argument valijkl")
      if valijkl is None:
        valijkl_ = None
      else:
        try:
          valijkl_ = memoryview(valijkl)
        except TypeError:
          try:
            _tmparr_valijkl = array.array("d",valijkl)
          except TypeError:
            raise TypeError("Argument valijkl has wrong type")
          else:
            valijkl_ = memoryview(_tmparr_valijkl)
      
        else:
          if valijkl_.format != "d":
            valijkl_ = memoryview(array.array("d",valijkl))
      
      if valijkl_ is not None and len(valijkl_) != (num_):
        raise ValueError("Array argument valijkl has wrong length")
      res = self.__obj.putbarablocktriplet(num_,subi_,subj_,subk_,subl_,valijkl_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getnumbarablocktriplets(self): # 3
      """
      Obtains an upper bound on the number of scalar elements in the block triplet form of bara.
    
      getnumbarablocktriplets(self)
      returns: num
        num: long. An upper bound on the number of elements in the block triplet form of bara.
      """
      res,resargs = self.__obj.getnumbarablocktriplets()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _num_return_value = resargs
      return _num_return_value
    
    def getbarablocktriplet(self,subi,subj,subk,subl,valijkl): # 3
      """
      Obtains barA in block triplet form.
    
      getbarablocktriplet(self,subi,subj,subk,subl,valijkl)
        subi: array of int. Constraint index.
        subj: array of int. Symmetric matrix variable index.
        subk: array of int. Block row index.
        subl: array of int. Block column index.
        valijkl: array of double. The numerical value associated with each block triplet.
      returns: num
        num: long. Number of elements in the block triplet form.
      """
      maxnum_ = self.getnumbarablocktriplets()
      if subi is None: raise TypeError("Invalid type for argument subi")
      _copyback_subi = False
      if subi is None:
        subi_ = None
      else:
        try:
          subi_ = memoryview(subi)
        except TypeError:
          try:
            _tmparr_subi = array.array("i",subi)
          except TypeError:
            raise TypeError("Argument subi has wrong type")
          else:
            subi_ = memoryview(_tmparr_subi)
            _copyback_subi = True
        else:
          if subi_.format != "i":
            subi_ = memoryview(array.array("i",subi))
            _copyback_subi = True
      if subi_ is not None and len(subi_) != (maxnum_):
        raise ValueError("Array argument subi has wrong length")
      if subj is None: raise TypeError("Invalid type for argument subj")
      _copyback_subj = False
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
            _copyback_subj = True
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
            _copyback_subj = True
      if subj_ is not None and len(subj_) != (maxnum_):
        raise ValueError("Array argument subj has wrong length")
      if subk is None: raise TypeError("Invalid type for argument subk")
      _copyback_subk = False
      if subk is None:
        subk_ = None
      else:
        try:
          subk_ = memoryview(subk)
        except TypeError:
          try:
            _tmparr_subk = array.array("i",subk)
          except TypeError:
            raise TypeError("Argument subk has wrong type")
          else:
            subk_ = memoryview(_tmparr_subk)
            _copyback_subk = True
        else:
          if subk_.format != "i":
            subk_ = memoryview(array.array("i",subk))
            _copyback_subk = True
      if subk_ is not None and len(subk_) != (maxnum_):
        raise ValueError("Array argument subk has wrong length")
      if subl is None: raise TypeError("Invalid type for argument subl")
      _copyback_subl = False
      if subl is None:
        subl_ = None
      else:
        try:
          subl_ = memoryview(subl)
        except TypeError:
          try:
            _tmparr_subl = array.array("i",subl)
          except TypeError:
            raise TypeError("Argument subl has wrong type")
          else:
            subl_ = memoryview(_tmparr_subl)
            _copyback_subl = True
        else:
          if subl_.format != "i":
            subl_ = memoryview(array.array("i",subl))
            _copyback_subl = True
      if subl_ is not None and len(subl_) != (maxnum_):
        raise ValueError("Array argument subl has wrong length")
      if valijkl is None: raise TypeError("Invalid type for argument valijkl")
      _copyback_valijkl = False
      if valijkl is None:
        valijkl_ = None
      else:
        try:
          valijkl_ = memoryview(valijkl)
        except TypeError:
          try:
            _tmparr_valijkl = array.array("d",valijkl)
          except TypeError:
            raise TypeError("Argument valijkl has wrong type")
          else:
            valijkl_ = memoryview(_tmparr_valijkl)
            _copyback_valijkl = True
        else:
          if valijkl_.format != "d":
            valijkl_ = memoryview(array.array("d",valijkl))
            _copyback_valijkl = True
      if valijkl_ is not None and len(valijkl_) != (maxnum_):
        raise ValueError("Array argument valijkl has wrong length")
      res,resargs = self.__obj.getbarablocktriplet(maxnum_,subi_,subj_,subk_,subl_,valijkl_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _num_return_value = resargs
      if _copyback_valijkl:
        valijkl[:] = _tmparr_valijkl
      if _copyback_subl:
        subl[:] = _tmparr_subl
      if _copyback_subk:
        subk[:] = _tmparr_subk
      if _copyback_subj:
        subj[:] = _tmparr_subj
      if _copyback_subi:
        subi[:] = _tmparr_subi
      return _num_return_value
    
    def putbound(self,accmode_,i_,bk_,bl_,bu_): # 3
      """
      Changes the bound for either one constraint or one variable.
    
      putbound(self,accmode_,i_,bk_,bl_,bu_)
        accmode: mosek.accmode. Defines whether the bound for a constraint or a variable is changed.
        i: int. Index of the constraint or variable.
        bk: mosek.boundkey. New bound key.
        bl: double. New lower bound.
        bu: double. New upper bound.
      """
      if not isinstance(accmode_,accmode): raise TypeError("Argument accmode has wrong type")
      if not isinstance(bk_,boundkey): raise TypeError("Argument bk has wrong type")
      res = self.__obj.putbound(accmode_,i_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putboundlist(self,accmode_,sub,bk,bl,bu): # 3
      """
      Changes the bounds of constraints or variables.
    
      putboundlist(self,accmode_,sub,bk,bl,bu)
        accmode: mosek.accmode. Defines whether to access bounds on variables or constraints.
        sub: array of int. Subscripts of the constraints or variables that should be changed.
        bk: array of mosek.boundkey. Bound keys.
        bl: array of double. Values for lower bounds.
        bu: array of double. Values for upper bounds.
      """
      if not isinstance(accmode_,accmode): raise TypeError("Argument accmode has wrong type")
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None:
        num_ = len(bk)
      elif num_ != len(bk):
        raise IndexError("Inconsistent length of array bk")
      if num_ is None:
        num_ = len(bl)
      elif num_ != len(bl):
        raise IndexError("Inconsistent length of array bl")
      if num_ is None:
        num_ = len(bu)
      elif num_ != len(bu):
        raise IndexError("Inconsistent length of array bu")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if bk is None: raise TypeError("Invalid type for argument bk")
      if bk is None:
        bk_ = None
      else:
        try:
          bk_ = memoryview(bk)
        except TypeError:
          try:
            _tmparr_bk = array.array("i",bk)
          except TypeError:
            raise TypeError("Argument bk has wrong type")
          else:
            bk_ = memoryview(_tmparr_bk)
      
        else:
          if bk_.format != "i":
            bk_ = memoryview(array.array("i",bk))
      
      if bl is None: raise TypeError("Invalid type for argument bl")
      if bl is None:
        bl_ = None
      else:
        try:
          bl_ = memoryview(bl)
        except TypeError:
          try:
            _tmparr_bl = array.array("d",bl)
          except TypeError:
            raise TypeError("Argument bl has wrong type")
          else:
            bl_ = memoryview(_tmparr_bl)
      
        else:
          if bl_.format != "d":
            bl_ = memoryview(array.array("d",bl))
      
      if bu is None: raise TypeError("Invalid type for argument bu")
      if bu is None:
        bu_ = None
      else:
        try:
          bu_ = memoryview(bu)
        except TypeError:
          try:
            _tmparr_bu = array.array("d",bu)
          except TypeError:
            raise TypeError("Argument bu has wrong type")
          else:
            bu_ = memoryview(_tmparr_bu)
      
        else:
          if bu_.format != "d":
            bu_ = memoryview(array.array("d",bu))
      
      res = self.__obj.putboundlist(accmode_,num_,sub_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putconbound(self,i_,bk_,bl_,bu_): # 3
      """
      Changes the bound for one constraint.
    
      putconbound(self,i_,bk_,bl_,bu_)
        i: int. Index of the constraint.
        bk: mosek.boundkey. New bound key.
        bl: double. New lower bound.
        bu: double. New upper bound.
      """
      if not isinstance(bk_,boundkey): raise TypeError("Argument bk has wrong type")
      res = self.__obj.putconbound(i_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putconboundlist(self,sub,bk,bl,bu): # 3
      """
      Changes the bounds of a list of constraints.
    
      putconboundlist(self,sub,bk,bl,bu)
        sub: array of int. List of constraint indexes.
        bk: array of mosek.boundkey. Bound keys.
        bl: array of double. Values for lower bounds.
        bu: array of double. Values for upper bounds.
      """
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None:
        num_ = len(bk)
      elif num_ != len(bk):
        raise IndexError("Inconsistent length of array bk")
      if num_ is None:
        num_ = len(bl)
      elif num_ != len(bl):
        raise IndexError("Inconsistent length of array bl")
      if num_ is None:
        num_ = len(bu)
      elif num_ != len(bu):
        raise IndexError("Inconsistent length of array bu")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if bk is None: raise TypeError("Invalid type for argument bk")
      if bk is None:
        bk_ = None
      else:
        try:
          bk_ = memoryview(bk)
        except TypeError:
          try:
            _tmparr_bk = array.array("i",bk)
          except TypeError:
            raise TypeError("Argument bk has wrong type")
          else:
            bk_ = memoryview(_tmparr_bk)
      
        else:
          if bk_.format != "i":
            bk_ = memoryview(array.array("i",bk))
      
      if bl is None: raise TypeError("Invalid type for argument bl")
      if bl is None:
        bl_ = None
      else:
        try:
          bl_ = memoryview(bl)
        except TypeError:
          try:
            _tmparr_bl = array.array("d",bl)
          except TypeError:
            raise TypeError("Argument bl has wrong type")
          else:
            bl_ = memoryview(_tmparr_bl)
      
        else:
          if bl_.format != "d":
            bl_ = memoryview(array.array("d",bl))
      
      if bu is None: raise TypeError("Invalid type for argument bu")
      if bu is None:
        bu_ = None
      else:
        try:
          bu_ = memoryview(bu)
        except TypeError:
          try:
            _tmparr_bu = array.array("d",bu)
          except TypeError:
            raise TypeError("Argument bu has wrong type")
          else:
            bu_ = memoryview(_tmparr_bu)
      
        else:
          if bu_.format != "d":
            bu_ = memoryview(array.array("d",bu))
      
      res = self.__obj.putconboundlist(num_,sub_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putconboundslice(self,first_,last_,bk,bl,bu): # 3
      """
      Changes the bounds for a slice of the constraints.
    
      putconboundslice(self,first_,last_,bk,bl,bu)
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        bk: array of mosek.boundkey. Bound keys.
        bl: array of double. Values for lower bounds.
        bu: array of double. Values for upper bounds.
      """
      if bk is None: raise TypeError("Invalid type for argument bk")
      if bk is None:
        bk_ = None
      else:
        try:
          bk_ = memoryview(bk)
        except TypeError:
          try:
            _tmparr_bk = array.array("i",bk)
          except TypeError:
            raise TypeError("Argument bk has wrong type")
          else:
            bk_ = memoryview(_tmparr_bk)
      
        else:
          if bk_.format != "i":
            bk_ = memoryview(array.array("i",bk))
      
      if bk_ is not None and len(bk_) != ((last_) - (first_)):
        raise ValueError("Array argument bk has wrong length")
      if bl is None: raise TypeError("Invalid type for argument bl")
      if bl is None:
        bl_ = None
      else:
        try:
          bl_ = memoryview(bl)
        except TypeError:
          try:
            _tmparr_bl = array.array("d",bl)
          except TypeError:
            raise TypeError("Argument bl has wrong type")
          else:
            bl_ = memoryview(_tmparr_bl)
      
        else:
          if bl_.format != "d":
            bl_ = memoryview(array.array("d",bl))
      
      if bl_ is not None and len(bl_) != ((last_) - (first_)):
        raise ValueError("Array argument bl has wrong length")
      if bu is None: raise TypeError("Invalid type for argument bu")
      if bu is None:
        bu_ = None
      else:
        try:
          bu_ = memoryview(bu)
        except TypeError:
          try:
            _tmparr_bu = array.array("d",bu)
          except TypeError:
            raise TypeError("Argument bu has wrong type")
          else:
            bu_ = memoryview(_tmparr_bu)
      
        else:
          if bu_.format != "d":
            bu_ = memoryview(array.array("d",bu))
      
      if bu_ is not None and len(bu_) != ((last_) - (first_)):
        raise ValueError("Array argument bu has wrong length")
      res = self.__obj.putconboundslice(first_,last_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putvarbound(self,j_,bk_,bl_,bu_): # 3
      """
      Changes the bound for one variable.
    
      putvarbound(self,j_,bk_,bl_,bu_)
        j: int. Index of the variable.
        bk: mosek.boundkey. New bound key.
        bl: double. New lower bound.
        bu: double. New upper bound.
      """
      if not isinstance(bk_,boundkey): raise TypeError("Argument bk has wrong type")
      res = self.__obj.putvarbound(j_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putvarboundlist(self,sub,bkx,blx,bux): # 3
      """
      Changes the bounds of a list of variables.
    
      putvarboundlist(self,sub,bkx,blx,bux)
        sub: array of int. List of variable indexes.
        bkx: array of mosek.boundkey. Bound keys for the variables.
        blx: array of double. Lower bounds for the variables.
        bux: array of double. Upper bounds for the variables.
      """
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None:
        num_ = len(bkx)
      elif num_ != len(bkx):
        raise IndexError("Inconsistent length of array bkx")
      if num_ is None:
        num_ = len(blx)
      elif num_ != len(blx):
        raise IndexError("Inconsistent length of array blx")
      if num_ is None:
        num_ = len(bux)
      elif num_ != len(bux):
        raise IndexError("Inconsistent length of array bux")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("i",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "i":
            sub_ = memoryview(array.array("i",sub))
      
      if bkx is None: raise TypeError("Invalid type for argument bkx")
      if bkx is None:
        bkx_ = None
      else:
        try:
          bkx_ = memoryview(bkx)
        except TypeError:
          try:
            _tmparr_bkx = array.array("i",bkx)
          except TypeError:
            raise TypeError("Argument bkx has wrong type")
          else:
            bkx_ = memoryview(_tmparr_bkx)
      
        else:
          if bkx_.format != "i":
            bkx_ = memoryview(array.array("i",bkx))
      
      if blx is None: raise TypeError("Invalid type for argument blx")
      if blx is None:
        blx_ = None
      else:
        try:
          blx_ = memoryview(blx)
        except TypeError:
          try:
            _tmparr_blx = array.array("d",blx)
          except TypeError:
            raise TypeError("Argument blx has wrong type")
          else:
            blx_ = memoryview(_tmparr_blx)
      
        else:
          if blx_.format != "d":
            blx_ = memoryview(array.array("d",blx))
      
      if bux is None: raise TypeError("Invalid type for argument bux")
      if bux is None:
        bux_ = None
      else:
        try:
          bux_ = memoryview(bux)
        except TypeError:
          try:
            _tmparr_bux = array.array("d",bux)
          except TypeError:
            raise TypeError("Argument bux has wrong type")
          else:
            bux_ = memoryview(_tmparr_bux)
      
        else:
          if bux_.format != "d":
            bux_ = memoryview(array.array("d",bux))
      
      res = self.__obj.putvarboundlist(num_,sub_,bkx_,blx_,bux_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putvarboundslice(self,first_,last_,bk,bl,bu): # 3
      """
      Changes the bounds for a slice of the variables.
    
      putvarboundslice(self,first_,last_,bk,bl,bu)
        first: int. First index in the sequence.
        last: int. Last index plus 1 in the sequence.
        bk: array of mosek.boundkey. Bound keys.
        bl: array of double. Values for lower bounds.
        bu: array of double. Values for upper bounds.
      """
      if bk is None: raise TypeError("Invalid type for argument bk")
      if bk is None:
        bk_ = None
      else:
        try:
          bk_ = memoryview(bk)
        except TypeError:
          try:
            _tmparr_bk = array.array("i",bk)
          except TypeError:
            raise TypeError("Argument bk has wrong type")
          else:
            bk_ = memoryview(_tmparr_bk)
      
        else:
          if bk_.format != "i":
            bk_ = memoryview(array.array("i",bk))
      
      if bk_ is not None and len(bk_) != ((last_) - (first_)):
        raise ValueError("Array argument bk has wrong length")
      if bl is None: raise TypeError("Invalid type for argument bl")
      if bl is None:
        bl_ = None
      else:
        try:
          bl_ = memoryview(bl)
        except TypeError:
          try:
            _tmparr_bl = array.array("d",bl)
          except TypeError:
            raise TypeError("Argument bl has wrong type")
          else:
            bl_ = memoryview(_tmparr_bl)
      
        else:
          if bl_.format != "d":
            bl_ = memoryview(array.array("d",bl))
      
      if bl_ is not None and len(bl_) != ((last_) - (first_)):
        raise ValueError("Array argument bl has wrong length")
      if bu is None: raise TypeError("Invalid type for argument bu")
      if bu is None:
        bu_ = None
      else:
        try:
          bu_ = memoryview(bu)
        except TypeError:
          try:
            _tmparr_bu = array.array("d",bu)
          except TypeError:
            raise TypeError("Argument bu has wrong type")
          else:
            bu_ = memoryview(_tmparr_bu)
      
        else:
          if bu_.format != "d":
            bu_ = memoryview(array.array("d",bu))
      
      if bu_ is not None and len(bu_) != ((last_) - (first_)):
        raise ValueError("Array argument bu has wrong length")
      res = self.__obj.putvarboundslice(first_,last_,bk_,bl_,bu_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putcfix(self,cfix_): # 3
      """
      Replaces the fixed term in the objective.
    
      putcfix(self,cfix_)
        cfix: double. Fixed term in the objective.
      """
      res = self.__obj.putcfix(cfix_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putcj(self,j_,cj_): # 3
      """
      Modifies one linear coefficient in the objective.
    
      putcj(self,j_,cj_)
        j: int. Index of the variable whose objective coefficient should be changed.
        cj: double. New coefficient value.
      """
      res = self.__obj.putcj(j_,cj_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putobjsense(self,sense_): # 3
      """
      Sets the objective sense.
    
      putobjsense(self,sense_)
        sense: mosek.objsense. The objective sense of the task
      """
      if not isinstance(sense_,objsense): raise TypeError("Argument sense has wrong type")
      res = self.__obj.putobjsense(sense_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getobjsense(self): # 3
      """
      Gets the objective sense.
    
      getobjsense(self)
      returns: sense
        sense: mosek.objsense. The returned objective sense.
      """
      res,resargs = self.__obj.getobjsense()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _sense_return_value = resargs
      _sense_return_value = objsense(_sense_return_value)
      return _sense_return_value
    
    def putclist(self,subj,val): # 3
      """
      Modifies a part of the linear objective coefficients.
    
      putclist(self,subj,val)
        subj: array of int. Indices of variables for which objective coefficients should be changed.
        val: array of double. New numerical values for the objective coefficients that should be modified.
      """
      num_ = None
      if num_ is None:
        num_ = len(subj)
      elif num_ != len(subj):
        raise IndexError("Inconsistent length of array subj")
      if num_ is None:
        num_ = len(val)
      elif num_ != len(val):
        raise IndexError("Inconsistent length of array val")
      if num_ is None: num_ = 0
      if subj is None: raise TypeError("Invalid type for argument subj")
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
      
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
      
      if val is None: raise TypeError("Invalid type for argument val")
      if val is None:
        val_ = None
      else:
        try:
          val_ = memoryview(val)
        except TypeError:
          try:
            _tmparr_val = array.array("d",val)
          except TypeError:
            raise TypeError("Argument val has wrong type")
          else:
            val_ = memoryview(_tmparr_val)
      
        else:
          if val_.format != "d":
            val_ = memoryview(array.array("d",val))
      
      res = self.__obj.putclist(num_,subj_,val_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putcslice(self,first_,last_,slice): # 3
      """
      Modifies a slice of the linear objective coefficients.
    
      putcslice(self,first_,last_,slice)
        first: int. First element in the slice of c.
        last: int. Last element plus 1 of the slice in c to be changed.
        slice: array of double. New numerical values for the objective coefficients that should be modified.
      """
      if slice is None: raise TypeError("Invalid type for argument slice")
      if slice is None:
        slice_ = None
      else:
        try:
          slice_ = memoryview(slice)
        except TypeError:
          try:
            _tmparr_slice = array.array("d",slice)
          except TypeError:
            raise TypeError("Argument slice has wrong type")
          else:
            slice_ = memoryview(_tmparr_slice)
      
        else:
          if slice_.format != "d":
            slice_ = memoryview(array.array("d",slice))
      
      if slice_ is not None and len(slice_) != ((last_) - (first_)):
        raise ValueError("Array argument slice has wrong length")
      res = self.__obj.putcslice(first_,last_,slice_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putbarcj(self,j_,sub,weights): # 3
      """
      Changes one element in barc.
    
      putbarcj(self,j_,sub,weights)
        j: int. Index of the element in barc` that should be changed.
        sub: array of long. sub is list of indexes of those symmetric matrices appearing in sum.
        weights: array of double. The weights of the terms in the weighted sum.
      """
      num_ = None
      if num_ is None:
        num_ = len(sub)
      elif num_ != len(sub):
        raise IndexError("Inconsistent length of array sub")
      if num_ is None:
        num_ = len(weights)
      elif num_ != len(weights):
        raise IndexError("Inconsistent length of array weights")
      if num_ is None: num_ = 0
      if sub is None: raise TypeError("Invalid type for argument sub")
      if sub is None:
        sub_ = None
      else:
        try:
          sub_ = memoryview(sub)
        except TypeError:
          try:
            _tmparr_sub = array.array("q",sub)
          except TypeError:
            raise TypeError("Argument sub has wrong type")
          else:
            sub_ = memoryview(_tmparr_sub)
      
        else:
          if sub_.format != "q":
            sub_ = memoryview(array.array("q",sub))
      
      if weights is None: raise TypeError("Invalid type for argument weights")
      if weights is None:
        weights_ = None
      else:
        try:
          weights_ = memoryview(weights)
        except TypeError:
          try:
            _tmparr_weights = array.array("d",weights)
          except TypeError:
            raise TypeError("Argument weights has wrong type")
          else:
            weights_ = memoryview(_tmparr_weights)
      
        else:
          if weights_.format != "d":
            weights_ = memoryview(array.array("d",weights))
      
      res = self.__obj.putbarcj(j_,num_,sub_,weights_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putcone(self,k_,ct_,conepar_,submem): # 3
      """
      Replaces a conic constraint.
    
      putcone(self,k_,ct_,conepar_,submem)
        k: int. Index of the cone.
        ct: mosek.conetype. Specifies the type of the cone.
        conepar: double. This argument is currently not used. It can be set to 0
        submem: array of int. Variable subscripts of the members in the cone.
      """
      if not isinstance(ct_,conetype): raise TypeError("Argument ct has wrong type")
      nummem_ = None
      if nummem_ is None:
        nummem_ = len(submem)
      elif nummem_ != len(submem):
        raise IndexError("Inconsistent length of array submem")
      if nummem_ is None: nummem_ = 0
      if submem is None: raise TypeError("Invalid type for argument submem")
      if submem is None:
        submem_ = None
      else:
        try:
          submem_ = memoryview(submem)
        except TypeError:
          try:
            _tmparr_submem = array.array("i",submem)
          except TypeError:
            raise TypeError("Argument submem has wrong type")
          else:
            submem_ = memoryview(_tmparr_submem)
      
        else:
          if submem_.format != "i":
            submem_ = memoryview(array.array("i",submem))
      
      res = self.__obj.putcone(k_,ct_,conepar_,nummem_,submem_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def appendsparsesymmat(self,dim_,subi,subj,valij): # 3
      """
      Appends a general sparse symmetric matrix to the storage of symmetric matrices.
    
      appendsparsesymmat(self,dim_,subi,subj,valij)
        dim: int. Dimension of the symmetric matrix that is appended.
        subi: array of int. Row subscript in the triplets.
        subj: array of int. Column subscripts in the triplets.
        valij: array of double. Values of each triplet.
      returns: idx
        idx: long. Unique index assigned to the inputted matrix.
      """
      nz_ = None
      if nz_ is None:
        nz_ = len(subi)
      elif nz_ != len(subi):
        raise IndexError("Inconsistent length of array subi")
      if nz_ is None:
        nz_ = len(subj)
      elif nz_ != len(subj):
        raise IndexError("Inconsistent length of array subj")
      if nz_ is None:
        nz_ = len(valij)
      elif nz_ != len(valij):
        raise IndexError("Inconsistent length of array valij")
      if nz_ is None: nz_ = 0
      if subi is None: raise TypeError("Invalid type for argument subi")
      if subi is None:
        subi_ = None
      else:
        try:
          subi_ = memoryview(subi)
        except TypeError:
          try:
            _tmparr_subi = array.array("i",subi)
          except TypeError:
            raise TypeError("Argument subi has wrong type")
          else:
            subi_ = memoryview(_tmparr_subi)
      
        else:
          if subi_.format != "i":
            subi_ = memoryview(array.array("i",subi))
      
      if subj is None: raise TypeError("Invalid type for argument subj")
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
      
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
      
      if valij is None: raise TypeError("Invalid type for argument valij")
      if valij is None:
        valij_ = None
      else:
        try:
          valij_ = memoryview(valij)
        except TypeError:
          try:
            _tmparr_valij = array.array("d",valij)
          except TypeError:
            raise TypeError("Argument valij has wrong type")
          else:
            valij_ = memoryview(_tmparr_valij)
      
        else:
          if valij_.format != "d":
            valij_ = memoryview(array.array("d",valij))
      
      res,resargs = self.__obj.appendsparsesymmat(dim_,nz_,subi_,subj_,valij_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _idx_return_value = resargs
      return _idx_return_value
    
    def getsymmatinfo(self,idx_): # 3
      """
      Obtains information about a matrix from the symmetric matrix storage.
    
      getsymmatinfo(self,idx_)
        idx: long. Index of the matrix for which information is requested.
      returns: dim,nz,type
        dim: int. Returns the dimension of the requested matrix.
        nz: long. Returns the number of non-zeros in the requested matrix.
        type: mosek.symmattype. Returns the type of the requested matrix.
      """
      res,resargs = self.__obj.getsymmatinfo(idx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _dim_return_value,_nz_return_value,_type_return_value = resargs
      _type_return_value = symmattype(_type_return_value)
      return _dim_return_value,_nz_return_value,_type_return_value
    
    def getnumsymmat(self): # 3
      """
      Obtains the number of symmetric matrices stored.
    
      getnumsymmat(self)
      returns: num
        num: long. The number of symmetric sparse matrices.
      """
      res,resargs = self.__obj.getnumsymmat()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _num_return_value = resargs
      return _num_return_value
    
    def getsparsesymmat(self,idx_,subi,subj,valij): # 3
      """
      Gets a single symmetric matrix from the matrix store.
    
      getsparsesymmat(self,idx_,subi,subj,valij)
        idx: long. Index of the matrix to retrieve.
        subi: array of int. Row subscripts of the matrix non-zero elements.
        subj: array of int. Column subscripts of the matrix non-zero elements.
        valij: array of double. Coefficients of the matrix non-zero elements.
      """
      maxlen_ = self.getsymmatinfo((idx_))[1]
      _copyback_subi = False
      if subi is None:
        subi_ = None
      else:
        try:
          subi_ = memoryview(subi)
        except TypeError:
          try:
            _tmparr_subi = array.array("i",subi)
          except TypeError:
            raise TypeError("Argument subi has wrong type")
          else:
            subi_ = memoryview(_tmparr_subi)
            _copyback_subi = True
        else:
          if subi_.format != "i":
            subi_ = memoryview(array.array("i",subi))
            _copyback_subi = True
      if subi_ is not None and len(subi_) != (maxlen_):
        raise ValueError("Array argument subi has wrong length")
      _copyback_subj = False
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
            _copyback_subj = True
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
            _copyback_subj = True
      if subj_ is not None and len(subj_) != (maxlen_):
        raise ValueError("Array argument subj has wrong length")
      _copyback_valij = False
      if valij is None:
        valij_ = None
      else:
        try:
          valij_ = memoryview(valij)
        except TypeError:
          try:
            _tmparr_valij = array.array("d",valij)
          except TypeError:
            raise TypeError("Argument valij has wrong type")
          else:
            valij_ = memoryview(_tmparr_valij)
            _copyback_valij = True
        else:
          if valij_.format != "d":
            valij_ = memoryview(array.array("d",valij))
            _copyback_valij = True
      if valij_ is not None and len(valij_) != (maxlen_):
        raise ValueError("Array argument valij has wrong length")
      res = self.__obj.getsparsesymmat(idx_,maxlen_,subi_,subj_,valij_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_valij:
        valij[:] = _tmparr_valij
      if _copyback_subj:
        subj[:] = _tmparr_subj
      if _copyback_subi:
        subi[:] = _tmparr_subi
    
    def putdouparam(self,param_,parvalue_): # 3
      """
      Sets a double parameter.
    
      putdouparam(self,param_,parvalue_)
        param: mosek.dparam. Which parameter.
        parvalue: double. Parameter value.
      """
      if not isinstance(param_,dparam): raise TypeError("Argument param has wrong type")
      res = self.__obj.putdouparam(param_,parvalue_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putintparam(self,param_,parvalue_): # 3
      """
      Sets an integer parameter.
    
      putintparam(self,param_,parvalue_)
        param: mosek.iparam. Which parameter.
        parvalue: int. Parameter value.
      """
      if not isinstance(param_,iparam): raise TypeError("Argument param has wrong type")
      res = self.__obj.putintparam(param_,parvalue_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putmaxnumcon(self,maxnumcon_): # 3
      """
      Sets the number of preallocated constraints in the optimization task.
    
      putmaxnumcon(self,maxnumcon_)
        maxnumcon: int. Number of preallocated constraints in the optimization task.
      """
      res = self.__obj.putmaxnumcon(maxnumcon_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putmaxnumcone(self,maxnumcone_): # 3
      """
      Sets the number of preallocated conic constraints in the optimization task.
    
      putmaxnumcone(self,maxnumcone_)
        maxnumcone: int. Number of preallocated conic constraints in the optimization task.
      """
      res = self.__obj.putmaxnumcone(maxnumcone_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getmaxnumcone(self): # 3
      """
      Obtains the number of preallocated cones in the optimization task.
    
      getmaxnumcone(self)
      returns: maxnumcone
        maxnumcone: int. Number of preallocated conic constraints in the optimization task.
      """
      res,resargs = self.__obj.getmaxnumcone()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _maxnumcone_return_value = resargs
      return _maxnumcone_return_value
    
    def putmaxnumvar(self,maxnumvar_): # 3
      """
      Sets the number of preallocated variables in the optimization task.
    
      putmaxnumvar(self,maxnumvar_)
        maxnumvar: int. Number of preallocated variables in the optimization task.
      """
      res = self.__obj.putmaxnumvar(maxnumvar_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putmaxnumbarvar(self,maxnumbarvar_): # 3
      """
      Sets the number of preallocated symmetric matrix variables.
    
      putmaxnumbarvar(self,maxnumbarvar_)
        maxnumbarvar: int. Number of preallocated symmetric matrix variables.
      """
      res = self.__obj.putmaxnumbarvar(maxnumbarvar_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putmaxnumanz(self,maxnumanz_): # 3
      """
      Sets the number of preallocated non-zero entries in the linear coefficient matrix.
    
      putmaxnumanz(self,maxnumanz_)
        maxnumanz: long. New size of the storage reserved for storing the linear coefficient matrix.
      """
      res = self.__obj.putmaxnumanz(maxnumanz_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putmaxnumqnz(self,maxnumqnz_): # 3
      """
      Sets the number of preallocated non-zero entries in quadratic terms.
    
      putmaxnumqnz(self,maxnumqnz_)
        maxnumqnz: long. Number of non-zero elements preallocated in quadratic coefficient matrices.
      """
      res = self.__obj.putmaxnumqnz(maxnumqnz_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getmaxnumqnz(self): # 3
      """
      Obtains the number of preallocated non-zeros for all quadratic terms in objective and constraints.
    
      getmaxnumqnz(self)
      returns: maxnumqnz
        maxnumqnz: long. Number of non-zero elements preallocated in quadratic coefficient matrices.
      """
      res,resargs = self.__obj.getmaxnumqnz64()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _maxnumqnz_return_value = resargs
      return _maxnumqnz_return_value
    
    def putnadouparam(self,paramname_,parvalue_): # 3
      """
      Sets a double parameter.
    
      putnadouparam(self,paramname_,parvalue_)
        paramname: str. Name of a parameter.
        parvalue: double. Parameter value.
      """
      res = self.__obj.putnadouparam(paramname_,parvalue_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putnaintparam(self,paramname_,parvalue_): # 3
      """
      Sets an integer parameter.
    
      putnaintparam(self,paramname_,parvalue_)
        paramname: str. Name of a parameter.
        parvalue: int. Parameter value.
      """
      res = self.__obj.putnaintparam(paramname_,parvalue_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putnastrparam(self,paramname_,parvalue_): # 3
      """
      Sets a string parameter.
    
      putnastrparam(self,paramname_,parvalue_)
        paramname: str. Name of a parameter.
        parvalue: str. Parameter value.
      """
      res = self.__obj.putnastrparam(paramname_,parvalue_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putobjname(self,objname_): # 3
      """
      Assigns a new name to the objective.
    
      putobjname(self,objname_)
        objname: str. Name of the objective.
      """
      res = self.__obj.putobjname(objname_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putparam(self,parname_,parvalue_): # 3
      """
      Modifies the value of parameter.
    
      putparam(self,parname_,parvalue_)
        parname: str. Parameter name.
        parvalue: str. Parameter value.
      """
      res = self.__obj.putparam(parname_,parvalue_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putqcon(self,qcsubk,qcsubi,qcsubj,qcval): # 3
      """
      Replaces all quadratic terms in constraints.
    
      putqcon(self,qcsubk,qcsubi,qcsubj,qcval)
        qcsubk: array of int. Constraint subscripts for quadratic coefficients.
        qcsubi: array of int. Row subscripts for quadratic constraint matrix.
        qcsubj: array of int. Column subscripts for quadratic constraint matrix.
        qcval: array of double. Quadratic constraint coefficient values.
      """
      numqcnz_ = None
      if numqcnz_ is None:
        numqcnz_ = len(qcsubi)
      elif numqcnz_ != len(qcsubi):
        raise IndexError("Inconsistent length of array qcsubi")
      if numqcnz_ is None:
        numqcnz_ = len(qcsubj)
      elif numqcnz_ != len(qcsubj):
        raise IndexError("Inconsistent length of array qcsubj")
      if numqcnz_ is None:
        numqcnz_ = len(qcval)
      elif numqcnz_ != len(qcval):
        raise IndexError("Inconsistent length of array qcval")
      if numqcnz_ is None: numqcnz_ = 0
      if qcsubk is None: raise TypeError("Invalid type for argument qcsubk")
      if qcsubk is None:
        qcsubk_ = None
      else:
        try:
          qcsubk_ = memoryview(qcsubk)
        except TypeError:
          try:
            _tmparr_qcsubk = array.array("i",qcsubk)
          except TypeError:
            raise TypeError("Argument qcsubk has wrong type")
          else:
            qcsubk_ = memoryview(_tmparr_qcsubk)
      
        else:
          if qcsubk_.format != "i":
            qcsubk_ = memoryview(array.array("i",qcsubk))
      
      if qcsubi is None: raise TypeError("Invalid type for argument qcsubi")
      if qcsubi is None:
        qcsubi_ = None
      else:
        try:
          qcsubi_ = memoryview(qcsubi)
        except TypeError:
          try:
            _tmparr_qcsubi = array.array("i",qcsubi)
          except TypeError:
            raise TypeError("Argument qcsubi has wrong type")
          else:
            qcsubi_ = memoryview(_tmparr_qcsubi)
      
        else:
          if qcsubi_.format != "i":
            qcsubi_ = memoryview(array.array("i",qcsubi))
      
      if qcsubj is None: raise TypeError("Invalid type for argument qcsubj")
      if qcsubj is None:
        qcsubj_ = None
      else:
        try:
          qcsubj_ = memoryview(qcsubj)
        except TypeError:
          try:
            _tmparr_qcsubj = array.array("i",qcsubj)
          except TypeError:
            raise TypeError("Argument qcsubj has wrong type")
          else:
            qcsubj_ = memoryview(_tmparr_qcsubj)
      
        else:
          if qcsubj_.format != "i":
            qcsubj_ = memoryview(array.array("i",qcsubj))
      
      if qcval is None: raise TypeError("Invalid type for argument qcval")
      if qcval is None:
        qcval_ = None
      else:
        try:
          qcval_ = memoryview(qcval)
        except TypeError:
          try:
            _tmparr_qcval = array.array("d",qcval)
          except TypeError:
            raise TypeError("Argument qcval has wrong type")
          else:
            qcval_ = memoryview(_tmparr_qcval)
      
        else:
          if qcval_.format != "d":
            qcval_ = memoryview(array.array("d",qcval))
      
      res = self.__obj.putqcon(numqcnz_,qcsubk_,qcsubi_,qcsubj_,qcval_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putqconk(self,k_,qcsubi,qcsubj,qcval): # 3
      """
      Replaces all quadratic terms in a single constraint.
    
      putqconk(self,k_,qcsubi,qcsubj,qcval)
        k: int. The constraint in which the new quadratic elements are inserted.
        qcsubi: array of int. Row subscripts for quadratic constraint matrix.
        qcsubj: array of int. Column subscripts for quadratic constraint matrix.
        qcval: array of double. Quadratic constraint coefficient values.
      """
      numqcnz_ = None
      if numqcnz_ is None:
        numqcnz_ = len(qcsubi)
      elif numqcnz_ != len(qcsubi):
        raise IndexError("Inconsistent length of array qcsubi")
      if numqcnz_ is None:
        numqcnz_ = len(qcsubj)
      elif numqcnz_ != len(qcsubj):
        raise IndexError("Inconsistent length of array qcsubj")
      if numqcnz_ is None:
        numqcnz_ = len(qcval)
      elif numqcnz_ != len(qcval):
        raise IndexError("Inconsistent length of array qcval")
      if numqcnz_ is None: numqcnz_ = 0
      if qcsubi is None: raise TypeError("Invalid type for argument qcsubi")
      if qcsubi is None:
        qcsubi_ = None
      else:
        try:
          qcsubi_ = memoryview(qcsubi)
        except TypeError:
          try:
            _tmparr_qcsubi = array.array("i",qcsubi)
          except TypeError:
            raise TypeError("Argument qcsubi has wrong type")
          else:
            qcsubi_ = memoryview(_tmparr_qcsubi)
      
        else:
          if qcsubi_.format != "i":
            qcsubi_ = memoryview(array.array("i",qcsubi))
      
      if qcsubj is None: raise TypeError("Invalid type for argument qcsubj")
      if qcsubj is None:
        qcsubj_ = None
      else:
        try:
          qcsubj_ = memoryview(qcsubj)
        except TypeError:
          try:
            _tmparr_qcsubj = array.array("i",qcsubj)
          except TypeError:
            raise TypeError("Argument qcsubj has wrong type")
          else:
            qcsubj_ = memoryview(_tmparr_qcsubj)
      
        else:
          if qcsubj_.format != "i":
            qcsubj_ = memoryview(array.array("i",qcsubj))
      
      if qcval is None: raise TypeError("Invalid type for argument qcval")
      if qcval is None:
        qcval_ = None
      else:
        try:
          qcval_ = memoryview(qcval)
        except TypeError:
          try:
            _tmparr_qcval = array.array("d",qcval)
          except TypeError:
            raise TypeError("Argument qcval has wrong type")
          else:
            qcval_ = memoryview(_tmparr_qcval)
      
        else:
          if qcval_.format != "d":
            qcval_ = memoryview(array.array("d",qcval))
      
      res = self.__obj.putqconk(k_,numqcnz_,qcsubi_,qcsubj_,qcval_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putqobj(self,qosubi,qosubj,qoval): # 3
      """
      Replaces all quadratic terms in the objective.
    
      putqobj(self,qosubi,qosubj,qoval)
        qosubi: array of int. Row subscripts for quadratic objective coefficients.
        qosubj: array of int. Column subscripts for quadratic objective coefficients.
        qoval: array of double. Quadratic objective coefficient values.
      """
      numqonz_ = None
      if numqonz_ is None:
        numqonz_ = len(qosubi)
      elif numqonz_ != len(qosubi):
        raise IndexError("Inconsistent length of array qosubi")
      if numqonz_ is None:
        numqonz_ = len(qosubj)
      elif numqonz_ != len(qosubj):
        raise IndexError("Inconsistent length of array qosubj")
      if numqonz_ is None:
        numqonz_ = len(qoval)
      elif numqonz_ != len(qoval):
        raise IndexError("Inconsistent length of array qoval")
      if numqonz_ is None: numqonz_ = 0
      if qosubi is None: raise TypeError("Invalid type for argument qosubi")
      if qosubi is None:
        qosubi_ = None
      else:
        try:
          qosubi_ = memoryview(qosubi)
        except TypeError:
          try:
            _tmparr_qosubi = array.array("i",qosubi)
          except TypeError:
            raise TypeError("Argument qosubi has wrong type")
          else:
            qosubi_ = memoryview(_tmparr_qosubi)
      
        else:
          if qosubi_.format != "i":
            qosubi_ = memoryview(array.array("i",qosubi))
      
      if qosubj is None: raise TypeError("Invalid type for argument qosubj")
      if qosubj is None:
        qosubj_ = None
      else:
        try:
          qosubj_ = memoryview(qosubj)
        except TypeError:
          try:
            _tmparr_qosubj = array.array("i",qosubj)
          except TypeError:
            raise TypeError("Argument qosubj has wrong type")
          else:
            qosubj_ = memoryview(_tmparr_qosubj)
      
        else:
          if qosubj_.format != "i":
            qosubj_ = memoryview(array.array("i",qosubj))
      
      if qoval is None: raise TypeError("Invalid type for argument qoval")
      if qoval is None:
        qoval_ = None
      else:
        try:
          qoval_ = memoryview(qoval)
        except TypeError:
          try:
            _tmparr_qoval = array.array("d",qoval)
          except TypeError:
            raise TypeError("Argument qoval has wrong type")
          else:
            qoval_ = memoryview(_tmparr_qoval)
      
        else:
          if qoval_.format != "d":
            qoval_ = memoryview(array.array("d",qoval))
      
      res = self.__obj.putqobj(numqonz_,qosubi_,qosubj_,qoval_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putqobjij(self,i_,j_,qoij_): # 3
      """
      Replaces one coefficient in the quadratic term in the objective.
    
      putqobjij(self,i_,j_,qoij_)
        i: int. Row index for the coefficient to be replaced.
        j: int. Column index for the coefficient to be replaced.
        qoij: double. The new coefficient value.
      """
      res = self.__obj.putqobjij(i_,j_,qoij_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putsolution(self,whichsol_,skc,skx,skn,xc,xx,y,slc,suc,slx,sux,snx): # 3
      """
      Inserts a solution.
    
      putsolution(self,whichsol_,skc,skx,skn,xc,xx,y,slc,suc,slx,sux,snx)
        whichsol: mosek.soltype. Selects a solution.
        skc: array of mosek.stakey. Status keys for the constraints.
        skx: array of mosek.stakey. Status keys for the variables.
        skn: array of mosek.stakey. Status keys for the conic constraints.
        xc: array of double. Primal constraint solution.
        xx: array of double. Primal variable solution.
        y: array of double. Vector of dual variables corresponding to the constraints.
        slc: array of double. Dual variables corresponding to the lower bounds on the constraints.
        suc: array of double. Dual variables corresponding to the upper bounds on the constraints.
        slx: array of double. Dual variables corresponding to the lower bounds on the variables.
        sux: array of double. Dual variables corresponding to the upper bounds on the variables.
        snx: array of double. Dual variables corresponding to the conic constraints on the variables.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if skc is None:
        skc_ = None
      else:
        try:
          skc_ = memoryview(skc)
        except TypeError:
          try:
            _tmparr_skc = array.array("i",skc)
          except TypeError:
            raise TypeError("Argument skc has wrong type")
          else:
            skc_ = memoryview(_tmparr_skc)
      
        else:
          if skc_.format != "i":
            skc_ = memoryview(array.array("i",skc))
      
      if skx is None:
        skx_ = None
      else:
        try:
          skx_ = memoryview(skx)
        except TypeError:
          try:
            _tmparr_skx = array.array("i",skx)
          except TypeError:
            raise TypeError("Argument skx has wrong type")
          else:
            skx_ = memoryview(_tmparr_skx)
      
        else:
          if skx_.format != "i":
            skx_ = memoryview(array.array("i",skx))
      
      if skn is None:
        skn_ = None
      else:
        try:
          skn_ = memoryview(skn)
        except TypeError:
          try:
            _tmparr_skn = array.array("i",skn)
          except TypeError:
            raise TypeError("Argument skn has wrong type")
          else:
            skn_ = memoryview(_tmparr_skn)
      
        else:
          if skn_.format != "i":
            skn_ = memoryview(array.array("i",skn))
      
      if xc is None:
        xc_ = None
      else:
        try:
          xc_ = memoryview(xc)
        except TypeError:
          try:
            _tmparr_xc = array.array("d",xc)
          except TypeError:
            raise TypeError("Argument xc has wrong type")
          else:
            xc_ = memoryview(_tmparr_xc)
      
        else:
          if xc_.format != "d":
            xc_ = memoryview(array.array("d",xc))
      
      if xx is None:
        xx_ = None
      else:
        try:
          xx_ = memoryview(xx)
        except TypeError:
          try:
            _tmparr_xx = array.array("d",xx)
          except TypeError:
            raise TypeError("Argument xx has wrong type")
          else:
            xx_ = memoryview(_tmparr_xx)
      
        else:
          if xx_.format != "d":
            xx_ = memoryview(array.array("d",xx))
      
      if y is None:
        y_ = None
      else:
        try:
          y_ = memoryview(y)
        except TypeError:
          try:
            _tmparr_y = array.array("d",y)
          except TypeError:
            raise TypeError("Argument y has wrong type")
          else:
            y_ = memoryview(_tmparr_y)
      
        else:
          if y_.format != "d":
            y_ = memoryview(array.array("d",y))
      
      if slc is None:
        slc_ = None
      else:
        try:
          slc_ = memoryview(slc)
        except TypeError:
          try:
            _tmparr_slc = array.array("d",slc)
          except TypeError:
            raise TypeError("Argument slc has wrong type")
          else:
            slc_ = memoryview(_tmparr_slc)
      
        else:
          if slc_.format != "d":
            slc_ = memoryview(array.array("d",slc))
      
      if suc is None:
        suc_ = None
      else:
        try:
          suc_ = memoryview(suc)
        except TypeError:
          try:
            _tmparr_suc = array.array("d",suc)
          except TypeError:
            raise TypeError("Argument suc has wrong type")
          else:
            suc_ = memoryview(_tmparr_suc)
      
        else:
          if suc_.format != "d":
            suc_ = memoryview(array.array("d",suc))
      
      if slx is None:
        slx_ = None
      else:
        try:
          slx_ = memoryview(slx)
        except TypeError:
          try:
            _tmparr_slx = array.array("d",slx)
          except TypeError:
            raise TypeError("Argument slx has wrong type")
          else:
            slx_ = memoryview(_tmparr_slx)
      
        else:
          if slx_.format != "d":
            slx_ = memoryview(array.array("d",slx))
      
      if sux is None:
        sux_ = None
      else:
        try:
          sux_ = memoryview(sux)
        except TypeError:
          try:
            _tmparr_sux = array.array("d",sux)
          except TypeError:
            raise TypeError("Argument sux has wrong type")
          else:
            sux_ = memoryview(_tmparr_sux)
      
        else:
          if sux_.format != "d":
            sux_ = memoryview(array.array("d",sux))
      
      if snx is None:
        snx_ = None
      else:
        try:
          snx_ = memoryview(snx)
        except TypeError:
          try:
            _tmparr_snx = array.array("d",snx)
          except TypeError:
            raise TypeError("Argument snx has wrong type")
          else:
            snx_ = memoryview(_tmparr_snx)
      
        else:
          if snx_.format != "d":
            snx_ = memoryview(array.array("d",snx))
      
      res = self.__obj.putsolution(whichsol_,skc_,skx_,skn_,xc_,xx_,y_,slc_,suc_,slx_,sux_,snx_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putsolutioni(self,accmode_,i_,whichsol_,sk_,x_,sl_,su_,sn_): # 3
      """
      Sets the primal and dual solution information for a single constraint or variable.
    
      putsolutioni(self,accmode_,i_,whichsol_,sk_,x_,sl_,su_,sn_)
        accmode: mosek.accmode. Defines whether solution information for a constraint or for a variable is modified.
        i: int. Index of the constraint or variable.
        whichsol: mosek.soltype. Selects a solution.
        sk: mosek.stakey. Status key of the constraint or variable.
        x: double. Solution value of the primal constraint or variable.
        sl: double. Solution value of the dual variable associated with the lower bound.
        su: double. Solution value of the dual variable associated with the upper bound.
        sn: double. Solution value of the dual variable associated with the conic constraint.
      """
      if not isinstance(accmode_,accmode): raise TypeError("Argument accmode has wrong type")
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      if not isinstance(sk_,stakey): raise TypeError("Argument sk has wrong type")
      res = self.__obj.putsolutioni(accmode_,i_,whichsol_,sk_,x_,sl_,su_,sn_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putsolutionyi(self,i_,whichsol_,y_): # 3
      """
      Inputs the dual variable of a solution.
    
      putsolutionyi(self,i_,whichsol_,y_)
        i: int. Index of the dual variable.
        whichsol: mosek.soltype. Selects a solution.
        y: double. Solution value of the dual variable.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res = self.__obj.putsolutionyi(i_,whichsol_,y_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putstrparam(self,param_,parvalue_): # 3
      """
      Sets a string parameter.
    
      putstrparam(self,param_,parvalue_)
        param: mosek.sparam. Which parameter.
        parvalue: str. Parameter value.
      """
      if not isinstance(param_,sparam): raise TypeError("Argument param has wrong type")
      res = self.__obj.putstrparam(param_,parvalue_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def puttaskname(self,taskname_): # 3
      """
      Assigns a new name to the task.
    
      puttaskname(self,taskname_)
        taskname: str. Name assigned to the task.
      """
      res = self.__obj.puttaskname(taskname_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putvartype(self,j_,vartype_): # 3
      """
      Sets the variable type of one variable.
    
      putvartype(self,j_,vartype_)
        j: int. Index of the variable.
        vartype: mosek.variabletype. The new variable type.
      """
      if not isinstance(vartype_,variabletype): raise TypeError("Argument vartype has wrong type")
      res = self.__obj.putvartype(j_,vartype_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def putvartypelist(self,subj,vartype): # 3
      """
      Sets the variable type for one or more variables.
    
      putvartypelist(self,subj,vartype)
        subj: array of int. A list of variable indexes for which the variable type should be changed.
        vartype: array of mosek.variabletype. A list of variable types.
      """
      num_ = None
      if num_ is None:
        num_ = len(subj)
      elif num_ != len(subj):
        raise IndexError("Inconsistent length of array subj")
      if num_ is None:
        num_ = len(vartype)
      elif num_ != len(vartype):
        raise IndexError("Inconsistent length of array vartype")
      if num_ is None: num_ = 0
      if subj is None: raise TypeError("Invalid type for argument subj")
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
      
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
      
      if vartype is None: raise TypeError("Invalid type for argument vartype")
      if vartype is None:
        vartype_ = None
      else:
        try:
          vartype_ = memoryview(vartype)
        except TypeError:
          try:
            _tmparr_vartype = array.array("i",vartype)
          except TypeError:
            raise TypeError("Argument vartype has wrong type")
          else:
            vartype_ = memoryview(_tmparr_vartype)
      
        else:
          if vartype_.format != "i":
            vartype_ = memoryview(array.array("i",vartype))
      
      res = self.__obj.putvartypelist(num_,subj_,vartype_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def readdataformat(self,filename_,format_,compress_): # 3
      """
      Reads problem data from a file.
    
      readdataformat(self,filename_,format_,compress_)
        filename: str. A valid file name.
        format: mosek.dataformat. File data format.
        compress: mosek.compresstype. File compression type.
      """
      if not isinstance(format_,dataformat): raise TypeError("Argument format has wrong type")
      if not isinstance(compress_,compresstype): raise TypeError("Argument compress has wrong type")
      res = self.__obj.readdataformat(filename_,format_,compress_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def readdata(self,filename_): # 3
      """
      Reads problem data from a file.
    
      readdata(self,filename_)
        filename: str. A valid file name.
      """
      res = self.__obj.readdataautoformat(filename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def readparamfile(self,filename_): # 3
      """
      Reads a parameter file.
    
      readparamfile(self,filename_)
        filename: str. A valid file name.
      """
      res = self.__obj.readparamfile(filename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def readsolution(self,whichsol_,filename_): # 3
      """
      Reads a solution from a file.
    
      readsolution(self,whichsol_,filename_)
        whichsol: mosek.soltype. Selects a solution.
        filename: str. A valid file name.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res = self.__obj.readsolution(whichsol_,filename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def readsummary(self,whichstream_): # 3
      """
      Prints information about last file read.
    
      readsummary(self,whichstream_)
        whichstream: mosek.streamtype. Index of the stream.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      res = self.__obj.readsummary(whichstream_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def resizetask(self,maxnumcon_,maxnumvar_,maxnumcone_,maxnumanz_,maxnumqnz_): # 3
      """
      Resizes an optimization task.
    
      resizetask(self,maxnumcon_,maxnumvar_,maxnumcone_,maxnumanz_,maxnumqnz_)
        maxnumcon: int. New maximum number of constraints.
        maxnumvar: int. New maximum number of variables.
        maxnumcone: int. New maximum number of cones.
        maxnumanz: long. New maximum number of linear non-zero elements.
        maxnumqnz: long. New maximum number of quadratic non-zeros elements.
      """
      res = self.__obj.resizetask(maxnumcon_,maxnumvar_,maxnumcone_,maxnumanz_,maxnumqnz_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def checkmem(self,file_,line_): # 3
      """
      Checks the memory allocated by the task.
    
      checkmem(self,file_,line_)
        file: str. File from which the function is called.
        line: int. Line in the file from which the function is called.
      """
      res = self.__obj.checkmemtask(file_,line_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def getmemusage(self): # 3
      """
      Obtains information about the amount of memory used by a task.
    
      getmemusage(self)
      returns: meminuse,maxmemuse
        meminuse: long. Amount of memory currently used by the task.
        maxmemuse: long. Maximum amount of memory used by the task until now.
      """
      res,resargs = self.__obj.getmemusagetask()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _meminuse_return_value,_maxmemuse_return_value = resargs
      return _meminuse_return_value,_maxmemuse_return_value
    
    def setdefaults(self): # 3
      """
      Resets all parameter values.
    
      setdefaults(self)
      """
      res = self.__obj.setdefaults()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def solutiondef(self,whichsol_): # 3
      """
      Checks whether a solution is defined.
    
      solutiondef(self,whichsol_)
        whichsol: mosek.soltype. Selects a solution.
      returns: isdef
        isdef: int. Is non-zero if the requested solution is defined.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res,resargs = self.__obj.solutiondef(whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _isdef_return_value = resargs
      return _isdef_return_value
    
    def deletesolution(self,whichsol_): # 3
      """
      Undefine a solution and free the memory it uses.
    
      deletesolution(self,whichsol_)
        whichsol: mosek.soltype. Selects a solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res = self.__obj.deletesolution(whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def onesolutionsummary(self,whichstream_,whichsol_): # 3
      """
      Prints a short summary of a specified solution.
    
      onesolutionsummary(self,whichstream_,whichsol_)
        whichstream: mosek.streamtype. Index of the stream.
        whichsol: mosek.soltype. Selects a solution.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res = self.__obj.onesolutionsummary(whichstream_,whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def solutionsummary(self,whichstream_): # 3
      """
      Prints a short summary of the current solutions.
    
      solutionsummary(self,whichstream_)
        whichstream: mosek.streamtype. Index of the stream.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      res = self.__obj.solutionsummary(whichstream_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def updatesolutioninfo(self,whichsol_): # 3
      """
      Update the information items related to the solution.
    
      updatesolutioninfo(self,whichsol_)
        whichsol: mosek.soltype. Selects a solution.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res = self.__obj.updatesolutioninfo(whichsol_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def optimizersummary(self,whichstream_): # 3
      """
      Prints a short summary with optimizer statistics from last optimization.
    
      optimizersummary(self,whichstream_)
        whichstream: mosek.streamtype. Index of the stream.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      res = self.__obj.optimizersummary(whichstream_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def strtoconetype(self,str_): # 3
      """
      Obtains a cone type code.
    
      strtoconetype(self,str_)
        str: str. String corresponding to the cone type code.
      returns: conetype
        conetype: mosek.conetype. The cone type corresponding to str.
      """
      res,resargs = self.__obj.strtoconetype(str_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _conetype_return_value = resargs
      _conetype_return_value = conetype(_conetype_return_value)
      return _conetype_return_value
    
    def strtosk(self,str_): # 3
      """
      Obtains a status key.
    
      strtosk(self,str_)
        str: str. Status key string.
      returns: sk
        sk: int. Status key corresponding to the string.
      """
      res,resargs = self.__obj.strtosk(str_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _sk_return_value = resargs
      return _sk_return_value
    
    def writedata(self,filename_): # 3
      """
      Writes problem data to a file.
    
      writedata(self,filename_)
        filename: str. A valid file name.
      """
      res = self.__obj.writedata(filename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def writetask(self,filename_): # 3
      """
      Write a complete binary dump of the task data.
    
      writetask(self,filename_)
        filename: str. A valid file name.
      """
      res = self.__obj.writetask(filename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def readtask(self,filename_): # 3
      """
      Load task data from a file.
    
      readtask(self,filename_)
        filename: str. A valid file name.
      """
      res = self.__obj.readtask(filename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def writeparamfile(self,filename_): # 3
      """
      Writes all the parameters to a parameter file.
    
      writeparamfile(self,filename_)
        filename: str. A valid file name.
      """
      res = self.__obj.writeparamfile(filename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def writesolution(self,whichsol_,filename_): # 3
      """
      Write a solution to a file.
    
      writesolution(self,whichsol_,filename_)
        whichsol: mosek.soltype. Selects a solution.
        filename: str. A valid file name.
      """
      if not isinstance(whichsol_,soltype): raise TypeError("Argument whichsol has wrong type")
      res = self.__obj.writesolution(whichsol_,filename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def writejsonsol(self,filename_): # 3
      """
      Writes a solution to a JSON file.
    
      writejsonsol(self,filename_)
        filename: str. A valid file name.
      """
      res = self.__obj.writejsonsol(filename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def primalsensitivity(self,subi,marki,subj,markj,leftpricei,rightpricei,leftrangei,rightrangei,leftpricej,rightpricej,leftrangej,rightrangej): # 3
      """
      Perform sensitivity analysis on bounds.
    
      primalsensitivity(self,subi,marki,subj,markj,leftpricei,rightpricei,leftrangei,rightrangei,leftpricej,rightpricej,leftrangej,rightrangej)
        subi: array of int. Indexes of constraints to analyze.
        marki: array of mosek.mark. Mark which constraint bounds to analyze.
        subj: array of int. Indexes of variables to analyze.
        markj: array of mosek.mark. Mark which variable bounds to analyze.
        leftpricei: array of double. Left shadow price for constraints.
        rightpricei: array of double. Right shadow price for constraints.
        leftrangei: array of double. Left range for constraints.
        rightrangei: array of double. Right range for constraints.
        leftpricej: array of double. Left shadow price for variables.
        rightpricej: array of double. Right shadow price for variables.
        leftrangej: array of double. Left range for variables.
        rightrangej: array of double. Right range for variables.
      """
      numi_ = None
      if numi_ is None:
        numi_ = len(subi)
      elif numi_ != len(subi):
        raise IndexError("Inconsistent length of array subi")
      if numi_ is None:
        numi_ = len(marki)
      elif numi_ != len(marki):
        raise IndexError("Inconsistent length of array marki")
      if numi_ is None: numi_ = 0
      if subi is None: raise TypeError("Invalid type for argument subi")
      if subi is None:
        subi_ = None
      else:
        try:
          subi_ = memoryview(subi)
        except TypeError:
          try:
            _tmparr_subi = array.array("i",subi)
          except TypeError:
            raise TypeError("Argument subi has wrong type")
          else:
            subi_ = memoryview(_tmparr_subi)
      
        else:
          if subi_.format != "i":
            subi_ = memoryview(array.array("i",subi))
      
      if marki is None: raise TypeError("Invalid type for argument marki")
      if marki is None:
        marki_ = None
      else:
        try:
          marki_ = memoryview(marki)
        except TypeError:
          try:
            _tmparr_marki = array.array("i",marki)
          except TypeError:
            raise TypeError("Argument marki has wrong type")
          else:
            marki_ = memoryview(_tmparr_marki)
      
        else:
          if marki_.format != "i":
            marki_ = memoryview(array.array("i",marki))
      
      numj_ = None
      if numj_ is None:
        numj_ = len(subj)
      elif numj_ != len(subj):
        raise IndexError("Inconsistent length of array subj")
      if numj_ is None:
        numj_ = len(markj)
      elif numj_ != len(markj):
        raise IndexError("Inconsistent length of array markj")
      if numj_ is None: numj_ = 0
      if subj is None: raise TypeError("Invalid type for argument subj")
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
      
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
      
      if markj is None: raise TypeError("Invalid type for argument markj")
      if markj is None:
        markj_ = None
      else:
        try:
          markj_ = memoryview(markj)
        except TypeError:
          try:
            _tmparr_markj = array.array("i",markj)
          except TypeError:
            raise TypeError("Argument markj has wrong type")
          else:
            markj_ = memoryview(_tmparr_markj)
      
        else:
          if markj_.format != "i":
            markj_ = memoryview(array.array("i",markj))
      
      _copyback_leftpricei = False
      if leftpricei is None:
        leftpricei_ = None
      else:
        try:
          leftpricei_ = memoryview(leftpricei)
        except TypeError:
          try:
            _tmparr_leftpricei = array.array("d",leftpricei)
          except TypeError:
            raise TypeError("Argument leftpricei has wrong type")
          else:
            leftpricei_ = memoryview(_tmparr_leftpricei)
            _copyback_leftpricei = True
        else:
          if leftpricei_.format != "d":
            leftpricei_ = memoryview(array.array("d",leftpricei))
            _copyback_leftpricei = True
      if leftpricei_ is not None and len(leftpricei_) != (numi_):
        raise ValueError("Array argument leftpricei has wrong length")
      _copyback_rightpricei = False
      if rightpricei is None:
        rightpricei_ = None
      else:
        try:
          rightpricei_ = memoryview(rightpricei)
        except TypeError:
          try:
            _tmparr_rightpricei = array.array("d",rightpricei)
          except TypeError:
            raise TypeError("Argument rightpricei has wrong type")
          else:
            rightpricei_ = memoryview(_tmparr_rightpricei)
            _copyback_rightpricei = True
        else:
          if rightpricei_.format != "d":
            rightpricei_ = memoryview(array.array("d",rightpricei))
            _copyback_rightpricei = True
      if rightpricei_ is not None and len(rightpricei_) != (numi_):
        raise ValueError("Array argument rightpricei has wrong length")
      _copyback_leftrangei = False
      if leftrangei is None:
        leftrangei_ = None
      else:
        try:
          leftrangei_ = memoryview(leftrangei)
        except TypeError:
          try:
            _tmparr_leftrangei = array.array("d",leftrangei)
          except TypeError:
            raise TypeError("Argument leftrangei has wrong type")
          else:
            leftrangei_ = memoryview(_tmparr_leftrangei)
            _copyback_leftrangei = True
        else:
          if leftrangei_.format != "d":
            leftrangei_ = memoryview(array.array("d",leftrangei))
            _copyback_leftrangei = True
      if leftrangei_ is not None and len(leftrangei_) != (numi_):
        raise ValueError("Array argument leftrangei has wrong length")
      _copyback_rightrangei = False
      if rightrangei is None:
        rightrangei_ = None
      else:
        try:
          rightrangei_ = memoryview(rightrangei)
        except TypeError:
          try:
            _tmparr_rightrangei = array.array("d",rightrangei)
          except TypeError:
            raise TypeError("Argument rightrangei has wrong type")
          else:
            rightrangei_ = memoryview(_tmparr_rightrangei)
            _copyback_rightrangei = True
        else:
          if rightrangei_.format != "d":
            rightrangei_ = memoryview(array.array("d",rightrangei))
            _copyback_rightrangei = True
      if rightrangei_ is not None and len(rightrangei_) != (numi_):
        raise ValueError("Array argument rightrangei has wrong length")
      _copyback_leftpricej = False
      if leftpricej is None:
        leftpricej_ = None
      else:
        try:
          leftpricej_ = memoryview(leftpricej)
        except TypeError:
          try:
            _tmparr_leftpricej = array.array("d",leftpricej)
          except TypeError:
            raise TypeError("Argument leftpricej has wrong type")
          else:
            leftpricej_ = memoryview(_tmparr_leftpricej)
            _copyback_leftpricej = True
        else:
          if leftpricej_.format != "d":
            leftpricej_ = memoryview(array.array("d",leftpricej))
            _copyback_leftpricej = True
      if leftpricej_ is not None and len(leftpricej_) != (numj_):
        raise ValueError("Array argument leftpricej has wrong length")
      _copyback_rightpricej = False
      if rightpricej is None:
        rightpricej_ = None
      else:
        try:
          rightpricej_ = memoryview(rightpricej)
        except TypeError:
          try:
            _tmparr_rightpricej = array.array("d",rightpricej)
          except TypeError:
            raise TypeError("Argument rightpricej has wrong type")
          else:
            rightpricej_ = memoryview(_tmparr_rightpricej)
            _copyback_rightpricej = True
        else:
          if rightpricej_.format != "d":
            rightpricej_ = memoryview(array.array("d",rightpricej))
            _copyback_rightpricej = True
      if rightpricej_ is not None and len(rightpricej_) != (numj_):
        raise ValueError("Array argument rightpricej has wrong length")
      _copyback_leftrangej = False
      if leftrangej is None:
        leftrangej_ = None
      else:
        try:
          leftrangej_ = memoryview(leftrangej)
        except TypeError:
          try:
            _tmparr_leftrangej = array.array("d",leftrangej)
          except TypeError:
            raise TypeError("Argument leftrangej has wrong type")
          else:
            leftrangej_ = memoryview(_tmparr_leftrangej)
            _copyback_leftrangej = True
        else:
          if leftrangej_.format != "d":
            leftrangej_ = memoryview(array.array("d",leftrangej))
            _copyback_leftrangej = True
      if leftrangej_ is not None and len(leftrangej_) != (numj_):
        raise ValueError("Array argument leftrangej has wrong length")
      _copyback_rightrangej = False
      if rightrangej is None:
        rightrangej_ = None
      else:
        try:
          rightrangej_ = memoryview(rightrangej)
        except TypeError:
          try:
            _tmparr_rightrangej = array.array("d",rightrangej)
          except TypeError:
            raise TypeError("Argument rightrangej has wrong type")
          else:
            rightrangej_ = memoryview(_tmparr_rightrangej)
            _copyback_rightrangej = True
        else:
          if rightrangej_.format != "d":
            rightrangej_ = memoryview(array.array("d",rightrangej))
            _copyback_rightrangej = True
      if rightrangej_ is not None and len(rightrangej_) != (numj_):
        raise ValueError("Array argument rightrangej has wrong length")
      res = self.__obj.primalsensitivity(numi_,subi_,marki_,numj_,subj_,markj_,leftpricei_,rightpricei_,leftrangei_,rightrangei_,leftpricej_,rightpricej_,leftrangej_,rightrangej_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_rightrangej:
        rightrangej[:] = _tmparr_rightrangej
      if _copyback_leftrangej:
        leftrangej[:] = _tmparr_leftrangej
      if _copyback_rightpricej:
        rightpricej[:] = _tmparr_rightpricej
      if _copyback_leftpricej:
        leftpricej[:] = _tmparr_leftpricej
      if _copyback_rightrangei:
        rightrangei[:] = _tmparr_rightrangei
      if _copyback_leftrangei:
        leftrangei[:] = _tmparr_leftrangei
      if _copyback_rightpricei:
        rightpricei[:] = _tmparr_rightpricei
      if _copyback_leftpricei:
        leftpricei[:] = _tmparr_leftpricei
    
    def sensitivityreport(self,whichstream_): # 3
      """
      Creates a sensitivity report.
    
      sensitivityreport(self,whichstream_)
        whichstream: mosek.streamtype. Index of the stream.
      """
      if not isinstance(whichstream_,streamtype): raise TypeError("Argument whichstream has wrong type")
      res = self.__obj.sensitivityreport(whichstream_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def dualsensitivity(self,subj,leftpricej,rightpricej,leftrangej,rightrangej): # 3
      """
      Performs sensitivity analysis on objective coefficients.
    
      dualsensitivity(self,subj,leftpricej,rightpricej,leftrangej,rightrangej)
        subj: array of int. Indexes of objective coefficients to analyze.
        leftpricej: array of double. Left shadow prices for requested coefficients.
        rightpricej: array of double. Right shadow prices for requested coefficients.
        leftrangej: array of double. Left range for requested coefficients.
        rightrangej: array of double. Right range for requested coefficients.
      """
      numj_ = None
      if numj_ is None:
        numj_ = len(subj)
      elif numj_ != len(subj):
        raise IndexError("Inconsistent length of array subj")
      if numj_ is None: numj_ = 0
      if subj is None: raise TypeError("Invalid type for argument subj")
      if subj is None:
        subj_ = None
      else:
        try:
          subj_ = memoryview(subj)
        except TypeError:
          try:
            _tmparr_subj = array.array("i",subj)
          except TypeError:
            raise TypeError("Argument subj has wrong type")
          else:
            subj_ = memoryview(_tmparr_subj)
      
        else:
          if subj_.format != "i":
            subj_ = memoryview(array.array("i",subj))
      
      _copyback_leftpricej = False
      if leftpricej is None:
        leftpricej_ = None
      else:
        try:
          leftpricej_ = memoryview(leftpricej)
        except TypeError:
          try:
            _tmparr_leftpricej = array.array("d",leftpricej)
          except TypeError:
            raise TypeError("Argument leftpricej has wrong type")
          else:
            leftpricej_ = memoryview(_tmparr_leftpricej)
            _copyback_leftpricej = True
        else:
          if leftpricej_.format != "d":
            leftpricej_ = memoryview(array.array("d",leftpricej))
            _copyback_leftpricej = True
      if leftpricej_ is not None and len(leftpricej_) != (numj_):
        raise ValueError("Array argument leftpricej has wrong length")
      _copyback_rightpricej = False
      if rightpricej is None:
        rightpricej_ = None
      else:
        try:
          rightpricej_ = memoryview(rightpricej)
        except TypeError:
          try:
            _tmparr_rightpricej = array.array("d",rightpricej)
          except TypeError:
            raise TypeError("Argument rightpricej has wrong type")
          else:
            rightpricej_ = memoryview(_tmparr_rightpricej)
            _copyback_rightpricej = True
        else:
          if rightpricej_.format != "d":
            rightpricej_ = memoryview(array.array("d",rightpricej))
            _copyback_rightpricej = True
      if rightpricej_ is not None and len(rightpricej_) != (numj_):
        raise ValueError("Array argument rightpricej has wrong length")
      _copyback_leftrangej = False
      if leftrangej is None:
        leftrangej_ = None
      else:
        try:
          leftrangej_ = memoryview(leftrangej)
        except TypeError:
          try:
            _tmparr_leftrangej = array.array("d",leftrangej)
          except TypeError:
            raise TypeError("Argument leftrangej has wrong type")
          else:
            leftrangej_ = memoryview(_tmparr_leftrangej)
            _copyback_leftrangej = True
        else:
          if leftrangej_.format != "d":
            leftrangej_ = memoryview(array.array("d",leftrangej))
            _copyback_leftrangej = True
      if leftrangej_ is not None and len(leftrangej_) != (numj_):
        raise ValueError("Array argument leftrangej has wrong length")
      _copyback_rightrangej = False
      if rightrangej is None:
        rightrangej_ = None
      else:
        try:
          rightrangej_ = memoryview(rightrangej)
        except TypeError:
          try:
            _tmparr_rightrangej = array.array("d",rightrangej)
          except TypeError:
            raise TypeError("Argument rightrangej has wrong type")
          else:
            rightrangej_ = memoryview(_tmparr_rightrangej)
            _copyback_rightrangej = True
        else:
          if rightrangej_.format != "d":
            rightrangej_ = memoryview(array.array("d",rightrangej))
            _copyback_rightrangej = True
      if rightrangej_ is not None and len(rightrangej_) != (numj_):
        raise ValueError("Array argument rightrangej has wrong length")
      res = self.__obj.dualsensitivity(numj_,subj_,leftpricej_,rightpricej_,leftrangej_,rightrangej_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      if _copyback_rightrangej:
        rightrangej[:] = _tmparr_rightrangej
      if _copyback_leftrangej:
        leftrangej[:] = _tmparr_leftrangej
      if _copyback_rightpricej:
        rightpricej[:] = _tmparr_rightpricej
      if _copyback_leftpricej:
        leftpricej[:] = _tmparr_leftpricej
    
    def checkconvexity(self): # 3
      """
      Checks if a quadratic optimization problem is convex.
    
      checkconvexity(self)
      """
      res = self.__obj.checkconvexity()
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def writetasksolverresult_file(self,filename_): # 3
      """
      Internal
    
      writetasksolverresult_file(self,filename_)
        filename: str. A valid file name.
      """
      res = self.__obj.writetasksolverresult_file(filename_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def optimizermt(self,server_,port_): # 3
      """
      Offload the optimization task to a solver server.
    
      optimizermt(self,server_,port_)
        server: str. Name or IP address of the solver server.
        port: str. Network port of the solver server.
      returns: trmcode
        trmcode: mosek.rescode. Is either OK or a termination response code.
      """
      res,resargs = self.__obj.optimizermt(server_,port_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _trmcode_return_value = resargs
      _trmcode_return_value = rescode(_trmcode_return_value)
      return _trmcode_return_value
    
    def asyncoptimize(self,server_,port_): # 3
      """
      Offload the optimization task to a solver server.
    
      asyncoptimize(self,server_,port_)
        server: str. Name or IP address of the solver server
        port: str. Network port of the solver service
      returns: token
        token: str. Returns the task token
      """
      arr_token = array.array("b",[0]*(33))
      memview_arr_token = memoryview(arr_token)
      res,resargs = self.__obj.asyncoptimize(server_,port_,memview_arr_token)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      retarg_token = resargs
      retarg_token = arr_token.tobytes()[:-1].decode("utf-8",errors="ignore")
      return retarg_token
    
    def asyncstop(self,server_,port_,token_): # 3
      """
      Request that the job identified by the token is terminated.
    
      asyncstop(self,server_,port_,token_)
        server: str. Name or IP address of the solver server
        port: str. Network port of the solver service
        token: str. The task token
      """
      res = self.__obj.asyncstop(server_,port_,token_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
    
    def asyncpoll(self,server_,port_,token_): # 3
      """
      Requests information about the status of the remote job.
    
      asyncpoll(self,server_,port_,token_)
        server: str. Name or IP address of the solver server
        port: str. Network port of the solver service
        token: str. The task token
      returns: respavailable,resp,trm
        respavailable: int. Indicates if a remote response is available.
        resp: mosek.rescode. Is the response code from the remote solver.
        trm: mosek.rescode. Is either OK or a termination response code.
      """
      res,resargs = self.__obj.asyncpoll(server_,port_,token_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _respavailable_return_value,_resp_return_value,_trm_return_value = resargs
      _trm_return_value = rescode(_trm_return_value)
      _resp_return_value = rescode(_resp_return_value)
      return _respavailable_return_value,_resp_return_value,_trm_return_value
    
    def asyncgetresult(self,server_,port_,token_): # 3
      """
      Request a response from a remote job.
    
      asyncgetresult(self,server_,port_,token_)
        server: str. Name or IP address of the solver server.
        port: str. Network port of the solver service.
        token: str. The task token.
      returns: respavailable,resp,trm
        respavailable: int. Indicates if a remote response is available.
        resp: mosek.rescode. Is the response code from the remote solver.
        trm: mosek.rescode. Is either OK or a termination response code.
      """
      res,resargs = self.__obj.asyncgetresult(server_,port_,token_)
      if res != 0:
        result,msg = self.__getlasterror(res)
        raise Error(rescode(res),msg)
      _respavailable_return_value,_resp_return_value,_trm_return_value = resargs
      _trm_return_value = rescode(_trm_return_value)
      _resp_return_value = rescode(_resp_return_value)
      return _respavailable_return_value,_resp_return_value,_trm_return_value
    


class LinAlg:
  __env = Env()

  axpy = __env.axpy
  dot  = __env.dot
  gemv = __env.gemv
  gemm = __env.gemm
  syrk = __env.syrk
  syeig = __env.syeig
  syevd = __env.syevd
  potrf = __env.potrf
