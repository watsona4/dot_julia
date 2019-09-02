#ifndef __FUSION_P_H__
#define __FUSION_P_H__
#include "monty.h"
#include "mosektask_p.h"
#include "list"
#include "vector"
#include "unordered_map"
#include "fusion.h"
namespace mosek
{
namespace fusion
{
// mosek.fusion.BaseModel from file 'src/fusion/cxx/BaseModel_p.h'
// namespace mosek::fusion
struct p_BaseModel
{
  p_BaseModel(BaseModel * _pubthis);

  void _initialize( monty::rc_ptr<BaseModel> m);
  void _initialize( const std::string & name,
                    const std::string & licpath);

  virtual ~p_BaseModel() { /* std::cout << "~p_BaseModel()" << std::endl;*/  }

  static p_BaseModel * _get_impl(Model * _inst) { return _inst->_impl; }

  //----------------------

  bool synched;
  std::string taskname;

  monty::rc_ptr<SolutionStruct> sol_itr;
  monty::rc_ptr<SolutionStruct> sol_itg;
  monty::rc_ptr<SolutionStruct> sol_bas;

  //---------------------

  std::unique_ptr<Task> task;

  //---------------------
  void task_setLogHandler (const msghandler_t & handler);
  void task_setDataCallbackHandler (const datacbhandler_t & handler);
  void task_setCallbackHandler (const cbhandler_t & handler);

  int alloc_rangedvar(const std::string & name, double lb, double ub);
  int alloc_linearvar(const std::string & name, mosek::fusion::RelationKey relkey, double bound);
  int task_append_barvar(int size, int num);

  void task_var_name   (int index, const std::string & name);
  void task_con_name   (int index, const std::string & name);
  void task_cone_name  (int index, const std::string & name);
  void task_barvar_name(int index, const std::string & name);
  void task_objectivename(         const std::string & name);

  void task_break_solve();

  //--------------------------

  int task_numvar();
  int task_numcon();
  int task_numcone();
  int task_numbarvar();

  //--------------------------

  void task_put_param(const std::string & name, const std::string & value);
  void task_put_param(const std::string & name, int    value);
  void task_put_param(const std::string & name, double value);
  
  double    task_get_dinf (const std::string & name);
  int       task_get_iinf (const std::string & name);
  long long task_get_liinf(const std::string & name);
  
  //--------------------------
  void task_con_putboundslice_fr(int first, int last); 
  void task_con_putboundslice_lo(int first, int last, const std::shared_ptr<monty::ndarray<double,1>> & rhs);
  void task_con_putboundslice_up(int first, int last, const std::shared_ptr<monty::ndarray<double,1>> & rhs);
  void task_con_putboundslice_ra(int first, int last, const std::shared_ptr<monty::ndarray<double,1>> & lb , 
                                                      const std::shared_ptr<monty::ndarray<double,1>> & ub );
  void task_con_putboundslice_fx(int first, int last, const std::shared_ptr<monty::ndarray<double,1>> & rhs);

  void task_con_putboundlist_lo(const std::shared_ptr<monty::ndarray<int,1>> idxs, const std::shared_ptr<monty::ndarray<double,1>> & rhs);
  void task_con_putboundlist_up(const std::shared_ptr<monty::ndarray<int,1>> idxs, const std::shared_ptr<monty::ndarray<double,1>> & rhs);
  void task_con_putboundlist_fx(const std::shared_ptr<monty::ndarray<int,1>> idxs, const std::shared_ptr<monty::ndarray<double,1>> & rhs);
  void task_con_putboundlist_ra(const std::shared_ptr<monty::ndarray<int,1>> idxs, const std::shared_ptr<monty::ndarray<double,1>> & lb , 
                                                            const std::shared_ptr<monty::ndarray<double,1>> & ub );
  void task_var_putboundslice_fr(int first, int last);
  void task_var_putboundslice_lo(int first, int last, const std::shared_ptr<monty::ndarray<double,1>> & rhs);
  void task_var_putboundslice_up(int first, int last, const std::shared_ptr<monty::ndarray<double,1>> & rhs);
  void task_var_putboundslice_ra(int first, int last, const std::shared_ptr<monty::ndarray<double,1>> & lb, 
                                                      const std::shared_ptr<monty::ndarray<double,1>> & ub);
  void task_var_putboundslice_fx(int first, int last, const std::shared_ptr<monty::ndarray<double,1>> & rhs);
  void task_var_putintlist(const std::shared_ptr<monty::ndarray<int,1>> & idxs);
  void task_var_putcontlist(const std::shared_ptr<monty::ndarray<int,1>> & idxs); 
 
  //--------------------------

  int  task_append_barmatrix
    ( int dim, 
      const std::shared_ptr<monty::ndarray<int,1>>    & subi, 
      const std::shared_ptr<monty::ndarray<int,1>>    & subj, 
      const std::shared_ptr<monty::ndarray<double,1>> & cof);
  int  task_barvar_dim(int j);
  void task_putbaraij (int i, int j, int k);
  void task_putbaraij (int i, int j, const std::shared_ptr<monty::ndarray<int,1>> & k);
  void task_putbarcj  (int j, int k);
  void task_putbarcj  (int j,        const std::shared_ptr<monty::ndarray<int,1>> & k);
  int  task_barvardim (int index);

  int task_append_var(int num);
  int task_append_con(int num);
  int task_append_quadcone (int conesize, int first, int num, int d0, int  d1);
  int task_append_rquadcone(int conesize, int first, int num, int d0, int  d1);

  void task_putarowslice(
    int first, 
    int last, 
    const std::shared_ptr<monty::ndarray<long long,1>> & ptrb, 
    const std::shared_ptr<monty::ndarray<int,1>>       & subj, 
    const std::shared_ptr<monty::ndarray<double,1>>    & cof);
  void task_putaijlist(
    const std::shared_ptr<monty::ndarray<int,1>>       & subi, 
    const std::shared_ptr<monty::ndarray<int,1>>       & subj, 
    const std::shared_ptr<monty::ndarray<double,1>>    & cof, 
    long long                           num);

  void task_setnumvar(int num);
  void task_cleanup(int oldnum, int oldnumcon, int oldnumcone, int oldnumbarvar);
  void task_solve();

  void task_putobjective( 
    bool                             maximize,
    const std::shared_ptr<monty::ndarray<int,1>>    & subj    ,
    const std::shared_ptr<monty::ndarray<double,1>> & cof     ,
    double                           cfix    );

  void task_putobjectivename(const std::string & name);

  void task_write(const std::string & filename);
  void task_dump (const std::string & filename);

  MSKtask_t task_get();
  void dispose();

  void task_putxx_slice(SolutionType which, int first, int last, std::shared_ptr<monty::ndarray<double,1>> & xx);

  static void env_syeig (int n, std::shared_ptr<monty::ndarray<double,1>> & a, std::shared_ptr<monty::ndarray<double,1>> & w);
  static void env_potrf (int n, std::shared_ptr<monty::ndarray<double,1>> & a);                        
  static void env_syevd (int n, std::shared_ptr<monty::ndarray<double,1>> & a, std::shared_ptr<monty::ndarray<double,1>> & w);

  static void env_putlicensecode(std::shared_ptr<monty::ndarray<int,1>> code);
  static void env_putlicensepath(const std::string &licfile);
  static void env_putlicensewait(int wait);

  void convertSolutionStatus(MSKsoltypee soltype, p_SolutionStruct * sol, MSKsolstae status, MSKprostae prosta);


};


// End of file 'src/fusion/cxx/BaseModel_p.h'
struct p_Model : public ::mosek::fusion::p_BaseModel
{
Model * _pubthis;
static mosek::fusion::p_Model* _get_impl(mosek::fusion::Model * _inst){ return static_cast< mosek::fusion::p_Model* >(mosek::fusion::p_BaseModel::_get_impl(_inst)); }
static mosek::fusion::p_Model * _get_impl(mosek::fusion::Model::t _inst) { return _get_impl(_inst.get()); }
p_Model(Model * _pubthis);
virtual ~p_Model() { /* std::cout << "~p_Model" << std::endl;*/ };
int task_vars_used{};int task_vars_allocated{};monty::rc_ptr< ::mosek::fusion::Utils::StringIntMap > con_map{};int cons_used{};std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::ModelConstraint >,1 > > cons{};int vars_used{};std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::ModelVariable >,1 > > vars{};std::shared_ptr< monty::ndarray< bool,1 > > initsol_xx_flag{};std::shared_ptr< monty::ndarray< double,1 > > initsol_xx{};int natbarvarmap_num{};std::shared_ptr< monty::ndarray< int,1 > > natbarvarmap_Var{};monty::rc_ptr< ::mosek::fusion::Utils::StringIntMap > var_map{};int natvarmap_num{};std::shared_ptr< monty::ndarray< long long,1 > > natvarmap_idx{};std::shared_ptr< monty::ndarray< int,1 > > natvarmap_Var{};mosek::fusion::SolutionType solutionptr{};mosek::fusion::AccSolutionStatus acceptable_sol{};std::string model_name{};virtual void destroy();
static Model::t _new_Model(monty::rc_ptr< ::mosek::fusion::Model > _436);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _436);
static Model::t _new_Model();
void _initialize();
static Model::t _new_Model(const std::string &  _443);
void _initialize(const std::string &  _443);
static  void putlicensewait(bool _444);
static  void putlicensepath(const std::string &  _445);
static  void putlicensecode(std::shared_ptr< monty::ndarray< int,1 > > _446);
static  void inst(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _447,int _448,int _449,std::shared_ptr< monty::ndarray< long long,1 > > _450,int _451,std::shared_ptr< monty::ndarray< int,1 > > _452,std::shared_ptr< monty::ndarray< int,1 > > _453,std::shared_ptr< monty::ndarray< int,1 > > _454);
static  void inst(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _475,std::shared_ptr< monty::ndarray< long long,1 > > _476,std::shared_ptr< monty::ndarray< int,1 > > _477,std::shared_ptr< monty::ndarray< int,1 > > _478,std::shared_ptr< monty::ndarray< int,1 > > _479);
virtual void dispose();
virtual void varname(int _482,const std::string &  _483);
virtual void nativeVarToStr(int _484,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _485);
virtual int append_linearvar(monty::rc_ptr< ::mosek::fusion::ModelVariable > _486,long long _487,mosek::fusion::RelationKey _488,double _489);
virtual int append_rangedvar(monty::rc_ptr< ::mosek::fusion::ModelVariable > _491,long long _492,double _493,double _494);
virtual MSKtask_t getTask();
virtual void flushNames();
virtual void writeTask(const std::string &  _498);
virtual long long getSolverLIntInfo(const std::string &  _499);
virtual int getSolverIntInfo(const std::string &  _500);
virtual double getSolverDoubleInfo(const std::string &  _501);
virtual void setCallbackHandler(mosek::cbhandler_t  _502);
virtual void setDataCallbackHandler(mosek::datacbhandler_t  _503);
virtual void setLogHandler(mosek::msghandler_t  _504);
virtual void setSolverParam(const std::string &  _505,double _506);
virtual void setSolverParam(const std::string &  _507,int _508);
virtual void setSolverParam(const std::string &  _509,const std::string &  _510);
virtual void breakSolver();
virtual void solve();
virtual void flushSolutions();
virtual void flush_initsol(mosek::fusion::SolutionType _511);
virtual mosek::fusion::SolutionStatus getDualSolutionStatus();
virtual mosek::fusion::SolutionStatus getPrimalSolutionStatus();
virtual double dualObjValue();
virtual double primalObjValue();
virtual monty::rc_ptr< ::mosek::fusion::SolutionStruct > get_sol_cache(mosek::fusion::SolutionType _519,bool _520,bool _521);
virtual monty::rc_ptr< ::mosek::fusion::SolutionStruct > get_sol_cache(mosek::fusion::SolutionType _526,bool _527);
virtual void setSolution_xx(std::shared_ptr< monty::ndarray< int,1 > > _528,std::shared_ptr< monty::ndarray< double,1 > > _529);
virtual void ensure_initsol_xx();
virtual std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< double,1 > >,1 > > getSolution_bars(mosek::fusion::SolutionType _535);
virtual std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< double,1 > >,1 > > getSolution_barx(mosek::fusion::SolutionType _536);
virtual std::shared_ptr< monty::ndarray< double,1 > > getSolution_y(mosek::fusion::SolutionType _537);
virtual std::shared_ptr< monty::ndarray< double,1 > > getSolution_xc(mosek::fusion::SolutionType _538);
virtual std::shared_ptr< monty::ndarray< double,1 > > getSolution_snx(mosek::fusion::SolutionType _539);
virtual std::shared_ptr< monty::ndarray< double,1 > > getSolution_suc(mosek::fusion::SolutionType _540);
virtual std::shared_ptr< monty::ndarray< double,1 > > getSolution_slc(mosek::fusion::SolutionType _541);
virtual std::shared_ptr< monty::ndarray< double,1 > > getSolution_sux(mosek::fusion::SolutionType _542);
virtual std::shared_ptr< monty::ndarray< double,1 > > getSolution_slx(mosek::fusion::SolutionType _543);
virtual std::shared_ptr< monty::ndarray< double,1 > > getSolution_xx(mosek::fusion::SolutionType _544);
virtual void selectedSolution(mosek::fusion::SolutionType _545);
virtual mosek::fusion::AccSolutionStatus getAcceptedSolutionStatus();
virtual void acceptedSolutionStatus(mosek::fusion::AccSolutionStatus _546);
virtual mosek::fusion::ProblemStatus getProblemStatus(mosek::fusion::SolutionType _547);
virtual mosek::fusion::SolutionStatus getDualSolutionStatus(mosek::fusion::SolutionType _549);
virtual mosek::fusion::SolutionStatus getPrimalSolutionStatus(mosek::fusion::SolutionType _550);
virtual mosek::fusion::SolutionStatus getSolutionStatus(mosek::fusion::SolutionType _551,bool _552);
virtual void objective_(const std::string &  _555,mosek::fusion::ObjectiveSense _556,monty::rc_ptr< ::mosek::fusion::Expression > _557);
virtual void objective(double _595);
virtual void objective(mosek::fusion::ObjectiveSense _596,double _597);
virtual void objective(mosek::fusion::ObjectiveSense _598,monty::rc_ptr< ::mosek::fusion::Variable > _599);
virtual void objective(mosek::fusion::ObjectiveSense _600,monty::rc_ptr< ::mosek::fusion::Expression > _601);
virtual void objective(const std::string &  _602,double _603);
virtual void objective(const std::string &  _604,mosek::fusion::ObjectiveSense _605,double _606);
virtual void objective(const std::string &  _607,mosek::fusion::ObjectiveSense _608,monty::rc_ptr< ::mosek::fusion::Variable > _609);
virtual void objective(const std::string &  _610,mosek::fusion::ObjectiveSense _611,monty::rc_ptr< ::mosek::fusion::Expression > _612);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Variable > _613,monty::rc_ptr< ::mosek::fusion::QConeDomain > _614);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _615,monty::rc_ptr< ::mosek::fusion::Variable > _616,monty::rc_ptr< ::mosek::fusion::QConeDomain > _617);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Set > _618,monty::rc_ptr< ::mosek::fusion::Variable > _619,monty::rc_ptr< ::mosek::fusion::QConeDomain > _620);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _621,monty::rc_ptr< ::mosek::fusion::Set > _622,monty::rc_ptr< ::mosek::fusion::Variable > _623,monty::rc_ptr< ::mosek::fusion::QConeDomain > _624);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Variable > _625,monty::rc_ptr< ::mosek::fusion::RangeDomain > _626);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _627,monty::rc_ptr< ::mosek::fusion::Variable > _628,monty::rc_ptr< ::mosek::fusion::RangeDomain > _629);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Set > _630,monty::rc_ptr< ::mosek::fusion::Variable > _631,monty::rc_ptr< ::mosek::fusion::RangeDomain > _632);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _633,monty::rc_ptr< ::mosek::fusion::Set > _634,monty::rc_ptr< ::mosek::fusion::Variable > _635,monty::rc_ptr< ::mosek::fusion::RangeDomain > _636);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Variable > _637,monty::rc_ptr< ::mosek::fusion::LinearDomain > _638);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _639,monty::rc_ptr< ::mosek::fusion::Variable > _640,monty::rc_ptr< ::mosek::fusion::LinearDomain > _641);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Set > _642,monty::rc_ptr< ::mosek::fusion::Variable > _643,monty::rc_ptr< ::mosek::fusion::LinearDomain > _644);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _645,monty::rc_ptr< ::mosek::fusion::Set > _646,monty::rc_ptr< ::mosek::fusion::Variable > _647,monty::rc_ptr< ::mosek::fusion::LinearDomain > _648);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Variable > _649,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _650);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _651,monty::rc_ptr< ::mosek::fusion::Variable > _652,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _653);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Variable > _654,monty::rc_ptr< ::mosek::fusion::PSDDomain > _655);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _656,monty::rc_ptr< ::mosek::fusion::Variable > _657,monty::rc_ptr< ::mosek::fusion::PSDDomain > _658);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Expression > _659,monty::rc_ptr< ::mosek::fusion::QConeDomain > _660);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _661,monty::rc_ptr< ::mosek::fusion::Expression > _662,monty::rc_ptr< ::mosek::fusion::QConeDomain > _663);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Set > _664,monty::rc_ptr< ::mosek::fusion::Expression > _665,monty::rc_ptr< ::mosek::fusion::QConeDomain > _666);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _667,monty::rc_ptr< ::mosek::fusion::Set > _668,monty::rc_ptr< ::mosek::fusion::Expression > _669,monty::rc_ptr< ::mosek::fusion::QConeDomain > _670);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Expression > _671,monty::rc_ptr< ::mosek::fusion::RangeDomain > _672);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _673,monty::rc_ptr< ::mosek::fusion::Expression > _674,monty::rc_ptr< ::mosek::fusion::RangeDomain > _675);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Set > _676,monty::rc_ptr< ::mosek::fusion::Expression > _677,monty::rc_ptr< ::mosek::fusion::RangeDomain > _678);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _679,monty::rc_ptr< ::mosek::fusion::Set > _680,monty::rc_ptr< ::mosek::fusion::Expression > _681,monty::rc_ptr< ::mosek::fusion::RangeDomain > _682);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Expression > _683,monty::rc_ptr< ::mosek::fusion::LinearDomain > _684);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _685,monty::rc_ptr< ::mosek::fusion::Expression > _686,monty::rc_ptr< ::mosek::fusion::LinearDomain > _687);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Set > _688,monty::rc_ptr< ::mosek::fusion::Expression > _689,monty::rc_ptr< ::mosek::fusion::LinearDomain > _690);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _691,monty::rc_ptr< ::mosek::fusion::Set > _692,monty::rc_ptr< ::mosek::fusion::Expression > _693,monty::rc_ptr< ::mosek::fusion::LinearDomain > _694);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Expression > _695,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _696);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _697,monty::rc_ptr< ::mosek::fusion::Expression > _698,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _699);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(monty::rc_ptr< ::mosek::fusion::Expression > _700,monty::rc_ptr< ::mosek::fusion::PSDDomain > _701);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint(const std::string &  _702,monty::rc_ptr< ::mosek::fusion::Expression > _703,monty::rc_ptr< ::mosek::fusion::PSDDomain > _704);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _705);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(int _706,int _707,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _708);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(int _709,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _710);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _711,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _712);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _713,int _714,int _715,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _716);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _717,int _718,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _719);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _720,monty::rc_ptr< ::mosek::fusion::Set > _721,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _722);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _723,std::shared_ptr< monty::ndarray< int,1 > > _724,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _725);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(monty::rc_ptr< ::mosek::fusion::PSDDomain > _726);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(int _727,int _728,monty::rc_ptr< ::mosek::fusion::PSDDomain > _729);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(int _730,monty::rc_ptr< ::mosek::fusion::PSDDomain > _731);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _732,monty::rc_ptr< ::mosek::fusion::PSDDomain > _733);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _734,int _735,int _736,monty::rc_ptr< ::mosek::fusion::PSDDomain > _737);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _738,int _739,monty::rc_ptr< ::mosek::fusion::PSDDomain > _740);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _741,monty::rc_ptr< ::mosek::fusion::Set > _742,monty::rc_ptr< ::mosek::fusion::PSDDomain > _743);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _744,std::shared_ptr< monty::ndarray< int,1 > > _745,monty::rc_ptr< ::mosek::fusion::PSDDomain > _746);
virtual monty::rc_ptr< ::mosek::fusion::SymmetricVariable > variable(int _747,monty::rc_ptr< ::mosek::fusion::SymmetricLinearDomain > _748);
virtual monty::rc_ptr< ::mosek::fusion::SymmetricVariable > variable(const std::string &  _749,int _750,monty::rc_ptr< ::mosek::fusion::SymmetricLinearDomain > _751);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(monty::rc_ptr< ::mosek::fusion::QConeDomain > _752);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(monty::rc_ptr< ::mosek::fusion::RangeDomain > _753);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(monty::rc_ptr< ::mosek::fusion::LinearDomain > _754);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(std::shared_ptr< monty::ndarray< int,1 > > _755,monty::rc_ptr< ::mosek::fusion::RangeDomain > _756);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(std::shared_ptr< monty::ndarray< int,1 > > _757,monty::rc_ptr< ::mosek::fusion::LinearDomain > _758);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(monty::rc_ptr< ::mosek::fusion::Set > _759,monty::rc_ptr< ::mosek::fusion::QConeDomain > _760);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(monty::rc_ptr< ::mosek::fusion::Set > _761,monty::rc_ptr< ::mosek::fusion::RangeDomain > _762);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(monty::rc_ptr< ::mosek::fusion::Set > _763,monty::rc_ptr< ::mosek::fusion::LinearDomain > _764);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(int _765,monty::rc_ptr< ::mosek::fusion::QConeDomain > _766);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(int _767,monty::rc_ptr< ::mosek::fusion::RangeDomain > _768);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(int _769,monty::rc_ptr< ::mosek::fusion::LinearDomain > _770);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(std::shared_ptr< monty::ndarray< int,1 > > _771);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(int _772);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable();
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _773,monty::rc_ptr< ::mosek::fusion::QConeDomain > _774);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _775,monty::rc_ptr< ::mosek::fusion::RangeDomain > _776);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _777,monty::rc_ptr< ::mosek::fusion::LinearDomain > _778);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _779,std::shared_ptr< monty::ndarray< int,1 > > _780,monty::rc_ptr< ::mosek::fusion::RangeDomain > _781);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _782,std::shared_ptr< monty::ndarray< int,1 > > _783,monty::rc_ptr< ::mosek::fusion::LinearDomain > _784);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _785,monty::rc_ptr< ::mosek::fusion::Set > _786,monty::rc_ptr< ::mosek::fusion::QConeDomain > _787);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _788,monty::rc_ptr< ::mosek::fusion::Set > _789,monty::rc_ptr< ::mosek::fusion::RangeDomain > _790);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _791,monty::rc_ptr< ::mosek::fusion::Set > _792,monty::rc_ptr< ::mosek::fusion::LinearDomain > _793);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _794,int _795,monty::rc_ptr< ::mosek::fusion::QConeDomain > _796);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _797,int _798,monty::rc_ptr< ::mosek::fusion::RangeDomain > _799);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _800,int _801,monty::rc_ptr< ::mosek::fusion::LinearDomain > _802);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _803,std::shared_ptr< monty::ndarray< int,1 > > _804);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _805,int _806);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable(const std::string &  _807);
virtual monty::rc_ptr< ::mosek::fusion::Variable > ranged_variable(const std::string &  _808,int _809,monty::rc_ptr< ::mosek::fusion::SymmetricRangeDomain > _810);
virtual monty::rc_ptr< ::mosek::fusion::Variable > ranged_variable(const std::string &  _829,monty::rc_ptr< ::mosek::fusion::Set > _830,monty::rc_ptr< ::mosek::fusion::RangeDomain > _831);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable_(const std::string &  _848,monty::rc_ptr< ::mosek::fusion::Set > _849,monty::rc_ptr< ::mosek::fusion::QConeDomain > _850);
virtual monty::rc_ptr< ::mosek::fusion::SymmetricVariable > variable_(const std::string &  _874,int _875,monty::rc_ptr< ::mosek::fusion::SymmetricLinearDomain > _876);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable_(const std::string &  _894,monty::rc_ptr< ::mosek::fusion::Set > _895,monty::rc_ptr< ::mosek::fusion::LinearDomain > _896);
virtual monty::rc_ptr< ::mosek::fusion::Variable > variable_(const std::string &  _913,monty::rc_ptr< ::mosek::fusion::Set > _914,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _915);
virtual monty::rc_ptr< ::mosek::fusion::SymmetricVariable > variable_(const std::string &  _923,monty::rc_ptr< ::mosek::fusion::Set > _924,monty::rc_ptr< ::mosek::fusion::PSDDomain > _925);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint_(const std::string &  _930,monty::rc_ptr< ::mosek::fusion::Set > _931,monty::rc_ptr< ::mosek::fusion::Expression > _932,monty::rc_ptr< ::mosek::fusion::RangeDomain > _933);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint_(const std::string &  _956,monty::rc_ptr< ::mosek::fusion::Set > _957,monty::rc_ptr< ::mosek::fusion::Expression > _958,monty::rc_ptr< ::mosek::fusion::QConeDomain > _959);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint_(const std::string &  _994,monty::rc_ptr< ::mosek::fusion::Set > _995,monty::rc_ptr< ::mosek::fusion::Expression > _996,monty::rc_ptr< ::mosek::fusion::LinearDomain > _997);
virtual monty::rc_ptr< ::mosek::fusion::ConNZStruct > build_conA(std::shared_ptr< monty::ndarray< long long,1 > > _1018,long long _1019,std::shared_ptr< monty::ndarray< long long,1 > > _1020,std::shared_ptr< monty::ndarray< long long,1 > > _1021,std::shared_ptr< monty::ndarray< double,1 > > _1022,std::shared_ptr< monty::ndarray< double,1 > > _1023,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _1024);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint_(const std::string &  _1081,monty::rc_ptr< ::mosek::fusion::Expression > _1082,monty::rc_ptr< ::mosek::fusion::LinPSDDomain > _1083);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > constraint_(const std::string &  _1118,monty::rc_ptr< ::mosek::fusion::Expression > _1119,monty::rc_ptr< ::mosek::fusion::PSDDomain > _1120);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > nonsym_psdconstraint(const std::string &  _1133,monty::rc_ptr< ::mosek::fusion::Expression > _1134,monty::rc_ptr< ::mosek::fusion::PSDDomain > _1135);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > sdptrilcon(const std::string &  _1196,int _1197,int _1198,std::shared_ptr< monty::ndarray< long long,1 > > _1199,std::shared_ptr< monty::ndarray< long long,1 > > _1200,std::shared_ptr< monty::ndarray< long long,1 > > _1201,std::shared_ptr< monty::ndarray< long long,1 > > _1202,std::shared_ptr< monty::ndarray< double,1 > > _1203,std::shared_ptr< monty::ndarray< double,1 > > _1204,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _1205);
virtual void addConstraint(const std::string &  _1278,monty::rc_ptr< ::mosek::fusion::ModelConstraint > _1279);
virtual void addVariable(const std::string &  _1283,monty::rc_ptr< ::mosek::fusion::ModelVariable > _1284);
virtual long long numConstraints();
virtual long long numVariables();
virtual bool hasConstraint(const std::string &  _1288);
virtual bool hasVariable(const std::string &  _1289);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > getConstraint(int _1290);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > getConstraint(const std::string &  _1291);
virtual monty::rc_ptr< ::mosek::fusion::Variable > getVariable(int _1292);
virtual monty::rc_ptr< ::mosek::fusion::Variable > getVariable(const std::string &  _1293);
virtual std::string getName();
virtual monty::rc_ptr< ::mosek::fusion::Model > clone();
virtual void natbarvarmap_ensure(int _1294);
virtual void natvarmap_ensure(int _1299);
virtual int task_alloc_vars(int _1304);
}; // struct Model;

// mosek.fusion.Debug from file 'src/fusion/cxx/Debug_p.h'
// namespace mosek::fusion
struct p_Debug
{
  Debug * _pubthis;

  p_Debug(Debug * _pubthis) : _pubthis(_pubthis) {}

  static Debug::t o ()                 { return monty::rc_ptr<Debug>(new Debug()); }
  Debug::t p (const std::string & val) { std::cout << val; return Debug::t(_pubthis); }
  Debug::t p (      int val)           { std::cout << val; return Debug::t(_pubthis); }
  Debug::t p (long long val)           { std::cout << val; return Debug::t(_pubthis); }
  Debug::t p (   double val)           { std::cout << val; return Debug::t(_pubthis); }
  Debug::t p (     bool val)           { std::cout << val; return Debug::t(_pubthis); }
  Debug::t lf()                        { std::cout << std::endl; return Debug::t(_pubthis); }

  static p_Debug * _get_impl(Debug * _inst) { return _inst->ptr.get(); }

  template<typename T>
  Debug::t p(const std::shared_ptr<monty::ndarray<T,1>> & val)
  {
    if (val->size() > 0)
    {
      std::cout << (*val)[0];
      for (int i = 1; i < val->size(); ++i)
        std::cout << "," << (*val)[i];
    }
    return Debug::t(_pubthis);
  }
};
// End of file 'src/fusion/cxx/Debug_p.h'
struct p_Sort
{
Sort * _pubthis;
static mosek::fusion::p_Sort* _get_impl(mosek::fusion::Sort * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_Sort * _get_impl(mosek::fusion::Sort::t _inst) { return _get_impl(_inst.get()); }
p_Sort(Sort * _pubthis);
virtual ~p_Sort() { /* std::cout << "~p_Sort" << std::endl;*/ };
virtual void destroy();
static  void argTransposeSort(std::shared_ptr< monty::ndarray< long long,1 > > _143,std::shared_ptr< monty::ndarray< long long,1 > > _144,int _145,int _146,int _147,std::shared_ptr< monty::ndarray< long long,1 > > _148);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _156,std::shared_ptr< monty::ndarray< long long,1 > > _157);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _158,std::shared_ptr< monty::ndarray< int,1 > > _159);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _160,std::shared_ptr< monty::ndarray< long long,1 > > _161,std::shared_ptr< monty::ndarray< long long,1 > > _162);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _163,std::shared_ptr< monty::ndarray< int,1 > > _164,std::shared_ptr< monty::ndarray< int,1 > > _165);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _166,std::shared_ptr< monty::ndarray< long long,1 > > _167,long long _168,long long _169);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _170,std::shared_ptr< monty::ndarray< int,1 > > _171,long long _172,long long _173);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _174,std::shared_ptr< monty::ndarray< long long,1 > > _175,std::shared_ptr< monty::ndarray< long long,1 > > _176,long long _177,long long _178);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _179,std::shared_ptr< monty::ndarray< int,1 > > _180,std::shared_ptr< monty::ndarray< int,1 > > _181,long long _182,long long _183);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _184,std::shared_ptr< monty::ndarray< long long,1 > > _185,long long _186,long long _187,bool _188);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _191,std::shared_ptr< monty::ndarray< int,1 > > _192,long long _193,long long _194,bool _195);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _198,std::shared_ptr< monty::ndarray< long long,1 > > _199,std::shared_ptr< monty::ndarray< long long,1 > > _200,long long _201,long long _202,bool _203);
static  void argsort(std::shared_ptr< monty::ndarray< long long,1 > > _206,std::shared_ptr< monty::ndarray< int,1 > > _207,std::shared_ptr< monty::ndarray< int,1 > > _208,long long _209,long long _210,bool _211);
static  void argbucketsort(std::shared_ptr< monty::ndarray< long long,1 > > _214,std::shared_ptr< monty::ndarray< long long,1 > > _215,long long _216,long long _217,long long _218,long long _219);
static  void argbucketsort(std::shared_ptr< monty::ndarray< long long,1 > > _220,std::shared_ptr< monty::ndarray< int,1 > > _221,long long _222,long long _223,int _224,int _225);
static  void getminmax(std::shared_ptr< monty::ndarray< long long,1 > > _226,std::shared_ptr< monty::ndarray< long long,1 > > _227,std::shared_ptr< monty::ndarray< long long,1 > > _228,long long _229,long long _230,std::shared_ptr< monty::ndarray< long long,1 > > _231);
static  void getminmax(std::shared_ptr< monty::ndarray< long long,1 > > _234,std::shared_ptr< monty::ndarray< int,1 > > _235,std::shared_ptr< monty::ndarray< int,1 > > _236,long long _237,long long _238,std::shared_ptr< monty::ndarray< int,1 > > _239);
static  bool issorted(std::shared_ptr< monty::ndarray< long long,1 > > _242,std::shared_ptr< monty::ndarray< long long,1 > > _243,long long _244,long long _245,bool _246);
static  bool issorted(std::shared_ptr< monty::ndarray< long long,1 > > _248,std::shared_ptr< monty::ndarray< int,1 > > _249,long long _250,long long _251,bool _252);
static  bool issorted(std::shared_ptr< monty::ndarray< long long,1 > > _254,std::shared_ptr< monty::ndarray< long long,1 > > _255,std::shared_ptr< monty::ndarray< long long,1 > > _256,long long _257,long long _258,bool _259);
static  bool issorted(std::shared_ptr< monty::ndarray< long long,1 > > _261,std::shared_ptr< monty::ndarray< int,1 > > _262,std::shared_ptr< monty::ndarray< int,1 > > _263,long long _264,long long _265,bool _266);
}; // struct Sort;

