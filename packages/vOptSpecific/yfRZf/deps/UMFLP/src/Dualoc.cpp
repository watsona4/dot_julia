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

#include "Dualoc.hpp"

Box* dualocprocedure(double lambda1, double lambda2, Data &data)
{
	Box* toReturn ;

	/* Initialization of Dualoc Data */ 

	DualocData* dualocdata = new DualocData ;

	InitializationData(dualocdata,lambda1,lambda2,data) ;

	/* Starting Procedure */ 


	// Initialization of Root Node
	Noeud* root = new Noeud ;
	InitializationRoot(dualocdata,root) ;

	// Dual Ascent Procedure 
	dualAscent(dualocdata,root);

	// Calculate interesting facilities and extract essential ones.
	calculateJstar(dualocdata,root) ;
	calculateJplus(dualocdata,root) ;

	// Calculate primal and dual value w.r.t. Jplus.
	calculatePrimalDualValue(dualocdata,root) ;

	bool feasible = verifySlacknessConditions(dualocdata,root) ;


	// if current solution is feasible for both dual and primal slack constraint, we have finished. We compute the corresponding UB and box and return it.
	if( feasible )
	{
		bool *facilityOpen = new bool[dualocdata->NB_FACILITY];

		for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
		{
			facilityOpen[j] = false ;
		}
		for( unsigned int j = 0 ; j < dualocdata->bestJplus.size() ; ++j )
		{
			facilityOpen[dualocdata->bestJplus[j]] = true ;
		}

		toReturn = new Box(data,facilityOpen);

		computeUB(dualocdata,toReturn,data);

		return toReturn;
	}

	// if not feasible, we will try to adjust it with a dual adjustment procedure.
	dualAdjustement(dualocdata,root);

	// Calculate interesting facilities and extract essential ones.
	calculateJstar(dualocdata,root) ;
	calculateJplus(dualocdata,root) ;

	// Calculate primal and dual value w.r.t. Jplus.
	calculatePrimalDualValue(dualocdata,root) ;	
	feasible = verifySlacknessConditions(dualocdata,root) ;

	// if current solution is feasible for both dual and primal slack constraint, we have finished. We compute the corresponding UB and box and return it.
	if( feasible )
	{
		bool *facilityOpen = new bool[dualocdata->NB_FACILITY];

		for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
		{
			facilityOpen[j] = false ;
		}
		for( unsigned int j = 0 ; j < dualocdata->bestJplus.size() ; ++j )
		{
			facilityOpen[dualocdata->bestJplus[j]] = true ;
		}

		toReturn = new Box(data,facilityOpen);

		computeUB(dualocdata,toReturn,data);

		return toReturn;
	}

	// if not possible we need to finish with a branch and bound, hopefully quick.

	list< Noeud* > ToDo ;

	ToDo.push_back(root) ;
	AddChildrenNode(ToDo,dualocdata,root) ;

	/* Branch and Bound */
	while( ToDo.size() > 0 )
	{
		Branch(dualocdata, ToDo);
	}

	// We compute the UB corresponding to the optimal solution and we return the corresponding box.
	bool *facilityOpen = new bool[dualocdata->NB_FACILITY];

	for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
	{
		facilityOpen[j] = false ;
	}
	for( unsigned int j = 0 ; j < dualocdata->bestJplus.size() ; ++j )
	{
		facilityOpen[dualocdata->bestJplus[j]] = true ;
	}

	toReturn = new Box(data,facilityOpen);

	computeUB(dualocdata,toReturn,data);

	dualocdata->openCost.clear() ;
	dualocdata->alloCost.clear() ;
	dualocdata->Iplus.clear() ;
	dualocdata->Jstar.clear() ;
	dualocdata->Jplus.clear() ;


	return toReturn;
}


