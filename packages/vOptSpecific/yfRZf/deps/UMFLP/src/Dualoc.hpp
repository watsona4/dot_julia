/*
 #License and Copyright
 
 #Version : 1.3
 
 #This file is part of BiUFLv2017.
 
 #BiUFLv2017 is Copyright © 2017, University of Nantes
 
 #BiUFLv2017 is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 
 #This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 #You should have received a copy of the GNU General Public License along with this program; if not, you can also find the GPL on the GNU web site.
 
 #In addition, we kindly ask you to acknowledge BiUFLv2017 and its authors in any program or publication in which you use BiUFLv2017. (You are not required to do so; it is up to your common sense to decide whether you want to comply with this request or not.) For general publications, we suggest referencing:  BiUFLv2017, MSc ORO, University of Nantes.
 
 #Non-free versions of BiUFLv2017 are available under terms different from those of the General Public License. (e.g. they do not require you to accompany any object code using BiUFLv2012 with the corresponding source code.) For these alternative terms you must purchase a license from Technology Transfer Office of the University of Nantes. Users interested in such a license should contact us (valorisation@univ-nantes.fr) for more information.
 */

/*!
* \file Functions.hpp
* \brief A set of functions usefull for our software.
* \author Quentin DELMEE & Xavier GANDIBLEUX & Anthony PRZYBYLSKI
* \date 01 January 2017
* \version 1.3
* \copyright GNU General Public License
*
* This file groups all the functions for solving our problem which are not methods of Class.
*
*/

#ifndef DUALOC_H
#define DUALOC_H

#include <vector>
#include <map>
#include <list>
#include <iostream>
#include <cmath>
#include <climits>

#include "Data.hpp"
#include "Box.hpp"

/*! \namespace std
* 
* Using the standard namespace std of the IOstream library of C++.
*/
using namespace std;

struct Noeud
{
	vector<double> vi ;
	vector<double> sj ;
	vector<int> fac ;
	unsigned int deepness ;
};

struct DualocData
{
	/*!
	*	\defgroup dualocglobal Global DUALOC Variables
	*/

	/*!
	*	\var facilityCost
	*	\ingroup dualocglobal
	*	\brief Variable representing the cost of facilities.
	*
	*	This vector of double represent the mono-objective cost of the facilities w.r.t. to given weights lambdas.
	*/
	vector< double > facilityCost ;

	/*!
	*	\var clientCost
	*	\ingroup dualocglobal
	*	\brief Variable representing the allocation cost of client.
	*
	*	This vector of double represent the mono-objective allocation cost of the clients to facilities w.r.t. to given weights lambdas.
	*/
	vector< vector< double > > clientCost ;

	/*!
	*	\var clientSort
	*	\ingroup dualocglobal
	*	\brief Variable representing the sorting of facilities w.r.t. the clients
	*
	*	This vector of double represents the decreasing sorting of facilities for each client w.r.t. the personal interest of the client for the corresponding facilities.
	*/
	vector< vector<int> > clientSort ;

	/*!
	*	\var primalvalue ;
	*	\ingroup dualocglobal
	*	\brief Variable representing the primal objective value
	*
	*	This variables represents the primal objective value. It is calculated after each Dual Ascent or Dual Adjustment (not considering the Dual Ascent inside Dual Adjustment).
	*/
	double primalvalue ;

	/*!
	*	\var dualvalue ;
	*	\ingroup dualocglobal
	*	\brief Variable representing the dual objective value
	*
	*	This variables represents the dual objective value. It is calculated after each Dual Ascent or Dual Adjustment (not considering the Dual Ascent inside Dual Adjustment).
	*/
	double dualvalue ;

	/*!
	*	\var NB_CUSTOMER ;
	*	\ingroup dualocglobal
	*	\brief Variable representing the number of customers.
	*
	*	This variables represents number of customer of the mono-objective problem.
	*/
	unsigned int NB_CUSTOMER ;

	/*!
	*	\var NB_FACILITY ;
	*	\ingroup dualocglobal
	*	\brief Variable representing the number of facilities.
	*
	*	This variables represents number of facilities of the mono-objective problem.
	*/
	unsigned int NB_FACILITY ;

	/*!
	*	\var bestIntegerSol ;
	*	\ingroup dualocglobal
	*	\brief Variable representing the best primal objective value
	*
	*	This variables represents the best primal objective value obtained so far. It is verified each time we calculate the primal and dual value, which means after each Dual Ascent or Dual Adjustment (not considering the Dual Ascent inside Dual Adjustment).
	*/
	double bestIntegerSol ;