struct p_IndexCounter
{
IndexCounter * _pubthis;
static mosek::fusion::p_IndexCounter* _get_impl(mosek::fusion::IndexCounter * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_IndexCounter * _get_impl(mosek::fusion::IndexCounter::t _inst) { return _get_impl(_inst.get()); }
p_IndexCounter(IndexCounter * _pubthis);
virtual ~p_IndexCounter() { /* std::cout << "~p_IndexCounter" << std::endl;*/ };
long long start{};std::shared_ptr< monty::ndarray< int,1 > > dims{};std::shared_ptr< monty::ndarray< long long,1 > > strides{};std::shared_ptr< monty::ndarray< long long,1 > > st{};std::shared_ptr< monty::ndarray< int,1 > > ii{};int n{};virtual void destroy();
static IndexCounter::t _new_IndexCounter(monty::rc_ptr< ::mosek::fusion::Set > _268);
void _initialize(monty::rc_ptr< ::mosek::fusion::Set > _268);
static IndexCounter::t _new_IndexCounter(long long _271,std::shared_ptr< monty::ndarray< int,1 > > _272,monty::rc_ptr< ::mosek::fusion::Set > _273);
void _initialize(long long _271,std::shared_ptr< monty::ndarray< int,1 > > _272,monty::rc_ptr< ::mosek::fusion::Set > _273);
static IndexCounter::t _new_IndexCounter(long long _276,std::shared_ptr< monty::ndarray< int,1 > > _277,std::shared_ptr< monty::ndarray< long long,1 > > _278);
void _initialize(long long _276,std::shared_ptr< monty::ndarray< int,1 > > _277,std::shared_ptr< monty::ndarray< long long,1 > > _278);
virtual bool atEnd();
virtual std::shared_ptr< monty::ndarray< int,1 > > getIndex();
virtual long long next();
virtual long long get();
virtual void inc();
virtual void reset();
}; // struct IndexCounter;

struct p_CommonTools
{
CommonTools * _pubthis;
static mosek::fusion::p_CommonTools* _get_impl(mosek::fusion::CommonTools * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_CommonTools * _get_impl(mosek::fusion::CommonTools::t _inst) { return _get_impl(_inst.get()); }
p_CommonTools(CommonTools * _pubthis);
virtual ~p_CommonTools() { /* std::cout << "~p_CommonTools" << std::endl;*/ };
virtual void destroy();
static  void ndIncr(std::shared_ptr< monty::ndarray< int,1 > > _284,std::shared_ptr< monty::ndarray< int,1 > > _285,std::shared_ptr< monty::ndarray< int,1 > > _286);
static  void transposeTriplets(std::shared_ptr< monty::ndarray< int,1 > > _288,std::shared_ptr< monty::ndarray< int,1 > > _289,std::shared_ptr< monty::ndarray< double,1 > > _290,std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< long long,1 > >,1 > > _291,std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< long long,1 > >,1 > > _292,std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< double,1 > >,1 > > _293,long long _294,int _295,int _296);
static  void transposeTriplets(std::shared_ptr< monty::ndarray< int,1 > > _309,std::shared_ptr< monty::ndarray< int,1 > > _310,std::shared_ptr< monty::ndarray< double,1 > > _311,std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< int,1 > >,1 > > _312,std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< int,1 > >,1 > > _313,std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< double,1 > >,1 > > _314,long long _315,int _316,int _317);
static  void tripletSort(std::shared_ptr< monty::ndarray< int,1 > > _330,std::shared_ptr< monty::ndarray< int,1 > > _331,std::shared_ptr< monty::ndarray< double,1 > > _332,std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< int,1 > >,1 > > _333,std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< int,1 > >,1 > > _334,std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< double,1 > >,1 > > _335,long long _336,int _337,int _338);
static  void argMSort(std::shared_ptr< monty::ndarray< int,1 > > _364,std::shared_ptr< monty::ndarray< int,1 > > _365);
static  void mergeInto(std::shared_ptr< monty::ndarray< int,1 > > _370,std::shared_ptr< monty::ndarray< int,1 > > _371,std::shared_ptr< monty::ndarray< int,1 > > _372,int _373,int _374,int _375);
static  void argQsort(std::shared_ptr< monty::ndarray< long long,1 > > _381,std::shared_ptr< monty::ndarray< long long,1 > > _382,std::shared_ptr< monty::ndarray< long long,1 > > _383,long long _384,long long _385);
static  void argQsort(std::shared_ptr< monty::ndarray< long long,1 > > _386,std::shared_ptr< monty::ndarray< int,1 > > _387,std::shared_ptr< monty::ndarray< int,1 > > _388,long long _389,long long _390);
}; // struct CommonTools;

struct p_SolutionStruct
{
SolutionStruct * _pubthis;
static mosek::fusion::p_SolutionStruct* _get_impl(mosek::fusion::SolutionStruct * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_SolutionStruct * _get_impl(mosek::fusion::SolutionStruct::t _inst) { return _get_impl(_inst.get()); }
p_SolutionStruct(SolutionStruct * _pubthis);
virtual ~p_SolutionStruct() { /* std::cout << "~p_SolutionStruct" << std::endl;*/ };
std::shared_ptr< monty::ndarray< double,1 > > snx{};std::shared_ptr< monty::ndarray< double,1 > > sux{};std::shared_ptr< monty::ndarray< double,1 > > slx{};std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< double,1 > >,1 > > bars{};std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< double,1 > >,1 > > barx{};std::shared_ptr< monty::ndarray< double,1 > > y{};std::shared_ptr< monty::ndarray< double,1 > > suc{};std::shared_ptr< monty::ndarray< double,1 > > slc{};std::shared_ptr< monty::ndarray< double,1 > > xx{};std::shared_ptr< monty::ndarray< double,1 > > xc{};double dobj{};double pobj{};mosek::fusion::ProblemStatus probstatus{};mosek::fusion::SolutionStatus dstatus{};mosek::fusion::SolutionStatus pstatus{};int sol_numbarvar{};int sol_numcone{};int sol_numvar{};int sol_numcon{};virtual void destroy();
static SolutionStruct::t _new_SolutionStruct(int _391,int _392,int _393,int _394);
void _initialize(int _391,int _392,int _393,int _394);
static SolutionStruct::t _new_SolutionStruct(monty::rc_ptr< ::mosek::fusion::SolutionStruct > _395);
void _initialize(monty::rc_ptr< ::mosek::fusion::SolutionStruct > _395);
virtual monty::rc_ptr< ::mosek::fusion::SolutionStruct > clone();
virtual void resize(int _398,int _399,int _400,int _401);
virtual bool isDualAcceptable(mosek::fusion::AccSolutionStatus _425);
virtual bool isPrimalAcceptable(mosek::fusion::AccSolutionStatus _426);
virtual bool isAcceptable(mosek::fusion::SolutionStatus _427,mosek::fusion::AccSolutionStatus _428);
}; // struct SolutionStruct;

struct p_ConNZStruct
{
ConNZStruct * _pubthis;
static mosek::fusion::p_ConNZStruct* _get_impl(mosek::fusion::ConNZStruct * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_ConNZStruct * _get_impl(mosek::fusion::ConNZStruct::t _inst) { return _get_impl(_inst.get()); }
p_ConNZStruct(ConNZStruct * _pubthis);
virtual ~p_ConNZStruct() { /* std::cout << "~p_ConNZStruct" << std::endl;*/ };
std::shared_ptr< monty::ndarray< int,1 > > barmidx{};std::shared_ptr< monty::ndarray< int,1 > > barsubj{};std::shared_ptr< monty::ndarray< int,1 > > barsubi{};std::shared_ptr< monty::ndarray< double,1 > > bfix{};std::shared_ptr< monty::ndarray< double,1 > > cof{};std::shared_ptr< monty::ndarray< int,1 > > subj{};std::shared_ptr< monty::ndarray< long long,1 > > ptrb{};virtual void destroy();
static ConNZStruct::t _new_ConNZStruct(std::shared_ptr< monty::ndarray< long long,1 > > _429,std::shared_ptr< monty::ndarray< int,1 > > _430,std::shared_ptr< monty::ndarray< double,1 > > _431,std::shared_ptr< monty::ndarray< double,1 > > _432,std::shared_ptr< monty::ndarray< int,1 > > _433,std::shared_ptr< monty::ndarray< int,1 > > _434,std::shared_ptr< monty::ndarray< int,1 > > _435);
void _initialize(std::shared_ptr< monty::ndarray< long long,1 > > _429,std::shared_ptr< monty::ndarray< int,1 > > _430,std::shared_ptr< monty::ndarray< double,1 > > _431,std::shared_ptr< monty::ndarray< double,1 > > _432,std::shared_ptr< monty::ndarray< int,1 > > _433,std::shared_ptr< monty::ndarray< int,1 > > _434,std::shared_ptr< monty::ndarray< int,1 > > _435);
}; // struct ConNZStruct;

struct p_BaseVariable : public /*implements*/ ::mosek::fusion::Variable
{
BaseVariable * _pubthis;
static mosek::fusion::p_BaseVariable* _get_impl(mosek::fusion::BaseVariable * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_BaseVariable * _get_impl(mosek::fusion::BaseVariable::t _inst) { return _get_impl(_inst.get()); }
p_BaseVariable(BaseVariable * _pubthis);
virtual ~p_BaseVariable() { /* std::cout << "~p_BaseVariable" << std::endl;*/ };
monty::rc_ptr< ::mosek::fusion::Model > model{};monty::rc_ptr< ::mosek::fusion::Set > shape_p{};virtual void destroy();
static BaseVariable::t _new_BaseVariable(monty::rc_ptr< ::mosek::fusion::BaseVariable > _2669,monty::rc_ptr< ::mosek::fusion::Model > _2670);
void _initialize(monty::rc_ptr< ::mosek::fusion::BaseVariable > _2669,monty::rc_ptr< ::mosek::fusion::Model > _2670);
static BaseVariable::t _new_BaseVariable(monty::rc_ptr< ::mosek::fusion::Model > _2671,monty::rc_ptr< ::mosek::fusion::Set > _2672);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _2671,monty::rc_ptr< ::mosek::fusion::Set > _2672);
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _2673,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2674);
virtual void elementName(long long _2675,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2676) { throw monty::AbstractClassError("Call to abstract method"); }
virtual std::string toString();
virtual void inst(std::shared_ptr< monty::ndarray< long long,1 > > _2682,int _2683,int _2684,long long _2685,long long _2686,std::shared_ptr< monty::ndarray< int,1 > > _2687,std::shared_ptr< monty::ndarray< int,1 > > _2688,std::shared_ptr< monty::ndarray< int,1 > > _2689);
virtual void inst(long long _2691,long long _2692,std::shared_ptr< monty::ndarray< int,1 > > _2693,std::shared_ptr< monty::ndarray< int,1 > > _2694,std::shared_ptr< monty::ndarray< int,1 > > _2695) { throw monty::AbstractClassError("Call to abstract method"); }
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _2696,std::shared_ptr< monty::ndarray< double,1 > > _2697,bool _2698) { throw monty::AbstractClassError("Call to abstract method"); }
virtual void set_values(long long _2699,std::shared_ptr< monty::ndarray< int,1 > > _2700,std::shared_ptr< monty::ndarray< long long,1 > > _2701,int _2702,std::shared_ptr< monty::ndarray< double,1 > > _2703,bool _2704) { throw monty::AbstractClassError("Call to abstract method"); }
virtual void values(int _2705,std::shared_ptr< monty::ndarray< double,1 > > _2706,bool _2707);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _2712,int _2713,std::shared_ptr< monty::ndarray< double,1 > > _2714,bool _2715) { throw monty::AbstractClassError("Call to abstract method"); }
virtual void values(long long _2716,std::shared_ptr< monty::ndarray< int,1 > > _2717,std::shared_ptr< monty::ndarray< long long,1 > > _2718,int _2719,std::shared_ptr< monty::ndarray< double,1 > > _2720,bool _2721) { throw monty::AbstractClassError("Call to abstract method"); }
virtual void setLevel(std::shared_ptr< monty::ndarray< double,1 > > _2722);
virtual monty::rc_ptr< ::mosek::fusion::Model > getModel();
virtual monty::rc_ptr< ::mosek::fusion::Set > shape();
virtual monty::rc_ptr< ::mosek::fusion::Set > getShape();
virtual long long size();
virtual std::shared_ptr< monty::ndarray< double,1 > > dual();
virtual std::shared_ptr< monty::ndarray< double,1 > > level();
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _2727) { throw monty::AbstractClassError("Call to abstract method"); }
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _2728) { throw monty::AbstractClassError("Call to abstract method"); }
virtual void makeContinuous();
virtual void makeInteger();
virtual monty::rc_ptr< ::mosek::fusion::Variable > transpose();
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2731,int _2732,int _2733);
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2734,int _2735);
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(std::shared_ptr< monty::ndarray< int,1 > > _2736);
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2737);
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2738,std::shared_ptr< monty::ndarray< int,1 > > _2739,std::shared_ptr< monty::ndarray< int,1 > > _2740);
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2742,std::shared_ptr< monty::ndarray< int,1 > > _2743);
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,2 > > _2745);
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2748);
virtual monty::rc_ptr< ::mosek::fusion::Variable > antidiag(int _2750);
virtual monty::rc_ptr< ::mosek::fusion::Variable > antidiag();
virtual monty::rc_ptr< ::mosek::fusion::Variable > diag(int _2751);
virtual monty::rc_ptr< ::mosek::fusion::Variable > diag();
virtual monty::rc_ptr< ::mosek::fusion::Variable > general_diag(std::shared_ptr< monty::ndarray< int,1 > > _2752,std::shared_ptr< monty::ndarray< int,1 > > _2753);
virtual monty::rc_ptr< ::mosek::fusion::Expression > asExpr();
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(std::shared_ptr< monty::ndarray< int,1 > > _2766,std::shared_ptr< monty::ndarray< int,1 > > _2767);
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(int _2770,int _2771);
}; // struct BaseVariable;

struct p_CompoundVariable : public ::mosek::fusion::p_BaseVariable
{
CompoundVariable * _pubthis;
static mosek::fusion::p_CompoundVariable* _get_impl(mosek::fusion::CompoundVariable * _inst){ return static_cast< mosek::fusion::p_CompoundVariable* >(mosek::fusion::p_BaseVariable::_get_impl(_inst)); }
static mosek::fusion::p_CompoundVariable * _get_impl(mosek::fusion::CompoundVariable::t _inst) { return _get_impl(_inst.get()); }
p_CompoundVariable(CompoundVariable * _pubthis);
virtual ~p_CompoundVariable() { /* std::cout << "~p_CompoundVariable" << std::endl;*/ };
int stackdim{};std::shared_ptr< monty::ndarray< int,1 > > varsb{};std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > vars{};virtual void destroy();
static CompoundVariable::t _new_CompoundVariable(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _1307,int _1308);
void _initialize(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _1307,int _1308);
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _1314,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _1315);
virtual void elementName(long long _1318,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _1319);
virtual void inst(long long _1322,long long _1323,std::shared_ptr< monty::ndarray< int,1 > > _1324,std::shared_ptr< monty::ndarray< int,1 > > _1325,std::shared_ptr< monty::ndarray< int,1 > > _1326);
virtual void set_values(long long _1329,std::shared_ptr< monty::ndarray< int,1 > > _1330,std::shared_ptr< monty::ndarray< long long,1 > > _1331,int _1332,std::shared_ptr< monty::ndarray< double,1 > > _1333,bool _1334);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _1352,std::shared_ptr< monty::ndarray< double,1 > > _1353,bool _1354);
virtual void values(long long _1362,std::shared_ptr< monty::ndarray< int,1 > > _1363,std::shared_ptr< monty::ndarray< long long,1 > > _1364,int _1365,std::shared_ptr< monty::ndarray< double,1 > > _1366,bool _1367);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _1382,int _1383,std::shared_ptr< monty::ndarray< double,1 > > _1384,bool _1385);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _1392);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _1399);
virtual monty::rc_ptr< ::mosek::fusion::Expression > asExpr();
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(std::shared_ptr< monty::ndarray< int,1 > > _1426,std::shared_ptr< monty::ndarray< int,1 > > _1427);
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(int _1445,int _1446);
static  monty::rc_ptr< ::mosek::fusion::Set > compute_shape(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _1454,int _1455);
static  monty::rc_ptr< ::mosek::fusion::Model > model_from_var(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _1463);
}; // struct CompoundVariable;

struct p_RepeatVariable : public ::mosek::fusion::p_BaseVariable
{
RepeatVariable * _pubthis;
static mosek::fusion::p_RepeatVariable* _get_impl(mosek::fusion::RepeatVariable * _inst){ return static_cast< mosek::fusion::p_RepeatVariable* >(mosek::fusion::p_BaseVariable::_get_impl(_inst)); }
static mosek::fusion::p_RepeatVariable * _get_impl(mosek::fusion::RepeatVariable::t _inst) { return _get_impl(_inst.get()); }
p_RepeatVariable(RepeatVariable * _pubthis);
virtual ~p_RepeatVariable() { /* std::cout << "~p_RepeatVariable" << std::endl;*/ };
long long d2{};long long d1{};long long d0{};int dim{};int count{};long long xsize{};std::shared_ptr< monty::ndarray< int,1 > > xdims{};monty::rc_ptr< ::mosek::fusion::Variable > x{};virtual void destroy();
static RepeatVariable::t _new_RepeatVariable(monty::rc_ptr< ::mosek::fusion::Variable > _1464,int _1465,int _1466);
void _initialize(monty::rc_ptr< ::mosek::fusion::Variable > _1464,int _1465,int _1466);
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _1473,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _1474);
virtual void elementName(long long _1479,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _1480);
virtual void inst(long long _1485,long long _1486,std::shared_ptr< monty::ndarray< int,1 > > _1487,std::shared_ptr< monty::ndarray< int,1 > > _1488,std::shared_ptr< monty::ndarray< int,1 > > _1489);
virtual void set_values(long long _1494,std::shared_ptr< monty::ndarray< int,1 > > _1495,std::shared_ptr< monty::ndarray< long long,1 > > _1496,int _1497,std::shared_ptr< monty::ndarray< double,1 > > _1498,bool _1499);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _1514,std::shared_ptr< monty::ndarray< double,1 > > _1515,bool _1516);
virtual void values(long long _1525,std::shared_ptr< monty::ndarray< int,1 > > _1526,std::shared_ptr< monty::ndarray< long long,1 > > _1527,int _1528,std::shared_ptr< monty::ndarray< double,1 > > _1529,bool _1530);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _1544,int _1545,std::shared_ptr< monty::ndarray< double,1 > > _1546,bool _1547);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _1556);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _1565);
static  monty::rc_ptr< ::mosek::fusion::Set > compute_shape(monty::rc_ptr< ::mosek::fusion::Variable > _1574,int _1575,int _1576);
}; // struct RepeatVariable;

struct p_PickVariable : public ::mosek::fusion::p_BaseVariable
{
PickVariable * _pubthis;
static mosek::fusion::p_PickVariable* _get_impl(mosek::fusion::PickVariable * _inst){ return static_cast< mosek::fusion::p_PickVariable* >(mosek::fusion::p_BaseVariable::_get_impl(_inst)); }
static mosek::fusion::p_PickVariable * _get_impl(mosek::fusion::PickVariable::t _inst) { return _get_impl(_inst.get()); }
p_PickVariable(PickVariable * _pubthis);
virtual ~p_PickVariable() { /* std::cout << "~p_PickVariable" << std::endl;*/ };
std::shared_ptr< monty::ndarray< long long,1 > > indexes{};monty::rc_ptr< ::mosek::fusion::Variable > origin{};virtual void destroy();
static PickVariable::t _new_PickVariable(monty::rc_ptr< ::mosek::fusion::Variable > _1585,std::shared_ptr< monty::ndarray< long long,1 > > _1586);
void _initialize(monty::rc_ptr< ::mosek::fusion::Variable > _1585,std::shared_ptr< monty::ndarray< long long,1 > > _1586);
virtual void inst(long long _1589,long long _1590,std::shared_ptr< monty::ndarray< int,1 > > _1591,std::shared_ptr< monty::ndarray< int,1 > > _1592,std::shared_ptr< monty::ndarray< int,1 > > _1593);
virtual void set_values(long long _1594,std::shared_ptr< monty::ndarray< int,1 > > _1595,std::shared_ptr< monty::ndarray< long long,1 > > _1596,int _1597,std::shared_ptr< monty::ndarray< double,1 > > _1598,bool _1599);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _1602,std::shared_ptr< monty::ndarray< double,1 > > _1603,bool _1604);
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _1606,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _1607);
virtual void elementName(long long _1608,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _1609);
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(int _1610,int _1611);
virtual void values(long long _1613,std::shared_ptr< monty::ndarray< int,1 > > _1614,std::shared_ptr< monty::ndarray< long long,1 > > _1615,int _1616,std::shared_ptr< monty::ndarray< double,1 > > _1617,bool _1618);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _1621,int _1622,std::shared_ptr< monty::ndarray< double,1 > > _1623,bool _1624);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _1627);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _1629);
}; // struct PickVariable;

struct p_SliceVariable : public ::mosek::fusion::p_BaseVariable
{
SliceVariable * _pubthis;
static mosek::fusion::p_SliceVariable* _get_impl(mosek::fusion::SliceVariable * _inst){ return static_cast< mosek::fusion::p_SliceVariable* >(mosek::fusion::p_BaseVariable::_get_impl(_inst)); }
static mosek::fusion::p_SliceVariable * _get_impl(mosek::fusion::SliceVariable::t _inst) { return _get_impl(_inst.get()); }
p_SliceVariable(SliceVariable * _pubthis);
virtual ~p_SliceVariable() { /* std::cout << "~p_SliceVariable" << std::endl;*/ };
std::shared_ptr< monty::ndarray< long long,1 > > strides{};long long first{};monty::rc_ptr< ::mosek::fusion::Variable > origin{};virtual void destroy();
static SliceVariable::t _new_SliceVariable(monty::rc_ptr< ::mosek::fusion::Variable > _1631,monty::rc_ptr< ::mosek::fusion::Set > _1632,long long _1633,std::shared_ptr< monty::ndarray< long long,1 > > _1634);
void _initialize(monty::rc_ptr< ::mosek::fusion::Variable > _1631,monty::rc_ptr< ::mosek::fusion::Set > _1632,long long _1633,std::shared_ptr< monty::ndarray< long long,1 > > _1634);
virtual void inst(long long _1635,long long _1636,std::shared_ptr< monty::ndarray< int,1 > > _1637,std::shared_ptr< monty::ndarray< int,1 > > _1638,std::shared_ptr< monty::ndarray< int,1 > > _1639);
virtual void set_values(long long _1644,std::shared_ptr< monty::ndarray< int,1 > > _1645,std::shared_ptr< monty::ndarray< long long,1 > > _1646,int _1647,std::shared_ptr< monty::ndarray< double,1 > > _1648,bool _1649);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _1668,std::shared_ptr< monty::ndarray< double,1 > > _1669,bool _1670);
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _1676,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _1677);
virtual void elementName(long long _1682,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _1683);
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(std::shared_ptr< monty::ndarray< int,1 > > _1688,std::shared_ptr< monty::ndarray< int,1 > > _1689);
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(int _1693,int _1694);
virtual void values(long long _1695,std::shared_ptr< monty::ndarray< int,1 > > _1696,std::shared_ptr< monty::ndarray< long long,1 > > _1697,int _1698,std::shared_ptr< monty::ndarray< double,1 > > _1699,bool _1700);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _1718,int _1719,std::shared_ptr< monty::ndarray< double,1 > > _1720,bool _1721);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _1727);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _1733);
}; // struct SliceVariable;

struct p_BoundInterfaceVariable : public ::mosek::fusion::p_SliceVariable
{
BoundInterfaceVariable * _pubthis;
static mosek::fusion::p_BoundInterfaceVariable* _get_impl(mosek::fusion::BoundInterfaceVariable * _inst){ return static_cast< mosek::fusion::p_BoundInterfaceVariable* >(mosek::fusion::p_SliceVariable::_get_impl(_inst)); }
static mosek::fusion::p_BoundInterfaceVariable * _get_impl(mosek::fusion::BoundInterfaceVariable::t _inst) { return _get_impl(_inst.get()); }
p_BoundInterfaceVariable(BoundInterfaceVariable * _pubthis);
virtual ~p_BoundInterfaceVariable() { /* std::cout << "~p_BoundInterfaceVariable" << std::endl;*/ };
monty::rc_ptr< ::mosek::fusion::RangedVariable > originvar{};bool islower{};virtual void destroy();
static BoundInterfaceVariable::t _new_BoundInterfaceVariable(monty::rc_ptr< ::mosek::fusion::RangedVariable > _2507,monty::rc_ptr< ::mosek::fusion::Set > _2508,long long _2509,std::shared_ptr< monty::ndarray< long long,1 > > _2510,bool _2511);
void _initialize(monty::rc_ptr< ::mosek::fusion::RangedVariable > _2507,monty::rc_ptr< ::mosek::fusion::Set > _2508,long long _2509,std::shared_ptr< monty::ndarray< long long,1 > > _2510,bool _2511);
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice_(monty::rc_ptr< ::mosek::fusion::Set > _2512,long long _2513,std::shared_ptr< monty::ndarray< long long,1 > > _2514);
virtual void dual_values(long long _2515,std::shared_ptr< monty::ndarray< int,1 > > _2516,std::shared_ptr< monty::ndarray< long long,1 > > _2517,int _2518,std::shared_ptr< monty::ndarray< double,1 > > _2519);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _2520,int _2521,std::shared_ptr< monty::ndarray< double,1 > > _2522);
}; // struct BoundInterfaceVariable;

struct p_ModelVariable : public ::mosek::fusion::p_BaseVariable
{
ModelVariable * _pubthis;
static mosek::fusion::p_ModelVariable* _get_impl(mosek::fusion::ModelVariable * _inst){ return static_cast< mosek::fusion::p_ModelVariable* >(mosek::fusion::p_BaseVariable::_get_impl(_inst)); }
static mosek::fusion::p_ModelVariable * _get_impl(mosek::fusion::ModelVariable::t _inst) { return _get_impl(_inst.get()); }
p_ModelVariable(ModelVariable * _pubthis);
virtual ~p_ModelVariable() { /* std::cout << "~p_ModelVariable" << std::endl;*/ };
long long varid{};std::string name{};virtual void destroy();
static ModelVariable::t _new_ModelVariable(monty::rc_ptr< ::mosek::fusion::ModelVariable > _2603,monty::rc_ptr< ::mosek::fusion::Model > _2604);
void _initialize(monty::rc_ptr< ::mosek::fusion::ModelVariable > _2603,monty::rc_ptr< ::mosek::fusion::Model > _2604);
static ModelVariable::t _new_ModelVariable(monty::rc_ptr< ::mosek::fusion::Model > _2605,const std::string &  _2606,monty::rc_ptr< ::mosek::fusion::Set > _2607,long long _2608);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _2605,const std::string &  _2606,monty::rc_ptr< ::mosek::fusion::Set > _2607,long long _2608);
virtual void flushNames() { throw monty::AbstractClassError("Call to abstract method"); }
virtual void elementName(long long _2609,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2610);
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(std::shared_ptr< monty::ndarray< int,1 > > _2611,std::shared_ptr< monty::ndarray< int,1 > > _2612);
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(int _2618,int _2619);
virtual monty::rc_ptr< ::mosek::fusion::ModelVariable > clone(monty::rc_ptr< ::mosek::fusion::Model > _2621) { throw monty::AbstractClassError("Call to abstract method"); }
}; // struct ModelVariable;