/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
void AddChildrenNode(list< Noeud* > &ToDo, DualocData* dualocdata, Noeud* node )
{
	// We prepare children nodes 

	Noeud* node1 = new Noeud ;
	Noeud* node2 = new Noeud ;
	
	node1->fac = vector<int>() ;
	node2->fac = vector<int>() ;

	node1->vi = vector<double>() ;
	node2->vi = vector<double>() ;

	node1->sj = vector<double>() ;
	node1->sj = vector<double>() ;

	node1->deepness = node->deepness + 1 ;
	node2->deepness = node->deepness + 1 ;

	for( unsigned int j = 0 ; j < node->fac.size() ; ++j )
	{
		node1->fac.push_back(node->fac[j]) ;
		node2->fac.push_back(node->fac[j]) ;
	}

	bool lookforviolation = true ;

	for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
	{
		node1->vi.push_back(node->vi[i]) ;
		node2->vi.push_back(node->vi[i]) ;

		unsigned int nextbranch = 2*dualocdata->NB_FACILITY ;

		
		if(lookforviolation && violateSlacknessConditions( dualocdata, node, i, nextbranch ) )
		{
			bool notin = true ;
			for( unsigned int j = 0 ; j < node->fac.size() ; ++j )
			{
				if( nextbranch == node->fac[j]-dualocdata->NB_FACILITY || nextbranch == dualocdata->NB_FACILITY+node->fac[j] )
				{
					notin = false ;
					break ;
				}
			}

			if( notin )
			{
				// we had or remove NB FACILITY to be able to know if we close or open facility zero. Close if negative, Open if positive.
				if( node1->deepness < dualocdata->NB_FACILITY )
				{
					node1->fac.push_back(nextbranch - dualocdata->NB_FACILITY) ;
				}

				node2->fac.push_back(nextbranch + dualocdata->NB_FACILITY) ;
				lookforviolation = false ;
			}
		}
	}

	for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
	{
		node1->sj.push_back(node->sj[j]) ;
		node2->sj.push_back(node->sj[j]) ;
	}

	ToDo.pop_front() ;
	
	if( node2->fac.size() == node2->deepness )
	{
		ToDo.push_front(node2) ;
	}
	if( node1->fac.size() == node1->deepness )
	{
		ToDo.push_front(node1) ;
	}
}

void Branch( DualocData* dualocdata, list< Noeud* > &ToDo )
{
	// Extract node to do from the list.
	Noeud* node = ToDo.front() ;

	dualocdata->Iplus.clear() ;
	dualocdata->Jstar.clear() ;
	dualocdata->Jplus.clear() ;

	dualocdata->Iplus = vector< bool >(dualocdata->NB_CUSTOMER,true);
	dualocdata->Jstar = vector<int>() ; 
	dualocdata->Jplus = vector<int>() ;


	// Update Cost w.r.t. closed and opened facilities.
	updateCost( dualocdata, node );

	// Launch Dual Ascent Procedure.
	dualAscent( dualocdata, node );

	// Calculate interesting facilities and extract essential ones.
	calculateJstar( dualocdata, node ) ;
	calculateJplus( dualocdata, node ) ;

	// Calculate primal and dual value w.r.t. Jplus.
	calculatePrimalDualValue( dualocdata, node ) ;


	bool feasible = verifySlacknessConditions( dualocdata, node ) ;

	// If Feasible for both dual and primal constraints, we fathom node. If current Dual is worst than best primal, we fathom node. Otherwise we continue.
	if( feasible )
	{
		ToDo.pop_front() ;
		return ;
	}
	else if( dualocdata->dualvalue > dualocdata->bestIntegerSol )
	{
		ToDo.pop_front() ;
		return ;
	}

	// Launch Dual Adjustment 
	dualAdjustement( dualocdata, node );		
	
	// Calculate interesting facilities and extract essential ones.
	calculateJstar( dualocdata, node ) ;
	calculateJplus( dualocdata, node ) ;

	// Calculate primal and dual value w.r.t. Jplus.
	calculatePrimalDualValue( dualocdata, node ) ;


	feasible = verifySlacknessConditions( dualocdata, node ) ;

	// If Feasible for both dual and primal constraints, we fathom node. If current Dual is worst than best primal, we fathom node. Otherwise we add children node w.r.t. first facility violating.
	if( feasible )
	{
		ToDo.pop_front() ;
		return ;

	}
	else if( dualocdata->dualvalue < dualocdata->bestIntegerSol && node->deepness+1 <= dualocdata->NB_FACILITY )
	{
		AddChildrenNode(ToDo,dualocdata,node) ;
		return ;
	}
	else
	{
		// Dual is worst than current best primal, we fathom it.
		ToDo.pop_front() ;
		return ;
	}
}