	/*!
	*	\var bestJplus ;
	*	\ingroup dualocglobal
	*	\brief Variable representing the best set of facilities
	*
	*	This variables represents the best set of facilities w.r.t. the best primal objective value obtained so far. It is verified each time we calculate the primal and dual value, which means after each Dual Ascent or Dual Adjustment (not considering the Dual Ascent inside Dual Adjustment).
	*/
	vector< int > bestJplus ;



	vector< double > openCost ;
	vector< vector< double > > alloCost ;

	vector< bool > Iplus ;
	vector<int> Jstar ; 
	vector<int> Jplus ;


};

/*!
*	\defgroup dualoc DUALOC methods from Erlenkotter
*/

/*!
*	\fn Box* dualocprocedure(double lambda1, double lambda2, Data &data)
*	\ingroup dualoc
*	\brief This method computes the optimal solution of the mono-objectif UFLP defined by the lambdas
*
*	This method computes the mono-objective UFLP defined by the corresponding lambdas and find the optimal solution as proposed by Erlenkotter. It first Initialize the solution, then use the Dual Ascent, Dual Adjustment and a Branch and Bound to finish it returns the corresponding UBS and \c Box.
*	\param[in] lambda1 : A double representing the percentage of objective 1 to consider.
*	\param[in] lambda2 : A double representing the percentage of objective 2 to consider.
*	\param[in,out] data : A \c Data object which contains all the values of the instance.
*	\return A \c Box which is the optimal solution w.r.t. the lambdas direction.
*/
Box* dualocprocedure(double lambda1, double lambda2, Data &data);

/*!
*	\fn void AddChildrenNode(list< Noeud* > &ToDo, DualocData* dualocdata, Noeud* node )
*	\ingroup dualoc
*	\brief This method computes the next node in the Branch and Bound and adds/branches the children nodes.
*
*	This method is a subroutine for the Branch method. It computes the next node in the Branch and Bound and add it to the list of node.
*	\param[in,out] ToDo : A vector of \c Noeud which need to be considered in the Branch and Bound.
*	\param[in] dualocdata : A \c DualocData needed to compute the next nodes
*	\param[in,out] node : A \c Noeud that we consider to compute its children.
*/
void AddChildrenNode(list< Noeud* > &ToDo, DualocData* dualocdata, Noeud* node ) ;

/*!
*	\fn void Branch(vector< double > &openCost, vector< vector< double > > &alloCost, list< Noeud* > &ToDo)
*	\ingroup dualoc
*	\brief This method computes the next node in the Branch and Bound and adds/branches the children nodes.
*
*	This method computes the next node in the Branch and Bound alogirhtm as defined by Erlenkotter. It considers the open and closed facilities and then applies the Dual Ascent and Dual Adjustment procedure. If the node is not fathomed, this methods will add/branch the children nodes.
*	\param[in] dualocdata : A \c DualocData needed to compute the next branching
*	\param[in,out] ToDo : A vector of \c Noeud to obtain next node and add its children.
*/
void Branch(DualocData* dualocdata, list< Noeud* > &ToDo);

/*!
*	\fn void updateCost(vector< double > &openCost, Noeud* node)
*	\ingroup dualoc
*	\brief This method updates the facility cost of current node.
*
*	This method updates the facility cost of current node w.r.t. the cost of the parent node. If a facility j is closed, then f_j and s_j are put to infinity. If a facility j is open, s_j is put to 0 and all v_i are update to be at most equal to c_ij.
*	\param[in] dualocdata : A \c DualocData needed to compute the update.
*	\param[in,out] node : A \c Noeud that we want to update.
*/
void updateCost(DualocData* dualocdata, Noeud* node);

/*!
*	\fn void InitializationData( vector< double > &vi,vector< double > &sj )
*	\ingroup dualoc
*	\brief This method initializes vi and sj to feasible value w.r.t. dual constraints.
*
*	This method initializes the vi to the best allocation for each client, thus all sj are equal to fj. It is done before launching the Dual Ascent to start with a feasible Dual solution.
*	\param[in] dualocdata : A \c DualocData to initialize w.r.t. the lambdas.
*	\param[in] lambda1 : A double representing the percentage of objective 1 to consider.
*	\param[in] lambda2 : A double representing the percentage of objective 2 to consider.
*	\param[in,out] data : A \c Data object which contains all the values of the instance.
*/
void InitializationData( DualocData* dualocdata, double lambda1, double lambda2, Data &data );