struct p_SymRangedVariable : public ::mosek::fusion::p_ModelVariable, public /*implements*/ ::mosek::fusion::SymmetricVariable
{
SymRangedVariable * _pubthis;
static mosek::fusion::p_SymRangedVariable* _get_impl(mosek::fusion::SymRangedVariable * _inst){ return static_cast< mosek::fusion::p_SymRangedVariable* >(mosek::fusion::p_ModelVariable::_get_impl(_inst)); }
static mosek::fusion::p_SymRangedVariable * _get_impl(mosek::fusion::SymRangedVariable::t _inst) { return _get_impl(_inst.get()); }
p_SymRangedVariable(SymRangedVariable * _pubthis);
virtual ~p_SymRangedVariable() { /* std::cout << "~p_SymRangedVariable" << std::endl;*/ };
int dim{};bool names_flushed{};std::shared_ptr< monty::ndarray< int,1 > > nativeidxs{};monty::rc_ptr< ::mosek::fusion::RangeDomain > dom{};monty::rc_ptr< ::mosek::fusion::Utils::IntMap > idxmap{};virtual void destroy();
static SymRangedVariable::t _new_SymRangedVariable(monty::rc_ptr< ::mosek::fusion::SymRangedVariable > _1739,monty::rc_ptr< ::mosek::fusion::Model > _1740);
void _initialize(monty::rc_ptr< ::mosek::fusion::SymRangedVariable > _1739,monty::rc_ptr< ::mosek::fusion::Model > _1740);
static SymRangedVariable::t _new_SymRangedVariable(monty::rc_ptr< ::mosek::fusion::Model > _1742,const std::string &  _1743,monty::rc_ptr< ::mosek::fusion::RangeDomain > _1744,int _1745,std::shared_ptr< monty::ndarray< int,1 > > _1746,long long _1747);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _1742,const std::string &  _1743,monty::rc_ptr< ::mosek::fusion::RangeDomain > _1744,int _1745,std::shared_ptr< monty::ndarray< int,1 > > _1746,long long _1747);
virtual std::string toString();
virtual void flushNames();
virtual void inst(std::shared_ptr< monty::ndarray< long long,1 > > _1754,int _1755,int _1756,long long _1757,long long _1758,std::shared_ptr< monty::ndarray< int,1 > > _1759,std::shared_ptr< monty::ndarray< int,1 > > _1760,std::shared_ptr< monty::ndarray< int,1 > > _1761);
virtual void inst(long long _1767,long long _1768,std::shared_ptr< monty::ndarray< int,1 > > _1769,std::shared_ptr< monty::ndarray< int,1 > > _1770,std::shared_ptr< monty::ndarray< int,1 > > _1771);
virtual void dual_u(long long _1776,std::shared_ptr< monty::ndarray< int,1 > > _1777,std::shared_ptr< monty::ndarray< long long,1 > > _1778,int _1779,std::shared_ptr< monty::ndarray< double,1 > > _1780);
virtual void dual_u(std::shared_ptr< monty::ndarray< long long,1 > > _1792,int _1793,std::shared_ptr< monty::ndarray< double,1 > > _1794);
virtual void dual_l(long long _1802,std::shared_ptr< monty::ndarray< int,1 > > _1803,std::shared_ptr< monty::ndarray< long long,1 > > _1804,int _1805,std::shared_ptr< monty::ndarray< double,1 > > _1806);
virtual void dual_l(std::shared_ptr< monty::ndarray< long long,1 > > _1818,int _1819,std::shared_ptr< monty::ndarray< double,1 > > _1820);
virtual void dual_values(long long _1827,std::shared_ptr< monty::ndarray< int,1 > > _1828,std::shared_ptr< monty::ndarray< long long,1 > > _1829,int _1830,std::shared_ptr< monty::ndarray< double,1 > > _1831);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _1843,int _1844,std::shared_ptr< monty::ndarray< double,1 > > _1845);
virtual void set_values(long long _1853,std::shared_ptr< monty::ndarray< int,1 > > _1854,std::shared_ptr< monty::ndarray< long long,1 > > _1855,int _1856,std::shared_ptr< monty::ndarray< double,1 > > _1857,bool _1858);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _1872,std::shared_ptr< monty::ndarray< double,1 > > _1873,bool _1874);
virtual void values(long long _1884,std::shared_ptr< monty::ndarray< int,1 > > _1885,std::shared_ptr< monty::ndarray< long long,1 > > _1886,int _1887,std::shared_ptr< monty::ndarray< double,1 > > _1888,bool _1889);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _1898,int _1899,std::shared_ptr< monty::ndarray< double,1 > > _1900,bool _1901);
virtual long long tril_idx(long long _1908);
virtual long long tril_lin_idx(long long _1911);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _1914);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _1917);
virtual monty::rc_ptr< ::mosek::fusion::ModelVariable > clone(monty::rc_ptr< ::mosek::fusion::Model > _1920);
virtual monty::rc_ptr< ::mosek::fusion::Expression > asExpr() /*override*/
{ return mosek::fusion::p_BaseVariable::asExpr(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(int _2618,int _2619) /*override*/
{ return mosek::fusion::p_ModelVariable::slice(_2618,_2619); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,2 > > _2745) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2745); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2748) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2748); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > antidiag() /*override*/
{ return mosek::fusion::p_BaseVariable::antidiag(); }
virtual void makeContinuous() /*override*/
{ mosek::fusion::p_BaseVariable::makeContinuous(); }
virtual monty::rc_ptr< ::mosek::fusion::Set > shape() /*override*/
{ return mosek::fusion::p_BaseVariable::shape(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2738,std::shared_ptr< monty::ndarray< int,1 > > _2739,std::shared_ptr< monty::ndarray< int,1 > > _2740) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2738,_2739,_2740); }
virtual void elementName(long long _2609,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2610) /*override*/
{ mosek::fusion::p_ModelVariable::elementName(_2609,_2610); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2737) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2737); }
virtual void makeInteger() /*override*/
{ mosek::fusion::p_BaseVariable::makeInteger(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2731,int _2732,int _2733) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2731,_2732,_2733); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > diag() /*override*/
{ return mosek::fusion::p_BaseVariable::diag(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2734,int _2735) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2734,_2735); }
virtual monty::rc_ptr< ::mosek::fusion::Set > getShape() /*override*/
{ return mosek::fusion::p_BaseVariable::getShape(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > transpose() /*override*/
{ return mosek::fusion::p_BaseVariable::transpose(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(std::shared_ptr< monty::ndarray< int,1 > > _2736) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2736); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2742,std::shared_ptr< monty::ndarray< int,1 > > _2743) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2742,_2743); }
virtual std::shared_ptr< monty::ndarray< double,1 > > level() /*override*/
{ return mosek::fusion::p_BaseVariable::level(); }
virtual monty::rc_ptr< ::mosek::fusion::Model > getModel() /*override*/
{ return mosek::fusion::p_BaseVariable::getModel(); }
virtual void setLevel(std::shared_ptr< monty::ndarray< double,1 > > _2722) /*override*/
{ mosek::fusion::p_BaseVariable::setLevel(_2722); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > diag(int _2751) /*override*/
{ return mosek::fusion::p_BaseVariable::diag(_2751); }
virtual std::shared_ptr< monty::ndarray< double,1 > > dual() /*override*/
{ return mosek::fusion::p_BaseVariable::dual(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(std::shared_ptr< monty::ndarray< int,1 > > _2611,std::shared_ptr< monty::ndarray< int,1 > > _2612) /*override*/
{ return mosek::fusion::p_ModelVariable::slice(_2611,_2612); }
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _2673,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2674) /*override*/
{ return mosek::fusion::p_BaseVariable::elementDesc(_2673,_2674); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > antidiag(int _2750) /*override*/
{ return mosek::fusion::p_BaseVariable::antidiag(_2750); }
virtual long long size() /*override*/
{ return mosek::fusion::p_BaseVariable::size(); }
virtual void values(int _2705,std::shared_ptr< monty::ndarray< double,1 > > _2706,bool _2707) /*override*/
{ mosek::fusion::p_BaseVariable::values(_2705,_2706,_2707); }
}; // struct SymRangedVariable;

struct p_RangedVariable : public ::mosek::fusion::p_ModelVariable
{
RangedVariable * _pubthis;
static mosek::fusion::p_RangedVariable* _get_impl(mosek::fusion::RangedVariable * _inst){ return static_cast< mosek::fusion::p_RangedVariable* >(mosek::fusion::p_ModelVariable::_get_impl(_inst)); }
static mosek::fusion::p_RangedVariable * _get_impl(mosek::fusion::RangedVariable::t _inst) { return _get_impl(_inst.get()); }
p_RangedVariable(RangedVariable * _pubthis);
virtual ~p_RangedVariable() { /* std::cout << "~p_RangedVariable" << std::endl;*/ };
bool names_flushed{};std::shared_ptr< monty::ndarray< int,1 > > nativeidxs{};monty::rc_ptr< ::mosek::fusion::RangeDomain > dom{};monty::rc_ptr< ::mosek::fusion::Utils::IntMap > idxmap{};virtual void destroy();
static RangedVariable::t _new_RangedVariable(monty::rc_ptr< ::mosek::fusion::RangedVariable > _1921,monty::rc_ptr< ::mosek::fusion::Model > _1922);
void _initialize(monty::rc_ptr< ::mosek::fusion::RangedVariable > _1921,monty::rc_ptr< ::mosek::fusion::Model > _1922);
static RangedVariable::t _new_RangedVariable(monty::rc_ptr< ::mosek::fusion::Model > _1924,const std::string &  _1925,monty::rc_ptr< ::mosek::fusion::Set > _1926,monty::rc_ptr< ::mosek::fusion::RangeDomain > _1927,std::shared_ptr< monty::ndarray< int,1 > > _1928,long long _1929);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _1924,const std::string &  _1925,monty::rc_ptr< ::mosek::fusion::Set > _1926,monty::rc_ptr< ::mosek::fusion::RangeDomain > _1927,std::shared_ptr< monty::ndarray< int,1 > > _1928,long long _1929);
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _1930,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _1931);
virtual void flushNames();
virtual void inst(std::shared_ptr< monty::ndarray< long long,1 > > _1936,int _1937,int _1938,long long _1939,long long _1940,std::shared_ptr< monty::ndarray< int,1 > > _1941,std::shared_ptr< monty::ndarray< int,1 > > _1942,std::shared_ptr< monty::ndarray< int,1 > > _1943);
virtual void inst(long long _1947,long long _1948,std::shared_ptr< monty::ndarray< int,1 > > _1949,std::shared_ptr< monty::ndarray< int,1 > > _1950,std::shared_ptr< monty::ndarray< int,1 > > _1951);
virtual monty::rc_ptr< ::mosek::fusion::Variable > upperBoundVar();
virtual monty::rc_ptr< ::mosek::fusion::Variable > lowerBoundVar();
virtual void dual_u(long long _1958,std::shared_ptr< monty::ndarray< int,1 > > _1959,std::shared_ptr< monty::ndarray< long long,1 > > _1960,int _1961,std::shared_ptr< monty::ndarray< double,1 > > _1962);
virtual void dual_u(std::shared_ptr< monty::ndarray< long long,1 > > _1973,int _1974,std::shared_ptr< monty::ndarray< double,1 > > _1975);
virtual void dual_l(long long _1982,std::shared_ptr< monty::ndarray< int,1 > > _1983,std::shared_ptr< monty::ndarray< long long,1 > > _1984,int _1985,std::shared_ptr< monty::ndarray< double,1 > > _1986);
virtual void dual_l(std::shared_ptr< monty::ndarray< long long,1 > > _1997,int _1998,std::shared_ptr< monty::ndarray< double,1 > > _1999);
virtual void dual_values(long long _2006,std::shared_ptr< monty::ndarray< int,1 > > _2007,std::shared_ptr< monty::ndarray< long long,1 > > _2008,int _2009,std::shared_ptr< monty::ndarray< double,1 > > _2010);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _2022,int _2023,std::shared_ptr< monty::ndarray< double,1 > > _2024);
virtual void set_values(long long _2032,std::shared_ptr< monty::ndarray< int,1 > > _2033,std::shared_ptr< monty::ndarray< long long,1 > > _2034,int _2035,std::shared_ptr< monty::ndarray< double,1 > > _2036,bool _2037);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _2051,std::shared_ptr< monty::ndarray< double,1 > > _2052,bool _2053);
virtual void values(long long _2063,std::shared_ptr< monty::ndarray< int,1 > > _2064,std::shared_ptr< monty::ndarray< long long,1 > > _2065,int _2066,std::shared_ptr< monty::ndarray< double,1 > > _2067,bool _2068);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _2077,int _2078,std::shared_ptr< monty::ndarray< double,1 > > _2079,bool _2080);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _2085);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _2088);
virtual monty::rc_ptr< ::mosek::fusion::ModelVariable > clone(monty::rc_ptr< ::mosek::fusion::Model > _2091);
}; // struct RangedVariable;

struct p_LinearPSDVariable : public ::mosek::fusion::p_ModelVariable
{
LinearPSDVariable * _pubthis;
static mosek::fusion::p_LinearPSDVariable* _get_impl(mosek::fusion::LinearPSDVariable * _inst){ return static_cast< mosek::fusion::p_LinearPSDVariable* >(mosek::fusion::p_ModelVariable::_get_impl(_inst)); }
static mosek::fusion::p_LinearPSDVariable * _get_impl(mosek::fusion::LinearPSDVariable::t _inst) { return _get_impl(_inst.get()); }
p_LinearPSDVariable(LinearPSDVariable * _pubthis);
virtual ~p_LinearPSDVariable() { /* std::cout << "~p_LinearPSDVariable" << std::endl;*/ };
int numcones{};int coneidx{};int conesize{};int sdpvardim{};int blocksize{};virtual void destroy();
static LinearPSDVariable::t _new_LinearPSDVariable(monty::rc_ptr< ::mosek::fusion::LinearPSDVariable > _2092,monty::rc_ptr< ::mosek::fusion::Model > _2093);
void _initialize(monty::rc_ptr< ::mosek::fusion::LinearPSDVariable > _2092,monty::rc_ptr< ::mosek::fusion::Model > _2093);
static LinearPSDVariable::t _new_LinearPSDVariable(monty::rc_ptr< ::mosek::fusion::Model > _2094,const std::string &  _2095,int _2096,monty::rc_ptr< ::mosek::fusion::Set > _2097,int _2098,long long _2099);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _2094,const std::string &  _2095,int _2096,monty::rc_ptr< ::mosek::fusion::Set > _2097,int _2098,long long _2099);
virtual void flushNames();
virtual std::string toString();
virtual void inst(std::shared_ptr< monty::ndarray< long long,1 > > _2103,int _2104,int _2105,long long _2106,long long _2107,std::shared_ptr< monty::ndarray< int,1 > > _2108,std::shared_ptr< monty::ndarray< int,1 > > _2109,std::shared_ptr< monty::ndarray< int,1 > > _2110);
virtual void inst(long long _2120,long long _2121,std::shared_ptr< monty::ndarray< int,1 > > _2122,std::shared_ptr< monty::ndarray< int,1 > > _2123,std::shared_ptr< monty::ndarray< int,1 > > _2124);
virtual void set_values(long long _2130,std::shared_ptr< monty::ndarray< int,1 > > _2131,std::shared_ptr< monty::ndarray< long long,1 > > _2132,int _2133,std::shared_ptr< monty::ndarray< double,1 > > _2134,bool _2135);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _2136,std::shared_ptr< monty::ndarray< double,1 > > _2137,bool _2138);
virtual void values(long long _2139,std::shared_ptr< monty::ndarray< int,1 > > _2140,std::shared_ptr< monty::ndarray< long long,1 > > _2141,int _2142,std::shared_ptr< monty::ndarray< double,1 > > _2143,bool _2144);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _2153,int _2154,std::shared_ptr< monty::ndarray< double,1 > > _2155,bool _2156);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _2162);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _2163);
virtual monty::rc_ptr< ::mosek::fusion::ModelVariable > clone(monty::rc_ptr< ::mosek::fusion::Model > _2164);
}; // struct LinearPSDVariable;

struct p_PSDVariable : public ::mosek::fusion::p_ModelVariable, public /*implements*/ ::mosek::fusion::SymmetricVariable
{
PSDVariable * _pubthis;
static mosek::fusion::p_PSDVariable* _get_impl(mosek::fusion::PSDVariable * _inst){ return static_cast< mosek::fusion::p_PSDVariable* >(mosek::fusion::p_ModelVariable::_get_impl(_inst)); }
static mosek::fusion::p_PSDVariable * _get_impl(mosek::fusion::PSDVariable::t _inst) { return _get_impl(_inst.get()); }
p_PSDVariable(PSDVariable * _pubthis);
virtual ~p_PSDVariable() { /* std::cout << "~p_PSDVariable" << std::endl;*/ };
int numcones{};int coneidx{};int conesize{};virtual void destroy();
static PSDVariable::t _new_PSDVariable(monty::rc_ptr< ::mosek::fusion::PSDVariable > _2165,monty::rc_ptr< ::mosek::fusion::Model > _2166);
void _initialize(monty::rc_ptr< ::mosek::fusion::PSDVariable > _2165,monty::rc_ptr< ::mosek::fusion::Model > _2166);
static PSDVariable::t _new_PSDVariable(monty::rc_ptr< ::mosek::fusion::Model > _2167,const std::string &  _2168,int _2169,int _2170,int _2171,long long _2172);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _2167,const std::string &  _2168,int _2169,int _2170,int _2171,long long _2172);
virtual void flushNames();
virtual std::string toString();
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _2175,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2176);
virtual void elementName(long long _2182,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2183);
virtual void inst(std::shared_ptr< monty::ndarray< long long,1 > > _2189,int _2190,int _2191,long long _2192,long long _2193,std::shared_ptr< monty::ndarray< int,1 > > _2194,std::shared_ptr< monty::ndarray< int,1 > > _2195,std::shared_ptr< monty::ndarray< int,1 > > _2196);
virtual void inst(long long _2205,long long _2206,std::shared_ptr< monty::ndarray< int,1 > > _2207,std::shared_ptr< monty::ndarray< int,1 > > _2208,std::shared_ptr< monty::ndarray< int,1 > > _2209);
virtual void set_values(long long _2214,std::shared_ptr< monty::ndarray< int,1 > > _2215,std::shared_ptr< monty::ndarray< long long,1 > > _2216,int _2217,std::shared_ptr< monty::ndarray< double,1 > > _2218,bool _2219);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _2220,std::shared_ptr< monty::ndarray< double,1 > > _2221,bool _2222);
virtual void values(long long _2223,std::shared_ptr< monty::ndarray< int,1 > > _2224,std::shared_ptr< monty::ndarray< long long,1 > > _2225,int _2226,std::shared_ptr< monty::ndarray< double,1 > > _2227,bool _2228);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _2240,int _2241,std::shared_ptr< monty::ndarray< double,1 > > _2242,bool _2243);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _2251);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _2252);
virtual monty::rc_ptr< ::mosek::fusion::ModelVariable > clone(monty::rc_ptr< ::mosek::fusion::Model > _2253);
virtual monty::rc_ptr< ::mosek::fusion::Expression > asExpr() /*override*/
{ return mosek::fusion::p_BaseVariable::asExpr(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(int _2618,int _2619) /*override*/
{ return mosek::fusion::p_ModelVariable::slice(_2618,_2619); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,2 > > _2745) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2745); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2748) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2748); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > antidiag() /*override*/
{ return mosek::fusion::p_BaseVariable::antidiag(); }
virtual void makeContinuous() /*override*/
{ mosek::fusion::p_BaseVariable::makeContinuous(); }
virtual monty::rc_ptr< ::mosek::fusion::Set > shape() /*override*/
{ return mosek::fusion::p_BaseVariable::shape(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2738,std::shared_ptr< monty::ndarray< int,1 > > _2739,std::shared_ptr< monty::ndarray< int,1 > > _2740) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2738,_2739,_2740); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2737) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2737); }
virtual void makeInteger() /*override*/
{ mosek::fusion::p_BaseVariable::makeInteger(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2731,int _2732,int _2733) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2731,_2732,_2733); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > diag() /*override*/
{ return mosek::fusion::p_BaseVariable::diag(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2734,int _2735) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2734,_2735); }
virtual monty::rc_ptr< ::mosek::fusion::Set > getShape() /*override*/
{ return mosek::fusion::p_BaseVariable::getShape(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > transpose() /*override*/
{ return mosek::fusion::p_BaseVariable::transpose(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(std::shared_ptr< monty::ndarray< int,1 > > _2736) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2736); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2742,std::shared_ptr< monty::ndarray< int,1 > > _2743) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2742,_2743); }
virtual std::shared_ptr< monty::ndarray< double,1 > > level() /*override*/
{ return mosek::fusion::p_BaseVariable::level(); }
virtual monty::rc_ptr< ::mosek::fusion::Model > getModel() /*override*/
{ return mosek::fusion::p_BaseVariable::getModel(); }
virtual void setLevel(std::shared_ptr< monty::ndarray< double,1 > > _2722) /*override*/
{ mosek::fusion::p_BaseVariable::setLevel(_2722); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > diag(int _2751) /*override*/
{ return mosek::fusion::p_BaseVariable::diag(_2751); }
virtual std::shared_ptr< monty::ndarray< double,1 > > dual() /*override*/
{ return mosek::fusion::p_BaseVariable::dual(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(std::shared_ptr< monty::ndarray< int,1 > > _2611,std::shared_ptr< monty::ndarray< int,1 > > _2612) /*override*/
{ return mosek::fusion::p_ModelVariable::slice(_2611,_2612); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > antidiag(int _2750) /*override*/
{ return mosek::fusion::p_BaseVariable::antidiag(_2750); }
virtual long long size() /*override*/
{ return mosek::fusion::p_BaseVariable::size(); }
virtual void values(int _2705,std::shared_ptr< monty::ndarray< double,1 > > _2706,bool _2707) /*override*/
{ mosek::fusion::p_BaseVariable::values(_2705,_2706,_2707); }
}; // struct PSDVariable;

struct p_SymLinearVariable : public ::mosek::fusion::p_ModelVariable, public /*implements*/ ::mosek::fusion::SymmetricVariable
{
SymLinearVariable * _pubthis;
static mosek::fusion::p_SymLinearVariable* _get_impl(mosek::fusion::SymLinearVariable * _inst){ return static_cast< mosek::fusion::p_SymLinearVariable* >(mosek::fusion::p_ModelVariable::_get_impl(_inst)); }
static mosek::fusion::p_SymLinearVariable * _get_impl(mosek::fusion::SymLinearVariable::t _inst) { return _get_impl(_inst.get()); }
p_SymLinearVariable(SymLinearVariable * _pubthis);
virtual ~p_SymLinearVariable() { /* std::cout << "~p_SymLinearVariable" << std::endl;*/ };
int dim{};bool names_flushed{};monty::rc_ptr< ::mosek::fusion::SymmetricLinearDomain > dom{};std::shared_ptr< monty::ndarray< int,1 > > nativeidxs{};monty::rc_ptr< ::mosek::fusion::Utils::IntMap > idxmap{};virtual void destroy();
static SymLinearVariable::t _new_SymLinearVariable(monty::rc_ptr< ::mosek::fusion::SymLinearVariable > _2254,monty::rc_ptr< ::mosek::fusion::Model > _2255);
void _initialize(monty::rc_ptr< ::mosek::fusion::SymLinearVariable > _2254,monty::rc_ptr< ::mosek::fusion::Model > _2255);
static SymLinearVariable::t _new_SymLinearVariable(monty::rc_ptr< ::mosek::fusion::Model > _2257,const std::string &  _2258,monty::rc_ptr< ::mosek::fusion::SymmetricLinearDomain > _2259,int _2260,std::shared_ptr< monty::ndarray< int,1 > > _2261,long long _2262);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _2257,const std::string &  _2258,monty::rc_ptr< ::mosek::fusion::SymmetricLinearDomain > _2259,int _2260,std::shared_ptr< monty::ndarray< int,1 > > _2261,long long _2262);
virtual std::string toString();
virtual void flushNames();
virtual void inst(std::shared_ptr< monty::ndarray< long long,1 > > _2272,int _2273,int _2274,long long _2275,long long _2276,std::shared_ptr< monty::ndarray< int,1 > > _2277,std::shared_ptr< monty::ndarray< int,1 > > _2278,std::shared_ptr< monty::ndarray< int,1 > > _2279);
virtual void inst(long long _2285,long long _2286,std::shared_ptr< monty::ndarray< int,1 > > _2287,std::shared_ptr< monty::ndarray< int,1 > > _2288,std::shared_ptr< monty::ndarray< int,1 > > _2289);
virtual void dual_values(long long _2293,std::shared_ptr< monty::ndarray< int,1 > > _2294,std::shared_ptr< monty::ndarray< long long,1 > > _2295,int _2296,std::shared_ptr< monty::ndarray< double,1 > > _2297);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _2309,int _2310,std::shared_ptr< monty::ndarray< double,1 > > _2311);
virtual void set_values(long long _2319,std::shared_ptr< monty::ndarray< int,1 > > _2320,std::shared_ptr< monty::ndarray< long long,1 > > _2321,int _2322,std::shared_ptr< monty::ndarray< double,1 > > _2323,bool _2324);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _2338,std::shared_ptr< monty::ndarray< double,1 > > _2339,bool _2340);
virtual void values(long long _2348,std::shared_ptr< monty::ndarray< int,1 > > _2349,std::shared_ptr< monty::ndarray< long long,1 > > _2350,int _2351,std::shared_ptr< monty::ndarray< double,1 > > _2352,bool _2353);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _2363,int _2364,std::shared_ptr< monty::ndarray< double,1 > > _2365,bool _2366);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _2374);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _2377);
virtual long long tril_idx(long long _2380);
virtual long long tril_lin_idx(long long _2383);
virtual monty::rc_ptr< ::mosek::fusion::ModelVariable > clone(monty::rc_ptr< ::mosek::fusion::Model > _2386);
virtual monty::rc_ptr< ::mosek::fusion::Expression > asExpr() /*override*/
{ return mosek::fusion::p_BaseVariable::asExpr(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(int _2618,int _2619) /*override*/
{ return mosek::fusion::p_ModelVariable::slice(_2618,_2619); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,2 > > _2745) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2745); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2748) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2748); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > antidiag() /*override*/
{ return mosek::fusion::p_BaseVariable::antidiag(); }
virtual void makeContinuous() /*override*/
{ mosek::fusion::p_BaseVariable::makeContinuous(); }
virtual monty::rc_ptr< ::mosek::fusion::Set > shape() /*override*/
{ return mosek::fusion::p_BaseVariable::shape(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2738,std::shared_ptr< monty::ndarray< int,1 > > _2739,std::shared_ptr< monty::ndarray< int,1 > > _2740) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2738,_2739,_2740); }
virtual void elementName(long long _2609,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2610) /*override*/
{ mosek::fusion::p_ModelVariable::elementName(_2609,_2610); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2737) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2737); }
virtual void makeInteger() /*override*/
{ mosek::fusion::p_BaseVariable::makeInteger(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2731,int _2732,int _2733) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2731,_2732,_2733); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > diag() /*override*/
{ return mosek::fusion::p_BaseVariable::diag(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2734,int _2735) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2734,_2735); }
virtual monty::rc_ptr< ::mosek::fusion::Set > getShape() /*override*/
{ return mosek::fusion::p_BaseVariable::getShape(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > transpose() /*override*/
{ return mosek::fusion::p_BaseVariable::transpose(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(std::shared_ptr< monty::ndarray< int,1 > > _2736) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2736); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2742,std::shared_ptr< monty::ndarray< int,1 > > _2743) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2742,_2743); }
virtual std::shared_ptr< monty::ndarray< double,1 > > level() /*override*/
{ return mosek::fusion::p_BaseVariable::level(); }
virtual monty::rc_ptr< ::mosek::fusion::Model > getModel() /*override*/
{ return mosek::fusion::p_BaseVariable::getModel(); }
virtual void setLevel(std::shared_ptr< monty::ndarray< double,1 > > _2722) /*override*/
{ mosek::fusion::p_BaseVariable::setLevel(_2722); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > diag(int _2751) /*override*/
{ return mosek::fusion::p_BaseVariable::diag(_2751); }
virtual std::shared_ptr< monty::ndarray< double,1 > > dual() /*override*/
{ return mosek::fusion::p_BaseVariable::dual(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(std::shared_ptr< monty::ndarray< int,1 > > _2611,std::shared_ptr< monty::ndarray< int,1 > > _2612) /*override*/
{ return mosek::fusion::p_ModelVariable::slice(_2611,_2612); }
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _2673,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2674) /*override*/
{ return mosek::fusion::p_BaseVariable::elementDesc(_2673,_2674); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > antidiag(int _2750) /*override*/
{ return mosek::fusion::p_BaseVariable::antidiag(_2750); }
virtual long long size() /*override*/
{ return mosek::fusion::p_BaseVariable::size(); }
virtual void values(int _2705,std::shared_ptr< monty::ndarray< double,1 > > _2706,bool _2707) /*override*/
{ mosek::fusion::p_BaseVariable::values(_2705,_2706,_2707); }
}; // struct SymLinearVariable;

struct p_LinearVariable : public ::mosek::fusion::p_ModelVariable
{
LinearVariable * _pubthis;
static mosek::fusion::p_LinearVariable* _get_impl(mosek::fusion::LinearVariable * _inst){ return static_cast< mosek::fusion::p_LinearVariable* >(mosek::fusion::p_ModelVariable::_get_impl(_inst)); }
static mosek::fusion::p_LinearVariable * _get_impl(mosek::fusion::LinearVariable::t _inst) { return _get_impl(_inst.get()); }
p_LinearVariable(LinearVariable * _pubthis);
virtual ~p_LinearVariable() { /* std::cout << "~p_LinearVariable" << std::endl;*/ };
bool names_flushed{};monty::rc_ptr< ::mosek::fusion::LinearDomain > dom{};std::shared_ptr< monty::ndarray< int,1 > > nativeidxs{};monty::rc_ptr< ::mosek::fusion::Utils::IntMap > idxmap{};virtual void destroy();
static LinearVariable::t _new_LinearVariable(monty::rc_ptr< ::mosek::fusion::LinearVariable > _2387,monty::rc_ptr< ::mosek::fusion::Model > _2388);
void _initialize(monty::rc_ptr< ::mosek::fusion::LinearVariable > _2387,monty::rc_ptr< ::mosek::fusion::Model > _2388);
static LinearVariable::t _new_LinearVariable(monty::rc_ptr< ::mosek::fusion::Model > _2390,const std::string &  _2391,monty::rc_ptr< ::mosek::fusion::LinearDomain > _2392,monty::rc_ptr< ::mosek::fusion::Set > _2393,std::shared_ptr< monty::ndarray< int,1 > > _2394,long long _2395);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _2390,const std::string &  _2391,monty::rc_ptr< ::mosek::fusion::LinearDomain > _2392,monty::rc_ptr< ::mosek::fusion::Set > _2393,std::shared_ptr< monty::ndarray< int,1 > > _2394,long long _2395);
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _2396,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2397);
virtual void elementName(long long _2398,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2399);
virtual void flushNames();
virtual void inst(std::shared_ptr< monty::ndarray< long long,1 > > _2404,int _2405,int _2406,long long _2407,long long _2408,std::shared_ptr< monty::ndarray< int,1 > > _2409,std::shared_ptr< monty::ndarray< int,1 > > _2410,std::shared_ptr< monty::ndarray< int,1 > > _2411);
virtual void inst(long long _2415,long long _2416,std::shared_ptr< monty::ndarray< int,1 > > _2417,std::shared_ptr< monty::ndarray< int,1 > > _2418,std::shared_ptr< monty::ndarray< int,1 > > _2419);
virtual void dual_values(long long _2421,std::shared_ptr< monty::ndarray< int,1 > > _2422,std::shared_ptr< monty::ndarray< long long,1 > > _2423,int _2424,std::shared_ptr< monty::ndarray< double,1 > > _2425);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _2437,int _2438,std::shared_ptr< monty::ndarray< double,1 > > _2439);
virtual void set_values(long long _2447,std::shared_ptr< monty::ndarray< int,1 > > _2448,std::shared_ptr< monty::ndarray< long long,1 > > _2449,int _2450,std::shared_ptr< monty::ndarray< double,1 > > _2451,bool _2452);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _2466,std::shared_ptr< monty::ndarray< double,1 > > _2467,bool _2468);
virtual void values(long long _2478,std::shared_ptr< monty::ndarray< int,1 > > _2479,std::shared_ptr< monty::ndarray< long long,1 > > _2480,int _2481,std::shared_ptr< monty::ndarray< double,1 > > _2482,bool _2483);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _2492);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _2495);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _2498,int _2499,std::shared_ptr< monty::ndarray< double,1 > > _2500,bool _2501);
virtual monty::rc_ptr< ::mosek::fusion::ModelVariable > clone(monty::rc_ptr< ::mosek::fusion::Model > _2506);
}; // struct LinearVariable;