void updateCost(DualocData* dualocdata, Noeud* node)
{
	// Reinitialize facility costs
	for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
	{
		dualocdata->openCost[j] = dualocdata->facilityCost[j] ;
	}

	// Actualize cost considering current needs.
	for( unsigned int j = 0 ; j < node->fac.size() ; ++j )
	{
		if( node->fac[j] < 0 )
		{
			dualocdata->openCost[node->fac[j]+dualocdata->NB_FACILITY] = DBL_MAX ;
		}
		else
		{
			dualocdata->openCost[node->fac[j]-dualocdata->NB_FACILITY] = 0.0 ;

			for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
			{
				if( node->vi[i] > dualocdata->clientCost[i][node->fac[j]-dualocdata->NB_FACILITY] )
				{
					node->vi[i] = dualocdata->clientCost[i][node->fac[j]-dualocdata->NB_FACILITY] ;
				}
			}
		}
	}
}

/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */

void InitializationData( DualocData* dualocdata, double lambda1, double lambda2, Data &data )
{
	dualocdata->bestIntegerSol = DBL_MAX ;
	dualocdata->bestJplus = vector<int>() ;

	dualocdata->NB_CUSTOMER = data.getnbCustomer() ;
	dualocdata->NB_FACILITY = data.getnbFacility() ;

	dualocdata->facilityCost = vector<double>(dualocdata->NB_FACILITY) ;
	dualocdata->clientCost = vector< vector <double > >(dualocdata->NB_CUSTOMER,vector<double>(dualocdata->NB_FACILITY)) ;

	dualocdata->openCost = vector<double>(dualocdata->NB_FACILITY) ;
	dualocdata->alloCost = vector< vector <double > >(dualocdata->NB_CUSTOMER,vector<double>(dualocdata->NB_FACILITY+1)) ;

	dualocdata->clientSort = vector< vector < int > >(dualocdata->NB_CUSTOMER,vector<int>(dualocdata->NB_FACILITY+1)) ;

	vector< double > toHelp = vector<double>(dualocdata->NB_FACILITY);

	for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
	{
		for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j)
		{
			dualocdata->clientSort[i][j] = j ;

			toHelp[j] = lambda1 * data.getAllocationObj1Cost(i,j) + lambda2 * data.getAllocationObj2Cost(i,j);

			dualocdata->alloCost[i][j] = lambda1 * data.getAllocationObj1Cost(i,j) + lambda2 * data.getAllocationObj2Cost(i,j);
			dualocdata->openCost[j] = lambda1 * data.getLocationObj1Cost(j) + lambda2 * data.getLocationObj2Cost(j) ;

			dualocdata->clientCost[i][j] = lambda1 * data.getAllocationObj1Cost(i,j) + lambda2 * data.getAllocationObj2Cost(i,j) ;
			dualocdata->facilityCost[j] = lambda1 * data.getLocationObj1Cost(j) + lambda2 * data.getLocationObj2Cost(j) ;
		}

		// Sorting Clients w.r.t. client interests. 
		quicksortClient(toHelp,dualocdata->clientSort[i],0,dualocdata->NB_FACILITY-1);
		dualocdata->alloCost[i][dualocdata->NB_FACILITY] = DBL_MAX ;
		dualocdata->clientSort[i][dualocdata->NB_FACILITY] = dualocdata->NB_FACILITY ;
	}

	dualocdata->Iplus = vector< bool >(dualocdata->NB_CUSTOMER,true);
	dualocdata->Jstar = vector<int>() ; 
	dualocdata->Jplus = vector<int>() ;
}

void InitializationRoot( DualocData* dualocdata, Noeud* node )
{
	node->vi = vector<double>(dualocdata->NB_CUSTOMER,0);
	node->sj = vector<double>(dualocdata->NB_FACILITY,0);
	node->deepness = 0 ;

	for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
	{
		node->vi[i] = dualocdata->clientCost[i][dualocdata->clientSort[i][0]] ;
	}
	for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
	{
		node->sj[j] = dualocdata->facilityCost[j] ;
	}
}