/*!
*	\fn void InitializationRoot( DualocData* dualocdata, Noeud* node )
*	\ingroup dualoc
*	\brief This method initializes vi and sj to feasible value w.r.t. dual constraints.
*
*	This method initializes the vi to the best allocation for each client, thus all sj are equal to fj. It is done before launching the Dual Ascent to start with a feasible Dual solution.
*	\param[in] dualocdata : A \c DualocData needed to initialize.
*	\param[in,out] node : A \c Noeud that we want to initialize.
*/
void InitializationRoot( DualocData* dualocdata, Noeud* node );

/*!
*	\fn void dualAscent(DualocData* dualocdata, Noeud* node)
*	\ingroup dualoc
*	\brief This method computes a first greedy approximation of the Dual and Primal optimal solutions.
*
*	This method computes a first greedy approximation of the Dual and Primal optimal solutions. It iteratively increase the client vi variables to let the other grow until all variable are blocked by the corresponding sj variables from the facilities.
*	\param[in] dualocdata : A \c DualocData needed to compute the Dual Ascent procedure.
*	\param[in,out] node : A \c Noeud with all the data needed to procede Dual Ascent.
*/
void dualAscent(DualocData* dualocdata, Noeud* node);

/*!
*	\fn void dualAdjustement(DualocData* dualocdata, Noeud* node)
*	\ingroup dualoc
*	\brief This method adjusts the variables from the Dual Ascent to improve current Dual solution.
*
*	This method follows the Dual Ascent Procedure. It adjusts the variables contributing to a violation of the Dual-Primal slack constraints to add room for improvement to other variables and try to improve Dual objective value.
*	\param[in] dualocdata : A \c DualocData needed to compute the Dual Adjustment procedure.
*	\param[in,out] node : A \c Noeud with all the data needed to procede Dual Adjustment.
*/
void dualAdjustement(DualocData* dualocdata, Noeud* node);

/*!
*	\fn void computeUB(Box* toReturn, Data &data)
*	\ingroup dualoc
*	\brief This methods compute the corresponding Upper Bound Set.
*
*	This methods computes the corresponding upper bound set when the optimal solution has been found for current mono-objective UFLP w.r.t. lambdas.
*	\param[in] dualocdata : the data needed to compute the Upper Bound
*	\param[in,out] toReturn : A \c Box which will be returned as an Upper Bound Set.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*/
void computeUB(DualocData* dualocdata, Box* toReturn, Data &data);

/*!
*	\fn bool violateSlacknessConditions( vector< double > &vi,vector<int> Jplus,unsigned int clienti,unsigned int &minfacility)
*	\ingroup dualoc
*	\brief This method find which facility contributes to the violation of a Slackness conditions.
*
*	This method verifies in the set of facility Jplus which facility is to be considered in the violation of the slackness conditions. It will then be used to branch on it.
*	\param[in] dualocdata : A \c DualocData needed to compute the Dual Adjustment procedure.
*	\param[in,out] node : A \c Noeud with all the data needed to procede Dual Adjustment.
*	\param[in] clienti : An int representing the client which currently interest us.
*	\param[in,out] minfacility : An int representing which facility we need to consider for the violation of constraint.
*/
bool violateSlacknessConditions( DualocData* dualocdata, Noeud* node, unsigned int clienti, unsigned int &minfacility);

/*!
*	\fn void verifySlacknessConditions( vector< double > &vi,vector<int> Jplus)
*	\ingroup dualoc
*	\brief This method verifies if vi participates to the violation of a constraint.
*
*	This method verifies in the set of facility Jplus if vi contributes to the violation of a slackness constraint.
*	\param[in] vi : A vector of double representing the earned value of the client.
*	\param[in] Jplus : A vector of int representing a sub-set of Jstar defined by Erlenkotter.
*/
bool verifySlacknessConditions( DualocData* dualocdata, Noeud* node );

/*!
*	\fn void calculatePrimalDualValue( vector< double > &openCost, vector< double > &vi, vector<int> Jplus)
*	\ingroup dualoc
*	\brief This method computes the current primal and dual objective value.
*
*	This method computes the current primal objective value w.r.t. given set of facilities Jplus and it computes the dual objective value w.r.t. given vi
*	\param[in] openCost : A vector of double representing the costs of facilities in current UFLP.
*	\param[in] vi : A vector of double representing the earned value of the client.
*	\param[in] Jplus : A vector of int representing a sub-set of Jstar defined by Erlenkotter.
*/
void calculatePrimalDualValue( DualocData* dualocdata, Noeud* node );