struct p_ConicVariable : public ::mosek::fusion::p_ModelVariable
{
ConicVariable * _pubthis;
static mosek::fusion::p_ConicVariable* _get_impl(mosek::fusion::ConicVariable * _inst){ return static_cast< mosek::fusion::p_ConicVariable* >(mosek::fusion::p_ModelVariable::_get_impl(_inst)); }
static mosek::fusion::p_ConicVariable * _get_impl(mosek::fusion::ConicVariable::t _inst) { return _get_impl(_inst.get()); }
p_ConicVariable(ConicVariable * _pubthis);
virtual ~p_ConicVariable() { /* std::cout << "~p_ConicVariable" << std::endl;*/ };
bool names_flushed{};std::shared_ptr< monty::ndarray< int,1 > > nativeidxs{};monty::rc_ptr< ::mosek::fusion::QConeDomain > dom{};int numcone{};int conesize{};int coneidx{};virtual void destroy();
static ConicVariable::t _new_ConicVariable(monty::rc_ptr< ::mosek::fusion::ConicVariable > _2523,monty::rc_ptr< ::mosek::fusion::Model > _2524);
void _initialize(monty::rc_ptr< ::mosek::fusion::ConicVariable > _2523,monty::rc_ptr< ::mosek::fusion::Model > _2524);
static ConicVariable::t _new_ConicVariable(monty::rc_ptr< ::mosek::fusion::Model > _2526,const std::string &  _2527,monty::rc_ptr< ::mosek::fusion::QConeDomain > _2528,monty::rc_ptr< ::mosek::fusion::Set > _2529,std::shared_ptr< monty::ndarray< int,1 > > _2530,int _2531,int _2532,int _2533,long long _2534);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _2526,const std::string &  _2527,monty::rc_ptr< ::mosek::fusion::QConeDomain > _2528,monty::rc_ptr< ::mosek::fusion::Set > _2529,std::shared_ptr< monty::ndarray< int,1 > > _2530,int _2531,int _2532,int _2533,long long _2534);
virtual std::string toString();
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _2537,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2538);
virtual void elementName(long long _2539,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2540);
virtual void flushNames();
virtual void inst(std::shared_ptr< monty::ndarray< long long,1 > > _2542,int _2543,int _2544,long long _2545,long long _2546,std::shared_ptr< monty::ndarray< int,1 > > _2547,std::shared_ptr< monty::ndarray< int,1 > > _2548,std::shared_ptr< monty::ndarray< int,1 > > _2549);
virtual void inst(long long _2551,long long _2552,std::shared_ptr< monty::ndarray< int,1 > > _2553,std::shared_ptr< monty::ndarray< int,1 > > _2554,std::shared_ptr< monty::ndarray< int,1 > > _2555);
virtual void set_values(long long _2556,std::shared_ptr< monty::ndarray< int,1 > > _2557,std::shared_ptr< monty::ndarray< long long,1 > > _2558,int _2559,std::shared_ptr< monty::ndarray< double,1 > > _2560,bool _2561);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _2571,std::shared_ptr< monty::ndarray< double,1 > > _2572,bool _2573);
virtual void values(long long _2579,std::shared_ptr< monty::ndarray< int,1 > > _2580,std::shared_ptr< monty::ndarray< long long,1 > > _2581,int _2582,std::shared_ptr< monty::ndarray< double,1 > > _2583,bool _2584);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _2591,int _2592,std::shared_ptr< monty::ndarray< double,1 > > _2593,bool _2594);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _2597);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _2599);
virtual int get_variable_index(int _2601);
virtual monty::rc_ptr< ::mosek::fusion::ModelVariable > clone(monty::rc_ptr< ::mosek::fusion::Model > _2602);
}; // struct ConicVariable;

struct p_NilVariable : public ::mosek::fusion::p_BaseVariable, public /*implements*/ ::mosek::fusion::SymmetricVariable
{
NilVariable * _pubthis;
static mosek::fusion::p_NilVariable* _get_impl(mosek::fusion::NilVariable * _inst){ return static_cast< mosek::fusion::p_NilVariable* >(mosek::fusion::p_BaseVariable::_get_impl(_inst)); }
static mosek::fusion::p_NilVariable * _get_impl(mosek::fusion::NilVariable::t _inst) { return _get_impl(_inst.get()); }
p_NilVariable(NilVariable * _pubthis);
virtual ~p_NilVariable() { /* std::cout << "~p_NilVariable" << std::endl;*/ };
virtual void destroy();
static NilVariable::t _new_NilVariable();
void _initialize();
virtual monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > elementDesc(long long _2622,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2623);
virtual void elementName(long long _2624,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2625);
virtual void inst(std::shared_ptr< monty::ndarray< long long,1 > > _2626,int _2627,int _2628,long long _2629,long long _2630,std::shared_ptr< monty::ndarray< int,1 > > _2631,std::shared_ptr< monty::ndarray< int,1 > > _2632,std::shared_ptr< monty::ndarray< int,1 > > _2633);
virtual void inst(long long _2634,long long _2635,std::shared_ptr< monty::ndarray< int,1 > > _2636,std::shared_ptr< monty::ndarray< int,1 > > _2637,std::shared_ptr< monty::ndarray< int,1 > > _2638);
virtual void set_values(std::shared_ptr< monty::ndarray< long long,1 > > _2639,std::shared_ptr< monty::ndarray< double,1 > > _2640,bool _2641);
virtual void set_values(long long _2642,std::shared_ptr< monty::ndarray< int,1 > > _2643,std::shared_ptr< monty::ndarray< long long,1 > > _2644,int _2645,std::shared_ptr< monty::ndarray< double,1 > > _2646,bool _2647);
virtual void values(std::shared_ptr< monty::ndarray< long long,1 > > _2648,int _2649,std::shared_ptr< monty::ndarray< double,1 > > _2650,bool _2651);
virtual void values(long long _2652,std::shared_ptr< monty::ndarray< int,1 > > _2653,std::shared_ptr< monty::ndarray< long long,1 > > _2654,int _2655,std::shared_ptr< monty::ndarray< double,1 > > _2656,bool _2657);
virtual void make_continuous(std::shared_ptr< monty::ndarray< long long,1 > > _2658);
virtual void make_integer(std::shared_ptr< monty::ndarray< long long,1 > > _2659);
virtual void makeContinuous();
virtual void makeInteger();
virtual std::string toString();
virtual long long size();
virtual std::shared_ptr< monty::ndarray< double,1 > > dual();
virtual std::shared_ptr< monty::ndarray< double,1 > > level();
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(std::shared_ptr< monty::ndarray< int,1 > > _2662);
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2663);
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(std::shared_ptr< monty::ndarray< int,1 > > _2664,std::shared_ptr< monty::ndarray< int,1 > > _2665);
virtual monty::rc_ptr< ::mosek::fusion::Variable > slice(int _2667,int _2668);
virtual monty::rc_ptr< ::mosek::fusion::Expression > asExpr() /*override*/
{ return mosek::fusion::p_BaseVariable::asExpr(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,2 > > _2745) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2745); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2748) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2748); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > antidiag() /*override*/
{ return mosek::fusion::p_BaseVariable::antidiag(); }
virtual monty::rc_ptr< ::mosek::fusion::Set > shape() /*override*/
{ return mosek::fusion::p_BaseVariable::shape(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2738,std::shared_ptr< monty::ndarray< int,1 > > _2739,std::shared_ptr< monty::ndarray< int,1 > > _2740) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2738,_2739,_2740); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2731,int _2732,int _2733) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2731,_2732,_2733); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > diag() /*override*/
{ return mosek::fusion::p_BaseVariable::diag(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > index(int _2734,int _2735) /*override*/
{ return mosek::fusion::p_BaseVariable::index(_2734,_2735); }
virtual monty::rc_ptr< ::mosek::fusion::Set > getShape() /*override*/
{ return mosek::fusion::p_BaseVariable::getShape(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > transpose() /*override*/
{ return mosek::fusion::p_BaseVariable::transpose(); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > pick(std::shared_ptr< monty::ndarray< int,1 > > _2742,std::shared_ptr< monty::ndarray< int,1 > > _2743) /*override*/
{ return mosek::fusion::p_BaseVariable::pick(_2742,_2743); }
virtual monty::rc_ptr< ::mosek::fusion::Model > getModel() /*override*/
{ return mosek::fusion::p_BaseVariable::getModel(); }
virtual void setLevel(std::shared_ptr< monty::ndarray< double,1 > > _2722) /*override*/
{ mosek::fusion::p_BaseVariable::setLevel(_2722); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > diag(int _2751) /*override*/
{ return mosek::fusion::p_BaseVariable::diag(_2751); }
virtual monty::rc_ptr< ::mosek::fusion::Variable > antidiag(int _2750) /*override*/
{ return mosek::fusion::p_BaseVariable::antidiag(_2750); }
virtual void values(int _2705,std::shared_ptr< monty::ndarray< double,1 > > _2706,bool _2707) /*override*/
{ mosek::fusion::p_BaseVariable::values(_2705,_2706,_2707); }
}; // struct NilVariable;

struct p_Var
{
Var * _pubthis;
static mosek::fusion::p_Var* _get_impl(mosek::fusion::Var * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_Var * _get_impl(mosek::fusion::Var::t _inst) { return _get_impl(_inst.get()); }
p_Var(Var * _pubthis);
virtual ~p_Var() { /* std::cout << "~p_Var" << std::endl;*/ };
virtual void destroy();
static  monty::rc_ptr< ::mosek::fusion::Variable > compress(monty::rc_ptr< ::mosek::fusion::Variable > _2834);
static  monty::rc_ptr< ::mosek::fusion::Variable > reshape(monty::rc_ptr< ::mosek::fusion::Variable > _2839,int _2840);
static  monty::rc_ptr< ::mosek::fusion::Variable > reshape(monty::rc_ptr< ::mosek::fusion::Variable > _2841,int _2842,int _2843);
static  monty::rc_ptr< ::mosek::fusion::Variable > flatten(monty::rc_ptr< ::mosek::fusion::Variable > _2844);
static  monty::rc_ptr< ::mosek::fusion::Variable > reshape(monty::rc_ptr< ::mosek::fusion::Variable > _2845,std::shared_ptr< monty::ndarray< int,1 > > _2846);
static  monty::rc_ptr< ::mosek::fusion::Variable > reshape(monty::rc_ptr< ::mosek::fusion::Variable > _2848,monty::rc_ptr< ::mosek::fusion::Set > _2849);
static  monty::rc_ptr< ::mosek::fusion::Variable > reshape_(monty::rc_ptr< ::mosek::fusion::Variable > _2851,monty::rc_ptr< ::mosek::fusion::Set > _2852);
static  monty::rc_ptr< ::mosek::fusion::Variable > index_flip_(monty::rc_ptr< ::mosek::fusion::Variable > _2855,std::shared_ptr< monty::ndarray< int,1 > > _2856);
static  monty::rc_ptr< ::mosek::fusion::Variable > index_permute_(monty::rc_ptr< ::mosek::fusion::Variable > _2863,std::shared_ptr< monty::ndarray< int,1 > > _2864);
static  monty::rc_ptr< ::mosek::fusion::Variable > hrepeat(monty::rc_ptr< ::mosek::fusion::Variable > _2869,int _2870);
static  monty::rc_ptr< ::mosek::fusion::Variable > vrepeat(monty::rc_ptr< ::mosek::fusion::Variable > _2871,int _2872);
static  monty::rc_ptr< ::mosek::fusion::Variable > repeat(monty::rc_ptr< ::mosek::fusion::Variable > _2873,int _2874);
static  monty::rc_ptr< ::mosek::fusion::Variable > repeat(monty::rc_ptr< ::mosek::fusion::Variable > _2875,int _2876,int _2877);
static  monty::rc_ptr< ::mosek::fusion::Variable > drepeat(monty::rc_ptr< ::mosek::fusion::Variable > _2878,int _2879,int _2880);
static  monty::rc_ptr< ::mosek::fusion::Variable > stack(std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > >,1 > > _2881);
static  monty::rc_ptr< ::mosek::fusion::Variable > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _2897,monty::rc_ptr< ::mosek::fusion::Variable > _2898,monty::rc_ptr< ::mosek::fusion::Variable > _2899);
static  monty::rc_ptr< ::mosek::fusion::Variable > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _2900,monty::rc_ptr< ::mosek::fusion::Variable > _2901);
static  monty::rc_ptr< ::mosek::fusion::Variable > vstack(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _2902);
static  monty::rc_ptr< ::mosek::fusion::Variable > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _2903,monty::rc_ptr< ::mosek::fusion::Variable > _2904,monty::rc_ptr< ::mosek::fusion::Variable > _2905);
static  monty::rc_ptr< ::mosek::fusion::Variable > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _2906,monty::rc_ptr< ::mosek::fusion::Variable > _2907);
static  monty::rc_ptr< ::mosek::fusion::Variable > hstack(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _2908);
static  monty::rc_ptr< ::mosek::fusion::Variable > stack(monty::rc_ptr< ::mosek::fusion::Variable > _2909,monty::rc_ptr< ::mosek::fusion::Variable > _2910,monty::rc_ptr< ::mosek::fusion::Variable > _2911,int _2912);
static  monty::rc_ptr< ::mosek::fusion::Variable > stack(monty::rc_ptr< ::mosek::fusion::Variable > _2913,monty::rc_ptr< ::mosek::fusion::Variable > _2914,int _2915);
static  monty::rc_ptr< ::mosek::fusion::Variable > stack(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _2916,int _2917);
static  monty::rc_ptr< ::mosek::fusion::Variable > dstack(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _2918,int _2919);
}; // struct Var;

struct p_ConstraintCache
{
ConstraintCache * _pubthis;
static mosek::fusion::p_ConstraintCache* _get_impl(mosek::fusion::ConstraintCache * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_ConstraintCache * _get_impl(mosek::fusion::ConstraintCache::t _inst) { return _get_impl(_inst.get()); }
p_ConstraintCache(ConstraintCache * _pubthis);
virtual ~p_ConstraintCache() { /* std::cout << "~p_ConstraintCache" << std::endl;*/ };
std::shared_ptr< monty::ndarray< int,1 > > barmatidx{};std::shared_ptr< monty::ndarray< int,1 > > barsubj{};std::shared_ptr< monty::ndarray< int,1 > > barsubi{};long long nbarnz{};long long nunordered{};std::shared_ptr< monty::ndarray< int,1 > > buffer_subi{};std::shared_ptr< monty::ndarray< int,1 > > buffer_subj{};std::shared_ptr< monty::ndarray< double,1 > > buffer_cof{};std::shared_ptr< monty::ndarray< double,1 > > bfix{};std::shared_ptr< monty::ndarray< double,1 > > cof{};std::shared_ptr< monty::ndarray< int,1 > > subi{};std::shared_ptr< monty::ndarray< int,1 > > subj{};long long nnz{};int nrows{};virtual void destroy();
static ConstraintCache::t _new_ConstraintCache(monty::rc_ptr< ::mosek::fusion::ConstraintCache > _3184);
void _initialize(monty::rc_ptr< ::mosek::fusion::ConstraintCache > _3184);
static ConstraintCache::t _new_ConstraintCache(std::shared_ptr< monty::ndarray< long long,1 > > _3185,std::shared_ptr< monty::ndarray< double,1 > > _3186,std::shared_ptr< monty::ndarray< int,1 > > _3187,std::shared_ptr< monty::ndarray< double,1 > > _3188,std::shared_ptr< monty::ndarray< int,1 > > _3189,std::shared_ptr< monty::ndarray< int,1 > > _3190,std::shared_ptr< monty::ndarray< int,1 > > _3191);
void _initialize(std::shared_ptr< monty::ndarray< long long,1 > > _3185,std::shared_ptr< monty::ndarray< double,1 > > _3186,std::shared_ptr< monty::ndarray< int,1 > > _3187,std::shared_ptr< monty::ndarray< double,1 > > _3188,std::shared_ptr< monty::ndarray< int,1 > > _3189,std::shared_ptr< monty::ndarray< int,1 > > _3190,std::shared_ptr< monty::ndarray< int,1 > > _3191);
virtual void unchecked_add_fx(std::shared_ptr< monty::ndarray< double,1 > > _3194);
virtual long long order_barentries();
virtual void add_bar(std::shared_ptr< monty::ndarray< int,1 > > _3204,std::shared_ptr< monty::ndarray< int,1 > > _3205,std::shared_ptr< monty::ndarray< int,1 > > _3206);
virtual void unchecked_add_l(std::shared_ptr< monty::ndarray< long long,1 > > _3212,std::shared_ptr< monty::ndarray< int,1 > > _3213,std::shared_ptr< monty::ndarray< double,1 > > _3214,std::shared_ptr< monty::ndarray< double,1 > > _3215);
virtual void add(std::shared_ptr< monty::ndarray< long long,1 > > _3224,std::shared_ptr< monty::ndarray< int,1 > > _3225,std::shared_ptr< monty::ndarray< double,1 > > _3226,std::shared_ptr< monty::ndarray< double,1 > > _3227);
virtual long long flush(std::shared_ptr< monty::ndarray< int,1 > > _3228,std::shared_ptr< monty::ndarray< int,1 > > _3229,std::shared_ptr< monty::ndarray< double,1 > > _3230,std::shared_ptr< monty::ndarray< double,1 > > _3231);
virtual long long numUnsorted();
virtual monty::rc_ptr< ::mosek::fusion::ConstraintCache > clone();
}; // struct ConstraintCache;

struct p_Constraint
{
Constraint * _pubthis;
static mosek::fusion::p_Constraint* _get_impl(mosek::fusion::Constraint * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_Constraint * _get_impl(mosek::fusion::Constraint::t _inst) { return _get_impl(_inst.get()); }
p_Constraint(Constraint * _pubthis);
virtual ~p_Constraint() { /* std::cout << "~p_Constraint" << std::endl;*/ };
monty::rc_ptr< ::mosek::fusion::Set > shape_p{};monty::rc_ptr< ::mosek::fusion::Model > model{};virtual void destroy();
static Constraint::t _new_Constraint(monty::rc_ptr< ::mosek::fusion::Constraint > _3904,monty::rc_ptr< ::mosek::fusion::Model > _3905);
void _initialize(monty::rc_ptr< ::mosek::fusion::Constraint > _3904,monty::rc_ptr< ::mosek::fusion::Model > _3905);
static Constraint::t _new_Constraint(monty::rc_ptr< ::mosek::fusion::Model > _3906,monty::rc_ptr< ::mosek::fusion::Set > _3907);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _3906,monty::rc_ptr< ::mosek::fusion::Set > _3907);
virtual std::string toString();
virtual void toStringArray(std::shared_ptr< monty::ndarray< long long,1 > > _3913,long long _3914,std::shared_ptr< monty::ndarray< std::string,1 > > _3915) { throw monty::AbstractClassError("Call to abstract method"); }
virtual monty::rc_ptr< ::mosek::fusion::Constraint > add(double _3916);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > add(std::shared_ptr< monty::ndarray< double,1 > > _3921);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > add(monty::rc_ptr< ::mosek::fusion::Variable > _3925);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > add(monty::rc_ptr< ::mosek::fusion::Expression > _3934);
static  void inst(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _3941,std::shared_ptr< monty::ndarray< long long,1 > > _3942,std::shared_ptr< monty::ndarray< int,1 > > _3943,std::shared_ptr< monty::ndarray< int,1 > > _3944,std::shared_ptr< monty::ndarray< int,1 > > _3945);
virtual void add_l(std::shared_ptr< monty::ndarray< long long,1 > > _3953,std::shared_ptr< monty::ndarray< long long,1 > > _3954,std::shared_ptr< monty::ndarray< int,1 > > _3955,std::shared_ptr< monty::ndarray< int,1 > > _3956,std::shared_ptr< monty::ndarray< int,1 > > _3957,std::shared_ptr< monty::ndarray< double,1 > > _3958,std::shared_ptr< monty::ndarray< double,1 > > _3959,long long _3960,int _3961,int _3962) { throw monty::AbstractClassError("Call to abstract method"); }
virtual std::shared_ptr< monty::ndarray< double,1 > > dual(std::shared_ptr< monty::ndarray< int,1 > > _3963,std::shared_ptr< monty::ndarray< int,1 > > _3964);
virtual std::shared_ptr< monty::ndarray< double,1 > > dual(int _3972,int _3973);
virtual std::shared_ptr< monty::ndarray< double,1 > > dual();
virtual void dual_values(int _3977,std::shared_ptr< monty::ndarray< double,1 > > _3978);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _3983,int _3984,std::shared_ptr< monty::ndarray< double,1 > > _3985) { throw monty::AbstractClassError("Call to abstract method"); }
virtual void dual_values(long long _3986,std::shared_ptr< monty::ndarray< int,1 > > _3987,std::shared_ptr< monty::ndarray< long long,1 > > _3988,int _3989,std::shared_ptr< monty::ndarray< double,1 > > _3990) { throw monty::AbstractClassError("Call to abstract method"); }
virtual std::shared_ptr< monty::ndarray< double,1 > > level();
virtual double level(int _3992);
virtual std::shared_ptr< monty::ndarray< double,1 > > level(std::shared_ptr< monty::ndarray< int,1 > > _3995,std::shared_ptr< monty::ndarray< int,1 > > _3996);
virtual std::shared_ptr< monty::ndarray< double,1 > > level(int _4006,int _4007);
virtual void level_values(int _4012,std::shared_ptr< monty::ndarray< double,1 > > _4013);
virtual void level_values(std::shared_ptr< monty::ndarray< long long,1 > > _4018,int _4019,std::shared_ptr< monty::ndarray< double,1 > > _4020) { throw monty::AbstractClassError("Call to abstract method"); }
virtual void level_values(long long _4021,std::shared_ptr< monty::ndarray< int,1 > > _4022,std::shared_ptr< monty::ndarray< long long,1 > > _4023,int _4024,std::shared_ptr< monty::ndarray< double,1 > > _4025) { throw monty::AbstractClassError("Call to abstract method"); }
virtual monty::rc_ptr< ::mosek::fusion::Model > get_model();
virtual int get_nd();
virtual long long size();
static  monty::rc_ptr< ::mosek::fusion::Constraint > stack(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Constraint >,1 > > _4026);
static  monty::rc_ptr< ::mosek::fusion::Constraint > stack(monty::rc_ptr< ::mosek::fusion::Constraint > _4027,monty::rc_ptr< ::mosek::fusion::Constraint > _4028,monty::rc_ptr< ::mosek::fusion::Constraint > _4029);
static  monty::rc_ptr< ::mosek::fusion::Constraint > stack(monty::rc_ptr< ::mosek::fusion::Constraint > _4031,monty::rc_ptr< ::mosek::fusion::Constraint > _4032);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > index(std::shared_ptr< monty::ndarray< int,1 > > _4034);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > index(int _4036);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > slice(std::shared_ptr< monty::ndarray< int,1 > > _4037,std::shared_ptr< monty::ndarray< int,1 > > _4038) { throw monty::AbstractClassError("Call to abstract method"); }
virtual monty::rc_ptr< ::mosek::fusion::Constraint > slice(int _4039,int _4040) { throw monty::AbstractClassError("Call to abstract method"); }
virtual monty::rc_ptr< ::mosek::fusion::Constraint > reduceDims();
virtual monty::rc_ptr< ::mosek::fusion::Set > shape();
}; // struct Constraint;

struct p_CompoundConstraint : public ::mosek::fusion::p_Constraint
{
CompoundConstraint * _pubthis;
static mosek::fusion::p_CompoundConstraint* _get_impl(mosek::fusion::CompoundConstraint * _inst){ return static_cast< mosek::fusion::p_CompoundConstraint* >(mosek::fusion::p_Constraint::_get_impl(_inst)); }
static mosek::fusion::p_CompoundConstraint * _get_impl(mosek::fusion::CompoundConstraint::t _inst) { return _get_impl(_inst.get()); }
p_CompoundConstraint(CompoundConstraint * _pubthis);
virtual ~p_CompoundConstraint() { /* std::cout << "~p_CompoundConstraint" << std::endl;*/ };
int stackdim{};std::shared_ptr< monty::ndarray< int,1 > > consb{};std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Constraint >,1 > > cons{};virtual void destroy();
static CompoundConstraint::t _new_CompoundConstraint(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Constraint >,1 > > _3254);
void _initialize(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Constraint >,1 > > _3254);
virtual void toStringArray(std::shared_ptr< monty::ndarray< long long,1 > > _3261,long long _3262,std::shared_ptr< monty::ndarray< std::string,1 > > _3263);
virtual void add_l(std::shared_ptr< monty::ndarray< long long,1 > > _3264,std::shared_ptr< monty::ndarray< long long,1 > > _3265,std::shared_ptr< monty::ndarray< int,1 > > _3266,std::shared_ptr< monty::ndarray< int,1 > > _3267,std::shared_ptr< monty::ndarray< int,1 > > _3268,std::shared_ptr< monty::ndarray< double,1 > > _3269,std::shared_ptr< monty::ndarray< double,1 > > _3270,long long _3271,int _3272,int _3273);
virtual void dual_values(long long _3298,std::shared_ptr< monty::ndarray< int,1 > > _3299,std::shared_ptr< monty::ndarray< long long,1 > > _3300,int _3301,std::shared_ptr< monty::ndarray< double,1 > > _3302);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _3319,int _3320,std::shared_ptr< monty::ndarray< double,1 > > _3321);
virtual void level_values(long long _3328,std::shared_ptr< monty::ndarray< int,1 > > _3329,std::shared_ptr< monty::ndarray< long long,1 > > _3330,int _3331,std::shared_ptr< monty::ndarray< double,1 > > _3332);
virtual void level_values(std::shared_ptr< monty::ndarray< long long,1 > > _3349,int _3350,std::shared_ptr< monty::ndarray< double,1 > > _3351);
virtual void add(std::shared_ptr< monty::ndarray< long long,1 > > _3358,std::shared_ptr< monty::ndarray< int,1 > > _3359,std::shared_ptr< monty::ndarray< double,1 > > _3360,std::shared_ptr< monty::ndarray< double,1 > > _3361,int _3362,std::shared_ptr< monty::ndarray< int,1 > > _3363,int _3364);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > slice(std::shared_ptr< monty::ndarray< int,1 > > _3365,std::shared_ptr< monty::ndarray< int,1 > > _3366);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > slice(int _3367,int _3368);
static  monty::rc_ptr< ::mosek::fusion::Set > compute_shape(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Constraint >,1 > > _3369,int _3370);
static  int count_numcon(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Constraint >,1 > > _3377);
static  monty::rc_ptr< ::mosek::fusion::Model > model_from_con(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Constraint >,1 > > _3383);
}; // struct CompoundConstraint;

struct p_SliceConstraint : public ::mosek::fusion::p_Constraint
{
SliceConstraint * _pubthis;
static mosek::fusion::p_SliceConstraint* _get_impl(mosek::fusion::SliceConstraint * _inst){ return static_cast< mosek::fusion::p_SliceConstraint* >(mosek::fusion::p_Constraint::_get_impl(_inst)); }
static mosek::fusion::p_SliceConstraint * _get_impl(mosek::fusion::SliceConstraint::t _inst) { return _get_impl(_inst.get()); }
p_SliceConstraint(SliceConstraint * _pubthis);
virtual ~p_SliceConstraint() { /* std::cout << "~p_SliceConstraint" << std::endl;*/ };
std::shared_ptr< monty::ndarray< long long,1 > > strides{};long long first{};monty::rc_ptr< ::mosek::fusion::ModelConstraint > origin{};virtual void destroy();
static SliceConstraint::t _new_SliceConstraint(monty::rc_ptr< ::mosek::fusion::ModelConstraint > _3400,monty::rc_ptr< ::mosek::fusion::Set > _3401,long long _3402,std::shared_ptr< monty::ndarray< long long,1 > > _3403);
void _initialize(monty::rc_ptr< ::mosek::fusion::ModelConstraint > _3400,monty::rc_ptr< ::mosek::fusion::Set > _3401,long long _3402,std::shared_ptr< monty::ndarray< long long,1 > > _3403);
virtual void add_l(std::shared_ptr< monty::ndarray< long long,1 > > _3404,std::shared_ptr< monty::ndarray< long long,1 > > _3405,std::shared_ptr< monty::ndarray< int,1 > > _3406,std::shared_ptr< monty::ndarray< int,1 > > _3407,std::shared_ptr< monty::ndarray< int,1 > > _3408,std::shared_ptr< monty::ndarray< double,1 > > _3409,std::shared_ptr< monty::ndarray< double,1 > > _3410,long long _3411,int _3412,int _3413);
virtual void add_fx(std::shared_ptr< monty::ndarray< long long,1 > > _3424,std::shared_ptr< monty::ndarray< double,1 > > _3425,long long _3426,int _3427,int _3428);
virtual void dual_values(long long _3435,std::shared_ptr< monty::ndarray< int,1 > > _3436,std::shared_ptr< monty::ndarray< long long,1 > > _3437,int _3438,std::shared_ptr< monty::ndarray< double,1 > > _3439);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _3462,int _3463,std::shared_ptr< monty::ndarray< double,1 > > _3464);
virtual void level_values(long long _3470,std::shared_ptr< monty::ndarray< int,1 > > _3471,std::shared_ptr< monty::ndarray< long long,1 > > _3472,int _3473,std::shared_ptr< monty::ndarray< double,1 > > _3474);
virtual void level_values(std::shared_ptr< monty::ndarray< long long,1 > > _3496,int _3497,std::shared_ptr< monty::ndarray< double,1 > > _3498);
virtual void toStringArray(std::shared_ptr< monty::ndarray< long long,1 > > _3504,long long _3505,std::shared_ptr< monty::ndarray< std::string,1 > > _3506);
virtual long long size();
virtual monty::rc_ptr< ::mosek::fusion::Constraint > slice(std::shared_ptr< monty::ndarray< int,1 > > _3512,std::shared_ptr< monty::ndarray< int,1 > > _3513);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > slice(int _3517,int _3518);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > slice_(monty::rc_ptr< ::mosek::fusion::Set > _3520,long long _3521,std::shared_ptr< monty::ndarray< long long,1 > > _3522);
}; // struct SliceConstraint;

struct p_BoundInterfaceConstraint : public ::mosek::fusion::p_SliceConstraint
{
BoundInterfaceConstraint * _pubthis;
static mosek::fusion::p_BoundInterfaceConstraint* _get_impl(mosek::fusion::BoundInterfaceConstraint * _inst){ return static_cast< mosek::fusion::p_BoundInterfaceConstraint* >(mosek::fusion::p_SliceConstraint::_get_impl(_inst)); }
static mosek::fusion::p_BoundInterfaceConstraint * _get_impl(mosek::fusion::BoundInterfaceConstraint::t _inst) { return _get_impl(_inst.get()); }
p_BoundInterfaceConstraint(BoundInterfaceConstraint * _pubthis);
virtual ~p_BoundInterfaceConstraint() { /* std::cout << "~p_BoundInterfaceConstraint" << std::endl;*/ };
monty::rc_ptr< ::mosek::fusion::RangedConstraint > origincon{};bool islower{};virtual void destroy();
static BoundInterfaceConstraint::t _new_BoundInterfaceConstraint(monty::rc_ptr< ::mosek::fusion::RangedConstraint > _3384,monty::rc_ptr< ::mosek::fusion::Set > _3385,long long _3386,std::shared_ptr< monty::ndarray< long long,1 > > _3387,bool _3388);
void _initialize(monty::rc_ptr< ::mosek::fusion::RangedConstraint > _3384,monty::rc_ptr< ::mosek::fusion::Set > _3385,long long _3386,std::shared_ptr< monty::ndarray< long long,1 > > _3387,bool _3388);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > slice_(monty::rc_ptr< ::mosek::fusion::Set > _3389,long long _3390,std::shared_ptr< monty::ndarray< long long,1 > > _3391);
virtual void dual_values(long long _3392,std::shared_ptr< monty::ndarray< int,1 > > _3393,std::shared_ptr< monty::ndarray< long long,1 > > _3394,int _3395,std::shared_ptr< monty::ndarray< double,1 > > _3396);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _3397,int _3398,std::shared_ptr< monty::ndarray< double,1 > > _3399);
}; // struct BoundInterfaceConstraint;