void dualAscent( DualocData* dualocdata, Noeud* node )
{

	vector<int> ciki = vector<int>(dualocdata->NB_CUSTOMER,0) ;


	for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
	{
		for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY+1 ; ++j )
		{
			if( node->vi[i] <= dualocdata->alloCost[i][dualocdata->clientSort[i][j]] )
			{
				ciki[i] = j ;
				break ;
			}
		}
		
		if( node->vi[i] == dualocdata->alloCost[i][dualocdata->clientSort[i][ciki[i]]] )
		{
			++ciki[i] ;
		}
	}

	// Recompute the sj w.r.t. costs and vi.
	for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
	{
		node->sj[j] = dualocdata->openCost[j] ;

		for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
		{
			node->sj[j] -= max(0.0, (node->vi[i] - dualocdata->clientCost[i][j]) ) ;
		}
	}

	bool delta = true ;

	// Start of the Dual Ascent Procedure 
	while( delta )
	{
		delta = false ;
		for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
		{
			if( dualocdata->Iplus[i] )
			{

				double Deltai = DBL_MAX;

				// Finding minimum difference with current vi
				for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
				{
					if( (node->vi[i] >= dualocdata->clientCost[i][j]) && Deltai > node->sj[j] )
					{
						Deltai = node->sj[j] ;
					}
				}

				// Decreasing the Delta to next allocation if necessary to let other vi improve.
				if( Deltai > (dualocdata->alloCost[i][dualocdata->clientSort[i][ciki[i]]] - node->vi[i]) )
				{
					Deltai = (dualocdata->alloCost[i][dualocdata->clientSort[i][ciki[i]]] - node->vi[i]) ;
					delta = true ;
					++ciki[i] ;
				}

				// Apply changes.
				for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
				{
					if( (node->vi[i] >= dualocdata->clientCost[i][j]) )
					{
						node->sj[j] -= Deltai ;
					}
				}
				
				node->vi[i] += Deltai ;
			}
		}
	}
}

void dualAdjustement( DualocData* dualocdata, Noeud* node )
{

	for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
	{
		bool stillgoing = true ;
		while( stillgoing )
		{

			// We save the original value of current vi to see if we can loop on current customer.
			double originalvi = node->vi[i] ;
			stillgoing = false ;

			// We calculate Jiplus and thus corresponding Jstar and Jplus which will also serve later for Ijplus.
			vector<int> Jiplus ;

			calculateJstar(dualocdata,node) ;
			calculateJplus(dualocdata,node) ;
			calculateJiplus(dualocdata,node,Jiplus,i);

			// if Jiplus strictly greater than 1, this customer violate a slack dual primal constraint. We then try to adjust it.
			if( Jiplus.size() > 1 )
			{
				int firstj = dualocdata->Jplus[0] ;
				int correspondingvalue = INT_MAX ;
				int correspondingvalue2 = INT_MAX ;
				int secondj = dualocdata->Jplus[dualocdata->Jplus.size()-1] ;

				for( unsigned int j = 0 ; j < dualocdata->Jplus.size() ; ++j )
				{
					if( correspondingvalue >= dualocdata->clientCost[i][dualocdata->Jplus[j]] )
					{
						secondj = firstj ;
						correspondingvalue2 = correspondingvalue ;
						firstj = dualocdata->Jplus[j] ;
						correspondingvalue = dualocdata->clientCost[i][dualocdata->Jplus[j]] ;
					}
					else if( correspondingvalue2 > dualocdata->clientCost[i][dualocdata->Jplus[j]])
					{
						correspondingvalue2 = dualocdata->clientCost[i][dualocdata->Jplus[j]] ;
						secondj = dualocdata->Jplus[j] ;
					}
				}

				// Considering previous code an subsequent, we find which facility in Jplus are the two best w.r.t customer i and we computer the set Ijplus and Ijsecond to see if there is other customers which could improve if we adjust current one.

				vector<int> Ijplus ;
				calculateIjplus(dualocdata,node,firstj,Ijplus);
				vector<int> Ijsecond ;
				calculateIjplus(dualocdata,node,secondj,Ijsecond);

				if( Ijplus.size() > 0 || Ijsecond.size() > 0 )
				{

					// We find the highest allocation strictly inferior to current vi and give back some slackness.

					double Cjmoins = calculateCjmoins(dualocdata,node,i) ;

					// We apply the modification to the sj and give back some room for improvement.
					for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
					{
						
						if( node->vi[i] > dualocdata->clientCost[i][j] )
						{
							node->sj[j] += (node->vi[i]-Cjmoins) ;	
						}
						
					}

					node->vi[i] = Cjmoins ;
					
					// We compute the set of customer which are able to improve w.r.t. current client.
					dualocdata->Iplus.clear() ;
					dualocdata->Iplus = vector<bool>(dualocdata->NB_CUSTOMER,false) ;

					for( unsigned int i2 = 0 ; i2 < Ijplus.size() ; ++i2 )
					{
						dualocdata->Iplus[Ijplus[i2]] = true ;
					}
					for( unsigned int i2 = 0 ; i2 < Ijsecond.size() ; ++i2 )
					{
						dualocdata->Iplus[Ijsecond[i2]] = true ;
					}

					// We apply Dual Ascent on this set of customer to let them improve.
					dualAscent(dualocdata,node);

					dualocdata->Iplus[i] = true ;

					// We apply Dual Ascent to client i.
					dualAscent(dualocdata,node);

					dualocdata->Iplus.clear() ;
					dualocdata->Iplus = vector<bool>(dualocdata->NB_CUSTOMER,true) ;

					// We apply Dual Ascent a last time to all customer.
					dualAscent(dualocdata,node);


					if( originalvi != node->vi[i] )
					{
						stillgoing = true ;
					}
				}
			}
		}
	}
}

