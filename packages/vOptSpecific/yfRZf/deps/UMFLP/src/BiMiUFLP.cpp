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
* \file Main.cpp
* \brief Main of the software.
* \author Quentin DELMEE & Xavier GANDIBLEUX & Anthony PRZYBYLSKI
* \date 01 January 2017
* \version 1.3
* \copyright GNU General Public License
*
* This class exports values, solutions to file in the folder res.
*
*/

#include <stdexcept>
#include <iostream>
#include <iomanip>

#include <string.h>
#include <cfloat>
#include <cmath>
#include <cstdlib>
#include <time.h>


#include "Data.hpp"
#include "Functions.hpp"


/*! \namespace std
* 
* Using the standard namespace std of the IOstream library of C++.
*/
using namespace std;


/*!
*	\defgroup main Main
*/

/*!
*	\fn int main(int argc, char *argv[])
*	\ingroup main
*
*	\brief This is the main of the software.
*	\param[in] argc : An integer which represents the number of arguments passed to the line command.
*	\param[in] argv : An array of character which represents all the arguments.
*/
extern "C"
int solve(unsigned int nbCustomer, unsigned int nbFacility, double *c_alloc1, double *c_alloc2, double *c_loc1, double *c_loc2, 
	bool modeVerbose, bool modeLowerBound, bool modeFullDicho, bool modeDichoBnB, bool modeImprovedLB, bool modeImprovedUB, bool modeParam, bool modeSortFacility, 
	double **z1, double **z2, bool **facility, bool **isEdge, bool **isExtremityDominated, int **nbAlloc, int **customerAllocation, int **correspondingFac, double **percentageAlloc )
{	

	Data data = Data() ; //Data
	
	long int boxBeforeFitlering(0);
	long int boxAfterFiltering(0);
	long int numberBoxComputed(0);
	long double boxTotal(0);

    //Time strucure
	clock_t start, end, beginB, endB, beginBF, endBF, beginLS, endLS, beginUB, endUB ;

	data.Init(nbFacility, nbCustomer, "BiUFLP");
    
	//Allocation cost w.r.t. objective 1
	for(unsigned int i = 0; i < nbCustomer; ++i)
	{
		for(unsigned int j = 0; j < nbFacility; ++j)
		{
			data.setAllocationObj1Cost(i, j, c_alloc1[i*nbFacility + j]);
		}
	}
	//Allocation cost w.r.t. objective 2
	for(unsigned int i = 0; i < nbCustomer; ++i)
	{
		for(unsigned int j = 0; j < nbFacility; ++j)
		{
			data.setAllocationObj2Cost(i, j, c_alloc2[i*nbFacility + j]);
		}
	}
	//Location cost w.r.t. objective 1 for Facility
	for(unsigned int i = 0; i < nbFacility; ++i)
	{			
		data.setLocationObj1Cost(i,c_loc1[i]);
	}
	//Location cost w.r.t. objective 2 for Facility
	for(unsigned int i = 0; i < nbFacility; ++i)
	{
		data.setLocationObj2Cost(i,c_loc2[i]);
	}
    

	data.modeVerbose = modeVerbose;	

	data.modeLowerBound = modeLowerBound;							

	data.modeFullDicho = modeFullDicho;				

	data.modeDichoBnB = modeDichoBnB;				

	data.modeImprovedLB = modeImprovedLB;				

	data.modeImprovedUB = modeImprovedUB;				

	data.modeParam = modeParam;				

	data.modeSortFacility = modeSortFacility;							

	//## END READING ARGUMENTS ##


	// if ImprovedLB data.mode is on, the necessarily LowerBound data.mode is also on.
	data.modeLowerBound = data.modeLowerBound || data.modeImprovedLB ;

	unsigned int NB_Facility = data.getnbFacility() ;
	unsigned int NB_Customer = data.getnbCustomer() ;
	int bound1 = 0;
	int bound2 = 0;
	data.BoundDeepNess = NB_Facility ;

	crono_start(start);



	if( true )
	{
		/* calculate max deepness */ 

		vector<double> allObj1 = vector<double>(NB_Facility,0);
		vector<double> allObj2 = vector<double>(NB_Facility,0);

		double maxObj1 = 0 ;
		double maxObj2 = 0 ;



		for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
		{
			for( unsigned int i = 0 ; i < data.getnbCustomer() ; ++ i)
			{
				allObj1[j] += data.getAllocationObj1Cost(i,j) ;
				allObj2[j] += data.getAllocationObj2Cost(i,j) ;
			}

			if( maxObj1 < allObj1[j] )
				maxObj1 = allObj1[j] ;

			if( maxObj2 < allObj2[j] )
				maxObj2 = allObj2[j] ;
		}

		vector< double > toSortObj1 ;
		vector< double > toSortObj2 ;

		for( unsigned int i = 0 ; i < data.getnbFacility() ; ++i )
		{
			toSortObj1.push_back( data.getLocationObj1Cost(i) ) ;
			toSortObj2.push_back( data.getLocationObj2Cost(i) ) ;
		}


		quicksortFacilityOBJ1(toSortObj1,0,toSortObj1.size()-1);
		quicksortFacilityOBJ2(toSortObj2,0,toSortObj2.size()-1);

		int minfacobj1 = 0 ;
		int minfacobj2 = 0 ; 

		double currentobj1 = 0 ;
		double currentobj2 = 0 ;

		for( unsigned int i = 0 ; i < data.getnbFacility() ; ++i )
		{
			currentobj1 += toSortObj1[i] ;

			if( currentobj1 >= maxObj1 )
			{
				minfacobj1 = i+1 ;
				break ;
			}	
		}

		if( minfacobj1 == 0 )
			minfacobj1 = NB_Facility ;

		for( unsigned int i = 0 ; i < data.getnbFacility() ; ++i )
		{
			currentobj2 += toSortObj2[i] ;

			if( currentobj2 >= maxObj2 )
			{
				minfacobj2 = i+1 ;
				break ;
			}	
		}

		if( minfacobj2 == 0 )
			minfacobj2 = NB_Facility ;


		bound1 = max(minfacobj1, minfacobj2);

		if( data.BoundDeepNess > bound1 )
		{
			data.BoundDeepNess = bound1 ;
		}

	}
	



	//#########################################################
	//## We prepare to sort facility by customer preferences ##

	vector< vector<double> > toHelp = vector< vector<double> >(4,vector<double>(NB_Facility)) ;

	data.customerSort = vector< vector< vector<int> > >(NB_Customer,vector< vector<int> >(2,vector<int>(NB_Facility)));

	for( unsigned int i = 0 ; i < NB_Customer ; ++i )
	{
		for( unsigned int j = 0 ; j < NB_Facility ; ++j)
		{
			data.customerSort[i][0][j] = j ;
			data.customerSort[i][1][j] = j ;

			toHelp[0][j] = data.getAllocationObj1Cost(i,j);
			toHelp[1][j] = data.getAllocationObj2Cost(i,j);
			toHelp[2][j] = data.getAllocationObj1Cost(i,j);
			toHelp[3][j] = data.getAllocationObj2Cost(i,j);

		}

		quicksortCusto(toHelp[0], toHelp[1],data.customerSort[i][0],0,NB_Facility-1);
		quicksortCusto(toHelp[3], toHelp[2],data.customerSort[i][1],0,NB_Facility-1);
	}

	for( unsigned int i = 0 ; i < data.getnbCustomer() ; ++i )
	{
		data.optimalAllocationObj1 += data.getAllocationObj1Cost(i, data.customerSort[i][0][0] );
		data.optimalAllocationObj2 += data.getAllocationObj2Cost(i, data.customerSort[i][1][0] );
	}

	//###############################################
	//## We initialise the order of the facilities ##

	for(unsigned int it = 0 ; it < NB_Facility ; ++it)
	{
		data.facilitySort.push_back(it);
	}

	//#############################
	//## Functions to create Box ##

	vector<Box*> vectorBox = vector<Box*>() ;
	vector<string> openedFacility = vector<string>() ;

	crono_start(beginUB);
	if( data.modeImprovedUB )
	{
		// If ImprovedUB data.mode is on we calculate a nice UBS using DUALOC and a heuristic dichotomic search
		vector<bool> dichoSearch;
		int size = (-1)  ;
		
		while( size < (int)vectorBox.size() )
		{
			size = vectorBox.size();
			computeUpperBound(vectorBox, dichoSearch, data);
		}


		// We Calculate a bound on the maximum deepness.
		if( true )
		{
			/* calculate max deepness */ 

			double maxObj1 = vectorBox[vectorBox.size()-1]->upperBoundObj1 ;
			double maxObj2 = vectorBox[0]->upperBoundObj2 ;

			vector< double > toSortObj1 ;
			vector< double > toSortObj2 ;

			for( unsigned int i = 0 ; i < data.getnbFacility() ; ++i )
			{
				toSortObj1.push_back( data.getLocationObj1Cost(i) ) ;
				toSortObj2.push_back( data.getLocationObj2Cost(i) ) ;
			}

			quicksortFacilityOBJ1(toSortObj1,0,toSortObj1.size()-1);
			quicksortFacilityOBJ2(toSortObj2,0,toSortObj2.size()-1);

			int minfacobj1 = 0 ;
			int minfacobj2 = 0 ; 

			double currentobj1 = 0 ;
			double currentobj2 = 0 ;

			for( unsigned int i = 0 ; i < data.getnbFacility() ; ++i )
			{
				currentobj1 += toSortObj1[i] ;
				if( currentobj1 >= maxObj1 - data.optimalAllocationObj1 )
				{
					minfacobj1 = i+1 ;
					break ;
				}	
			}

			if( minfacobj1 == 0 )
				minfacobj1 = NB_Facility ;

			for( unsigned int i = 0 ; i < data.getnbFacility() ; ++i )
			{
				currentobj2 += toSortObj2[i] ;
				if( currentobj2 >= maxObj2 - data.optimalAllocationObj2 )
				{
					minfacobj2 = i+1 ;
					break ;
				}	
			}

			if( minfacobj2 == 0 )
				minfacobj2 = NB_Facility ;

			if( maxObj1 == vectorBox[0]->getMinZ1() )
			{
				minfacobj1 = max(minfacobj1,minfacobj2) ;
				minfacobj2 = minfacobj1 ;
			}

			bound2 = min( minfacobj1, minfacobj2);

			if( data.BoundDeepNess > bound2 )
			{
				data.BoundDeepNess = bound2 ;
			}
		}





		vector<Box*> temp = vectorBox ;
		vectorBox.clear() ;

		/* ELIMINATION OF DOUBLE MOLP */
		for( unsigned int it = 0 ; it < temp.size() ; ++it )
		{
			if( !isAlreadyIn(openedFacility, temp[it]) )
			{
				vectorBox.push_back(temp[it]);
				openedFacility.push_back(temp[it]->getId());
			}
		}

		// We calculate the MOLP of each remaining point to improve the UBS then we filter dominated edges.
		for(unsigned int it = 0 ; it < vectorBox.size() ; ++it )
		{
			if( vectorBox[it]->getHasEdge() && vectorBox[it]->getHasMoreStepWS() )
				parametricSearchUB(vectorBox[it], data) ;
		}
		filter(vectorBox);
		edgefiltering(vectorBox,data);
	}
	crono_stop(endUB);

	if( data.modeSortFacility )
	{
		// If SortFacility data.mode is on, we will calculate a preference value of each facility and sort them in increasing value of preference.
		vector< double > clientfacilitycost1 ;
		vector< double > clientfacilitycost2 ;

		clientfacilitycost1 = vector<double>(NB_Facility,0);
		clientfacilitycost2 = vector<double>(NB_Facility,0);

		// We calculate the cost of allocating every client to each facility w.r.t. objective 1 and objective 2
		for( unsigned int i = 0 ; i < NB_Facility ; ++i )
		{
			for( unsigned int j = 0 ; j < NB_Customer ; ++j )
			{
				clientfacilitycost1[i] += data.getAllocationObj1Cost(j,i) ;
				clientfacilitycost2[i] += data.getAllocationObj2Cost(j,i) ;
			}
		}

		// We sort the facility w.r.t. a heuristic function value ( could be improved )
		sortFacility(data,clientfacilitycost1,clientfacilitycost2);
	}

	//######################
	//## Branch and Bound ##


	crono_start(beginB);
	numberBoxComputed = createBox(vectorBox, openedFacility, data);
	boxBeforeFitlering = vectorBox.size();
	crono_stop(endB);

	//###############################
	//## Functions to filter Boxes ##

	vector<Box*> vectorBoxFinal = vector<Box*>();

	crono_start(beginBF);
	if( data.modeParam )
	{
		// If Param data.mode is on, we will use a specific parametric search to calculate the non-dominated point of each box then filter the dominated edges.
		for( unsigned int it = 0 ; it < vectorBox.size() ; ++it )
		{
			if( vectorBox[it]->getHasEdge() && vectorBox[it]->getHasMoreStepWS() )
			{
				parametricSearch(vectorBox[it],data) ;
			}
		}

		filter(vectorBox);
	}
	else
	{
		// If Param data.mode is off, we will use a heuristic dichotomic search which filter the box at the same time.
		boxFiltering(vectorBox,data);
	}
	crono_stop(endBF);

	boxAfterFiltering = vectorBox.size();


	// We sort the boxes in lexicographical order w.r.t objective 1
	quicksortedge(vectorBox,0,vectorBox.size()-1);


	vectorBoxFinal.clear() ;
	vectorBoxFinal = vectorBox;

	//#################################################################################
	//## We finish filtering edges and point considering the comparison of T.Vincent ##

	crono_start(beginLS);
	edgefiltering(vectorBoxFinal,data);
	crono_stop(endLS);

	//#########
	//## END ##		

	crono_stop(end);

	int EdgeNumber = 0;
	int PointNumber = 0;

	//####################################################
	//## We compute the number of point and edges found ##

	for(unsigned int it = 0 ; it < vectorBoxFinal.size() ; ++it )
	{
		for(unsigned int it2 = 0 ; it2 < vectorBoxFinal[it]->points.size()-2 ; it2 = it2 + 2 )
		{
			if( vectorBoxFinal[it]->edges[it2/2] )
			{
				if( !vectorBoxFinal[it]->getHasEdge() )
				{
					PointNumber++ ;
				}
				else
				{
					EdgeNumber++;
				}
			}
		}
	}

	//###################################
	//## Messages from Verbose Mode ON ##

	boxTotal = pow((long double)2, (int)NB_Facility )-1;

	if(data.modeVerbose)
	{
		cout << endl;
		cout << "+" << setfill('-') << setw(15) << "+" << " INSTANCE " << "+" << setw(16) << "+" << endl;
		cout << setfill (' ');
		cout << " " << setw(20) << left << "Name " << "|" << setw(20) << right << data.getFileName() << " " << endl;
		cout << " " << setw(20) << left << "Facility " << "|" << setw(20) << right << NB_Facility << " " << endl;
		cout << " " << setw(20) << left << "Customer " << "|" << setw(20) << right << NB_Customer << " " << endl;
		cout << " " << setw(20) << left << "Correlation " << "|" << setw(20) << right << computeCorrelation(data) << " " << endl;
		cout << "+" << setfill('-') << setw(42) << "+" << endl << endl;
	}
	if(data.modeVerbose)
	{
		cout << "+" << setfill('-') << setw(15) << "+" << " DEEPNESS " << "+" << setw(16) << "+" << endl;
		cout << setfill (' ');
		cout << " " << setw(20) << left << "Bound 1 " << "|" << setw(20) << right << bound1 << " " << endl;
		if( data.modeImprovedUB )
		{
			cout << " " << setw(20) << left << "Bound 2 " << "|" << setw(20) << right << bound2 << " " << endl;
			cout << " " << setw(20) << left << "Final Bound " << "|" << setw(20) << right << min(bound1,bound2) << " " << endl;
		}	
		cout << " " << setw(20) << left << "Reality " << "|" << setw(20) << right << data.MaxDeepNess << " " << endl;
		cout << "+" << setfill('-') << setw(42) << "+" << endl << endl;
	}
	if(data.modeVerbose)
	{
		cout << "+" << setfill('-') << setw(18) << "+" << " BNB " << "+" << setw(18) << "+" << endl;
		cout << setfill (' ');
		cout << " " << setw(20) << left << "UB Time (ms) " << "|" << setw(20) << right << crono_ms(beginUB,endUB) << " " << endl;
		cout << " " << setw(20) << left << "Box Total " << "|" << setw(20) << right << setprecision(0) << fixed << boxTotal << " " << endl;
		cout << " " << setw(20) << left << "Box Computed " << "|" << setw(20) << right << numberBoxComputed << " " << endl;
		cout << " " << setw(20) << left << "Box Non-Dominated" << "|" << setw(20) << right << boxBeforeFitlering << " " << endl;
		cout << " " << setw(20) << left << "BNB Time (ms) " << "|" << setw(20) << right << crono_ms(beginB,endB) << " " << endl;
		cout << "+" << setfill('-') << setw(42) << "+" << endl << endl;
	}

	if(data.modeVerbose)
	{
		cout << "+" << setfill('-') << setw(13) << "+" << " BOX FILTERING " << "+" << setw(13) << "+" << endl;
		cout << setfill (' ');
		cout << "+" << setfill(' ') << setw(10) << " " <<" ! after filtering !  " << " " << setw(9) << "+" << endl;
		cout << " " << setw(20) << left << "Box " << "|" << setw(20) << right << setprecision(0) << fixed << boxAfterFiltering << " " << endl;
		cout << " " << setw(20) << left << "Time (ms) " << "|" << setw(20) << right << crono_ms(beginBF,endBF) << " " << endl;
	}

	if(data.modeVerbose)
	{
		cout << "+" << setfill('-') << setw(12) << "+" << " DOMINANCE FILTER " << "+" << setw(11) << "+" << endl;
		cout << setfill (' ');
		cout << " " << setw(20) << left << "Non Dominated Box" << "|" << setw(20) << right << setprecision(0) << fixed << vectorBoxFinal.size() << " " << endl;
		cout << " " << setw(20) << left << "Time (ms) " << "|" << setw(20) << right << crono_ms(beginLS,endLS) << " " << endl;
		cout << "+" << setfill('-') << setw(42) << "+" << endl;
	}


	cout << endl;
	cout << "+" << setfill('-') << setw(15) << "+" << " SYNTHESIS " << "+" << setw(15) << "+" << endl;
	cout << setfill (' ');
	cout << " " << setw(20) << left << "Instance " << "|" << setw(20) << right << data.getFileName() << " " << endl;
	cout << " " << setw(20) << left << "Set of Facilities " << "|" << setw(20) << right << setprecision(0) << fixed << vectorBoxFinal.size() << " " << endl;
	cout << " " << setw(20) << left << "Number of Points " << "|" << setw(20) << right << setprecision(0) << fixed << PointNumber << " " << endl;
	cout << " " << setw(20) << left << "Number of Edges " << "|" << setw(20) << right << setprecision(0) << fixed << EdgeNumber << " " << endl;
	cout << " " << setw(20) << left << "Total Time (ms) " << "|" << setw(20) << right << crono_ms(start,end) << " " << endl;
	cout << "+" << setfill('-') << setw(42) << "+" << endl << endl;


























	// cout << "Post-Processing Result ..." << endl ;
	// cout << "0% " << flush ;
	for( unsigned int i = 0 ; i < vectorBoxFinal.size() ; ++i )
	{
		postProcessing(vectorBoxFinal[i], data);
		// cout << double(i+1) / double(vectorBoxFinal.size()) * 100.0 << "% " << flush  ;
	}
	// cout << endl ;
	// cout << "Retrieving Result ..." << endl ;

	int nbpoint = 0 ;
	int totalAlloc = 0 ;

	vector<double> futurZ1 = vector<double>() ;
	vector<double> futurZ2 = vector<double>() ;
	vector<bool> futurEdge = vector<bool>() ;
	vector<bool> futurExtremity = vector<bool>() ;
	vector<int> futurAlloc = vector<int>() ;
	vector<int> futurCorFac = vector<int>() ;
	vector<int> futurCustoAlloc = vector<int>() ;
	vector<bool> futurFacility = vector<bool>() ;
	vector<double> futurPercentage = vector<double>() ;


	for(unsigned int it = 0; it < vectorBoxFinal.size(); it++)
	{
		unsigned int last = vectorBoxFinal[it]->points.size() - 2 ;

		if( !vectorBoxFinal[it]->getHasEdge() )
		{
			nbpoint++ ;
			futurZ1.push_back( vectorBoxFinal[it]->getMinZ1() ) ;
			futurZ2.push_back( vectorBoxFinal[it]->getMinZ2() ) ;

			for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
			{
				futurFacility.push_back( vectorBoxFinal[it]->isOpened(j) ) ;
			}

			int nbAlloc = 0 ;
			
			for( unsigned int i = 0 ; i < data.getnbCustomer() ; ++i )
			{
				for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
				{
					if( vectorBoxFinal[it]->clientAllocation[0][i][j] )
					{
						nbAlloc++ ;
						futurCustoAlloc.push_back(i) ;
						futurCorFac.push_back(j) ;
						futurPercentage.push_back(1.0) ;
						break ;
					}
				}
			}

			totalAlloc += nbAlloc ;
			futurAlloc.push_back( nbAlloc ) ;

			futurEdge.push_back( false ) ;
			futurExtremity.push_back( false ) ;
		}
		else
		{
			for( unsigned int it2 = 0 ; it2 < last ; it2 = it2 + 2 )
			{
				
				if( vectorBoxFinal[it]->edges[it2/2] )
				{
					nbpoint++ ;
					bool point1dominated = false ;

					for( unsigned int i = 0 ; i < vectorBoxFinal.size() ; ++i )
					{
						for( unsigned int j = 0 ; j < vectorBoxFinal[i]->points.size() ; j = j + 2 )
						{
							if( ( vectorBoxFinal[i]->points[j] < vectorBoxFinal[it]->points[it2] && vectorBoxFinal[i]->points[j+1] <= vectorBoxFinal[it]->points[it2+1] ) || ( vectorBoxFinal[i]->points[j] <= vectorBoxFinal[it]->points[it2] && vectorBoxFinal[i]->points[j+1] < vectorBoxFinal[it]->points[it2+1] ) ) 
							{
								point1dominated = true ;
								break ;
							}
						}
					}

					futurEdge.push_back( true ) ;
					futurExtremity.push_back(point1dominated) ;

					futurZ1.push_back( vectorBoxFinal[it]->points[it2] ) ;
					futurZ2.push_back( vectorBoxFinal[it]->points[it2+1] ) ;

					for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
					{
						futurFacility.push_back( vectorBoxFinal[it]->isOpened(j) ) ;
					}

					int nbAlloc = 0 ;

					for( unsigned int i = 0 ; i < data.getnbCustomer() ; ++i )
					{
						for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
						{
							if( vectorBoxFinal[it]->clientAllocation[it2/2][i][j] == 1 )
							{
								nbAlloc++ ;
								futurCustoAlloc.push_back(i) ;
								futurCorFac.push_back(j) ;
								futurPercentage.push_back(1.0) ;
								break ;
							}
							else if( vectorBoxFinal[it]->clientAllocation[it2/2][i][j] > 0 )
							{
								nbAlloc++ ;
								futurCustoAlloc.push_back(i) ;
								futurCorFac.push_back(j) ;
								futurPercentage.push_back(vectorBoxFinal[it]->clientAllocation[it2/2][i][j]) ;
							}
						}
					}
					totalAlloc += nbAlloc ;
					futurAlloc.push_back( nbAlloc ) ;
				}//endelseif
				else
				{
					nbpoint++ ;
					
					futurEdge.push_back( false ) ;
					futurExtremity.push_back( false ) ;

					futurZ1.push_back( vectorBoxFinal[it]->points[it2] ) ;
					futurZ2.push_back( vectorBoxFinal[it]->points[it2+1] ) ;

					for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
					{
						futurFacility.push_back( vectorBoxFinal[it]->isOpened(j) ) ;
					}

					int nbAlloc = 0 ;

					for( unsigned int i = 0 ; i < data.getnbCustomer() ; ++i )
					{
						for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
						{
							if( vectorBoxFinal[it]->clientAllocation[it2/2][i][j] == 1 )
							{
								nbAlloc++ ;
								futurCustoAlloc.push_back(i) ;
								futurCorFac.push_back(j) ;
								futurPercentage.push_back(1.0) ;
								break ;
							}
							else if( vectorBoxFinal[it]->clientAllocation[it2/2][i][j] > 0 )
							{
								nbAlloc++ ;
								futurCustoAlloc.push_back(i) ;
								futurCorFac.push_back(j) ;
								futurPercentage.push_back(vectorBoxFinal[it]->clientAllocation[it2/2][i][j]) ;
							}
						}
					}

					totalAlloc += nbAlloc ;
					futurAlloc.push_back( nbAlloc ) ;
				}
			}//endfor2

			nbpoint++ ;

			bool point1dominated = false ;

			for( unsigned int i = 0 ; i < vectorBoxFinal.size() ; ++i )
			{
				for( unsigned int j = 0 ; j < vectorBoxFinal[i]->points.size() ; j = j + 2 )
				{
					if( ( vectorBoxFinal[i]->points[j] < vectorBoxFinal[it]->points[last] && vectorBoxFinal[i]->points[j+1] <= vectorBoxFinal[it]->points[last+1] ) || ( vectorBoxFinal[i]->points[j] <= vectorBoxFinal[it]->points[last] && vectorBoxFinal[i]->points[j+1] < vectorBoxFinal[it]->points[last+1] ) ) 
					{
						point1dominated = true ;
						break ;
					}
				}
			}

			futurEdge.push_back( false ) ;

			futurExtremity.push_back( point1dominated ) ;

			futurZ1.push_back( vectorBoxFinal[it]->points[last] ) ;
			futurZ2.push_back( vectorBoxFinal[it]->points[last+1] ) ;

			for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
			{
				futurFacility.push_back( vectorBoxFinal[it]->isOpened(j) ) ;
			}

			int nbAlloc = 0 ;

			for( unsigned int i = 0 ; i < data.getnbCustomer() ; ++i )
			{
				for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
				{
					if( vectorBoxFinal[it]->clientAllocation[last/2][i][j] == 1 )
					{
						nbAlloc++ ;
						futurCustoAlloc.push_back(i) ;
						futurCorFac.push_back(j) ;
						futurPercentage.push_back(1.0) ;
						break ;
					}
					else if( vectorBoxFinal[it]->clientAllocation[last/2][i][j] > 0 )
					{
						nbAlloc++ ;
						futurCustoAlloc.push_back(i) ;
						futurCorFac.push_back(j) ;
						futurPercentage.push_back(vectorBoxFinal[it]->clientAllocation[last/2][i][j]) ;
					}
				}
			}

			totalAlloc += nbAlloc ;
			futurAlloc.push_back( nbAlloc ) ;



		}//endelse
		//cout << 100.0 * double(it+1)/double(vectorBoxFinal.size()) << "% " << flush ;
	}//endfor1
	// cout << endl ;

	//##############################
	//## Result from Test Mode ON ##


	// double **z1, double **z2, bool **facility, bool **isEdge, bool **isExtremityDominated, int **nbAlloc, int **customerAllocation, int **correspondingFac, double **percentageAlloc 

	*z1 = (double *) calloc(nbpoint, sizeof(double));
	*z2 = (double *) calloc(nbpoint, sizeof(double));

	*facility = (bool *) calloc(nbpoint*nbFacility, sizeof(bool));
	*isEdge = (bool *) calloc(nbpoint, sizeof(bool));
	*isExtremityDominated = (bool *) calloc(nbpoint, sizeof(bool));

	*nbAlloc = (int *) calloc(nbpoint, sizeof(int)) ;


	*customerAllocation = (int *) calloc(totalAlloc, sizeof(int)) ;
	*correspondingFac = (int *) calloc(totalAlloc, sizeof(int)) ;

	*percentageAlloc = (double *) calloc(totalAlloc, sizeof(double)) ;

	for( int i = 0 ; i < nbpoint ; ++i )
	{
		(*z1)[i] = futurZ1[i] ;
		(*z2)[i] = futurZ2[i] ;

		(*isEdge)[i] = futurEdge[i] ;
		(*isExtremityDominated)[i] = futurExtremity[i] ;

		(*nbAlloc)[i] = futurAlloc[i] ;
	}

	for( unsigned int i = 0 ; i < nbpoint * nbFacility ; ++i )
	{
		(*facility)[i] = futurFacility[i] ;
	}


	for( int i = 0 ; i < totalAlloc ; ++i )
	{
		(*customerAllocation)[i] = futurCustoAlloc[i] ;
		(*correspondingFac)[i] = futurCorFac[i] ;

		(*percentageAlloc)[i] = futurPercentage[i] ;
	}


    // cout << "Finished ! Program will Terminate." << endl ;

	return nbpoint ;
}