struct p_ModelConstraint : public ::mosek::fusion::p_Constraint
{
ModelConstraint * _pubthis;
static mosek::fusion::p_ModelConstraint* _get_impl(mosek::fusion::ModelConstraint * _inst){ return static_cast< mosek::fusion::p_ModelConstraint* >(mosek::fusion::p_Constraint::_get_impl(_inst)); }
static mosek::fusion::p_ModelConstraint * _get_impl(mosek::fusion::ModelConstraint::t _inst) { return _get_impl(_inst.get()); }
p_ModelConstraint(ModelConstraint * _pubthis);
virtual ~p_ModelConstraint() { /* std::cout << "~p_ModelConstraint" << std::endl;*/ };
bool names_flushed{};std::shared_ptr< monty::ndarray< int,1 > > nativeindexes{};std::string name{};std::shared_ptr< monty::ndarray< double,1 > > cache_bfix{};monty::rc_ptr< ::mosek::fusion::ConstraintCache > cache{};virtual void destroy();
static ModelConstraint::t _new_ModelConstraint(monty::rc_ptr< ::mosek::fusion::ModelConstraint > _3790,monty::rc_ptr< ::mosek::fusion::Model > _3791);
void _initialize(monty::rc_ptr< ::mosek::fusion::ModelConstraint > _3790,monty::rc_ptr< ::mosek::fusion::Model > _3791);
static ModelConstraint::t _new_ModelConstraint(monty::rc_ptr< ::mosek::fusion::Model > _3794,const std::string &  _3795,monty::rc_ptr< ::mosek::fusion::Set > _3796,std::shared_ptr< monty::ndarray< int,1 > > _3797,std::shared_ptr< monty::ndarray< long long,1 > > _3798,std::shared_ptr< monty::ndarray< int,1 > > _3799,std::shared_ptr< monty::ndarray< double,1 > > _3800,std::shared_ptr< monty::ndarray< double,1 > > _3801,std::shared_ptr< monty::ndarray< int,1 > > _3802,std::shared_ptr< monty::ndarray< int,1 > > _3803,std::shared_ptr< monty::ndarray< int,1 > > _3804);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _3794,const std::string &  _3795,monty::rc_ptr< ::mosek::fusion::Set > _3796,std::shared_ptr< monty::ndarray< int,1 > > _3797,std::shared_ptr< monty::ndarray< long long,1 > > _3798,std::shared_ptr< monty::ndarray< int,1 > > _3799,std::shared_ptr< monty::ndarray< double,1 > > _3800,std::shared_ptr< monty::ndarray< double,1 > > _3801,std::shared_ptr< monty::ndarray< int,1 > > _3802,std::shared_ptr< monty::ndarray< int,1 > > _3803,std::shared_ptr< monty::ndarray< int,1 > > _3804);
virtual void flushNames();
virtual std::string toString();
virtual void toStringArray(std::shared_ptr< monty::ndarray< long long,1 > > _3811,long long _3812,std::shared_ptr< monty::ndarray< std::string,1 > > _3813);
virtual void domainToString(long long _3829,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _3830) { throw monty::AbstractClassError("Call to abstract method"); }
virtual void add_l(std::shared_ptr< monty::ndarray< long long,1 > > _3831,std::shared_ptr< monty::ndarray< long long,1 > > _3832,std::shared_ptr< monty::ndarray< int,1 > > _3833,std::shared_ptr< monty::ndarray< int,1 > > _3834,std::shared_ptr< monty::ndarray< int,1 > > _3835,std::shared_ptr< monty::ndarray< double,1 > > _3836,std::shared_ptr< monty::ndarray< double,1 > > _3837,long long _3838,int _3839,int _3840);
virtual void add_fx(std::shared_ptr< monty::ndarray< long long,1 > > _3888,std::shared_ptr< monty::ndarray< double,1 > > _3889,long long _3890,int _3891,int _3892) { throw monty::AbstractClassError("Call to abstract method"); }
virtual monty::rc_ptr< ::mosek::fusion::Constraint > slice(std::shared_ptr< monty::ndarray< int,1 > > _3893,std::shared_ptr< monty::ndarray< int,1 > > _3894);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > slice(int _3900,int _3901);
virtual monty::rc_ptr< ::mosek::fusion::ModelConstraint > clone(monty::rc_ptr< ::mosek::fusion::Model > _3903) { throw monty::AbstractClassError("Call to abstract method"); }
}; // struct ModelConstraint;

struct p_LinearPSDConstraint : public ::mosek::fusion::p_ModelConstraint
{
LinearPSDConstraint * _pubthis;
static mosek::fusion::p_LinearPSDConstraint* _get_impl(mosek::fusion::LinearPSDConstraint * _inst){ return static_cast< mosek::fusion::p_LinearPSDConstraint* >(mosek::fusion::p_ModelConstraint::_get_impl(_inst)); }
static mosek::fusion::p_LinearPSDConstraint * _get_impl(mosek::fusion::LinearPSDConstraint::t _inst) { return _get_impl(_inst.get()); }
p_LinearPSDConstraint(LinearPSDConstraint * _pubthis);
virtual ~p_LinearPSDConstraint() { /* std::cout << "~p_LinearPSDConstraint" << std::endl;*/ };
int psdvardim{};bool names_flushed{};int numcones{};int conesize{};int coneidx{};virtual void destroy();
static LinearPSDConstraint::t _new_LinearPSDConstraint(monty::rc_ptr< ::mosek::fusion::LinearPSDConstraint > _2933,monty::rc_ptr< ::mosek::fusion::Model > _2934);
void _initialize(monty::rc_ptr< ::mosek::fusion::LinearPSDConstraint > _2933,monty::rc_ptr< ::mosek::fusion::Model > _2934);
static LinearPSDConstraint::t _new_LinearPSDConstraint(monty::rc_ptr< ::mosek::fusion::Model > _2935,const std::string &  _2936,monty::rc_ptr< ::mosek::fusion::Set > _2937,std::shared_ptr< monty::ndarray< int,1 > > _2938,int _2939,int _2940,int _2941,std::shared_ptr< monty::ndarray< long long,1 > > _2942,std::shared_ptr< monty::ndarray< int,1 > > _2943,std::shared_ptr< monty::ndarray< double,1 > > _2944,std::shared_ptr< monty::ndarray< double,1 > > _2945,std::shared_ptr< monty::ndarray< int,1 > > _2946,std::shared_ptr< monty::ndarray< int,1 > > _2947,std::shared_ptr< monty::ndarray< int,1 > > _2948);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _2935,const std::string &  _2936,monty::rc_ptr< ::mosek::fusion::Set > _2937,std::shared_ptr< monty::ndarray< int,1 > > _2938,int _2939,int _2940,int _2941,std::shared_ptr< monty::ndarray< long long,1 > > _2942,std::shared_ptr< monty::ndarray< int,1 > > _2943,std::shared_ptr< monty::ndarray< double,1 > > _2944,std::shared_ptr< monty::ndarray< double,1 > > _2945,std::shared_ptr< monty::ndarray< int,1 > > _2946,std::shared_ptr< monty::ndarray< int,1 > > _2947,std::shared_ptr< monty::ndarray< int,1 > > _2948);
virtual void domainToString(long long _2951,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _2952);
virtual std::string toString();
virtual void toStringArray(std::shared_ptr< monty::ndarray< long long,1 > > _2962,long long _2963,std::shared_ptr< monty::ndarray< std::string,1 > > _2964);
virtual void toStringArray(std::shared_ptr< monty::ndarray< long long,1 > > _2965,long long _2966,std::shared_ptr< monty::ndarray< std::string,1 > > _2967,bool _2968);
virtual void flushNames();
virtual void add_fx(std::shared_ptr< monty::ndarray< long long,1 > > _2996,std::shared_ptr< monty::ndarray< double,1 > > _2997,long long _2998,int _2999,int _3000);
virtual void dual_values(long long _3005,std::shared_ptr< monty::ndarray< int,1 > > _3006,std::shared_ptr< monty::ndarray< long long,1 > > _3007,int _3008,std::shared_ptr< monty::ndarray< double,1 > > _3009);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _3018,int _3019,std::shared_ptr< monty::ndarray< double,1 > > _3020);
virtual void level_values(long long _3026,std::shared_ptr< monty::ndarray< int,1 > > _3027,std::shared_ptr< monty::ndarray< long long,1 > > _3028,int _3029,std::shared_ptr< monty::ndarray< double,1 > > _3030);
virtual void level_values(std::shared_ptr< monty::ndarray< long long,1 > > _3039,int _3040,std::shared_ptr< monty::ndarray< double,1 > > _3041);
virtual monty::rc_ptr< ::mosek::fusion::ModelConstraint > clone(monty::rc_ptr< ::mosek::fusion::Model > _3047);
}; // struct LinearPSDConstraint;

struct p_PSDConstraint : public ::mosek::fusion::p_ModelConstraint
{
PSDConstraint * _pubthis;
static mosek::fusion::p_PSDConstraint* _get_impl(mosek::fusion::PSDConstraint * _inst){ return static_cast< mosek::fusion::p_PSDConstraint* >(mosek::fusion::p_ModelConstraint::_get_impl(_inst)); }
static mosek::fusion::p_PSDConstraint * _get_impl(mosek::fusion::PSDConstraint::t _inst) { return _get_impl(_inst.get()); }
p_PSDConstraint(PSDConstraint * _pubthis);
virtual ~p_PSDConstraint() { /* std::cout << "~p_PSDConstraint" << std::endl;*/ };
bool names_flushed{};int numcones{};int conesize{};int coneidx{};virtual void destroy();
static PSDConstraint::t _new_PSDConstraint(monty::rc_ptr< ::mosek::fusion::PSDConstraint > _3048,monty::rc_ptr< ::mosek::fusion::Model > _3049);
void _initialize(monty::rc_ptr< ::mosek::fusion::PSDConstraint > _3048,monty::rc_ptr< ::mosek::fusion::Model > _3049);
static PSDConstraint::t _new_PSDConstraint(monty::rc_ptr< ::mosek::fusion::Model > _3050,const std::string &  _3051,monty::rc_ptr< ::mosek::fusion::Set > _3052,std::shared_ptr< monty::ndarray< int,1 > > _3053,int _3054,int _3055,int _3056,std::shared_ptr< monty::ndarray< long long,1 > > _3057,std::shared_ptr< monty::ndarray< int,1 > > _3058,std::shared_ptr< monty::ndarray< double,1 > > _3059,std::shared_ptr< monty::ndarray< double,1 > > _3060,std::shared_ptr< monty::ndarray< int,1 > > _3061,std::shared_ptr< monty::ndarray< int,1 > > _3062,std::shared_ptr< monty::ndarray< int,1 > > _3063);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _3050,const std::string &  _3051,monty::rc_ptr< ::mosek::fusion::Set > _3052,std::shared_ptr< monty::ndarray< int,1 > > _3053,int _3054,int _3055,int _3056,std::shared_ptr< monty::ndarray< long long,1 > > _3057,std::shared_ptr< monty::ndarray< int,1 > > _3058,std::shared_ptr< monty::ndarray< double,1 > > _3059,std::shared_ptr< monty::ndarray< double,1 > > _3060,std::shared_ptr< monty::ndarray< int,1 > > _3061,std::shared_ptr< monty::ndarray< int,1 > > _3062,std::shared_ptr< monty::ndarray< int,1 > > _3063);
virtual void domainToString(long long _3064,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _3065);
virtual std::string toString();
virtual void toStringArray(std::shared_ptr< monty::ndarray< long long,1 > > _3075,long long _3076,std::shared_ptr< monty::ndarray< std::string,1 > > _3077);
virtual void toStringArray(std::shared_ptr< monty::ndarray< long long,1 > > _3078,long long _3079,std::shared_ptr< monty::ndarray< std::string,1 > > _3080,bool _3081);
virtual void flushNames();
virtual void add_fx(std::shared_ptr< monty::ndarray< long long,1 > > _3114,std::shared_ptr< monty::ndarray< double,1 > > _3115,long long _3116,int _3117,int _3118);
virtual void dual_values(long long _3123,std::shared_ptr< monty::ndarray< int,1 > > _3124,std::shared_ptr< monty::ndarray< long long,1 > > _3125,int _3126,std::shared_ptr< monty::ndarray< double,1 > > _3127);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _3143,int _3144,std::shared_ptr< monty::ndarray< double,1 > > _3145);
virtual void level_values(long long _3153,std::shared_ptr< monty::ndarray< int,1 > > _3154,std::shared_ptr< monty::ndarray< long long,1 > > _3155,int _3156,std::shared_ptr< monty::ndarray< double,1 > > _3157);
virtual void level_values(std::shared_ptr< monty::ndarray< long long,1 > > _3173,int _3174,std::shared_ptr< monty::ndarray< double,1 > > _3175);
virtual monty::rc_ptr< ::mosek::fusion::ModelConstraint > clone(monty::rc_ptr< ::mosek::fusion::Model > _3183);
}; // struct PSDConstraint;

struct p_RangedConstraint : public ::mosek::fusion::p_ModelConstraint
{
RangedConstraint * _pubthis;
static mosek::fusion::p_RangedConstraint* _get_impl(mosek::fusion::RangedConstraint * _inst){ return static_cast< mosek::fusion::p_RangedConstraint* >(mosek::fusion::p_ModelConstraint::_get_impl(_inst)); }
static mosek::fusion::p_RangedConstraint * _get_impl(mosek::fusion::RangedConstraint::t _inst) { return _get_impl(_inst.get()); }
p_RangedConstraint(RangedConstraint * _pubthis);
virtual ~p_RangedConstraint() { /* std::cout << "~p_RangedConstraint" << std::endl;*/ };
monty::rc_ptr< ::mosek::fusion::Utils::IntMap > idxmap{};monty::rc_ptr< ::mosek::fusion::RangeDomain > dom{};virtual void destroy();
static RangedConstraint::t _new_RangedConstraint(monty::rc_ptr< ::mosek::fusion::RangedConstraint > _3523,monty::rc_ptr< ::mosek::fusion::Model > _3524);
void _initialize(monty::rc_ptr< ::mosek::fusion::RangedConstraint > _3523,monty::rc_ptr< ::mosek::fusion::Model > _3524);
static RangedConstraint::t _new_RangedConstraint(monty::rc_ptr< ::mosek::fusion::Model > _3525,const std::string &  _3526,monty::rc_ptr< ::mosek::fusion::Set > _3527,monty::rc_ptr< ::mosek::fusion::RangeDomain > _3528,std::shared_ptr< monty::ndarray< int,1 > > _3529,std::shared_ptr< monty::ndarray< long long,1 > > _3530,std::shared_ptr< monty::ndarray< int,1 > > _3531,std::shared_ptr< monty::ndarray< double,1 > > _3532,std::shared_ptr< monty::ndarray< double,1 > > _3533,std::shared_ptr< monty::ndarray< int,1 > > _3534,std::shared_ptr< monty::ndarray< int,1 > > _3535,std::shared_ptr< monty::ndarray< int,1 > > _3536);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _3525,const std::string &  _3526,monty::rc_ptr< ::mosek::fusion::Set > _3527,monty::rc_ptr< ::mosek::fusion::RangeDomain > _3528,std::shared_ptr< monty::ndarray< int,1 > > _3529,std::shared_ptr< monty::ndarray< long long,1 > > _3530,std::shared_ptr< monty::ndarray< int,1 > > _3531,std::shared_ptr< monty::ndarray< double,1 > > _3532,std::shared_ptr< monty::ndarray< double,1 > > _3533,std::shared_ptr< monty::ndarray< int,1 > > _3534,std::shared_ptr< monty::ndarray< int,1 > > _3535,std::shared_ptr< monty::ndarray< int,1 > > _3536);
virtual void add_fx(std::shared_ptr< monty::ndarray< long long,1 > > _3537,std::shared_ptr< monty::ndarray< double,1 > > _3538,long long _3539,int _3540,int _3541);
virtual void dual_u(long long _3547,std::shared_ptr< monty::ndarray< int,1 > > _3548,std::shared_ptr< monty::ndarray< long long,1 > > _3549,int _3550,std::shared_ptr< monty::ndarray< double,1 > > _3551);
virtual void dual_u(std::shared_ptr< monty::ndarray< long long,1 > > _3559,int _3560,std::shared_ptr< monty::ndarray< double,1 > > _3561);
virtual void dual_l(long long _3565,std::shared_ptr< monty::ndarray< int,1 > > _3566,std::shared_ptr< monty::ndarray< long long,1 > > _3567,int _3568,std::shared_ptr< monty::ndarray< double,1 > > _3569);
virtual void dual_l(std::shared_ptr< monty::ndarray< long long,1 > > _3577,int _3578,std::shared_ptr< monty::ndarray< double,1 > > _3579);
virtual void dual_values(long long _3583,std::shared_ptr< monty::ndarray< int,1 > > _3584,std::shared_ptr< monty::ndarray< long long,1 > > _3585,int _3586,std::shared_ptr< monty::ndarray< double,1 > > _3587);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _3595,int _3596,std::shared_ptr< monty::ndarray< double,1 > > _3597);
virtual void level_values(long long _3601,std::shared_ptr< monty::ndarray< int,1 > > _3602,std::shared_ptr< monty::ndarray< long long,1 > > _3603,int _3604,std::shared_ptr< monty::ndarray< double,1 > > _3605);
virtual void level_values(std::shared_ptr< monty::ndarray< long long,1 > > _3613,int _3614,std::shared_ptr< monty::ndarray< double,1 > > _3615);
virtual void add_l(std::shared_ptr< monty::ndarray< long long,1 > > _3619,std::shared_ptr< monty::ndarray< long long,1 > > _3620,std::shared_ptr< monty::ndarray< int,1 > > _3621,std::shared_ptr< monty::ndarray< int,1 > > _3622,std::shared_ptr< monty::ndarray< int,1 > > _3623,std::shared_ptr< monty::ndarray< double,1 > > _3624,std::shared_ptr< monty::ndarray< double,1 > > _3625,int _3626,int _3627,int _3628);
virtual void domainToString(long long _3634,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _3635);
virtual monty::rc_ptr< ::mosek::fusion::Constraint > upperBoundCon();
virtual monty::rc_ptr< ::mosek::fusion::Constraint > lowerBoundCon();
virtual monty::rc_ptr< ::mosek::fusion::ModelConstraint > clone(monty::rc_ptr< ::mosek::fusion::Model > _3640);
}; // struct RangedConstraint;

struct p_ConicConstraint : public ::mosek::fusion::p_ModelConstraint
{
ConicConstraint * _pubthis;
static mosek::fusion::p_ConicConstraint* _get_impl(mosek::fusion::ConicConstraint * _inst){ return static_cast< mosek::fusion::p_ConicConstraint* >(mosek::fusion::p_ModelConstraint::_get_impl(_inst)); }
static mosek::fusion::p_ConicConstraint * _get_impl(mosek::fusion::ConicConstraint::t _inst) { return _get_impl(_inst.get()); }
p_ConicConstraint(ConicConstraint * _pubthis);
virtual ~p_ConicConstraint() { /* std::cout << "~p_ConicConstraint" << std::endl;*/ };
bool names_flushed{};monty::rc_ptr< ::mosek::fusion::QConeDomain > dom{};int conesize{};int last{};int first{};int last_slack{};int first_slack{};int coneidx{};virtual void destroy();
static ConicConstraint::t _new_ConicConstraint(monty::rc_ptr< ::mosek::fusion::ConicConstraint > _3641,monty::rc_ptr< ::mosek::fusion::Model > _3642);
void _initialize(monty::rc_ptr< ::mosek::fusion::ConicConstraint > _3641,monty::rc_ptr< ::mosek::fusion::Model > _3642);
static ConicConstraint::t _new_ConicConstraint(monty::rc_ptr< ::mosek::fusion::Model > _3643,const std::string &  _3644,monty::rc_ptr< ::mosek::fusion::QConeDomain > _3645,monty::rc_ptr< ::mosek::fusion::Set > _3646,std::shared_ptr< monty::ndarray< int,1 > > _3647,int _3648,int _3649,int _3650,int _3651,int _3652,std::shared_ptr< monty::ndarray< long long,1 > > _3653,std::shared_ptr< monty::ndarray< int,1 > > _3654,std::shared_ptr< monty::ndarray< double,1 > > _3655,std::shared_ptr< monty::ndarray< double,1 > > _3656,std::shared_ptr< monty::ndarray< int,1 > > _3657,std::shared_ptr< monty::ndarray< int,1 > > _3658,std::shared_ptr< monty::ndarray< int,1 > > _3659);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _3643,const std::string &  _3644,monty::rc_ptr< ::mosek::fusion::QConeDomain > _3645,monty::rc_ptr< ::mosek::fusion::Set > _3646,std::shared_ptr< monty::ndarray< int,1 > > _3647,int _3648,int _3649,int _3650,int _3651,int _3652,std::shared_ptr< monty::ndarray< long long,1 > > _3653,std::shared_ptr< monty::ndarray< int,1 > > _3654,std::shared_ptr< monty::ndarray< double,1 > > _3655,std::shared_ptr< monty::ndarray< double,1 > > _3656,std::shared_ptr< monty::ndarray< int,1 > > _3657,std::shared_ptr< monty::ndarray< int,1 > > _3658,std::shared_ptr< monty::ndarray< int,1 > > _3659);
virtual void flushNames();
virtual std::string toString();
virtual void dual_values(long long _3667,std::shared_ptr< monty::ndarray< int,1 > > _3668,std::shared_ptr< monty::ndarray< long long,1 > > _3669,int _3670,std::shared_ptr< monty::ndarray< double,1 > > _3671);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _3678,int _3679,std::shared_ptr< monty::ndarray< double,1 > > _3680);
virtual void level_values(long long _3683,std::shared_ptr< monty::ndarray< int,1 > > _3684,std::shared_ptr< monty::ndarray< long long,1 > > _3685,int _3686,std::shared_ptr< monty::ndarray< double,1 > > _3687);
virtual void level_values(std::shared_ptr< monty::ndarray< long long,1 > > _3695,int _3696,std::shared_ptr< monty::ndarray< double,1 > > _3697);
virtual void add_fx(std::shared_ptr< monty::ndarray< long long,1 > > _3701,std::shared_ptr< monty::ndarray< double,1 > > _3702,long long _3703,int _3704,int _3705);
virtual void dual(std::shared_ptr< monty::ndarray< int,1 > > _3710,int _3711,int _3712,int _3713,std::shared_ptr< monty::ndarray< double,1 > > _3714);
virtual void dual_values(std::shared_ptr< monty::ndarray< int,1 > > _3717,std::shared_ptr< monty::ndarray< int,1 > > _3718,int _3719,std::shared_ptr< monty::ndarray< double,1 > > _3720);
virtual void domainToString(long long _3725,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _3726);
virtual monty::rc_ptr< ::mosek::fusion::ModelConstraint > clone(monty::rc_ptr< ::mosek::fusion::Model > _3727);
}; // struct ConicConstraint;

struct p_LinearConstraint : public ::mosek::fusion::p_ModelConstraint
{
LinearConstraint * _pubthis;
static mosek::fusion::p_LinearConstraint* _get_impl(mosek::fusion::LinearConstraint * _inst){ return static_cast< mosek::fusion::p_LinearConstraint* >(mosek::fusion::p_ModelConstraint::_get_impl(_inst)); }
static mosek::fusion::p_LinearConstraint * _get_impl(mosek::fusion::LinearConstraint::t _inst) { return _get_impl(_inst.get()); }
p_LinearConstraint(LinearConstraint * _pubthis);
virtual ~p_LinearConstraint() { /* std::cout << "~p_LinearConstraint" << std::endl;*/ };
monty::rc_ptr< ::mosek::fusion::LinearDomain > dom{};monty::rc_ptr< ::mosek::fusion::Utils::IntMap > idxmap{};virtual void destroy();
static LinearConstraint::t _new_LinearConstraint(monty::rc_ptr< ::mosek::fusion::LinearConstraint > _3728,monty::rc_ptr< ::mosek::fusion::Model > _3729);
void _initialize(monty::rc_ptr< ::mosek::fusion::LinearConstraint > _3728,monty::rc_ptr< ::mosek::fusion::Model > _3729);
static LinearConstraint::t _new_LinearConstraint(monty::rc_ptr< ::mosek::fusion::Model > _3730,const std::string &  _3731,monty::rc_ptr< ::mosek::fusion::LinearDomain > _3732,monty::rc_ptr< ::mosek::fusion::Set > _3733,std::shared_ptr< monty::ndarray< int,1 > > _3734,std::shared_ptr< monty::ndarray< long long,1 > > _3735,std::shared_ptr< monty::ndarray< int,1 > > _3736,std::shared_ptr< monty::ndarray< double,1 > > _3737,std::shared_ptr< monty::ndarray< double,1 > > _3738,std::shared_ptr< monty::ndarray< int,1 > > _3739,std::shared_ptr< monty::ndarray< int,1 > > _3740,std::shared_ptr< monty::ndarray< int,1 > > _3741);
void _initialize(monty::rc_ptr< ::mosek::fusion::Model > _3730,const std::string &  _3731,monty::rc_ptr< ::mosek::fusion::LinearDomain > _3732,monty::rc_ptr< ::mosek::fusion::Set > _3733,std::shared_ptr< monty::ndarray< int,1 > > _3734,std::shared_ptr< monty::ndarray< long long,1 > > _3735,std::shared_ptr< monty::ndarray< int,1 > > _3736,std::shared_ptr< monty::ndarray< double,1 > > _3737,std::shared_ptr< monty::ndarray< double,1 > > _3738,std::shared_ptr< monty::ndarray< int,1 > > _3739,std::shared_ptr< monty::ndarray< int,1 > > _3740,std::shared_ptr< monty::ndarray< int,1 > > _3741);
virtual void add_fx(std::shared_ptr< monty::ndarray< long long,1 > > _3742,std::shared_ptr< monty::ndarray< double,1 > > _3743,long long _3744,int _3745,int _3746);
virtual void dual_values(long long _3751,std::shared_ptr< monty::ndarray< int,1 > > _3752,std::shared_ptr< monty::ndarray< long long,1 > > _3753,int _3754,std::shared_ptr< monty::ndarray< double,1 > > _3755);
virtual void dual_values(std::shared_ptr< monty::ndarray< long long,1 > > _3763,int _3764,std::shared_ptr< monty::ndarray< double,1 > > _3765);
virtual void level_values(long long _3769,std::shared_ptr< monty::ndarray< int,1 > > _3770,std::shared_ptr< monty::ndarray< long long,1 > > _3771,int _3772,std::shared_ptr< monty::ndarray< double,1 > > _3773);
virtual void level_values(std::shared_ptr< monty::ndarray< long long,1 > > _3781,int _3782,std::shared_ptr< monty::ndarray< double,1 > > _3783);
virtual void domainToString(long long _3787,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _3788);
virtual monty::rc_ptr< ::mosek::fusion::ModelConstraint > clone(monty::rc_ptr< ::mosek::fusion::Model > _3789);
}; // struct LinearConstraint;