/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */

void computeUB(DualocData* dualocdata, Box* toReturn, Data &data)
{
	toReturn->upperBoundObj1 = 0.0 ;
	toReturn->upperBoundObj2 = 0.0 ;

	// Add construction cost of open facilities
	for( unsigned int j = 0 ; j < dualocdata->bestJplus.size() ; ++j )
	{
		toReturn->upperBoundObj1 += data.getLocationObj1Cost( dualocdata->bestJplus[j] ) ;
		toReturn->upperBoundObj2 += data.getLocationObj2Cost( dualocdata->bestJplus[j] ) ;
	}

	// Add allocation cost of client facilities.
	for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
	{
		for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
		{
			bool toStop = false ;

			for( unsigned int k = 0 ; k < dualocdata->bestJplus.size() ; ++k )
			{
				if( dualocdata->clientSort[i][j] == dualocdata->bestJplus[k] )
				{
					toStop = true ;
					break ;
				}
			}

			if( toStop )
			{
				toReturn->upperBoundObj1 += data.getAllocationObj1Cost(i,dualocdata->clientSort[i][j]) ;
				toReturn->upperBoundObj2 += data.getAllocationObj2Cost(i,dualocdata->clientSort[i][j]) ;
				break ;
			}
		}
	}
}

bool violateSlacknessConditions( DualocData* dualocdata, Noeud* node, unsigned int clienti, unsigned int &minfacility)
{
	bool infeasible = false ;
	double currentminalloc = DBL_MAX ;
	int total = 0 ;


	for( unsigned int j = 0 ; j < dualocdata->Jplus.size() ; ++j )
	{
		// We check how many allocation vi is strictly greater than.
		if( node->vi[clienti] > dualocdata->clientCost[clienti][dualocdata->Jplus[j]] )
		{
			++total ;

			// We remember the smallest allocation and the corresponding facilities for further use.
			if( currentminalloc > dualocdata->clientCost[clienti][dualocdata->Jplus[j]] )
			{
				currentminalloc = dualocdata->clientCost[clienti][dualocdata->Jplus[j]] ;
				minfacility = dualocdata->Jplus[j] ;
			}
		}

		// If vi is greater than two allocation then current set Jplus does not give an optimal set.
		if( total > 1 )
		{
			infeasible = true ;
		}
	}

	return infeasible ;
}	