/*!
*	\fn void calculateCjmoins( vector< double > &vi, int clienti, double &Cjmoins)
*	\ingroup dualoc
*	\brief This method computes the value of cjmoins.
*
*	This method computes the value of cjmoins w.r.t. client i. It represents the maximum allocation strictly inferio to the corresponding vi of client i.
*	\param[in] vi : A vector of double representing the earned value of the client.
*	\param[in] clienti : An int representing the client we want to compute cjmoins.
*	\param[in,out] Cjmoins : A double representing the value to return.
*/
double calculateCjmoins( DualocData* dualocdata, Noeud* nodes, int clienti );

/*!
*	\fn void calculateIjplus(vector<int> &Jstar, vector< double > &vi, int facilityj, vector<int> &Ijplus)
*	\ingroup dualoc
*	\brief This method computes the set of client corresponding to facility j.
*
*	This method computes the set of client corresponding to facility j in Jstar such that all client have stricly one facility lower or equal than vi being this facility j.
*	\param[in] Jstar : A vector of int representing the facility where sj equals 0.
*	\param[in] vi : A vector of double representing the earned value of the client.
*	\param[in] facilityj : An int representing the facility to consider.
*	\param[in] Ijplus : A vector of int representing a sub-set of Jstar defined by Erlenkotter.
*/
void calculateIjplus( DualocData* dualocdata, Noeud* node, int facilityj, vector<int> &Ijplus );

/*!
*	\fn void calculateJstar(vector< double > &sj, vector<int> &Jstar)
*	\ingroup dualoc
*	\brief This method extracts the interesting facilities.
*
*	This method extracts the facilities which have a sj equals to zero as they are thus interesting for the primal.
*	\param[in] sj : A vector of double representing the slackness of facilites.
*	\param[in,out] Jstar : A vector of int representing the facility where sj equals 0.
*/
void calculateJstar( DualocData* dualocdata, Noeud* node );

/*!
*	\fn void calculateJplus(vector< double > &vi, vector<int> &Jstar, vector<int> &Jplus)
*	\ingroup dualoc
*	\brief This method extracts the interesting facilities from Jstar.
*
*	This method extracts the essential facilities from Jstar and completes with adding facility sequentially to obtain feasible dual constraints.
*	\param[in] sj : A vector of double representing the slackness of facilites.
*	\param[in] Jstar : A vector of int representing the facility where sj equals 0.
*	\param[in,out] Jplus : A vector of int representing a sub-set of Jstar defined by Erlenkotter.
*/
void calculateJplus( DualocData* dualocdata, Noeud* node );

/*!
*	\fn void calculateJistar(vector<int> &Jstar, vector<int> &Jistar, vector< double > &vi, int clienti)
*	\ingroup dualoc
*	\brief This method extracts a set of facilities w.r.t a specific client i.
*
*	This method extracts the facilities such that for a given client i we have that vi is greater or equal than cij. It then used for other purpose in the algorithm.
*	\param[in] Jstar : A vector of int representing the facility where sj equals 0.
*	\param[in] Jistar : A vector of int representing the facility such that vi is greater or equal than cij.
*	\param[in] vi : A vector of double representing the earned value of the client.
*	\param[in] clienti : An int representing the client we want to compute cjmoins.
*/
void calculateJistar( DualocData* dualocdata, Noeud* node, vector<int> &Jistar, int clienti );

/*!
*	\fn void calculateJistar(vector<int> &Jstar, vector<int> &Jistar, vector< double > &vi, int clienti)
*	\ingroup dualoc
*	\brief This method extracts a set of facilities w.r.t a specific client i.
*
*	This method extracts the facilities such that for a given client i we have that vi is strictly greater than cij. It then used for other purpose in the algorithm.
*	\param[in,out] Jplus : A vector of int representing a sub-set of Jstar defined by Erlenkotter.
*	\param[in] Jiplus : A vector of int representing the facility such that vi is strictly greater than cij.
*	\param[in] vi : A vector of double representing the earned value of the client.
*	\param[in] clienti : An int representing the client we want to compute cjmoins.
*/
void calculateJiplus( DualocData* dualocdata, Noeud* node, vector<int> &Jiplus, int clienti );

/*!
*	\fn void quicksortClient(vector<double> &toHelp, vector<int> &toSort, int begin, int end)
*	\ingroup paving
*	\brief This method sorts the facility with decreasing interest w.r.t. a given client.
*
*	This method sorts the facility in decreasing interest w.r.t. a given client and some lambda to obtain a mono-objective interest function.
*	\param[in] toHelp : A vector of double representing the interest of each facility.
*	\param[in,out] toSort : A vector of int representing the facility to sort.
*	\param[in] begin : An int representing where we need to begin to sort in the current quicksort.
*	\param[in] end : An int representing where we need to end to sort in the current quicksort.
*/
void quicksortClient(vector<double> &toHelp, vector<int> &toSort, int begin, int end);



#endif