struct p_Set
{
Set * _pubthis;
static mosek::fusion::p_Set* _get_impl(mosek::fusion::Set * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_Set * _get_impl(mosek::fusion::Set::t _inst) { return _get_impl(_inst.get()); }
p_Set(Set * _pubthis);
virtual ~p_Set() { /* std::cout << "~p_Set" << std::endl;*/ };
long long size{};int nd_p{};int nd{};virtual void destroy();
static Set::t _new_Set(int _4132,long long _4133);
void _initialize(int _4132,long long _4133);
virtual std::string toString();
virtual std::string indexToString(long long _4136) { throw monty::AbstractClassError("Call to abstract method"); }
virtual monty::rc_ptr< ::mosek::fusion::Set > slice(std::shared_ptr< monty::ndarray< int,1 > > _4137,std::shared_ptr< monty::ndarray< int,1 > > _4138) { throw monty::AbstractClassError("Call to abstract method"); }
virtual monty::rc_ptr< ::mosek::fusion::Set > slice(int _4139,int _4140) { throw monty::AbstractClassError("Call to abstract method"); }
virtual long long linearidx(int _4141,int _4142,int _4143);
virtual long long linearidx(int _4144,int _4145);
virtual long long linearidx(std::shared_ptr< monty::ndarray< int,1 > > _4146);
virtual std::shared_ptr< monty::ndarray< int,1 > > idxtokey(long long _4149);
virtual std::string getname(std::shared_ptr< monty::ndarray< int,1 > > _4153) { throw monty::AbstractClassError("Call to abstract method"); }
virtual std::string getname(long long _4154) { throw monty::AbstractClassError("Call to abstract method"); }
virtual long long stride(int _4155) { throw monty::AbstractClassError("Call to abstract method"); }
virtual int dim(int _4156) { throw monty::AbstractClassError("Call to abstract method"); }
static  monty::rc_ptr< ::mosek::fusion::Set > make(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Set >,1 > > _4157);
static  monty::rc_ptr< ::mosek::fusion::Set > make(monty::rc_ptr< ::mosek::fusion::Set > _4158,monty::rc_ptr< ::mosek::fusion::Set > _4159);
static  monty::rc_ptr< ::mosek::fusion::Set > make(std::shared_ptr< monty::ndarray< int,1 > > _4160);
static  monty::rc_ptr< ::mosek::fusion::Set > make(int _4161,int _4162,int _4163);
static  monty::rc_ptr< ::mosek::fusion::Set > make(int _4164,int _4165);
static  monty::rc_ptr< ::mosek::fusion::Set > make(int _4166);
static  monty::rc_ptr< ::mosek::fusion::Set > scalar();
static  monty::rc_ptr< ::mosek::fusion::Set > make(std::shared_ptr< monty::ndarray< std::string,1 > > _4167);
virtual int realnd();
virtual long long getSize();
virtual bool compare(monty::rc_ptr< ::mosek::fusion::Set > _4170);
}; // struct Set;

struct p_BaseSet : public ::mosek::fusion::p_Set
{
BaseSet * _pubthis;
static mosek::fusion::p_BaseSet* _get_impl(mosek::fusion::BaseSet * _inst){ return static_cast< mosek::fusion::p_BaseSet* >(mosek::fusion::p_Set::_get_impl(_inst)); }
static mosek::fusion::p_BaseSet * _get_impl(mosek::fusion::BaseSet::t _inst) { return _get_impl(_inst.get()); }
p_BaseSet(BaseSet * _pubthis);
virtual ~p_BaseSet() { /* std::cout << "~p_BaseSet" << std::endl;*/ };
virtual void destroy();
static BaseSet::t _new_BaseSet(long long _4091);
void _initialize(long long _4091);
virtual int dim(int _4092);
}; // struct BaseSet;

struct p_IntSet : public ::mosek::fusion::p_BaseSet
{
IntSet * _pubthis;
static mosek::fusion::p_IntSet* _get_impl(mosek::fusion::IntSet * _inst){ return static_cast< mosek::fusion::p_IntSet* >(mosek::fusion::p_BaseSet::_get_impl(_inst)); }
static mosek::fusion::p_IntSet * _get_impl(mosek::fusion::IntSet::t _inst) { return _get_impl(_inst.get()); }
p_IntSet(IntSet * _pubthis);
virtual ~p_IntSet() { /* std::cout << "~p_IntSet" << std::endl;*/ };
int last{};int first{};virtual void destroy();
static IntSet::t _new_IntSet(int _4063);
void _initialize(int _4063);
static IntSet::t _new_IntSet(int _4064,int _4065);
void _initialize(int _4064,int _4065);
virtual std::string indexToString(long long _4066);
virtual std::string getname(std::shared_ptr< monty::ndarray< int,1 > > _4067);
virtual std::string getname(long long _4068);
virtual monty::rc_ptr< ::mosek::fusion::Set > slice(std::shared_ptr< monty::ndarray< int,1 > > _4069,std::shared_ptr< monty::ndarray< int,1 > > _4070);
virtual monty::rc_ptr< ::mosek::fusion::Set > slice(int _4071,int _4072);
virtual int getidx(int _4073);
virtual long long stride(int _4074);
}; // struct IntSet;

struct p_StringSet : public ::mosek::fusion::p_BaseSet
{
StringSet * _pubthis;
static mosek::fusion::p_StringSet* _get_impl(mosek::fusion::StringSet * _inst){ return static_cast< mosek::fusion::p_StringSet* >(mosek::fusion::p_BaseSet::_get_impl(_inst)); }
static mosek::fusion::p_StringSet * _get_impl(mosek::fusion::StringSet::t _inst) { return _get_impl(_inst.get()); }
p_StringSet(StringSet * _pubthis);
virtual ~p_StringSet() { /* std::cout << "~p_StringSet" << std::endl;*/ };
std::shared_ptr< monty::ndarray< std::string,1 > > keys{};virtual void destroy();
static StringSet::t _new_StringSet(std::shared_ptr< monty::ndarray< std::string,1 > > _4075);
void _initialize(std::shared_ptr< monty::ndarray< std::string,1 > > _4075);
virtual std::string indexToString(long long _4076);
virtual std::string getname(std::shared_ptr< monty::ndarray< int,1 > > _4077);
virtual std::string getname(long long _4078);
virtual monty::rc_ptr< ::mosek::fusion::BaseSet > slice_(std::shared_ptr< monty::ndarray< int,1 > > _4079,std::shared_ptr< monty::ndarray< int,1 > > _4080);
virtual monty::rc_ptr< ::mosek::fusion::BaseSet > slice_(int _4081,int _4082);
virtual monty::rc_ptr< ::mosek::fusion::Set > slice(std::shared_ptr< monty::ndarray< int,1 > > _4084,std::shared_ptr< monty::ndarray< int,1 > > _4085);
virtual monty::rc_ptr< ::mosek::fusion::Set > slice(int _4086,int _4087);
virtual std::string toString();
virtual long long stride(int _4090);
}; // struct StringSet;

struct p_NDSet : public ::mosek::fusion::p_Set
{
NDSet * _pubthis;
static mosek::fusion::p_NDSet* _get_impl(mosek::fusion::NDSet * _inst){ return static_cast< mosek::fusion::p_NDSet* >(mosek::fusion::p_Set::_get_impl(_inst)); }
static mosek::fusion::p_NDSet * _get_impl(mosek::fusion::NDSet::t _inst) { return _get_impl(_inst.get()); }
p_NDSet(NDSet * _pubthis);
virtual ~p_NDSet() { /* std::cout << "~p_NDSet" << std::endl;*/ };
std::shared_ptr< monty::ndarray< long long,1 > > strides{};std::shared_ptr< monty::ndarray< int,1 > > dimdef{};virtual void destroy();
static NDSet::t _new_NDSet(int _4093,int _4094,int _4095);
void _initialize(int _4093,int _4094,int _4095);
static NDSet::t _new_NDSet(int _4096,int _4097);
void _initialize(int _4096,int _4097);
static NDSet::t _new_NDSet(std::shared_ptr< monty::ndarray< int,1 > > _4098);
void _initialize(std::shared_ptr< monty::ndarray< int,1 > > _4098);
virtual std::string indexToString(long long _4102);
virtual std::string getname(std::shared_ptr< monty::ndarray< int,1 > > _4106);
virtual std::string getname(long long _4110);
virtual int dim(int _4115);
virtual monty::rc_ptr< ::mosek::fusion::Set > slice(std::shared_ptr< monty::ndarray< int,1 > > _4116,std::shared_ptr< monty::ndarray< int,1 > > _4117);
virtual monty::rc_ptr< ::mosek::fusion::Set > slice(int _4121,int _4122);
virtual std::shared_ptr< monty::ndarray< int,1 > > selectidxs(std::shared_ptr< monty::ndarray< std::string,1 > > _4123);
virtual int linear_index_in_dim(int _4124,std::shared_ptr< monty::ndarray< int,1 > > _4125);
virtual int linear_index_in_dim(int _4126,int _4127);
static  long long sumdims(std::shared_ptr< monty::ndarray< int,1 > > _4128);
virtual long long stride(int _4131);
}; // struct NDSet;

struct p_ProductSet : public ::mosek::fusion::p_NDSet
{
ProductSet * _pubthis;
static mosek::fusion::p_ProductSet* _get_impl(mosek::fusion::ProductSet * _inst){ return static_cast< mosek::fusion::p_ProductSet* >(mosek::fusion::p_NDSet::_get_impl(_inst)); }
static mosek::fusion::p_ProductSet * _get_impl(mosek::fusion::ProductSet::t _inst) { return _get_impl(_inst.get()); }
p_ProductSet(ProductSet * _pubthis);
virtual ~p_ProductSet() { /* std::cout << "~p_ProductSet" << std::endl;*/ };
std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Set >,1 > > sets{};virtual void destroy();
static ProductSet::t _new_ProductSet(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Set >,1 > > _4045);
void _initialize(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Set >,1 > > _4045);
virtual std::string indexToString(long long _4047);
static  std::shared_ptr< monty::ndarray< int,1 > > computedims(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Set >,1 > > _4057);
}; // struct ProductSet;

struct p_QConeDomain
{
QConeDomain * _pubthis;
static mosek::fusion::p_QConeDomain* _get_impl(mosek::fusion::QConeDomain * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_QConeDomain * _get_impl(mosek::fusion::QConeDomain::t _inst) { return _get_impl(_inst.get()); }
p_QConeDomain(QConeDomain * _pubthis);
virtual ~p_QConeDomain() { /* std::cout << "~p_QConeDomain" << std::endl;*/ };
monty::rc_ptr< ::mosek::fusion::Set > shape{};bool int_flag{};int axisidx{};mosek::fusion::QConeKey key{};virtual void destroy();
static QConeDomain::t _new_QConeDomain(mosek::fusion::QConeKey _4173,std::shared_ptr< monty::ndarray< int,1 > > _4174,int _4175);
void _initialize(mosek::fusion::QConeKey _4173,std::shared_ptr< monty::ndarray< int,1 > > _4174,int _4175);
virtual std::string domainToString(long long _4176,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _4177);
virtual bool match_shape(monty::rc_ptr< ::mosek::fusion::Set > _4184);
virtual monty::rc_ptr< ::mosek::fusion::QConeDomain > integral();
virtual int getAxis();
virtual monty::rc_ptr< ::mosek::fusion::QConeDomain > axis(int _4185);
}; // struct QConeDomain;

struct p_LinPSDDomain
{
LinPSDDomain * _pubthis;
static mosek::fusion::p_LinPSDDomain* _get_impl(mosek::fusion::LinPSDDomain * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_LinPSDDomain * _get_impl(mosek::fusion::LinPSDDomain::t _inst) { return _get_impl(_inst.get()); }
p_LinPSDDomain(LinPSDDomain * _pubthis);
virtual ~p_LinPSDDomain() { /* std::cout << "~p_LinPSDDomain" << std::endl;*/ };
monty::rc_ptr< ::mosek::fusion::Set > shape{};virtual void destroy();
static LinPSDDomain::t _new_LinPSDDomain();
void _initialize();
static LinPSDDomain::t _new_LinPSDDomain(monty::rc_ptr< ::mosek::fusion::Set > _4186);
void _initialize(monty::rc_ptr< ::mosek::fusion::Set > _4186);
}; // struct LinPSDDomain;

struct p_PSDDomain
{
PSDDomain * _pubthis;
static mosek::fusion::p_PSDDomain* _get_impl(mosek::fusion::PSDDomain * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_PSDDomain * _get_impl(mosek::fusion::PSDDomain::t _inst) { return _get_impl(_inst.get()); }
p_PSDDomain(PSDDomain * _pubthis);
virtual ~p_PSDDomain() { /* std::cout << "~p_PSDDomain" << std::endl;*/ };
mosek::fusion::PSDKey key{};monty::rc_ptr< ::mosek::fusion::Set > shape{};virtual void destroy();
static PSDDomain::t _new_PSDDomain(mosek::fusion::PSDKey _4187);
void _initialize(mosek::fusion::PSDKey _4187);
static PSDDomain::t _new_PSDDomain(mosek::fusion::PSDKey _4188,monty::rc_ptr< ::mosek::fusion::Set > _4189);
void _initialize(mosek::fusion::PSDKey _4188,monty::rc_ptr< ::mosek::fusion::Set > _4189);
virtual std::string domainToString(long long _4190,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _4191);
}; // struct PSDDomain;

struct p_RangeDomain
{
RangeDomain * _pubthis;
static mosek::fusion::p_RangeDomain* _get_impl(mosek::fusion::RangeDomain * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_RangeDomain * _get_impl(mosek::fusion::RangeDomain::t _inst) { return _get_impl(_inst.get()); }
p_RangeDomain(RangeDomain * _pubthis);
virtual ~p_RangeDomain() { /* std::cout << "~p_RangeDomain" << std::endl;*/ };
bool sparse_flag{};bool cardinal_flag{};std::shared_ptr< monty::ndarray< double,1 > > ub{};std::shared_ptr< monty::ndarray< double,1 > > lb{};monty::rc_ptr< ::mosek::fusion::Utils::IntMap > idxmap{};monty::rc_ptr< ::mosek::fusion::Set > shape{};virtual void destroy();
static RangeDomain::t _new_RangeDomain(std::shared_ptr< monty::ndarray< double,1 > > _4196,std::shared_ptr< monty::ndarray< double,1 > > _4197,std::shared_ptr< monty::ndarray< int,1 > > _4198,std::shared_ptr< monty::ndarray< long long,1 > > _4199);
void _initialize(std::shared_ptr< monty::ndarray< double,1 > > _4196,std::shared_ptr< monty::ndarray< double,1 > > _4197,std::shared_ptr< monty::ndarray< int,1 > > _4198,std::shared_ptr< monty::ndarray< long long,1 > > _4199);
static RangeDomain::t _new_RangeDomain(monty::rc_ptr< ::mosek::fusion::RangeDomain > _4201);
void _initialize(monty::rc_ptr< ::mosek::fusion::RangeDomain > _4201);
virtual monty::rc_ptr< ::mosek::fusion::SymmetricRangeDomain > symmetric();
virtual monty::rc_ptr< ::mosek::fusion::RangeDomain > sparse();
virtual monty::rc_ptr< ::mosek::fusion::RangeDomain > integral();
virtual std::string domainToString(long long _4202,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _4203);
virtual bool match_shape(monty::rc_ptr< ::mosek::fusion::Set > _4204);
virtual double get_ub_item(long long _4205);
virtual double get_lb_item(long long _4206);
}; // struct RangeDomain;

struct p_SymmetricRangeDomain : public ::mosek::fusion::p_RangeDomain
{
SymmetricRangeDomain * _pubthis;
static mosek::fusion::p_SymmetricRangeDomain* _get_impl(mosek::fusion::SymmetricRangeDomain * _inst){ return static_cast< mosek::fusion::p_SymmetricRangeDomain* >(mosek::fusion::p_RangeDomain::_get_impl(_inst)); }
static mosek::fusion::p_SymmetricRangeDomain * _get_impl(mosek::fusion::SymmetricRangeDomain::t _inst) { return _get_impl(_inst.get()); }
p_SymmetricRangeDomain(SymmetricRangeDomain * _pubthis);
virtual ~p_SymmetricRangeDomain() { /* std::cout << "~p_SymmetricRangeDomain" << std::endl;*/ };
int dim{};virtual void destroy();
static SymmetricRangeDomain::t _new_SymmetricRangeDomain(monty::rc_ptr< ::mosek::fusion::RangeDomain > _4195);
void _initialize(monty::rc_ptr< ::mosek::fusion::RangeDomain > _4195);
}; // struct SymmetricRangeDomain;

struct p_SymmetricLinearDomain
{
SymmetricLinearDomain * _pubthis;
static mosek::fusion::p_SymmetricLinearDomain* _get_impl(mosek::fusion::SymmetricLinearDomain * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_SymmetricLinearDomain * _get_impl(mosek::fusion::SymmetricLinearDomain::t _inst) { return _get_impl(_inst.get()); }
p_SymmetricLinearDomain(SymmetricLinearDomain * _pubthis);
virtual ~p_SymmetricLinearDomain() { /* std::cout << "~p_SymmetricLinearDomain" << std::endl;*/ };
bool sparse_flag{};bool cardinal_flag{};mosek::fusion::RelationKey key{};monty::rc_ptr< ::mosek::fusion::Set > shape{};monty::rc_ptr< ::mosek::fusion::LinearDomain > dom{};int dim{};virtual void destroy();
static SymmetricLinearDomain::t _new_SymmetricLinearDomain(monty::rc_ptr< ::mosek::fusion::LinearDomain > _4207);
void _initialize(monty::rc_ptr< ::mosek::fusion::LinearDomain > _4207);
virtual monty::rc_ptr< ::mosek::fusion::SymmetricLinearDomain > sparse();
virtual monty::rc_ptr< ::mosek::fusion::SymmetricLinearDomain > integral();
virtual std::string domainToString(long long _4208,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _4209);
virtual bool match_shape(monty::rc_ptr< ::mosek::fusion::Set > _4210);
virtual double get_rhs_item(long long _4211);
}; // struct SymmetricLinearDomain;

struct p_LinearDomain
{
LinearDomain * _pubthis;
static mosek::fusion::p_LinearDomain* _get_impl(mosek::fusion::LinearDomain * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_LinearDomain * _get_impl(mosek::fusion::LinearDomain::t _inst) { return _get_impl(_inst.get()); }
p_LinearDomain(LinearDomain * _pubthis);
virtual ~p_LinearDomain() { /* std::cout << "~p_LinearDomain" << std::endl;*/ };
bool sparse_flag{};bool cardinal_flag{};mosek::fusion::RelationKey key{};std::shared_ptr< monty::ndarray< double,1 > > bnd{};monty::rc_ptr< ::mosek::fusion::Utils::IntMap > inst{};monty::rc_ptr< ::mosek::fusion::Set > shape{};virtual void destroy();
static LinearDomain::t _new_LinearDomain(mosek::fusion::RelationKey _4212,std::shared_ptr< monty::ndarray< double,1 > > _4213,std::shared_ptr< monty::ndarray< long long,1 > > _4214,std::shared_ptr< monty::ndarray< int,1 > > _4215);
void _initialize(mosek::fusion::RelationKey _4212,std::shared_ptr< monty::ndarray< double,1 > > _4213,std::shared_ptr< monty::ndarray< long long,1 > > _4214,std::shared_ptr< monty::ndarray< int,1 > > _4215);
static LinearDomain::t _new_LinearDomain(monty::rc_ptr< ::mosek::fusion::LinearDomain > _4217);
void _initialize(monty::rc_ptr< ::mosek::fusion::LinearDomain > _4217);
virtual monty::rc_ptr< ::mosek::fusion::SymmetricLinearDomain > symmetric();
virtual monty::rc_ptr< ::mosek::fusion::LinearDomain > sparse();
virtual monty::rc_ptr< ::mosek::fusion::LinearDomain > integral();
virtual std::string domainToString(long long _4218,monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _4219);
virtual bool match_shape(monty::rc_ptr< ::mosek::fusion::Set > _4220);
virtual double get_rhs_item(long long _4221);
virtual bool scalable();
}; // struct LinearDomain;

struct p_Domain
{
Domain * _pubthis;
static mosek::fusion::p_Domain* _get_impl(mosek::fusion::Domain * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_Domain * _get_impl(mosek::fusion::Domain::t _inst) { return _get_impl(_inst.get()); }
p_Domain(Domain * _pubthis);
virtual ~p_Domain() { /* std::cout << "~p_Domain" << std::endl;*/ };
virtual void destroy();
static  long long dimsize(std::shared_ptr< monty::ndarray< int,1 > > _4222);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > mkLinearDomain(mosek::fusion::RelationKey _4225,monty::rc_ptr< ::mosek::fusion::Matrix > _4226);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > mkLinearDomain(mosek::fusion::RelationKey _4232,std::shared_ptr< monty::ndarray< double,2 > > _4233);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > mkLinearDomain(mosek::fusion::RelationKey _4236,std::shared_ptr< monty::ndarray< double,1 > > _4237,std::shared_ptr< monty::ndarray< int,1 > > _4238);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > mkLinearDomain(mosek::fusion::RelationKey _4241,std::shared_ptr< monty::ndarray< double,1 > > _4242);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > mkLinearDomain(mosek::fusion::RelationKey _4244,double _4245,std::shared_ptr< monty::ndarray< int,1 > > _4246);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > mkLinearDomain(mosek::fusion::RelationKey _4249,double _4250);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > inRange(std::shared_ptr< monty::ndarray< double,1 > > _4251,std::shared_ptr< monty::ndarray< double,1 > > _4252,std::shared_ptr< monty::ndarray< int,1 > > _4253);
static  monty::rc_ptr< ::mosek::fusion::SymmetricRangeDomain > symmetric(monty::rc_ptr< ::mosek::fusion::RangeDomain > _4255);
static  monty::rc_ptr< ::mosek::fusion::SymmetricLinearDomain > symmetric(monty::rc_ptr< ::mosek::fusion::LinearDomain > _4256);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > sparse(monty::rc_ptr< ::mosek::fusion::RangeDomain > _4257);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > sparse(monty::rc_ptr< ::mosek::fusion::LinearDomain > _4258);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > integral(monty::rc_ptr< ::mosek::fusion::RangeDomain > _4259);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > integral(monty::rc_ptr< ::mosek::fusion::LinearDomain > _4260);
static  monty::rc_ptr< ::mosek::fusion::QConeDomain > integral(monty::rc_ptr< ::mosek::fusion::QConeDomain > _4261);
static  monty::rc_ptr< ::mosek::fusion::QConeDomain > axis(monty::rc_ptr< ::mosek::fusion::QConeDomain > _4262,int _4263);
static  monty::rc_ptr< ::mosek::fusion::QConeDomain > inRotatedQCone(std::shared_ptr< monty::ndarray< int,1 > > _4264);
static  monty::rc_ptr< ::mosek::fusion::QConeDomain > inRotatedQCone(int _4266,int _4267);
static  monty::rc_ptr< ::mosek::fusion::QConeDomain > inRotatedQCone(int _4268);
static  monty::rc_ptr< ::mosek::fusion::QConeDomain > inRotatedQCone();
static  monty::rc_ptr< ::mosek::fusion::QConeDomain > inQCone(std::shared_ptr< monty::ndarray< int,1 > > _4269);
static  monty::rc_ptr< ::mosek::fusion::QConeDomain > inQCone(int _4271,int _4272);
static  monty::rc_ptr< ::mosek::fusion::QConeDomain > inQCone(int _4273);
static  monty::rc_ptr< ::mosek::fusion::QConeDomain > inQCone();
static  monty::rc_ptr< ::mosek::fusion::LinPSDDomain > isLinPSD(int _4274,int _4275);
static  monty::rc_ptr< ::mosek::fusion::LinPSDDomain > isLinPSD(int _4276);
static  monty::rc_ptr< ::mosek::fusion::LinPSDDomain > isLinPSD();
static  monty::rc_ptr< ::mosek::fusion::PSDDomain > isTrilPSD(int _4277,int _4278);
static  monty::rc_ptr< ::mosek::fusion::PSDDomain > isTrilPSD(int _4279);
static  monty::rc_ptr< ::mosek::fusion::PSDDomain > isTrilPSD();
static  monty::rc_ptr< ::mosek::fusion::PSDDomain > inPSDCone(int _4280,int _4281);
static  monty::rc_ptr< ::mosek::fusion::PSDDomain > inPSDCone(int _4282);
static  monty::rc_ptr< ::mosek::fusion::PSDDomain > inPSDCone();
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > binary();
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > binary(std::shared_ptr< monty::ndarray< int,1 > > _4283);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > binary(int _4286,int _4287);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > binary(int _4290);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > inRange(monty::rc_ptr< ::mosek::fusion::Matrix > _4293,monty::rc_ptr< ::mosek::fusion::Matrix > _4294);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > inRange(monty::rc_ptr< ::mosek::fusion::Matrix > _4295,double _4296);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > inRange(double _4298,monty::rc_ptr< ::mosek::fusion::Matrix > _4299);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > inRange(std::shared_ptr< monty::ndarray< double,1 > > _4301,std::shared_ptr< monty::ndarray< double,1 > > _4302);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > inRange(std::shared_ptr< monty::ndarray< double,1 > > _4303,double _4304);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > inRange(double _4306,std::shared_ptr< monty::ndarray< double,1 > > _4307);
static  monty::rc_ptr< ::mosek::fusion::RangeDomain > inRange(double _4309,double _4310);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > greaterThan(monty::rc_ptr< ::mosek::fusion::Matrix > _4311);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > greaterThan(std::shared_ptr< monty::ndarray< double,1 > > _4312,std::shared_ptr< monty::ndarray< int,1 > > _4313);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > greaterThan(std::shared_ptr< monty::ndarray< double,2 > > _4314);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > greaterThan(std::shared_ptr< monty::ndarray< double,1 > > _4315);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > greaterThan(double _4316,std::shared_ptr< monty::ndarray< int,1 > > _4317);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > greaterThan(double _4318,int _4319,int _4320);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > greaterThan(double _4321,int _4322);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > greaterThan(double _4323);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > lessThan(monty::rc_ptr< ::mosek::fusion::Matrix > _4324);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > lessThan(std::shared_ptr< monty::ndarray< double,1 > > _4325,std::shared_ptr< monty::ndarray< int,1 > > _4326);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > lessThan(std::shared_ptr< monty::ndarray< double,2 > > _4327);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > lessThan(std::shared_ptr< monty::ndarray< double,1 > > _4328);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > lessThan(double _4329,std::shared_ptr< monty::ndarray< int,1 > > _4330);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > lessThan(double _4331,int _4332,int _4333);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > lessThan(double _4334,int _4335);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > lessThan(double _4336);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > equalsTo(monty::rc_ptr< ::mosek::fusion::Matrix > _4337);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > equalsTo(std::shared_ptr< monty::ndarray< double,1 > > _4338,std::shared_ptr< monty::ndarray< int,1 > > _4339);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > equalsTo(std::shared_ptr< monty::ndarray< double,2 > > _4340);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > equalsTo(std::shared_ptr< monty::ndarray< double,1 > > _4341);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > equalsTo(double _4342,std::shared_ptr< monty::ndarray< int,1 > > _4343);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > equalsTo(double _4344,int _4345,int _4346);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > equalsTo(double _4347,int _4348);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > equalsTo(double _4349);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > unbounded(std::shared_ptr< monty::ndarray< int,1 > > _4350);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > unbounded(int _4352,int _4353);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > unbounded(int _4354);
static  monty::rc_ptr< ::mosek::fusion::LinearDomain > unbounded();
}; // struct Domain;

struct p_SymmetricExpr
{
SymmetricExpr * _pubthis;
static mosek::fusion::p_SymmetricExpr* _get_impl(mosek::fusion::SymmetricExpr * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_SymmetricExpr * _get_impl(mosek::fusion::SymmetricExpr::t _inst) { return _get_impl(_inst.get()); }
p_SymmetricExpr(SymmetricExpr * _pubthis);
virtual ~p_SymmetricExpr() { /* std::cout << "~p_SymmetricExpr" << std::endl;*/ };
std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > xs{};monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > b{};std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::SymmetricMatrix >,1 > > Ms{};int n{};virtual void destroy();
static SymmetricExpr::t _new_SymmetricExpr(int _4363,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::SymmetricMatrix >,1 > > _4364,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _4365,monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > _4366);
void _initialize(int _4363,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::SymmetricMatrix >,1 > > _4364,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _4365,monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > _4366);
static  monty::rc_ptr< ::mosek::fusion::SymmetricExpr > add(monty::rc_ptr< ::mosek::fusion::SymmetricExpr > _4367,monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > _4368);
static  monty::rc_ptr< ::mosek::fusion::SymmetricExpr > mul(monty::rc_ptr< ::mosek::fusion::SymmetricExpr > _4369,double _4370);
static  monty::rc_ptr< ::mosek::fusion::SymmetricExpr > add(monty::rc_ptr< ::mosek::fusion::SymmetricExpr > _4372,monty::rc_ptr< ::mosek::fusion::SymmetricExpr > _4373);
virtual std::string toString();
}; // struct SymmetricExpr;

struct p_Expr : public /*implements*/ ::mosek::fusion::Expression
{
Expr * _pubthis;
static mosek::fusion::p_Expr* _get_impl(mosek::fusion::Expr * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_Expr * _get_impl(mosek::fusion::Expr::t _inst) { return _get_impl(_inst.get()); }
p_Expr(Expr * _pubthis);
virtual ~p_Expr() { /* std::cout << "~p_Expr" << std::endl;*/ };
std::shared_ptr< monty::ndarray< long long,1 > > varsb{};std::shared_ptr< monty::ndarray< long long,1 > > inst{};std::shared_ptr< monty::ndarray< double,1 > > cof_v{};std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > x{};std::shared_ptr< monty::ndarray< long long,1 > > subj{};std::shared_ptr< monty::ndarray< long long,1 > > ptrb{};std::shared_ptr< monty::ndarray< double,1 > > bfix{};monty::rc_ptr< ::mosek::fusion::Set > shape_p{};monty::rc_ptr< ::mosek::fusion::Model > model{};virtual void destroy();
static Expr::t _new_Expr(std::shared_ptr< monty::ndarray< long long,1 > > _4384,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _4385,std::shared_ptr< monty::ndarray< long long,1 > > _4386,std::shared_ptr< monty::ndarray< double,1 > > _4387,std::shared_ptr< monty::ndarray< double,1 > > _4388,monty::rc_ptr< ::mosek::fusion::Set > _4389,std::shared_ptr< monty::ndarray< long long,1 > > _4390);
void _initialize(std::shared_ptr< monty::ndarray< long long,1 > > _4384,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _4385,std::shared_ptr< monty::ndarray< long long,1 > > _4386,std::shared_ptr< monty::ndarray< double,1 > > _4387,std::shared_ptr< monty::ndarray< double,1 > > _4388,monty::rc_ptr< ::mosek::fusion::Set > _4389,std::shared_ptr< monty::ndarray< long long,1 > > _4390);
static Expr::t _new_Expr(std::shared_ptr< monty::ndarray< long long,1 > > _4394,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _4395,std::shared_ptr< monty::ndarray< long long,1 > > _4396,std::shared_ptr< monty::ndarray< double,1 > > _4397,std::shared_ptr< monty::ndarray< double,1 > > _4398,monty::rc_ptr< ::mosek::fusion::Set > _4399,std::shared_ptr< monty::ndarray< long long,1 > > _4400,int _4401);
void _initialize(std::shared_ptr< monty::ndarray< long long,1 > > _4394,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _4395,std::shared_ptr< monty::ndarray< long long,1 > > _4396,std::shared_ptr< monty::ndarray< double,1 > > _4397,std::shared_ptr< monty::ndarray< double,1 > > _4398,monty::rc_ptr< ::mosek::fusion::Set > _4399,std::shared_ptr< monty::ndarray< long long,1 > > _4400,int _4401);
static Expr::t _new_Expr(monty::rc_ptr< ::mosek::fusion::Expression > _4403);
void _initialize(monty::rc_ptr< ::mosek::fusion::Expression > _4403);
virtual std::string toString();
virtual void tostr(monty::rc_ptr< ::mosek::fusion::Utils::StringBuffer > _4412,int _4413);
static  std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > varstack(std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > >,1 > > _4419);
static  std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > varstack(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _4422,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _4423);
static  monty::rc_ptr< ::mosek::fusion::Expression > flatten(monty::rc_ptr< ::mosek::fusion::Expression > _4427);
static  monty::rc_ptr< ::mosek::fusion::Expression > reshape(monty::rc_ptr< ::mosek::fusion::Expression > _4428,int _4429,int _4430);
static  monty::rc_ptr< ::mosek::fusion::Expression > reshape(monty::rc_ptr< ::mosek::fusion::Expression > _4431,int _4432);
static  monty::rc_ptr< ::mosek::fusion::Expression > reshape(monty::rc_ptr< ::mosek::fusion::Expression > _4433,monty::rc_ptr< ::mosek::fusion::Set > _4434);
virtual long long size();
virtual monty::rc_ptr< ::mosek::fusion::FlatExpr > eval();
static  monty::rc_ptr< ::mosek::fusion::Expression > zeros(int _4440);
static  monty::rc_ptr< ::mosek::fusion::Expression > ones(int _4446);
static  monty::rc_ptr< ::mosek::fusion::Expression > constTerm(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _4451);
static  monty::rc_ptr< ::mosek::fusion::Expression > constTerm(monty::rc_ptr< ::mosek::fusion::Matrix > _4459);
static  monty::rc_ptr< ::mosek::fusion::Expression > constTerm(double _4471);
static  monty::rc_ptr< ::mosek::fusion::Expression > constTerm(monty::rc_ptr< ::mosek::fusion::Set > _4477,double _4478);
static  monty::rc_ptr< ::mosek::fusion::Expression > constTerm(int _4484,double _4485);
static  monty::rc_ptr< ::mosek::fusion::Expression > constTerm(std::shared_ptr< monty::ndarray< double,2 > > _4491);
static  monty::rc_ptr< ::mosek::fusion::Expression > constTerm(std::shared_ptr< monty::ndarray< double,1 > > _4501);
virtual long long numNonzeros();
static  monty::rc_ptr< ::mosek::fusion::Expression > sum_expr(monty::rc_ptr< ::mosek::fusion::Expression > _4507,int _4508,int _4509);
static  monty::rc_ptr< ::mosek::fusion::Expression > sum_var(monty::rc_ptr< ::mosek::fusion::Variable > _4555,int _4556,int _4557);
static  monty::rc_ptr< ::mosek::fusion::Expression > sum(monty::rc_ptr< ::mosek::fusion::Expression > _4587,int _4588,int _4589);
static  monty::rc_ptr< ::mosek::fusion::Expression > sum(monty::rc_ptr< ::mosek::fusion::Expression > _4590,int _4591);
static  monty::rc_ptr< ::mosek::fusion::Expression > sum(monty::rc_ptr< ::mosek::fusion::Variable > _4592,int _4593,int _4594);
static  monty::rc_ptr< ::mosek::fusion::Expression > sum(monty::rc_ptr< ::mosek::fusion::Variable > _4595,int _4596);
static  monty::rc_ptr< ::mosek::fusion::Expression > sum(monty::rc_ptr< ::mosek::fusion::Variable > _4597);
static  monty::rc_ptr< ::mosek::fusion::Expression > sum(monty::rc_ptr< ::mosek::fusion::Expression > _4598);
static  monty::rc_ptr< ::mosek::fusion::Expression > neg(monty::rc_ptr< ::mosek::fusion::Variable > _4606);
static  monty::rc_ptr< ::mosek::fusion::Expression > neg(monty::rc_ptr< ::mosek::fusion::Expression > _4611);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul__(monty::rc_ptr< ::mosek::fusion::Matrix > _4617,monty::rc_ptr< ::mosek::fusion::Expression > _4618);
static  void sparseMatrixVector(std::shared_ptr< monty::ndarray< long long,1 > > _4730,std::shared_ptr< monty::ndarray< int,1 > > _4731,std::shared_ptr< monty::ndarray< double,1 > > _4732,std::shared_ptr< monty::ndarray< double,1 > > _4733,std::shared_ptr< monty::ndarray< double,1 > > _4734,int _4735);
static  void sparseMatmul(std::shared_ptr< monty::ndarray< long long,1 > > _4740,std::shared_ptr< monty::ndarray< int,1 > > _4741,std::shared_ptr< monty::ndarray< double,1 > > _4742,std::shared_ptr< monty::ndarray< long long,1 > > _4743,std::shared_ptr< monty::ndarray< int,1 > > _4744,std::shared_ptr< monty::ndarray< double,1 > > _4745,std::shared_ptr< monty::ndarray< long long,1 > > _4746,std::shared_ptr< monty::ndarray< int,1 > > _4747,std::shared_ptr< monty::ndarray< double,1 > > _4748,int _4749,int _4750,std::shared_ptr< monty::ndarray< int,1 > > _4751);
static  long long computeNz(std::shared_ptr< monty::ndarray< long long,1 > > _4763,std::shared_ptr< monty::ndarray< int,1 > > _4764,std::shared_ptr< monty::ndarray< long long,1 > > _4765,std::shared_ptr< monty::ndarray< int,1 > > _4766,int _4767,int _4768,std::shared_ptr< monty::ndarray< int,1 > > _4769,std::shared_ptr< monty::ndarray< long long,1 > > _4770);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulDiag(monty::rc_ptr< ::mosek::fusion::Variable > _4779,monty::rc_ptr< ::mosek::fusion::Matrix > _4780);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulDiag(monty::rc_ptr< ::mosek::fusion::Matrix > _4805,monty::rc_ptr< ::mosek::fusion::Variable > _4806);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulDiag(monty::rc_ptr< ::mosek::fusion::Expression > _4825,monty::rc_ptr< ::mosek::fusion::Matrix > _4826);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulDiag(monty::rc_ptr< ::mosek::fusion::Matrix > _4909,monty::rc_ptr< ::mosek::fusion::Expression > _4910);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulDiag(monty::rc_ptr< ::mosek::fusion::Variable > _4975,std::shared_ptr< monty::ndarray< double,2 > > _4976);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulDiag(std::shared_ptr< monty::ndarray< double,2 > > _4977,monty::rc_ptr< ::mosek::fusion::Variable > _4978);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulDiag(monty::rc_ptr< ::mosek::fusion::Expression > _4979,std::shared_ptr< monty::ndarray< double,2 > > _4980);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulDiag(std::shared_ptr< monty::ndarray< double,2 > > _4981,monty::rc_ptr< ::mosek::fusion::Expression > _4982);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm_(monty::rc_ptr< ::mosek::fusion::Matrix > _4983,monty::rc_ptr< ::mosek::fusion::Expression > _4984);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm_(monty::rc_ptr< ::mosek::fusion::Matrix > _4992,monty::rc_ptr< ::mosek::fusion::Variable > _4993);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm_(std::shared_ptr< monty::ndarray< double,1 > > _5000,monty::rc_ptr< ::mosek::fusion::Variable > _5001);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm_(std::shared_ptr< monty::ndarray< double,1 > > _5002,monty::rc_ptr< ::mosek::fusion::Expression > _5003);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm_(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _5005,monty::rc_ptr< ::mosek::fusion::Expression > _5006);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm_(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _5011,monty::rc_ptr< ::mosek::fusion::Variable > _5012);
static  monty::rc_ptr< ::mosek::fusion::Expression > dotmul_(std::shared_ptr< monty::ndarray< long long,1 > > _5014,std::shared_ptr< monty::ndarray< double,1 > > _5015,monty::rc_ptr< ::mosek::fusion::Variable > _5016,monty::rc_ptr< ::mosek::fusion::Set > _5017);
static  monty::rc_ptr< ::mosek::fusion::Expression > dotmul_(std::shared_ptr< monty::ndarray< long long,1 > > _5023,std::shared_ptr< monty::ndarray< double,1 > > _5024,std::shared_ptr< monty::ndarray< long long,1 > > _5025,std::shared_ptr< monty::ndarray< long long,1 > > _5026,std::shared_ptr< monty::ndarray< double,1 > > _5027,std::shared_ptr< monty::ndarray< double,1 > > _5028,std::shared_ptr< monty::ndarray< long long,1 > > _5029,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _5030,monty::rc_ptr< ::mosek::fusion::Set > _5031);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(monty::rc_ptr< ::mosek::fusion::Matrix > _5052,monty::rc_ptr< ::mosek::fusion::Expression > _5053);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(monty::rc_ptr< ::mosek::fusion::Expression > _5066,monty::rc_ptr< ::mosek::fusion::Matrix > _5067);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(monty::rc_ptr< ::mosek::fusion::Expression > _5080,std::shared_ptr< monty::ndarray< double,1 > > _5081);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(std::shared_ptr< monty::ndarray< double,1 > > _5089,monty::rc_ptr< ::mosek::fusion::Expression > _5090);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(double _5098,monty::rc_ptr< ::mosek::fusion::Expression > _5099);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(monty::rc_ptr< ::mosek::fusion::Expression > _5103,double _5104);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul_SMatrix_2DSExpr(std::shared_ptr< monty::ndarray< long long,1 > > _5105,std::shared_ptr< monty::ndarray< long long,1 > > _5106,std::shared_ptr< monty::ndarray< double,1 > > _5107,std::shared_ptr< monty::ndarray< double,1 > > _5108,std::shared_ptr< monty::ndarray< long long,1 > > _5109,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _5110,monty::rc_ptr< ::mosek::fusion::Set > _5111,int _5112,int _5113,std::shared_ptr< monty::ndarray< int,1 > > _5114,std::shared_ptr< monty::ndarray< int,1 > > _5115,std::shared_ptr< monty::ndarray< double,1 > > _5116,int _5117,int _5118);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul_2DSExpr_SMatrix(std::shared_ptr< monty::ndarray< long long,1 > > _5170,std::shared_ptr< monty::ndarray< long long,1 > > _5171,std::shared_ptr< monty::ndarray< double,1 > > _5172,std::shared_ptr< monty::ndarray< double,1 > > _5173,std::shared_ptr< monty::ndarray< long long,1 > > _5174,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _5175,monty::rc_ptr< ::mosek::fusion::Set > _5176,int _5177,int _5178,std::shared_ptr< monty::ndarray< int,1 > > _5179,std::shared_ptr< monty::ndarray< int,1 > > _5180,std::shared_ptr< monty::ndarray< double,1 > > _5181,int _5182,int _5183);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul_DMatrix_2DDExpr(std::shared_ptr< monty::ndarray< long long,1 > > _5231,std::shared_ptr< monty::ndarray< long long,1 > > _5232,std::shared_ptr< monty::ndarray< double,1 > > _5233,std::shared_ptr< monty::ndarray< double,1 > > _5234,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _5235,monty::rc_ptr< ::mosek::fusion::Set > _5236,int _5237,int _5238,std::shared_ptr< monty::ndarray< double,1 > > _5239,int _5240,int _5241);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul_2DDExpr_DMatrix(std::shared_ptr< monty::ndarray< long long,1 > > _5261,std::shared_ptr< monty::ndarray< long long,1 > > _5262,std::shared_ptr< monty::ndarray< double,1 > > _5263,std::shared_ptr< monty::ndarray< double,1 > > _5264,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _5265,monty::rc_ptr< ::mosek::fusion::Set > _5266,int _5267,int _5268,std::shared_ptr< monty::ndarray< double,1 > > _5269,int _5270,int _5271);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul_0DExpr_Matrix(std::shared_ptr< monty::ndarray< long long,1 > > _5293,std::shared_ptr< monty::ndarray< double,1 > > _5294,std::shared_ptr< monty::ndarray< double,1 > > _5295,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _5296,monty::rc_ptr< ::mosek::fusion::Matrix > _5297);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(monty::rc_ptr< ::mosek::fusion::Variable > _5315,std::shared_ptr< monty::ndarray< double,2 > > _5316);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(std::shared_ptr< monty::ndarray< double,2 > > _5320,monty::rc_ptr< ::mosek::fusion::Variable > _5321);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(monty::rc_ptr< ::mosek::fusion::Variable > _5322,double _5323);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(double _5324,monty::rc_ptr< ::mosek::fusion::Variable > _5325);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(std::shared_ptr< monty::ndarray< double,1 > > _5332,monty::rc_ptr< ::mosek::fusion::Variable > _5333);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(monty::rc_ptr< ::mosek::fusion::Variable > _5345,std::shared_ptr< monty::ndarray< double,1 > > _5346);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(monty::rc_ptr< ::mosek::fusion::Variable > _5364,monty::rc_ptr< ::mosek::fusion::Matrix > _5365);
static  monty::rc_ptr< ::mosek::fusion::Expression > mul(monty::rc_ptr< ::mosek::fusion::Matrix > _5408,monty::rc_ptr< ::mosek::fusion::Variable > _5409);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot_(monty::rc_ptr< ::mosek::fusion::Matrix > _5455,monty::rc_ptr< ::mosek::fusion::Expression > _5456);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot_(monty::rc_ptr< ::mosek::fusion::Matrix > _5464,monty::rc_ptr< ::mosek::fusion::Variable > _5465);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot_(std::shared_ptr< monty::ndarray< double,1 > > _5472,monty::rc_ptr< ::mosek::fusion::Variable > _5473);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot_(std::shared_ptr< monty::ndarray< double,1 > > _5474,monty::rc_ptr< ::mosek::fusion::Expression > _5475);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot_(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _5477,monty::rc_ptr< ::mosek::fusion::Expression > _5478);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot_(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _5483,monty::rc_ptr< ::mosek::fusion::Variable > _5484);
static  monty::rc_ptr< ::mosek::fusion::Expression > inner_(std::shared_ptr< monty::ndarray< long long,1 > > _5486,std::shared_ptr< monty::ndarray< double,1 > > _5487,monty::rc_ptr< ::mosek::fusion::Variable > _5488);
static  monty::rc_ptr< ::mosek::fusion::Expression > inner_(std::shared_ptr< monty::ndarray< long long,1 > > _5494,std::shared_ptr< monty::ndarray< double,1 > > _5495,std::shared_ptr< monty::ndarray< long long,1 > > _5496,std::shared_ptr< monty::ndarray< long long,1 > > _5497,std::shared_ptr< monty::ndarray< double,1 > > _5498,std::shared_ptr< monty::ndarray< double,1 > > _5499,std::shared_ptr< monty::ndarray< long long,1 > > _5500,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _5501);
static  monty::rc_ptr< ::mosek::fusion::Expression > outer(std::shared_ptr< monty::ndarray< double,1 > > _5518,monty::rc_ptr< ::mosek::fusion::Expression > _5519);
static  monty::rc_ptr< ::mosek::fusion::Expression > outer(monty::rc_ptr< ::mosek::fusion::Expression > _5522,std::shared_ptr< monty::ndarray< double,1 > > _5523);
static  monty::rc_ptr< ::mosek::fusion::Expression > outer(monty::rc_ptr< ::mosek::fusion::Matrix > _5526,monty::rc_ptr< ::mosek::fusion::Variable > _5527);
static  monty::rc_ptr< ::mosek::fusion::Expression > outer(monty::rc_ptr< ::mosek::fusion::Variable > _5533,monty::rc_ptr< ::mosek::fusion::Matrix > _5534);
static  monty::rc_ptr< ::mosek::fusion::Expression > outer(std::shared_ptr< monty::ndarray< double,1 > > _5540,monty::rc_ptr< ::mosek::fusion::Variable > _5541);
static  monty::rc_ptr< ::mosek::fusion::Expression > outer(monty::rc_ptr< ::mosek::fusion::Variable > _5542,std::shared_ptr< monty::ndarray< double,1 > > _5543);
static  monty::rc_ptr< ::mosek::fusion::Expression > outer_(int _5544,std::shared_ptr< monty::ndarray< long long,1 > > _5545,std::shared_ptr< monty::ndarray< long long,1 > > _5546,std::shared_ptr< monty::ndarray< double,1 > > _5547,std::shared_ptr< monty::ndarray< double,1 > > _5548,std::shared_ptr< monty::ndarray< long long,1 > > _5549,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _5550,std::shared_ptr< monty::ndarray< double,1 > > _5551,std::shared_ptr< monty::ndarray< int,1 > > _5552,int _5553,bool _5554);
static  monty::rc_ptr< ::mosek::fusion::Expression > outer_(monty::rc_ptr< ::mosek::fusion::Variable > _5584,int _5585,std::shared_ptr< monty::ndarray< double,1 > > _5586,std::shared_ptr< monty::ndarray< int,1 > > _5587,int _5588,bool _5589);
virtual monty::rc_ptr< ::mosek::fusion::Expression > pick(std::shared_ptr< monty::ndarray< int,2 > > _5606);
virtual monty::rc_ptr< ::mosek::fusion::Expression > pick(std::shared_ptr< monty::ndarray< int,1 > > _5612);
virtual monty::rc_ptr< ::mosek::fusion::Expression > pick_(std::shared_ptr< monty::ndarray< long long,1 > > _5615);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Expression >,1 > >,1 > > _5653);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5659,double _5660,double _5661);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5662,double _5663,monty::rc_ptr< ::mosek::fusion::Variable > _5664);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5665,double _5666,monty::rc_ptr< ::mosek::fusion::Expression > _5667);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5668,monty::rc_ptr< ::mosek::fusion::Variable > _5669,double _5670);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5671,monty::rc_ptr< ::mosek::fusion::Variable > _5672,monty::rc_ptr< ::mosek::fusion::Variable > _5673);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5674,monty::rc_ptr< ::mosek::fusion::Variable > _5675,monty::rc_ptr< ::mosek::fusion::Expression > _5676);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5677,monty::rc_ptr< ::mosek::fusion::Expression > _5678,double _5679);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5680,monty::rc_ptr< ::mosek::fusion::Expression > _5681,monty::rc_ptr< ::mosek::fusion::Variable > _5682);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5683,monty::rc_ptr< ::mosek::fusion::Expression > _5684,monty::rc_ptr< ::mosek::fusion::Expression > _5685);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5686,double _5687,double _5688);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5689,double _5690,monty::rc_ptr< ::mosek::fusion::Variable > _5691);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5692,double _5693,monty::rc_ptr< ::mosek::fusion::Expression > _5694);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5695,monty::rc_ptr< ::mosek::fusion::Variable > _5696,double _5697);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5698,monty::rc_ptr< ::mosek::fusion::Variable > _5699,monty::rc_ptr< ::mosek::fusion::Variable > _5700);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5701,monty::rc_ptr< ::mosek::fusion::Variable > _5702,monty::rc_ptr< ::mosek::fusion::Expression > _5703);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5704,monty::rc_ptr< ::mosek::fusion::Expression > _5705,double _5706);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5707,monty::rc_ptr< ::mosek::fusion::Expression > _5708,monty::rc_ptr< ::mosek::fusion::Variable > _5709);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5710,monty::rc_ptr< ::mosek::fusion::Expression > _5711,monty::rc_ptr< ::mosek::fusion::Expression > _5712);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5713,double _5714,double _5715);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5716,double _5717,monty::rc_ptr< ::mosek::fusion::Variable > _5718);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5719,double _5720,monty::rc_ptr< ::mosek::fusion::Expression > _5721);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5722,monty::rc_ptr< ::mosek::fusion::Variable > _5723,double _5724);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5725,monty::rc_ptr< ::mosek::fusion::Variable > _5726,monty::rc_ptr< ::mosek::fusion::Variable > _5727);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5728,monty::rc_ptr< ::mosek::fusion::Variable > _5729,monty::rc_ptr< ::mosek::fusion::Expression > _5730);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5731,monty::rc_ptr< ::mosek::fusion::Expression > _5732,double _5733);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5734,monty::rc_ptr< ::mosek::fusion::Expression > _5735,monty::rc_ptr< ::mosek::fusion::Variable > _5736);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5737,monty::rc_ptr< ::mosek::fusion::Expression > _5738,monty::rc_ptr< ::mosek::fusion::Expression > _5739);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5740,monty::rc_ptr< ::mosek::fusion::Variable > _5741);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(double _5742,monty::rc_ptr< ::mosek::fusion::Expression > _5743);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5744,double _5745);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5746,monty::rc_ptr< ::mosek::fusion::Variable > _5747);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Variable > _5748,monty::rc_ptr< ::mosek::fusion::Expression > _5749);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5750,double _5751);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5752,monty::rc_ptr< ::mosek::fusion::Variable > _5753);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(monty::rc_ptr< ::mosek::fusion::Expression > _5754,monty::rc_ptr< ::mosek::fusion::Expression > _5755);
static  monty::rc_ptr< ::mosek::fusion::Expression > vstack(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Expression >,1 > > _5756);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5758,monty::rc_ptr< ::mosek::fusion::Expression > _5759,monty::rc_ptr< ::mosek::fusion::Expression > _5760);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5761,monty::rc_ptr< ::mosek::fusion::Expression > _5762,monty::rc_ptr< ::mosek::fusion::Variable > _5763);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5764,monty::rc_ptr< ::mosek::fusion::Expression > _5765,double _5766);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5767,monty::rc_ptr< ::mosek::fusion::Variable > _5768,monty::rc_ptr< ::mosek::fusion::Expression > _5769);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5770,monty::rc_ptr< ::mosek::fusion::Variable > _5771,monty::rc_ptr< ::mosek::fusion::Variable > _5772);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5773,monty::rc_ptr< ::mosek::fusion::Variable > _5774,double _5775);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5776,double _5777,monty::rc_ptr< ::mosek::fusion::Expression > _5778);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5779,double _5780,monty::rc_ptr< ::mosek::fusion::Variable > _5781);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5782,double _5783,double _5784);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5785,monty::rc_ptr< ::mosek::fusion::Expression > _5786,monty::rc_ptr< ::mosek::fusion::Expression > _5787);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5788,monty::rc_ptr< ::mosek::fusion::Expression > _5789,monty::rc_ptr< ::mosek::fusion::Variable > _5790);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5791,monty::rc_ptr< ::mosek::fusion::Expression > _5792,double _5793);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5794,monty::rc_ptr< ::mosek::fusion::Variable > _5795,monty::rc_ptr< ::mosek::fusion::Expression > _5796);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5797,monty::rc_ptr< ::mosek::fusion::Variable > _5798,monty::rc_ptr< ::mosek::fusion::Variable > _5799);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5800,monty::rc_ptr< ::mosek::fusion::Variable > _5801,double _5802);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5803,double _5804,monty::rc_ptr< ::mosek::fusion::Expression > _5805);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5806,double _5807,monty::rc_ptr< ::mosek::fusion::Variable > _5808);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5809,double _5810,double _5811);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(double _5812,monty::rc_ptr< ::mosek::fusion::Expression > _5813,monty::rc_ptr< ::mosek::fusion::Expression > _5814);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(double _5815,monty::rc_ptr< ::mosek::fusion::Expression > _5816,monty::rc_ptr< ::mosek::fusion::Variable > _5817);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(double _5818,monty::rc_ptr< ::mosek::fusion::Expression > _5819,double _5820);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(double _5821,monty::rc_ptr< ::mosek::fusion::Variable > _5822,monty::rc_ptr< ::mosek::fusion::Expression > _5823);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(double _5824,monty::rc_ptr< ::mosek::fusion::Variable > _5825,monty::rc_ptr< ::mosek::fusion::Variable > _5826);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(double _5827,monty::rc_ptr< ::mosek::fusion::Variable > _5828,double _5829);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(double _5830,double _5831,monty::rc_ptr< ::mosek::fusion::Expression > _5832);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(double _5833,double _5834,monty::rc_ptr< ::mosek::fusion::Variable > _5835);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5836,monty::rc_ptr< ::mosek::fusion::Expression > _5837);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5838,monty::rc_ptr< ::mosek::fusion::Variable > _5839);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Variable > _5840,double _5841);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(double _5842,monty::rc_ptr< ::mosek::fusion::Expression > _5843);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(double _5844,monty::rc_ptr< ::mosek::fusion::Variable > _5845);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5846,monty::rc_ptr< ::mosek::fusion::Variable > _5847);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5848,double _5849);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(monty::rc_ptr< ::mosek::fusion::Expression > _5850,monty::rc_ptr< ::mosek::fusion::Expression > _5851);
static  monty::rc_ptr< ::mosek::fusion::Expression > hstack(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Expression >,1 > > _5852);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5854,monty::rc_ptr< ::mosek::fusion::Expression > _5855,monty::rc_ptr< ::mosek::fusion::Expression > _5856,monty::rc_ptr< ::mosek::fusion::Expression > _5857);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5858,monty::rc_ptr< ::mosek::fusion::Expression > _5859,monty::rc_ptr< ::mosek::fusion::Expression > _5860,monty::rc_ptr< ::mosek::fusion::Variable > _5861);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5862,monty::rc_ptr< ::mosek::fusion::Expression > _5863,monty::rc_ptr< ::mosek::fusion::Expression > _5864,double _5865);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5866,monty::rc_ptr< ::mosek::fusion::Expression > _5867,monty::rc_ptr< ::mosek::fusion::Variable > _5868,monty::rc_ptr< ::mosek::fusion::Expression > _5869);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5870,monty::rc_ptr< ::mosek::fusion::Expression > _5871,monty::rc_ptr< ::mosek::fusion::Variable > _5872,monty::rc_ptr< ::mosek::fusion::Variable > _5873);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5874,monty::rc_ptr< ::mosek::fusion::Expression > _5875,monty::rc_ptr< ::mosek::fusion::Variable > _5876,double _5877);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5878,monty::rc_ptr< ::mosek::fusion::Expression > _5879,double _5880,monty::rc_ptr< ::mosek::fusion::Expression > _5881);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5882,monty::rc_ptr< ::mosek::fusion::Expression > _5883,double _5884,monty::rc_ptr< ::mosek::fusion::Variable > _5885);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5886,monty::rc_ptr< ::mosek::fusion::Expression > _5887,double _5888,double _5889);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5890,monty::rc_ptr< ::mosek::fusion::Variable > _5891,monty::rc_ptr< ::mosek::fusion::Expression > _5892,monty::rc_ptr< ::mosek::fusion::Expression > _5893);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5894,monty::rc_ptr< ::mosek::fusion::Variable > _5895,monty::rc_ptr< ::mosek::fusion::Expression > _5896,monty::rc_ptr< ::mosek::fusion::Variable > _5897);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5898,monty::rc_ptr< ::mosek::fusion::Variable > _5899,monty::rc_ptr< ::mosek::fusion::Expression > _5900,double _5901);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5902,monty::rc_ptr< ::mosek::fusion::Variable > _5903,monty::rc_ptr< ::mosek::fusion::Variable > _5904,monty::rc_ptr< ::mosek::fusion::Expression > _5905);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5906,monty::rc_ptr< ::mosek::fusion::Variable > _5907,monty::rc_ptr< ::mosek::fusion::Variable > _5908,monty::rc_ptr< ::mosek::fusion::Variable > _5909);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5910,monty::rc_ptr< ::mosek::fusion::Variable > _5911,monty::rc_ptr< ::mosek::fusion::Variable > _5912,double _5913);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5914,monty::rc_ptr< ::mosek::fusion::Variable > _5915,double _5916,monty::rc_ptr< ::mosek::fusion::Expression > _5917);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5918,monty::rc_ptr< ::mosek::fusion::Variable > _5919,double _5920,monty::rc_ptr< ::mosek::fusion::Variable > _5921);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5922,monty::rc_ptr< ::mosek::fusion::Variable > _5923,double _5924,double _5925);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5926,double _5927,monty::rc_ptr< ::mosek::fusion::Expression > _5928,monty::rc_ptr< ::mosek::fusion::Expression > _5929);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5930,double _5931,monty::rc_ptr< ::mosek::fusion::Expression > _5932,monty::rc_ptr< ::mosek::fusion::Variable > _5933);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5934,double _5935,monty::rc_ptr< ::mosek::fusion::Expression > _5936,double _5937);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5938,double _5939,monty::rc_ptr< ::mosek::fusion::Variable > _5940,monty::rc_ptr< ::mosek::fusion::Expression > _5941);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5942,double _5943,monty::rc_ptr< ::mosek::fusion::Variable > _5944,monty::rc_ptr< ::mosek::fusion::Variable > _5945);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5946,double _5947,monty::rc_ptr< ::mosek::fusion::Variable > _5948,double _5949);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5950,double _5951,double _5952,monty::rc_ptr< ::mosek::fusion::Expression > _5953);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5954,double _5955,double _5956,monty::rc_ptr< ::mosek::fusion::Variable > _5957);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5958,monty::rc_ptr< ::mosek::fusion::Variable > _5959,monty::rc_ptr< ::mosek::fusion::Expression > _5960);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5961,monty::rc_ptr< ::mosek::fusion::Variable > _5962,monty::rc_ptr< ::mosek::fusion::Variable > _5963);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5964,monty::rc_ptr< ::mosek::fusion::Variable > _5965,double _5966);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5967,double _5968,monty::rc_ptr< ::mosek::fusion::Expression > _5969);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5970,double _5971,monty::rc_ptr< ::mosek::fusion::Variable > _5972);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5973,monty::rc_ptr< ::mosek::fusion::Expression > _5974,monty::rc_ptr< ::mosek::fusion::Variable > _5975);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5976,monty::rc_ptr< ::mosek::fusion::Expression > _5977,double _5978);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5979,monty::rc_ptr< ::mosek::fusion::Expression > _5980,monty::rc_ptr< ::mosek::fusion::Expression > _5981);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack(int _5982,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Expression >,1 > > _5983);
static  monty::rc_ptr< ::mosek::fusion::Expression > stack_(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Expression >,1 > > _5984,int _5985);
static  monty::rc_ptr< ::mosek::fusion::Expression > repeat(monty::rc_ptr< ::mosek::fusion::Expression > _6074,int _6075,int _6076);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Expression >,1 > > _6078);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _6148);
static  monty::rc_ptr< ::mosek::fusion::Expression > add_(monty::rc_ptr< ::mosek::fusion::Expression > _6161,double _6162,monty::rc_ptr< ::mosek::fusion::Expression > _6163,double _6164);
virtual monty::rc_ptr< ::mosek::fusion::Expression > transpose();
virtual monty::rc_ptr< ::mosek::fusion::Expression > slice(std::shared_ptr< monty::ndarray< int,1 > > _6264,std::shared_ptr< monty::ndarray< int,1 > > _6265);
virtual monty::rc_ptr< ::mosek::fusion::Expression > index(std::shared_ptr< monty::ndarray< int,1 > > _6306);
virtual monty::rc_ptr< ::mosek::fusion::Expression > index(int _6309);
virtual monty::rc_ptr< ::mosek::fusion::Expression > slice(int _6310,int _6311);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::Matrix > _6312,monty::rc_ptr< ::mosek::fusion::Expression > _6313);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::Matrix > _6314,monty::rc_ptr< ::mosek::fusion::Variable > _6315);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6316,monty::rc_ptr< ::mosek::fusion::Variable > _6317);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6318,monty::rc_ptr< ::mosek::fusion::Expression > _6319);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(std::shared_ptr< monty::ndarray< double,2 > > _6320,monty::rc_ptr< ::mosek::fusion::Variable > _6321);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(std::shared_ptr< monty::ndarray< double,2 > > _6322,monty::rc_ptr< ::mosek::fusion::Expression > _6323);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(std::shared_ptr< monty::ndarray< double,1 > > _6324,monty::rc_ptr< ::mosek::fusion::Variable > _6325);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(std::shared_ptr< monty::ndarray< double,1 > > _6326,monty::rc_ptr< ::mosek::fusion::Expression > _6327);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::Expression > _6328,monty::rc_ptr< ::mosek::fusion::Matrix > _6329);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::Expression > _6330,std::shared_ptr< monty::ndarray< double,2 > > _6331);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::Expression > _6332,std::shared_ptr< monty::ndarray< double,1 > > _6333);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::Expression > _6334,monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6335);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::Variable > _6336,monty::rc_ptr< ::mosek::fusion::Matrix > _6337);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::Variable > _6338,monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6339);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::Variable > _6340,std::shared_ptr< monty::ndarray< double,2 > > _6341);
static  monty::rc_ptr< ::mosek::fusion::Expression > mulElm(monty::rc_ptr< ::mosek::fusion::Variable > _6342,std::shared_ptr< monty::ndarray< double,1 > > _6343);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::Matrix > _6344,monty::rc_ptr< ::mosek::fusion::Expression > _6345);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::Matrix > _6346,monty::rc_ptr< ::mosek::fusion::Variable > _6347);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6348,monty::rc_ptr< ::mosek::fusion::Variable > _6349);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6350,monty::rc_ptr< ::mosek::fusion::Expression > _6351);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(std::shared_ptr< monty::ndarray< double,2 > > _6352,monty::rc_ptr< ::mosek::fusion::Variable > _6353);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(std::shared_ptr< monty::ndarray< double,2 > > _6354,monty::rc_ptr< ::mosek::fusion::Expression > _6355);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(std::shared_ptr< monty::ndarray< double,1 > > _6356,monty::rc_ptr< ::mosek::fusion::Variable > _6357);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(std::shared_ptr< monty::ndarray< double,1 > > _6358,monty::rc_ptr< ::mosek::fusion::Expression > _6359);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::Expression > _6360,monty::rc_ptr< ::mosek::fusion::Matrix > _6361);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::Expression > _6362,std::shared_ptr< monty::ndarray< double,2 > > _6363);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::Expression > _6364,std::shared_ptr< monty::ndarray< double,1 > > _6365);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::Expression > _6366,monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6367);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::Variable > _6368,monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6369);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::Variable > _6370,monty::rc_ptr< ::mosek::fusion::Matrix > _6371);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::Variable > _6372,std::shared_ptr< monty::ndarray< double,2 > > _6373);
static  monty::rc_ptr< ::mosek::fusion::Expression > dot(monty::rc_ptr< ::mosek::fusion::Variable > _6374,std::shared_ptr< monty::ndarray< double,1 > > _6375);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6376,monty::rc_ptr< ::mosek::fusion::Variable > _6377);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Variable > _6378,monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6379);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Matrix > _6380,monty::rc_ptr< ::mosek::fusion::Variable > _6381);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Variable > _6382,monty::rc_ptr< ::mosek::fusion::Matrix > _6383);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(double _6384,monty::rc_ptr< ::mosek::fusion::Variable > _6385);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Variable > _6386,double _6387);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(std::shared_ptr< monty::ndarray< double,2 > > _6388,monty::rc_ptr< ::mosek::fusion::Variable > _6389);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(std::shared_ptr< monty::ndarray< double,1 > > _6390,monty::rc_ptr< ::mosek::fusion::Variable > _6391);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Variable > _6392,std::shared_ptr< monty::ndarray< double,2 > > _6393);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Variable > _6394,std::shared_ptr< monty::ndarray< double,1 > > _6395);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Variable > _6396,monty::rc_ptr< ::mosek::fusion::Variable > _6397);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6398,monty::rc_ptr< ::mosek::fusion::Expression > _6399);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Expression > _6400,monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6401);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Matrix > _6402,monty::rc_ptr< ::mosek::fusion::Expression > _6403);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Expression > _6404,monty::rc_ptr< ::mosek::fusion::Matrix > _6405);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(double _6406,monty::rc_ptr< ::mosek::fusion::Expression > _6407);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Expression > _6408,double _6409);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(std::shared_ptr< monty::ndarray< double,2 > > _6410,monty::rc_ptr< ::mosek::fusion::Expression > _6411);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(std::shared_ptr< monty::ndarray< double,1 > > _6412,monty::rc_ptr< ::mosek::fusion::Expression > _6413);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Expression > _6414,std::shared_ptr< monty::ndarray< double,2 > > _6415);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Expression > _6416,std::shared_ptr< monty::ndarray< double,1 > > _6417);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Variable > _6418,monty::rc_ptr< ::mosek::fusion::Expression > _6419);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Expression > _6420,monty::rc_ptr< ::mosek::fusion::Variable > _6421);
static  monty::rc_ptr< ::mosek::fusion::Expression > sub(monty::rc_ptr< ::mosek::fusion::Expression > _6422,monty::rc_ptr< ::mosek::fusion::Expression > _6423);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6424,monty::rc_ptr< ::mosek::fusion::Variable > _6425);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Variable > _6426,monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6427);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Matrix > _6428,monty::rc_ptr< ::mosek::fusion::Variable > _6429);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Variable > _6430,monty::rc_ptr< ::mosek::fusion::Matrix > _6431);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(double _6432,monty::rc_ptr< ::mosek::fusion::Variable > _6433);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Variable > _6434,double _6435);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(std::shared_ptr< monty::ndarray< double,2 > > _6436,monty::rc_ptr< ::mosek::fusion::Variable > _6437);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(std::shared_ptr< monty::ndarray< double,1 > > _6438,monty::rc_ptr< ::mosek::fusion::Variable > _6439);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Variable > _6440,std::shared_ptr< monty::ndarray< double,2 > > _6441);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Variable > _6442,std::shared_ptr< monty::ndarray< double,1 > > _6443);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Variable > _6444,monty::rc_ptr< ::mosek::fusion::Variable > _6445);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6446,monty::rc_ptr< ::mosek::fusion::Expression > _6447);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Expression > _6448,monty::rc_ptr< ::mosek::fusion::NDSparseArray > _6449);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Matrix > _6450,monty::rc_ptr< ::mosek::fusion::Expression > _6451);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Expression > _6452,monty::rc_ptr< ::mosek::fusion::Matrix > _6453);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(double _6454,monty::rc_ptr< ::mosek::fusion::Expression > _6455);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Expression > _6456,double _6457);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(std::shared_ptr< monty::ndarray< double,2 > > _6458,monty::rc_ptr< ::mosek::fusion::Expression > _6459);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(std::shared_ptr< monty::ndarray< double,1 > > _6460,monty::rc_ptr< ::mosek::fusion::Expression > _6461);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Expression > _6462,std::shared_ptr< monty::ndarray< double,2 > > _6463);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Expression > _6464,std::shared_ptr< monty::ndarray< double,1 > > _6465);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Variable > _6466,monty::rc_ptr< ::mosek::fusion::Expression > _6467);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Expression > _6468,monty::rc_ptr< ::mosek::fusion::Variable > _6469);
static  monty::rc_ptr< ::mosek::fusion::Expression > add(monty::rc_ptr< ::mosek::fusion::Expression > _6470,monty::rc_ptr< ::mosek::fusion::Expression > _6471);
virtual monty::rc_ptr< ::mosek::fusion::Set > shape();
virtual monty::rc_ptr< ::mosek::fusion::Set > getShape();
virtual monty::rc_ptr< ::mosek::fusion::Model > getModel();
static  void validateData(std::shared_ptr< monty::ndarray< long long,1 > > _6472,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _6473,std::shared_ptr< monty::ndarray< long long,1 > > _6474,std::shared_ptr< monty::ndarray< double,1 > > _6475,std::shared_ptr< monty::ndarray< double,1 > > _6476,monty::rc_ptr< ::mosek::fusion::Set > _6477,std::shared_ptr< monty::ndarray< long long,1 > > _6478);
static  monty::rc_ptr< ::mosek::fusion::Model > extractModel(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _6493);
}; // struct Expr;