bool verifySlacknessConditions( DualocData* dualocdata, Noeud* node )
{
	for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
	{
		int total = 0 ;

		for( unsigned int j = 0 ; j < dualocdata->Jplus.size() ; ++j )
		{
			// We check how many allocation vi is strictly greater than.
			if( node->vi[i] > dualocdata->clientCost[i][dualocdata->Jplus[j]] )
			{
				++total ;
			}

			// If vi is greater than two allocation then current set Jplus does not give an optimal set.
			if( total > 1 )
			{
				return false ;
			}
		}
	}

	return true ;
}

void calculatePrimalDualValue( DualocData* dualocdata, Noeud* node )
{
	dualocdata->primalvalue = 0.0 ;
	dualocdata->dualvalue = 0.0 ;

	// Add Facility Cost to Primal and Dual objective Value.
	for( unsigned int j = 0 ; j < dualocdata->Jplus.size() ; ++j )
	{
		dualocdata->primalvalue += dualocdata->facilityCost[dualocdata->Jplus[j]] ;

		if( dualocdata->openCost[dualocdata->Jplus[j]] == 0.0 )
		{
			dualocdata->dualvalue += dualocdata->facilityCost[dualocdata->Jplus[j]] ;
		}
	}

	// Add Vi and allocation value to primal and dual objective value.
	for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
	{
		dualocdata->dualvalue += node->vi[i] ;

		for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
		{
			bool toStop = false ;

			// Check which is best allocation for current client w.r.t current Jplus set.
			for( unsigned int k = 0 ; k < dualocdata->Jplus.size() ; ++k )
			{
				if( dualocdata->clientSort[i][j] == dualocdata->Jplus[k] )
				{
					toStop = true ;
					break ;
				}
			}

			if( toStop )
			{
				dualocdata->primalvalue += dualocdata->clientCost[i][dualocdata->clientSort[i][j]] ;
				break ;
			}
		}
	}

	// if current primal value is better than best in memory, we update it.
	if( dualocdata->primalvalue < dualocdata->bestIntegerSol )
	{
		dualocdata->bestIntegerSol = dualocdata->primalvalue ;
		dualocdata->bestJplus.clear() ;

		for( unsigned int j = 0 ; j < dualocdata->Jplus.size() ; ++j )
		{
			dualocdata->bestJplus.push_back(dualocdata->Jplus[j]) ;
		}
	}
}

double calculateCjmoins( DualocData* dualocdata, Noeud* node, int clienti )
{
	double Cjmoins = 0.0 ;

	// Find the maximum allocation strictly lower than vi w.r.t. client i
	for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
	{
		if( node->vi[clienti] > dualocdata->clientCost[clienti][j] && Cjmoins < dualocdata->clientCost[clienti][j] )
		{
			Cjmoins = dualocdata->clientCost[clienti][j] ;
		}
	}

	return Cjmoins ;
}

void calculateIjplus( DualocData* dualocdata, Noeud* node, int facilityj, vector<int> &Ijplus)
{
	Ijplus.clear() ;
	Ijplus = vector<int>() ;

	// Find the client which can potentially increase if we had slackness to facility j.
	for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
	{
		vector<int> Jistar = vector<int>() ;	
		calculateJistar(dualocdata,node,Jistar,i);

		if( Jistar.size() == 1 && Jistar[0] == facilityj )
		{
			Ijplus.push_back(i) ;
		}
	}
}

void calculateJstar( DualocData* dualocdata, Noeud* node )
{
	dualocdata->Jstar.clear() ;
	dualocdata->Jstar = vector<int>() ;

	// Finding all the viable facilities for the Primal
	for( unsigned int j = 0 ; j < dualocdata->NB_FACILITY ; ++j )
	{
		if( node->sj[j] == 0.0 )
		{
			dualocdata->Jstar.push_back(j) ;
		}
	}
}

void calculateJplus( DualocData* dualocdata, Noeud* node )
{
	dualocdata->Jplus.clear() ;
	dualocdata->Jplus = vector<int>() ;

	// Adding Essential Facilities as stated by Erlenkotter 
	for( unsigned int j = 0 ; j < dualocdata->Jstar.size() ; ++j )
	{
		int sum = 0 ;
		for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
		{
			if( dualocdata->clientCost[i][dualocdata->Jstar[j]] <= node->vi[i] )
			{
				sum++ ;
			}	
			if( sum > 1 )
			{
				break ;
			}
		}

		if( sum == 1 )
		{
			dualocdata->Jplus.push_back(dualocdata->Jstar[j]) ;
		}
	}

	// Adding Non-Essential Facilities to make the primal viable
	for( unsigned int i = 0 ; i < dualocdata->NB_CUSTOMER ; ++i )
	{
		bool searchtodo = true ;

		for( unsigned int j = 0 ; j < dualocdata->Jplus.size() ; ++j )
		{
			if( dualocdata->clientCost[i][dualocdata->Jplus[j]] <= node->vi[i] )
			{
				searchtodo = false ;
				break ;
			}
		}

		// We do not have a current viable facilities for current customer inside Jplus, so we find which one to add.
		if( searchtodo )
		{
			double cij = DBL_MAX;
			int correspondingj = -1 ;

			for( unsigned int j = 0 ; j < dualocdata->Jstar.size() ; ++j )
			{
				if( dualocdata->clientCost[i][dualocdata->Jstar[j]] <= node->vi[i] && cij > dualocdata->clientCost[i][dualocdata->Jstar[j]] )
				{
					cij = dualocdata->clientCost[i][dualocdata->Jstar[j]] ;
					correspondingj = dualocdata->Jstar[j] ;
				}
			}

			dualocdata->Jplus.push_back(correspondingj) ;
		}
	}
}

void calculateJistar(DualocData* dualocdata, Noeud* node, vector<int> &Jistar, int clienti)
{
	Jistar.clear() ;
	Jistar = vector<int>() ;

	// For a given client i, we compute the set of facilities such that vi is greater or equal than allocation cost
	for( unsigned int j = 0 ; j < dualocdata->Jstar.size() ; ++j )
	{
		if( node->vi[clienti] >= dualocdata->clientCost[clienti][dualocdata->Jstar[j]] )
		{
			Jistar.push_back(dualocdata->Jstar[j]) ;
		}
	}
}

void calculateJiplus( DualocData* dualocdata, Noeud* node, vector<int> &Jiplus, int clienti )
{
	Jiplus.clear() ;
	Jiplus = vector<int>() ;

	// For a given client i, we compute the set of facilities such that vi is strictly greater than allocation cost
	for( unsigned int j = 0 ; j < dualocdata->Jplus.size() ; ++j )
	{
		if( node->vi[clienti] > dualocdata->clientCost[clienti][dualocdata->Jplus[j]] )
		{
			Jiplus.push_back(dualocdata->Jplus[j]) ;
		}
	}
}

/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */
/*
 *
 *
 *
 */

void quicksortClient(vector<double> &toHelp, vector<int> &toSort, int begin, int end)
{
	int i = begin, j = end;
	double tmpcost;
	int tmpfacility;

	double pivot = toHelp[(begin + end) / 2];

	/* partition */

	while (i <= j) 
	{
		bool cntn = true ;
	    while (toHelp[i] <= pivot && cntn && i < end)
	    {
	    	if( toHelp[i] < pivot )
	        {
	        	i++;
	        }
	      	else
	      	{
	      		cntn = false ;
	      	}
	    }

	    cntn = true ;
	    while (toHelp[j] >= pivot && cntn && j > begin )
	    {
	    	if( toHelp[j] > pivot )
	        {
	        	j--;
	        }
	      	else
	      	{
	      		cntn = false ;
	      	}
	    }

	    if (i <= j) 
	    {
	          tmpfacility = toSort[i];
	          tmpcost = toHelp[i];

	          toSort[i] = toSort[j];
	          toHelp[i] = toHelp[j];

	          toSort[j] = tmpfacility;
	          toHelp[j] = tmpcost;

	          i++;
	          j--;
	    }
	};

	/* recursion */

	if (begin < j)
	{
	    quicksortClient(toHelp, toSort, begin, j);
	}
	if (i < end)
	{
	    quicksortClient(toHelp, toSort, i, end);
	}
}