struct p_FlatExpr
{
FlatExpr * _pubthis;
static mosek::fusion::p_FlatExpr* _get_impl(mosek::fusion::FlatExpr * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_FlatExpr * _get_impl(mosek::fusion::FlatExpr::t _inst) { return _get_impl(_inst.get()); }
p_FlatExpr(FlatExpr * _pubthis);
virtual ~p_FlatExpr() { /* std::cout << "~p_FlatExpr" << std::endl;*/ };
std::shared_ptr< monty::ndarray< long long,1 > > inst{};monty::rc_ptr< ::mosek::fusion::Set > shape{};long long nnz{};std::shared_ptr< monty::ndarray< double,1 > > cof{};std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > x{};std::shared_ptr< monty::ndarray< long long,1 > > subj{};std::shared_ptr< monty::ndarray< long long,1 > > ptrb{};std::shared_ptr< monty::ndarray< double,1 > > bfix{};virtual void destroy();
static FlatExpr::t _new_FlatExpr(monty::rc_ptr< ::mosek::fusion::FlatExpr > _6494);
void _initialize(monty::rc_ptr< ::mosek::fusion::FlatExpr > _6494);
static FlatExpr::t _new_FlatExpr(std::shared_ptr< monty::ndarray< double,1 > > _6495,std::shared_ptr< monty::ndarray< long long,1 > > _6496,std::shared_ptr< monty::ndarray< long long,1 > > _6497,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _6498,std::shared_ptr< monty::ndarray< double,1 > > _6499,monty::rc_ptr< ::mosek::fusion::Set > _6500,std::shared_ptr< monty::ndarray< long long,1 > > _6501);
void _initialize(std::shared_ptr< monty::ndarray< double,1 > > _6495,std::shared_ptr< monty::ndarray< long long,1 > > _6496,std::shared_ptr< monty::ndarray< long long,1 > > _6497,std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Variable >,1 > > _6498,std::shared_ptr< monty::ndarray< double,1 > > _6499,monty::rc_ptr< ::mosek::fusion::Set > _6500,std::shared_ptr< monty::ndarray< long long,1 > > _6501);
virtual std::string toString();
virtual int size();
}; // struct FlatExpr;

struct p_SymmetricMatrix
{
SymmetricMatrix * _pubthis;
static mosek::fusion::p_SymmetricMatrix* _get_impl(mosek::fusion::SymmetricMatrix * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_SymmetricMatrix * _get_impl(mosek::fusion::SymmetricMatrix::t _inst) { return _get_impl(_inst.get()); }
p_SymmetricMatrix(SymmetricMatrix * _pubthis);
virtual ~p_SymmetricMatrix() { /* std::cout << "~p_SymmetricMatrix" << std::endl;*/ };
int nnz{};double scale{};std::shared_ptr< monty::ndarray< double,1 > > vval{};std::shared_ptr< monty::ndarray< int,1 > > vsubj{};std::shared_ptr< monty::ndarray< int,1 > > vsubi{};std::shared_ptr< monty::ndarray< double,1 > > uval{};std::shared_ptr< monty::ndarray< int,1 > > usubj{};std::shared_ptr< monty::ndarray< int,1 > > usubi{};int d1{};int d0{};virtual void destroy();
static SymmetricMatrix::t _new_SymmetricMatrix(int _6503,int _6504,std::shared_ptr< monty::ndarray< int,1 > > _6505,std::shared_ptr< monty::ndarray< int,1 > > _6506,std::shared_ptr< monty::ndarray< double,1 > > _6507,std::shared_ptr< monty::ndarray< int,1 > > _6508,std::shared_ptr< monty::ndarray< int,1 > > _6509,std::shared_ptr< monty::ndarray< double,1 > > _6510,double _6511);
void _initialize(int _6503,int _6504,std::shared_ptr< monty::ndarray< int,1 > > _6505,std::shared_ptr< monty::ndarray< int,1 > > _6506,std::shared_ptr< monty::ndarray< double,1 > > _6507,std::shared_ptr< monty::ndarray< int,1 > > _6508,std::shared_ptr< monty::ndarray< int,1 > > _6509,std::shared_ptr< monty::ndarray< double,1 > > _6510,double _6511);
static  monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > rankOne(int _6512,std::shared_ptr< monty::ndarray< int,1 > > _6513,std::shared_ptr< monty::ndarray< double,1 > > _6514);
static  monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > rankOne(std::shared_ptr< monty::ndarray< double,1 > > _6522);
static  monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > antiDiag(std::shared_ptr< monty::ndarray< double,1 > > _6530);
static  monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > diag(std::shared_ptr< monty::ndarray< double,1 > > _6537);
virtual monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > add(monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > _6543);
virtual monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > sub(monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > _6563);
virtual monty::rc_ptr< ::mosek::fusion::SymmetricMatrix > mul(double _6564);
virtual int getdim();
}; // struct SymmetricMatrix;

struct p_NDSparseArray
{
NDSparseArray * _pubthis;
static mosek::fusion::p_NDSparseArray* _get_impl(mosek::fusion::NDSparseArray * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_NDSparseArray * _get_impl(mosek::fusion::NDSparseArray::t _inst) { return _get_impl(_inst.get()); }
p_NDSparseArray(NDSparseArray * _pubthis);
virtual ~p_NDSparseArray() { /* std::cout << "~p_NDSparseArray" << std::endl;*/ };
std::shared_ptr< monty::ndarray< double,1 > > cof{};std::shared_ptr< monty::ndarray< long long,1 > > inst{};std::shared_ptr< monty::ndarray< int,1 > > dims{};long long size{};virtual void destroy();
static NDSparseArray::t _new_NDSparseArray(std::shared_ptr< monty::ndarray< int,1 > > _6565,std::shared_ptr< monty::ndarray< int,2 > > _6566,std::shared_ptr< monty::ndarray< double,1 > > _6567);
void _initialize(std::shared_ptr< monty::ndarray< int,1 > > _6565,std::shared_ptr< monty::ndarray< int,2 > > _6566,std::shared_ptr< monty::ndarray< double,1 > > _6567);
static NDSparseArray::t _new_NDSparseArray(std::shared_ptr< monty::ndarray< int,1 > > _6587,std::shared_ptr< monty::ndarray< long long,1 > > _6588,std::shared_ptr< monty::ndarray< double,1 > > _6589);
void _initialize(std::shared_ptr< monty::ndarray< int,1 > > _6587,std::shared_ptr< monty::ndarray< long long,1 > > _6588,std::shared_ptr< monty::ndarray< double,1 > > _6589);
static NDSparseArray::t _new_NDSparseArray(monty::rc_ptr< ::mosek::fusion::Matrix > _6603);
void _initialize(monty::rc_ptr< ::mosek::fusion::Matrix > _6603);
static  monty::rc_ptr< ::mosek::fusion::NDSparseArray > make(monty::rc_ptr< ::mosek::fusion::Matrix > _6611);
static  monty::rc_ptr< ::mosek::fusion::NDSparseArray > make(std::shared_ptr< monty::ndarray< int,1 > > _6612,std::shared_ptr< monty::ndarray< long long,1 > > _6613,std::shared_ptr< monty::ndarray< double,1 > > _6614);
static  monty::rc_ptr< ::mosek::fusion::NDSparseArray > make(std::shared_ptr< monty::ndarray< int,1 > > _6615,std::shared_ptr< monty::ndarray< int,2 > > _6616,std::shared_ptr< monty::ndarray< double,1 > > _6617);
}; // struct NDSparseArray;

struct p_Matrix
{
Matrix * _pubthis;
static mosek::fusion::p_Matrix* _get_impl(mosek::fusion::Matrix * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_Matrix * _get_impl(mosek::fusion::Matrix::t _inst) { return _get_impl(_inst.get()); }
p_Matrix(Matrix * _pubthis);
virtual ~p_Matrix() { /* std::cout << "~p_Matrix" << std::endl;*/ };
int dimj{};int dimi{};virtual void destroy();
static Matrix::t _new_Matrix(int _6686,int _6687);
void _initialize(int _6686,int _6687);
virtual std::string toString();
virtual void switchDims();
static  monty::rc_ptr< ::mosek::fusion::Matrix > diag(int _6689,monty::rc_ptr< ::mosek::fusion::Matrix > _6690);
static  monty::rc_ptr< ::mosek::fusion::Matrix > diag(std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Matrix >,1 > > _6692);
static  monty::rc_ptr< ::mosek::fusion::Matrix > antidiag(int _6710,double _6711,int _6712);
static  monty::rc_ptr< ::mosek::fusion::Matrix > antidiag(int _6713,double _6714);
static  monty::rc_ptr< ::mosek::fusion::Matrix > diag(int _6715,double _6716,int _6717);
static  monty::rc_ptr< ::mosek::fusion::Matrix > diag(int _6718,double _6719);
static  monty::rc_ptr< ::mosek::fusion::Matrix > antidiag(std::shared_ptr< monty::ndarray< double,1 > > _6720,int _6721);
static  monty::rc_ptr< ::mosek::fusion::Matrix > antidiag(std::shared_ptr< monty::ndarray< double,1 > > _6731);
static  monty::rc_ptr< ::mosek::fusion::Matrix > diag(std::shared_ptr< monty::ndarray< double,1 > > _6732,int _6733);
static  monty::rc_ptr< ::mosek::fusion::Matrix > diag(std::shared_ptr< monty::ndarray< double,1 > > _6741);
static  monty::rc_ptr< ::mosek::fusion::Matrix > ones(int _6742,int _6743);
static  monty::rc_ptr< ::mosek::fusion::Matrix > eye(int _6744);
static  monty::rc_ptr< ::mosek::fusion::Matrix > dense(monty::rc_ptr< ::mosek::fusion::Matrix > _6746);
static  monty::rc_ptr< ::mosek::fusion::Matrix > dense(int _6747,int _6748,double _6749);
static  monty::rc_ptr< ::mosek::fusion::Matrix > dense(int _6750,int _6751,std::shared_ptr< monty::ndarray< double,1 > > _6752);
static  monty::rc_ptr< ::mosek::fusion::Matrix > dense(std::shared_ptr< monty::ndarray< double,2 > > _6753);
static  monty::rc_ptr< ::mosek::fusion::Matrix > sparse(monty::rc_ptr< ::mosek::fusion::Matrix > _6754);
static  monty::rc_ptr< ::mosek::fusion::Matrix > sparse(std::shared_ptr< monty::ndarray< std::shared_ptr< monty::ndarray< monty::rc_ptr< ::mosek::fusion::Matrix >,1 > >,1 > > _6758);
static  monty::rc_ptr< ::mosek::fusion::Matrix > sparse(std::shared_ptr< monty::ndarray< double,2 > > _6789);
static  monty::rc_ptr< ::mosek::fusion::Matrix > sparse(int _6802,int _6803);
static  monty::rc_ptr< ::mosek::fusion::Matrix > sparse(int _6804,int _6805,std::shared_ptr< monty::ndarray< int,1 > > _6806,std::shared_ptr< monty::ndarray< int,1 > > _6807,double _6808);
static  monty::rc_ptr< ::mosek::fusion::Matrix > sparse(std::shared_ptr< monty::ndarray< int,1 > > _6810,std::shared_ptr< monty::ndarray< int,1 > > _6811,double _6812);
static  monty::rc_ptr< ::mosek::fusion::Matrix > sparse(std::shared_ptr< monty::ndarray< int,1 > > _6817,std::shared_ptr< monty::ndarray< int,1 > > _6818,std::shared_ptr< monty::ndarray< double,1 > > _6819);
static  monty::rc_ptr< ::mosek::fusion::Matrix > sparse(int _6824,int _6825,std::shared_ptr< monty::ndarray< int,1 > > _6826,std::shared_ptr< monty::ndarray< int,1 > > _6827,std::shared_ptr< monty::ndarray< double,1 > > _6828);
virtual double get(int _6833,int _6834) { throw monty::AbstractClassError("Call to abstract method"); }
virtual bool isSparse() { throw monty::AbstractClassError("Call to abstract method"); }
virtual std::shared_ptr< monty::ndarray< double,1 > > getDataAsArray() { throw monty::AbstractClassError("Call to abstract method"); }
virtual void getDataAsTriplets(std::shared_ptr< monty::ndarray< int,1 > > _6835,std::shared_ptr< monty::ndarray< int,1 > > _6836,std::shared_ptr< monty::ndarray< double,1 > > _6837) { throw monty::AbstractClassError("Call to abstract method"); }
virtual monty::rc_ptr< ::mosek::fusion::Matrix > transpose() { throw monty::AbstractClassError("Call to abstract method"); }
virtual long long numNonzeros() { throw monty::AbstractClassError("Call to abstract method"); }
virtual int numColumns();
virtual int numRows();
}; // struct Matrix;

struct p_DenseMatrix : public ::mosek::fusion::p_Matrix
{
DenseMatrix * _pubthis;
static mosek::fusion::p_DenseMatrix* _get_impl(mosek::fusion::DenseMatrix * _inst){ return static_cast< mosek::fusion::p_DenseMatrix* >(mosek::fusion::p_Matrix::_get_impl(_inst)); }
static mosek::fusion::p_DenseMatrix * _get_impl(mosek::fusion::DenseMatrix::t _inst) { return _get_impl(_inst.get()); }
p_DenseMatrix(DenseMatrix * _pubthis);
virtual ~p_DenseMatrix() { /* std::cout << "~p_DenseMatrix" << std::endl;*/ };
long long nnz{};std::shared_ptr< monty::ndarray< double,1 > > data{};virtual void destroy();
static DenseMatrix::t _new_DenseMatrix(int _6618,int _6619,std::shared_ptr< monty::ndarray< double,1 > > _6620);
void _initialize(int _6618,int _6619,std::shared_ptr< monty::ndarray< double,1 > > _6620);
static DenseMatrix::t _new_DenseMatrix(monty::rc_ptr< ::mosek::fusion::Matrix > _6621);
void _initialize(monty::rc_ptr< ::mosek::fusion::Matrix > _6621);
static DenseMatrix::t _new_DenseMatrix(std::shared_ptr< monty::ndarray< double,2 > > _6626);
void _initialize(std::shared_ptr< monty::ndarray< double,2 > > _6626);
static DenseMatrix::t _new_DenseMatrix(int _6629,int _6630,double _6631);
void _initialize(int _6629,int _6630,double _6631);
virtual std::string toString();
virtual monty::rc_ptr< ::mosek::fusion::Matrix > transpose();
virtual bool isSparse();
virtual std::shared_ptr< monty::ndarray< double,1 > > getDataAsArray();
virtual void getDataAsTriplets(std::shared_ptr< monty::ndarray< int,1 > > _6644,std::shared_ptr< monty::ndarray< int,1 > > _6645,std::shared_ptr< monty::ndarray< double,1 > > _6646);
virtual double get(int _6650,int _6651);
virtual long long numNonzeros();
}; // struct DenseMatrix;

struct p_SparseMatrix : public ::mosek::fusion::p_Matrix
{
SparseMatrix * _pubthis;
static mosek::fusion::p_SparseMatrix* _get_impl(mosek::fusion::SparseMatrix * _inst){ return static_cast< mosek::fusion::p_SparseMatrix* >(mosek::fusion::p_Matrix::_get_impl(_inst)); }
static mosek::fusion::p_SparseMatrix * _get_impl(mosek::fusion::SparseMatrix::t _inst) { return _get_impl(_inst.get()); }
p_SparseMatrix(SparseMatrix * _pubthis);
virtual ~p_SparseMatrix() { /* std::cout << "~p_SparseMatrix" << std::endl;*/ };
long long nnz{};std::shared_ptr< monty::ndarray< double,1 > > val{};std::shared_ptr< monty::ndarray< int,1 > > subj{};std::shared_ptr< monty::ndarray< int,1 > > subi{};virtual void destroy();
static SparseMatrix::t _new_SparseMatrix(int _6652,int _6653,std::shared_ptr< monty::ndarray< int,1 > > _6654,std::shared_ptr< monty::ndarray< int,1 > > _6655,std::shared_ptr< monty::ndarray< double,1 > > _6656,long long _6657);
void _initialize(int _6652,int _6653,std::shared_ptr< monty::ndarray< int,1 > > _6654,std::shared_ptr< monty::ndarray< int,1 > > _6655,std::shared_ptr< monty::ndarray< double,1 > > _6656,long long _6657);
static SparseMatrix::t _new_SparseMatrix(int _6662,int _6663,std::shared_ptr< monty::ndarray< int,1 > > _6664,std::shared_ptr< monty::ndarray< int,1 > > _6665,std::shared_ptr< monty::ndarray< double,1 > > _6666);
void _initialize(int _6662,int _6663,std::shared_ptr< monty::ndarray< int,1 > > _6664,std::shared_ptr< monty::ndarray< int,1 > > _6665,std::shared_ptr< monty::ndarray< double,1 > > _6666);
virtual std::shared_ptr< monty::ndarray< long long,1 > > formPtrb();
virtual std::string toString();
virtual long long numNonzeros();
virtual monty::rc_ptr< ::mosek::fusion::Matrix > transpose();
virtual bool isSparse();
virtual std::shared_ptr< monty::ndarray< double,1 > > getDataAsArray();
virtual void getDataAsTriplets(std::shared_ptr< monty::ndarray< int,1 > > _6678,std::shared_ptr< monty::ndarray< int,1 > > _6679,std::shared_ptr< monty::ndarray< double,1 > > _6680);
virtual double get(int _6681,int _6682);
}; // struct SparseMatrix;

struct p_Parameters
{
Parameters * _pubthis;
static mosek::fusion::p_Parameters* _get_impl(mosek::fusion::Parameters * _inst){ assert(_inst); assert(_inst->_impl); return _inst->_impl; }
static mosek::fusion::p_Parameters * _get_impl(mosek::fusion::Parameters::t _inst) { return _get_impl(_inst.get()); }
p_Parameters(Parameters * _pubthis);
virtual ~p_Parameters() { /* std::cout << "~p_Parameters" << std::endl;*/ };
virtual void destroy();
static  void setParameter(monty::rc_ptr< ::mosek::fusion::Model > _6861,const std::string &  _6862,double _6863);
static  void setParameter(monty::rc_ptr< ::mosek::fusion::Model > _6962,const std::string &  _6963,int _6964);
static  void setParameter(monty::rc_ptr< ::mosek::fusion::Model > _7063,const std::string &  _7064,const std::string &  _7065);
static  int string_to_miocontsoltype_value(const std::string &  _7311);
static  int string_to_internal_dinf_value(const std::string &  _7312);
static  int string_to_presolvemode_value(const std::string &  _7313);
static  int string_to_optimizertype_value(const std::string &  _7314);
static  int string_to_stakey_value(const std::string &  _7315);
static  int string_to_iinfitem_value(const std::string &  _7316);
static  int string_to_simreform_value(const std::string &  _7317);
static  int string_to_value_value(const std::string &  _7318);
static  int string_to_scalingmethod_value(const std::string &  _7319);
static  int string_to_soltype_value(const std::string &  _7320);
static  int string_to_startpointtype_value(const std::string &  _7321);
static  int string_to_language_value(const std::string &  _7322);
static  int string_to_checkconvexitytype_value(const std::string &  _7323);
static  int string_to_variabletype_value(const std::string &  _7324);
static  int string_to_mpsformat_value(const std::string &  _7325);
static  int string_to_nametype_value(const std::string &  _7326);
static  int string_to_compresstype_value(const std::string &  _7327);
static  int string_to_simdupvec_value(const std::string &  _7328);
static  int string_to_dparam_value(const std::string &  _7329);
static  int string_to_inftype_value(const std::string &  _7330);
static  int string_to_problemtype_value(const std::string &  _7331);
static  int string_to_orderingtype_value(const std::string &  _7332);
static  int string_to_dataformat_value(const std::string &  _7333);
static  int string_to_simdegen_value(const std::string &  _7334);
static  int string_to_onoffkey_value(const std::string &  _7335);
static  int string_to_transpose_value(const std::string &  _7336);
static  int string_to_mionodeseltype_value(const std::string &  _7337);
static  int string_to_rescode_value(const std::string &  _7338);
static  int string_to_scalingtype_value(const std::string &  _7339);
static  int string_to_prosta_value(const std::string &  _7340);
static  int string_to_rescodetype_value(const std::string &  _7341);
static  int string_to_parametertype_value(const std::string &  _7342);
static  int string_to_dinfitem_value(const std::string &  _7343);
static  int string_to_miomode_value(const std::string &  _7344);
static  int string_to_xmlwriteroutputtype_value(const std::string &  _7345);
static  int string_to_simseltype_value(const std::string &  _7346);
static  int string_to_internal_liinf_value(const std::string &  _7347);
static  int string_to_iomode_value(const std::string &  _7348);
static  int string_to_streamtype_value(const std::string &  _7349);
static  int string_to_conetype_value(const std::string &  _7350);
static  int string_to_mark_value(const std::string &  _7351);
static  int string_to_feature_value(const std::string &  _7352);
static  int string_to_symmattype_value(const std::string &  _7353);
static  int string_to_callbackcode_value(const std::string &  _7354);
static  int string_to_simhotstart_value(const std::string &  _7355);
static  int string_to_liinfitem_value(const std::string &  _7356);
static  int string_to_branchdir_value(const std::string &  _7357);
static  int string_to_basindtype_value(const std::string &  _7358);
static  int string_to_internal_iinf_value(const std::string &  _7359);
static  int string_to_boundkey_value(const std::string &  _7360);
static  int string_to_solitem_value(const std::string &  _7361);
static  int string_to_objsense_value(const std::string &  _7362);
static  int string_to_solsta_value(const std::string &  _7363);
static  int string_to_iparam_value(const std::string &  _7364);
static  int string_to_sparam_value(const std::string &  _7365);
static  int string_to_intpnthotstart_value(const std::string &  _7366);
static  int string_to_uplo_value(const std::string &  _7367);
static  int string_to_sensitivitytype_value(const std::string &  _7368);
static  int string_to_accmode_value(const std::string &  _7369);
static  int string_to_problemitem_value(const std::string &  _7370);
static  int string_to_solveform_value(const std::string &  _7371);
}; // struct Parameters;

}
}
namespace mosek
{
namespace fusion
{
namespace Utils
{
// mosek.fusion.Utils.IntMap from file 'src/fusion/cxx/IntMap_p.h'
struct p_IntMap 
{
  IntMap * _pubself;

  static p_IntMap * _get_impl(IntMap * _inst) { return _inst->_impl.get(); }

  p_IntMap(IntMap * _pubself) : _pubself(_pubself) {}

  static IntMap::t _new_IntMap() { return new IntMap(); }

  ::std::unordered_map<long long,int> m;

  bool hasItem (long long key) { return m.find(key) != m.end(); }
  int  getItem (long long key) { return m.find(key)->second; } // will probably throw something or crash of no such key
  void setItem (long long key, int val) { m[key] = val; }

  std::shared_ptr<monty::ndarray<long long,1>> keys()
  { 
    size_t size = m.size();
    auto res = std::shared_ptr<monty::ndarray<long long,1>>(new monty::ndarray<long long,1>(monty::shape((int)size)));

    ptrdiff_t i = 0;
    for (auto it = m.begin(); it != m.end(); ++it)
      (*res)[i++] = it->first;

    return res;    
  }

  std::shared_ptr<monty::ndarray<int,1>> values()
  {
    size_t size = m.size();
    auto res = std::shared_ptr<monty::ndarray<int,1>>(new monty::ndarray<int,1>(monty::shape((int)size)));

    ptrdiff_t i = 0;
    for (auto it = m.begin(); it != m.end(); ++it)
      (*res)[i++] = it->second;

    return res;
  }

  IntMap::t clone();
};



struct p_StringIntMap
{
  StringIntMap * _pubself;

  static p_StringIntMap * _get_impl(StringIntMap * _inst) { return _inst->_impl.get(); }

  p_StringIntMap(StringIntMap * _pubself) : _pubself(_pubself) {}

  static StringIntMap::t _new_StringIntMap() { return new StringIntMap(); }

  ::std::unordered_map<std::string,int> m;

  bool hasItem (const std::string & key) { return m.find(key) != m.end(); }
  int  getItem (const std::string & key) { return m.find(key)->second; } // will probably throw something or crash of no such key
  void setItem (const std::string & key, int val) { m[key] = val; }

  std::shared_ptr<monty::ndarray<std::string,1>> keys()
  {
    size_t size = m.size();
    auto res = std::shared_ptr<monty::ndarray<std::string,1>>(new monty::ndarray<std::string,1>(monty::shape((int)size)));

    ptrdiff_t i = 0;
    for (auto it = m.begin(); it != m.end(); ++it)
      (*res)[i++] = it->first;

    return res;
  }

  std::shared_ptr<monty::ndarray<int,1>> values()
  {
    size_t size = m.size();
    auto res = std::shared_ptr<monty::ndarray<int,1>>(new monty::ndarray<int,1>(monty::shape((int)size)));

    ptrdiff_t i = 0;
    for (auto it = m.begin(); it != m.end(); ++it)
      (*res)[i++] = it->second;

    return res;
  }

  StringIntMap::t clone();
};
// End of file 'src/fusion/cxx/IntMap_p.h'
// mosek.fusion.Utils.StringBuffer from file 'src/fusion/cxx/StringBuffer_p.h'
// namespace mosek::fusion::Utils
struct p_StringBuffer
{
  StringBuffer * _pubthis; 
  std::stringstream ss;

  p_StringBuffer(StringBuffer * _pubthis) : _pubthis(_pubthis) {}

  static p_StringBuffer * _get_impl(StringBuffer::t ptr) { return ptr->_impl.get(); }
  static p_StringBuffer * _get_impl(StringBuffer * ptr) { return ptr->_impl.get(); }

  static StringBuffer::t _new_StringBuffer() { return new StringBuffer(); }

  StringBuffer::t clear ();

  template<typename T> StringBuffer::t a (const monty::ndarray<T,1> & val);

  template<typename T> StringBuffer::t a (const T & val);

  StringBuffer::t lf ();
  std::string toString () const;
};

template<typename T> 
StringBuffer::t p_StringBuffer::a(const monty::ndarray<T,1> & val)
{
  if (val.size() > 0)
  {
    ss << val[0];
    for (int i = 1; i < val.size(); ++i)
      ss << "," << val[i];
  }
  return StringBuffer::t(_pubthis);
}
  
template<typename T>
StringBuffer::t p_StringBuffer::a (const T & val)
{
  ss << val;
  return _pubthis;
}


// End of file 'src/fusion/cxx/StringBuffer_p.h'
}
}
}
#endif
