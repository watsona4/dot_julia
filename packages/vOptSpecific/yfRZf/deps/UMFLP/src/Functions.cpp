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

#include "Functions.hpp"


long int createBox(vector<Box*> &vectorBox, vector<string> openedFacility, Data &data)
{
	long int nbBoxComputed = 0;
	int currentSize = vectorBox.size() ;
		
	//Add the first boxes with only one facility opened
	Box *box0 = new Box(data);
	addChildren(box0,vectorBox,data);
	delete box0;
	
	for(unsigned int it = currentSize; it < vectorBox.size();)
	{
		nbBoxComputed++;

		if( data.modeImprovedUB && isAlreadyIn(openedFacility,vectorBox[it]) ) 
		{
			// If box has already been computed in the Upper Bound Set, we add its children and we delete the doublon.
			if( vectorBox[it]->getNbFacilityOpen() < (data.BoundDeepNess - 1) )
			{
				addChildren(vectorBox[it],vectorBox,data);
			}
			delete vectorBox[it];
			vectorBox.erase(vectorBox.begin() += it);
		}
		else if( isDominatedByItsOrigin(vectorBox,vectorBox[it]) )
		{
			delete vectorBox[it];
			vectorBox.erase(vectorBox.begin() += it);
		}
		else
		{
			if( data.modeLowerBound )
			{
				computeLowerBound(vectorBox[it],data);
			}

			if( data.modeLowerBound && isDominatedByItsLowerBound(vectorBox,vectorBox[it],data) )
			{
				// If Lower Bound Set is dominated, we can delete current box and cut the node. Children does not need to be added as the LBS is valable for the Children.
				delete vectorBox[it];
				vectorBox.erase(vectorBox.begin() += it);
			}
			else
			{

				//Compute bounds of this box
				vectorBox[it]->computeBox(data);
				//Compute all potential children of this box as candidates boxes
				if( vectorBox[it]->getNbFacilityOpen() < (data.BoundDeepNess - 1) )
				{
					addChildren(vectorBox[it],vectorBox,data);
				}

				if( data.modeDichoBnB && vectorBox[it]->getHasEdge() )
				{
					weightedSumOneStep(vectorBox[it],data);
				}

				//If this box is dominated by all the boxes (existing + its children) regarding to its bounds
				if( isDominatedByItsBox(vectorBox,vectorBox[it]) )
				{
					delete vectorBox[it];
					vectorBox.erase(vectorBox.begin() += it);
				}
				else
				{
					//If one of all others boxes are dominated by this box, we delete it
					for(unsigned int it2 = 0; it2 != it;)
					{
						if(isDominatedBetweenTwoBoxes(vectorBox[it2],vectorBox[it]))
						{
							delete vectorBox[it2];
							vectorBox.erase(vectorBox.begin() += it2);
							//We delete an element before (the list shift one step forward), so we shift one step backward
							it--;
						}
						else
						{
							it2++;
						}	
					}
					it++;
				}
			}
		}
	}
    
	return nbBoxComputed;
}

void addChildren(Box *boxMother, vector<Box*> &vBox, Data &data)
{
    int deepness = 1 ;

    //To find the last digit at 1 in the open facility
    bool *facilityOpen = new bool[data.getnbFacility()];
    int indexLastOpened = -1;

    if( data.modeSortFacility )
    {
	    for(unsigned int i = 0 ; i < data.getnbFacility() ; i++)
	    {
	        if(boxMother->isOpened(data.facilitySort[i]))
	        {
	            indexLastOpened = i;
	            ++deepness ;
	        }
	        facilityOpen[data.facilitySort[i]] = boxMother->isOpened(data.facilitySort[i]);
	    }
	    
	    //For each digit 0 of facilities not yet affected, we change it in 1 to create the corresponding a new combination
	    for( unsigned int i = indexLastOpened + 1 ; i < data.getnbFacility() ; i++)
	    {
	        facilityOpen[data.facilitySort[i]] = true;
	        Box *tmp = new Box(data,facilityOpen,data.facilitySort,i);
	        vBox.push_back(tmp);		
	        facilityOpen[data.facilitySort[i]] = false;
	    }
    }
    else
    {
	    for(unsigned int i = 0 ; i < data.getnbFacility() ; i++)
	    {
	        if(boxMother->isOpened(i))
	        {
	            indexLastOpened = i;
	            ++deepness ;
	        }
	        facilityOpen[i] = boxMother->isOpened(i);
	    }
	    
	    //For each digit 0 of facilities not yet affected, we change it in 1 to create the corresponding a new combination
	    for(unsigned int i = indexLastOpened + 1 ; i < data.getnbFacility() ; i++)
	    {
	        facilityOpen[i] = true;
	        Box *tmp = new Box(data,facilityOpen);
	        vBox.push_back(tmp);		
	        facilityOpen[i] = false;
	    }
    }

    if( deepness > data.MaxDeepNess )
    	data.MaxDeepNess = deepness ;
    
    delete []facilityOpen;
}

void computeUpperBound(vector<Box*> &vectorBox, vector<bool> &dichoSearch, Data &data)
{
	if(vectorBox.size() < 2 )
	{
		// If not done yet, compute first lexicographical point w.r.t. objective1 then objective2
		Box* tmp = dualocprocedure(1.0,0.0,data);

		tmp->computeBox(data);

		vectorBox.push_back(tmp);
	}

	




	if(vectorBox.size() < 2 )
	{
		// If not done yet, compute last lexicographical point w.r.t. objective2 then objective1
	
		Box* tmp = dualocprocedure(0.0,1.0,data);

		tmp->computeBox(data);

		vectorBox.push_back(tmp);
	}

	if( vectorBox.size() == 2 )
	{
		dichoSearch.push_back(true);
	}

	if( vectorBox.size() >= 2 )
	{
		// For every pair of point, we compute a weighted sum.
		vector<Box*> tempBox = vector<Box*>() ;
		vector<bool> tempDicho = vector<bool>() ;


		for(unsigned int it = 0 ; it < vectorBox.size() - 1 ; ++it )
		{
			tempBox.push_back(vectorBox[it]);

			if( !data.modeFullDicho && (vectorBox[it]->getId() == vectorBox[it+1]->getId()) )
			{
				tempDicho.push_back(false);
			}
			else if( dichoSearch[it] )
			{

				double alpha =	1.0 * ( vectorBox[it+1]->upperBoundObj1 - vectorBox[it]->upperBoundObj1 ) ;
				double beta =  1.0 * ( vectorBox[it]->upperBoundObj2 - vectorBox[it+1]->upperBoundObj2 ) ;


				Box* tmp = dualocprocedure(beta,alpha,data);

				if( ( beta * tmp->upperBoundObj1 + alpha * tmp->upperBoundObj2) < ( beta * vectorBox[it]->upperBoundObj1 + alpha * vectorBox[it]->upperBoundObj2) - data.epsilon )
				{
					tmp->computeBox(data);

					tempBox.push_back(tmp);
					tempDicho.push_back(true);
					tempDicho.push_back(true);
				}
				else
				{
					tempDicho.push_back(false);
				}
			}
			else
			{
				tempDicho.push_back(false);
			}

		} // END FOR

		tempBox.push_back(vectorBox[vectorBox.size()-1]);

		vectorBox.clear() ;
		vectorBox = tempBox ;

		dichoSearch.clear() ;
		dichoSearch = tempDicho ;
	}

}

void computeLowerBound(Box *box, Data &data)
{
	// We assign all the customer to their best possiblyOpenFacility
	for(unsigned int i = 0 ; i < data.getnbCustomer();++i)
	{
		bool toStop1 = false;
		bool toStop2 = false;
		
		for(unsigned int j = 0 ; j < data.getnbFacility() && (!toStop1||!toStop2);++j)
		{
			for(unsigned int k = 0 ; k < box->possiblyOpenFacility.size() && !toStop1 ; ++k )
			{
				if( data.customerSort[i][0][j] == box->possiblyOpenFacility[k] && !toStop1 )
				{
					box->pointsLB[0] += data.getAllocationObj1Cost(i,box->possiblyOpenFacility[k]) ;
					box->pointsLB[1] += data.getAllocationObj2Cost(i,box->possiblyOpenFacility[k]) ;
					toStop1 = true ;
				}
			}
			for(unsigned int k = 0 ; k < box->possiblyOpenFacility.size() && !toStop2 ; ++k )
			{
				if( data.customerSort[i][1][j] == box->possiblyOpenFacility[k] && !toStop2 )
				{
					
					box->pointsLB[2] += data.getAllocationObj1Cost(i,box->possiblyOpenFacility[k]) ;
					box->pointsLB[3] += data.getAllocationObj2Cost(i,box->possiblyOpenFacility[k]) ;
					toStop2 = true ;
				}
			}
		}
	}

	// If ImprovedLB data.mode is on, we compute the supported points of the LBS.
	if( data.modeImprovedLB && box->pointsLB[0] != box->pointsLB[2] )
	{
		parametricSearchLB(box,data);
	}
}

void filter(vector<Box*> &vectorBox)
{
	//Filtering and update of booleans

	unsigned int size = vectorBox.size() ;

	for(unsigned int it = 0; it < size;)
	{	
		for(unsigned int it2 = it + 1 ; it2 < size;)
		{
			if( isDominatedBetweenTwoBoxes(vectorBox[it2] , vectorBox[it]) )
			{
				delete vectorBox[it2];
				vectorBox.erase(vectorBox.begin() += it2);
				size-- ;
			}
			else if( isDominatedBetweenTwoBoxes(vectorBox[it] , vectorBox[it2]) )
			{
				delete vectorBox[it];
				vectorBox.erase(vectorBox.begin()+=it);
				it2 = it + 1 ; //Initialize it2 at the begin of the vector
				size-- ;
			}
			else
			{
				//it2 wasn't deleted
				it2++;
			}
		}
		//it wasn't deleted
		it++;
	}
}

void boxFiltering(vector<Box*> &vectorBox, Data &data)
{
	bool MoreStep = true ;
	filter(vectorBox);
	
	// As long as there is some weighted sum to do, we do a weighted sum on all pair of point and update current box. Then we filter them with the new informations obtained.
	while(MoreStep)
	{
		weightedSumOneStepAll(vectorBox, data, MoreStep);
		filter(vectorBox);
	}
    
}

void weightedSumOneStep(Box* box, Data &data)
{
	if( box->getHasMoreStepWS() )
	{
		vector<double> temPoints = vector<double>();
		vector<bool> tempEdges = vector<bool>() ;
		vector<bool> tempDicho = vector<bool>() ;

		for(unsigned int it2 = 0 ; it2 < box->points.size()-2 ;  it2 = it2 + 2)
		{
			// For every pair of point of this box, we compute a weighted sum to improve current deepness by one.
			temPoints.push_back(box->points[it2]);
			temPoints.push_back(box->points[it2+1]);

			if( box->dicho[it2/2] && box->edges[it2/2] )
			{
				double alpha =	( box->points[it2+2] - box->points[it2] ) / 
								( box->points[it2+1] - box->points[it2+3] ) ;
	            
				double z_obj1 = box->getOriginZ1();
				double z_obj2 = box->getOriginZ2();
	            
				for(unsigned int i = 0; i < data.getnbCustomer(); ++i)
				{
					// For all customers, we find the best indice considering current pair of points and current weighted sum
					if(! (box->isAssigned(i)))
					{
						int ind = -1;
						double val = DBL_MAX;
						for(unsigned int j = 0; j < data.getnbFacility(); ++j)
						{
							if( box->isOpened(j) )
							{
								if(val > data.getAllocationObj1Cost(i,j) + alpha * data.getAllocationObj2Cost(i,j))
								{
									ind = j;
									val = data.getAllocationObj1Cost(i,j) + alpha * data.getAllocationObj2Cost(i,j);
								}
							}
						}
						z_obj1 += data.getAllocationObj1Cost(i,ind);
						z_obj2 += data.getAllocationObj2Cost(i,ind);
					}
				}
				
				if( (z_obj1 + alpha * z_obj2) <  (box->points[it2] + alpha * box->points[it2+1] - data.epsilon ) )
				{
					// If new obtained solution is better than current solution, we add the new point.
				  	
					temPoints.push_back(z_obj1);
					temPoints.push_back(z_obj2);

					tempEdges.push_back(true);
					tempEdges.push_back(true);

					tempDicho.push_back(true);
					tempDicho.push_back(true);
				}
				else
				{
					tempEdges.push_back(true);
					tempDicho.push_back(false);
				}
			}
			else
			{
				tempEdges.push_back(box->edges[it2/2]);
				tempDicho.push_back(false);
			}
		}

		temPoints.push_back(box->points[box->points.size()-2]);
		temPoints.push_back(box->points[box->points.size()-1]);	

		bool hasmoredicho = false ;

		if( temPoints.size() > box->points.size() )
		{
			// If a new point was created, this means this box still has weighted sum to compute before proving completion.
			hasmoredicho = true ;
		}

		box->setHasMoreStepWS(hasmoredicho);

		box->points.clear() ;
		box->points = temPoints ;

		box->edges.clear() ;
		box->edges = tempEdges ;

		box->dicho.clear() ;
		box->dicho = tempDicho ;
	}
	else
	{
		
	}
}

void weightedSumOneStepLB(Box* box, Data &data)
{
	// It is the same weighted sum method than weightedSumOneStep but applied to the Lower Bound Set.

	vector<double> temPoints = vector<double>();
	vector<bool> tempEdges = vector<bool>() ;
	vector<bool> tempDicho = vector<bool>() ;

	for(unsigned int it2 = 0 ; it2 < box->pointsLB.size()-2 ;  it2 = it2 + 2)
	{
		temPoints.push_back(box->pointsLB[it2]);
		temPoints.push_back(box->pointsLB[it2+1]);

		if( box->dichoLB[it2/2] )
		{
			double alpha =	( box->pointsLB[it2+2] - box->pointsLB[it2] ) / 
							( box->pointsLB[it2+1] - box->pointsLB[it2+3] ) ;
            
			double z_obj1 = box->getOriginZ1();
			double z_obj2 = box->getOriginZ2();
            
			for(unsigned int i = 0; i < data.getnbCustomer(); ++i)
			{
				int ind = -1;
				double val = DBL_MAX;
				for(unsigned int j = 0; j < box->possiblyOpenFacility.size() ; ++j)
				{
					if(val > data.getAllocationObj1Cost(i,box->possiblyOpenFacility[j]) + alpha * data.getAllocationObj2Cost(i,box->possiblyOpenFacility[j]))
					{
						ind = box->possiblyOpenFacility[j];
						val = data.getAllocationObj1Cost(i,ind) + alpha * data.getAllocationObj2Cost(i,ind);
					}
				}
				z_obj1 += data.getAllocationObj1Cost(i,ind);
				z_obj2 += data.getAllocationObj2Cost(i,ind);
			}
			
			if( (z_obj1 + alpha * z_obj2) <  (box->pointsLB[it2] + alpha * box->pointsLB[it2+1] - data.epsilon ) )
			{ 	
				temPoints.push_back(z_obj1);
				temPoints.push_back(z_obj2);

				tempEdges.push_back(true);
				tempEdges.push_back(true);

				tempDicho.push_back(true);
				tempDicho.push_back(true);
			}
			else
			{
				tempEdges.push_back(true);
				tempDicho.push_back(false);
			}
		}
		else
		{
			tempEdges.push_back(true);
			tempDicho.push_back(false);
		}
	}

	temPoints.push_back(box->pointsLB[box->pointsLB.size()-2]);
	temPoints.push_back(box->pointsLB[box->pointsLB.size()-1]);	

	box->setHasMoreStepLB( temPoints.size() > box->pointsLB.size() ) ;

	box->pointsLB.clear() ;
	box->pointsLB = temPoints ;

	box->edgesLB.clear() ;
	box->edgesLB = tempEdges ;

	box->dichoLB.clear() ;
	box->dichoLB = tempDicho ;
}

void weightedSumOneStepAll(vector<Box*> &vectorBox, Data &data, bool &MoreStep)
{
	// It is the same weighted sum method than weightedSumOneStep but applied to all box of current vectorBox

	MoreStep = false ;
	unsigned int size = vectorBox.size();
	
	for(unsigned int it = 0; it < size; it++)
	{
		if( vectorBox[it]->getHasMoreStepWS() )
		{
			vector<double> temPoints = vector<double>();
			vector<bool> tempEdges = vector<bool>() ;
			vector<bool> tempDicho = vector<bool>() ;

			for(unsigned int it2 = 0 ; it2 < vectorBox[it]->points.size()-2 ;  it2 = it2 + 2)
			{
				temPoints.push_back(vectorBox[it]->points[it2]);
				temPoints.push_back(vectorBox[it]->points[it2+1]);

				if( vectorBox[it]->dicho[it2/2] && vectorBox[it]->edges[it2/2] )
				{
					double alpha =	( vectorBox[it]->points[it2+2] - vectorBox[it]->points[it2] ) / 
									( vectorBox[it]->points[it2+1] - vectorBox[it]->points[it2+3] ) ;
		            
					double z_obj1 = vectorBox[it]->getOriginZ1();
					double z_obj2 = vectorBox[it]->getOriginZ2();
		            
					for(unsigned int i = 0; i < data.getnbCustomer(); ++i)
					{
						if(! (vectorBox[it]->isAssigned(i)))
						{
							int ind = -1;
							double val = DBL_MAX;
							for(unsigned int j = 0; j < data.getnbFacility(); ++j)
							{
								if( vectorBox[it]->isOpened(j) )
								{
									if(val > data.getAllocationObj1Cost(i,j) + alpha * data.getAllocationObj2Cost(i,j))
									{
										ind = j;
										val = data.getAllocationObj1Cost(i,j) + alpha * data.getAllocationObj2Cost(i,j);
									}
								}
							}
							z_obj1 += data.getAllocationObj1Cost(i,ind);
							z_obj2 += data.getAllocationObj2Cost(i,ind);
						}
					}
					
					if( (z_obj1 + alpha * z_obj2) <  (vectorBox[it]->points[it2] + alpha * vectorBox[it]->points[it2+1] - data.epsilon ) )
					{ 	
						temPoints.push_back(z_obj1);
						temPoints.push_back(z_obj2);

						tempEdges.push_back(true);
						tempEdges.push_back(true);

						tempDicho.push_back(true);
						tempDicho.push_back(true);
					}
					else
					{
						tempEdges.push_back(true);
						tempDicho.push_back(false);
					}
				}
				else
				{
					tempEdges.push_back(vectorBox[it]->edges[it2/2]);
					tempDicho.push_back(false);
				}
			}

			temPoints.push_back(vectorBox[it]->points[vectorBox[it]->points.size()-2]);
			temPoints.push_back(vectorBox[it]->points[vectorBox[it]->points.size()-1]);	

			bool hasmoredicho = false ;

			if( temPoints.size() > vectorBox[it]->points.size() )
			{
				hasmoredicho = true ;
				MoreStep = true ;
			}

			vectorBox[it]->setHasMoreStepWS(hasmoredicho);

			vectorBox[it]->points.clear() ;
			vectorBox[it]->points = temPoints ;

			vectorBox[it]->edges.clear() ;
			vectorBox[it]->edges = tempEdges ;

			vectorBox[it]->dicho.clear() ;
			vectorBox[it]->dicho = tempDicho ;
		}
		else
		{
			
		}
	}
}

void parametricSearch(Box* box, Data &data)
{
	vector<int> assignation = vector<int>(data.getnbCustomer(),-1);
	vector<int> nextAssignation = vector<int>(data.getnbCustomer(),-1);

	double maxNextLambda = 1 ;
	double end1 ;
	double end2 ;

	vector<double> assignedLambda = vector<double>(data.getnbCustomer(),0);

	box->points[0] = box->getOriginZ1() ;
	box->points[1] = box->getOriginZ2() ;

	if( !data.modeDichoBnB || box->points.size() == 4 )
	{
		end1 = box->points[2];
		end2 = box->points[3];
		box->points.erase(box->points.begin() + 2 );
		box->points.erase(box->points.begin() + 2 );
		box->edges.erase( box->edges.begin() );
	}
	else
	{
		end1 = box->points[4];
		end2 = box->points[5];

		box->points.erase(box->points.begin() + 2 );
		box->points.erase(box->points.begin() + 2 );
		box->points.erase(box->points.begin() + 2 );
		box->points.erase(box->points.begin() + 2 );
		box->edges.erase( box->edges.begin() );
		box->edges.erase( box->edges.begin() );
	}

	for(unsigned int i = 0 ; i < data.getnbCustomer(); ++i)
	{
		if( !box->isAssigned(i) )
		{
			bool stop = false ;
			for(unsigned int j = 0 ; j < data.getnbFacility() && !stop ; ++j)
			{
				if( box->isOpened( data.customerSort[i][0][j] ) )
				{
					box->points[0] += data.getAllocationObj1Cost(i,data.customerSort[i][0][j]) ;
					box->points[1] += data.getAllocationObj2Cost(i,data.customerSort[i][0][j]) ;
					assignation[i] = data.customerSort[i][0][j] ;
					stop = true ; 
				}
			}
		}
	}

	int currentPoint = 0 ;

	while( box->points[currentPoint] != end1 && box->points[currentPoint+1] != end2 && maxNextLambda > 0 )
	{
		maxNextLambda = 0 ;

		for(unsigned int i = 0 ; i < data.getnbCustomer();++i)
		{
			if( !box->isAssigned(i) && nextAssignation[i] == -1 )
			{		
				nextAssignation[i] = assignation[i] ;

				for(unsigned int j = 0 ; j < data.getnbFacility();++j)
				{
					if(  box->isOpened(j) && (data.getAllocationObj1Cost(i,j) - data.getAllocationObj2Cost(i,j) ) > ( data.getAllocationObj1Cost(i,assignation[i]) - data.getAllocationObj2Cost(i,assignation[i]) ) )
					{
						double temp = ( data.getAllocationObj2Cost(i,j) - data.getAllocationObj2Cost(i,assignation[i]) ) / ( ( data.getAllocationObj2Cost(i,j) - data.getAllocationObj2Cost(i,assignation[i]) ) - ( data.getAllocationObj1Cost(i,j) - data.getAllocationObj1Cost(i,assignation[i]) ) ) ;

						if( assignedLambda[i] < temp && temp < 1 )
						{
							nextAssignation[i] = j ;
							assignedLambda[i] = temp ;
						}
					}
				}

				if( assignedLambda[i] > maxNextLambda )
					maxNextLambda = assignedLambda[i] ;

			}
			else if( !box->isAssigned(i) && assignedLambda[i] > maxNextLambda )
			{
				maxNextLambda = assignedLambda[i] ;
			}
		}

		if( maxNextLambda > 0 )
		{
			double temp1 = box->points[currentPoint] ;
			double temp2 = box->points[currentPoint+1] ;

			for(unsigned int i = 0 ; i < data.getnbCustomer() ; ++i )
			{
				if( !box->isAssigned(i) && maxNextLambda == assignedLambda[i] )
				{
					temp1 += data.getAllocationObj1Cost(i,nextAssignation[i]) - data.getAllocationObj1Cost(i,assignation[i]) ;
					temp2 += data.getAllocationObj2Cost(i,nextAssignation[i]) - data.getAllocationObj2Cost(i,assignation[i]) ;

					assignation[i] = nextAssignation[i] ;
					assignedLambda[i] = 0 ;
					nextAssignation[i] = -1 ;
				}
			}

			box->points.push_back(temp1);
			box->points.push_back(temp2);
			box->edges.push_back(true);

			currentPoint = currentPoint + 2 ;
		}
	}

	if( box->points[currentPoint] != end1 && box->points[currentPoint+1] != end2)
	{
		box->points.push_back(end1);
		box->points.push_back(end2);
		box->edges.push_back(true);
	}

	box->setHasMoreStepWS(false) ;
}

void parametricSearchUB(Box* box, Data &data)
{
	vector<int> assignation = vector<int>(data.getnbCustomer(),-1);
	vector<int> nextAssignation = vector<int>(data.getnbCustomer(),-1);

	double maxNextLambda = 1 ;
	double end1 ;
	double end2 ;

	vector<double> assignedLambda = vector<double>(data.getnbCustomer(),0);

	box->points[0] = box->getOriginZ1() ;
	box->points[1] = box->getOriginZ2() ;

	end1 = box->points[2];
	end2 = box->points[3];
	box->points.erase(box->points.begin() + 2 );
	box->points.erase(box->points.begin() + 2 );
	box->edges.erase( box->edges.begin() );

	for(unsigned int i = 0 ; i < data.getnbCustomer(); ++i)
	{
		if( !box->isAssigned(i) )
		{
			for(unsigned int j = 0 ; j < data.getnbFacility() ; ++j)
			{
				if( box->isOpened( data.customerSort[i][0][j] ) )
				{
					box->points[0] += data.getAllocationObj1Cost(i,data.customerSort[i][0][j]) ;
					box->points[1] += data.getAllocationObj2Cost(i,data.customerSort[i][0][j]) ;
					assignation[i] = data.customerSort[i][0][j] ;
					break ;
				}
			}	
		}
	}

	int currentPoint = 0 ;

	while( box->points[currentPoint] != end1 && box->points[currentPoint+1] != end2 && maxNextLambda > 0 )
	{
		maxNextLambda = 0 ;

		for(unsigned int i = 0 ; i < data.getnbCustomer();++i)
		{
			if( !box->isAssigned(i) && nextAssignation[i] == -1 )
			{		
				nextAssignation[i] = assignation[i] ;

				for(unsigned int j = 0 ; j < data.getnbFacility();++j)
				{
					if(  box->isOpened(j) && (data.getAllocationObj1Cost(i,j) - data.getAllocationObj2Cost(i,j) ) > ( data.getAllocationObj1Cost(i,assignation[i]) - data.getAllocationObj2Cost(i,assignation[i]) ) )
					{
						double temp = ( data.getAllocationObj2Cost(i,j) - data.getAllocationObj2Cost(i,assignation[i]) ) / ( ( data.getAllocationObj2Cost(i,j) - data.getAllocationObj2Cost(i,assignation[i]) ) - ( data.getAllocationObj1Cost(i,j) - data.getAllocationObj1Cost(i,assignation[i]) ) ) ;

						if( assignedLambda[i] < temp && temp < 1 )
						{
							nextAssignation[i] = j ;
							assignedLambda[i] = temp ;
						}
					}
				}

				if( assignedLambda[i] > maxNextLambda )
					maxNextLambda = assignedLambda[i] ;

			}
			else if( !box->isAssigned(i) && assignedLambda[i] > maxNextLambda )
			{
				maxNextLambda = assignedLambda[i] ;
			}
		}

		if( maxNextLambda > 0 )
		{
			double temp1 = box->points[currentPoint] ;
			double temp2 = box->points[currentPoint+1] ;

			for(unsigned int i = 0 ; i < data.getnbCustomer() ; ++i )
			{
				if( !box->isAssigned(i) && maxNextLambda == assignedLambda[i] )
				{
					temp1 += data.getAllocationObj1Cost(i,nextAssignation[i]) - data.getAllocationObj1Cost(i,assignation[i]) ;
					temp2 += data.getAllocationObj2Cost(i,nextAssignation[i]) - data.getAllocationObj2Cost(i,assignation[i]) ;

					assignation[i] = nextAssignation[i] ;
					assignedLambda[i] = 0 ;
					nextAssignation[i] = -1 ;
				}
			}

			box->points.push_back(temp1);
			box->points.push_back(temp2);
			box->edges.push_back(true);

			currentPoint = currentPoint + 2 ;
		}
	}

	if( box->points[currentPoint] != end1 && box->points[currentPoint+1] != end2)
	{
		box->points.push_back(end1);
		box->points.push_back(end2);
		box->edges.push_back(true);
	}

	box->setHasMoreStepWS(false) ;
}

void parametricSearchLB(Box* box, Data &data)
{
	vector<int> assignation = vector<int>(data.getnbCustomer(),-1);
	vector<int> nextAssignation = vector<int>(data.getnbCustomer(),-1);


	double maxNextLambda = 1 ;
	double end1 ;
	double end2 ;

	vector<double> assignedLambda = vector<double>(data.getnbCustomer(),0);

	box->pointsLB[0] = box->getOriginZ1() ;
	box->pointsLB[1] = box->getOriginZ2() ;

	end1 = box->pointsLB[2];
	end2 = box->pointsLB[3];
	box->pointsLB.erase(box->pointsLB.begin() + 2 );
	box->pointsLB.erase(box->pointsLB.begin() + 2 );
	box->edgesLB.erase( box->edgesLB.begin() );

	for(unsigned int i = 0 ; i < data.getnbCustomer();++i)
	{
		bool toStop1 = false;
		
		for(unsigned int j = 0 ; j < data.getnbFacility() && !toStop1;++j)
		{
			for(unsigned int k = 0 ; k < box->possiblyOpenFacility.size() && !toStop1 ; ++k )
			{
				if( data.customerSort[i][0][j] == box->possiblyOpenFacility[k] && !toStop1 )
				{
					box->pointsLB[0] += data.getAllocationObj1Cost(i,box->possiblyOpenFacility[k]) ;
					box->pointsLB[1] += data.getAllocationObj2Cost(i,box->possiblyOpenFacility[k]) ;
					assignation[i] = box->possiblyOpenFacility[k] ;
					toStop1 = true ;
				}
			}
		}
	}

	int currentPoint = 0 ;

	while( box->pointsLB[currentPoint] != end1 && box->pointsLB[currentPoint+1] != end2 && maxNextLambda > 0 )
	{
		maxNextLambda = 0 ;

		for(unsigned int i = 0 ; i < data.getnbCustomer();++i)
		{
			if( !box->isAssigned(i) && nextAssignation[i] == -1 )
			{		
				nextAssignation[i] = assignation[i] ;

				for(unsigned int j = 0 ; j < data.getnbFacility();++j)
				{
					if(  box->isOpened(j) && (data.getAllocationObj1Cost(i,j) - data.getAllocationObj2Cost(i,j) ) > ( data.getAllocationObj1Cost(i,assignation[i]) - data.getAllocationObj2Cost(i,assignation[i]) ) )
					{

						double temp = ( data.getAllocationObj2Cost(i,j) - data.getAllocationObj2Cost(i,assignation[i]) ) / ( ( data.getAllocationObj2Cost(i,j) - data.getAllocationObj2Cost(i,assignation[i]) ) - ( data.getAllocationObj1Cost(i,j) - data.getAllocationObj1Cost(i,assignation[i]) ) ) ;

						if( assignedLambda[i] < temp && temp < 1 )
						{
							nextAssignation[i] = j ;
							assignedLambda[i] = temp ;
						}
					}
				}

				if( assignedLambda[i] > maxNextLambda )
					maxNextLambda = assignedLambda[i] ;

			}
			else if( !box->isAssigned(i) && assignedLambda[i] > maxNextLambda )
			{
				maxNextLambda = assignedLambda[i] ;
			}
		}

		if( maxNextLambda > 0 )
		{
			double temp1 = box->pointsLB[currentPoint] ;
			double temp2 = box->pointsLB[currentPoint+1] ;

			for(unsigned int i = 0 ; i < data.getnbCustomer() ; ++i )
			{
				if( !box->isAssigned(i) && maxNextLambda == assignedLambda[i] )
				{
					temp1 += data.getAllocationObj1Cost(i,nextAssignation[i]) - data.getAllocationObj1Cost(i,assignation[i]) ;
					temp2 += data.getAllocationObj2Cost(i,nextAssignation[i]) - data.getAllocationObj2Cost(i,assignation[i]) ;

					assignation[i] = nextAssignation[i] ;
					assignedLambda[i] = 0 ;
					nextAssignation[i] = -1 ;
				}
			}

			box->pointsLB.push_back(temp1);
			box->pointsLB.push_back(temp2);
			box->edgesLB.push_back(true);

			currentPoint = currentPoint + 2 ;
		}
	}

	if( box->pointsLB[currentPoint] != end1 && box->pointsLB[currentPoint+1] != end2)
	{
		box->pointsLB.push_back(end1);
		box->pointsLB.push_back(end2);
		box->edgesLB.push_back(true);
	}

	box->setHasMoreStepLB(false) ;
}

void postProcessing(Box* box, Data &data)
{
	if( !box->getHasEdge() )
	{
		box->clientAllocation.push_back(vector< vector<double> >(data.getnbCustomer(),vector<double>(data.getnbFacility(),0))) ;
		for(unsigned int i = 0 ; i < data.getnbCustomer(); ++i)
		{
			if( !box->isAssigned(i) )
			{
				bool stop = false ;
				for(unsigned int j = 0 ; j < data.getnbFacility() && !stop ; ++j)
				{
					if( box->isOpened( data.customerSort[i][0][j] ) )
					{
						box->clientAllocation[0][i][ data.customerSort[i][0][j] ] = 1 ;
						stop = true ; 
					}
				}
			}
			else
			{
				bool stop = false ;
				for(unsigned int j = 0 ; j < data.getnbFacility() && !stop ; ++j)
				{
					if( box->isOpened( data.customerSort[i][0][j] ) )
					{
						box->clientAllocation[0][i][ data.customerSort[i][0][j] ] = 1 ;
						stop = true ; 
					}
				}
			}
		}

		return ;
	}

	vector<int> assignation = vector<int>(data.getnbCustomer(),-1);
	vector<int> nextAssignation = vector<int>(data.getnbCustomer(),-1);

	vector< double > tempPoints = vector<double>() ;
	vector< vector< vector<double> > > tempClient = vector< vector< vector<double> > >() ;
	//vector< vector<double> >(data_.getnbCustomer(),vector<double>(data_.getnbFacility(),0))


	double maxNextLambda = 1 ;

	double end1 = box->getOriginZ1();
	double end2 = box->getOriginZ2();
	vector< vector<double> > endAlloc = vector< vector<double> >(data.getnbCustomer(),vector<double>(data.getnbFacility(),0));

	vector<double> assignedLambda = vector<double>(data.getnbCustomer(),0);

	tempPoints.push_back(box->getOriginZ1()) ;
	tempPoints.push_back(box->getOriginZ2()) ;
	tempClient.push_back(vector< vector<double> >(data.getnbCustomer(),vector<double>(data.getnbFacility(),0))) ;
	int counter = 0 ;



	for(unsigned int i = 0 ; i < data.getnbCustomer(); ++i)
	{
		if( !box->isAssigned(i) )
		{
			bool stop = false ;
			for(unsigned int j = 0 ; j < data.getnbFacility() && !stop ; ++j)
			{
				if( box->isOpened( data.customerSort[i][0][j] ) )
				{
					tempPoints[0] += data.getAllocationObj1Cost(i,data.customerSort[i][0][j]) ;
					tempPoints[1] += data.getAllocationObj2Cost(i,data.customerSort[i][0][j]) ;
					assignation[i] = data.customerSort[i][0][j] ;
					tempClient[counter][i][ data.customerSort[i][0][j] ] = 1 ;
					stop = true ; 
				}
			}
		}
		else
		{
			bool stop = false ;
			for(unsigned int j = 0 ; j < data.getnbFacility() && !stop ; ++j)
			{
				if( box->isOpened( data.customerSort[i][0][j] ) )
				{
					tempClient[counter][i][ data.customerSort[i][0][j] ] = 1 ;
					stop = true ; 
				}
			}
		}
	}

	for(unsigned int i = 0 ; i < data.getnbCustomer(); ++i)
	{
		if( !box->isAssigned(i) )
		{
			bool stop = false ;
			for(unsigned int j = 0 ; j < data.getnbFacility() && !stop ; ++j)
			{
				if( box->isOpened( data.customerSort[i][1][j] ) )
				{
					end1 += data.getAllocationObj1Cost(i,data.customerSort[i][1][j]) ;
					end2 += data.getAllocationObj2Cost(i,data.customerSort[i][1][j]) ;
					endAlloc[i][ data.customerSort[i][1][j] ] = 1 ;
					stop = true ; 
				}
			}
		}
		else
		{
			bool stop = false ;
			for(unsigned int j = 0 ; j < data.getnbFacility() && !stop ; ++j)
			{
				if( box->isOpened( data.customerSort[i][1][j] ) )
				{
					endAlloc[i][ data.customerSort[i][1][j] ] = 1 ;
					stop = true ; 
				}
			}
		}
	}


	counter++ ;
	int currentPoint = 0 ;

	while( tempPoints[currentPoint] != end1 && tempPoints[currentPoint+1] != end2 && maxNextLambda > 0 )
	{
		maxNextLambda = 0 ;

		for(unsigned int i = 0 ; i < data.getnbCustomer();++i)
		{
			if( !box->isAssigned(i) && nextAssignation[i] == -1 )
			{		
				nextAssignation[i] = assignation[i] ;

				for(unsigned int j = 0 ; j < data.getnbFacility();++j)
				{
					if(  box->isOpened(j) && (data.getAllocationObj1Cost(i,j) - data.getAllocationObj2Cost(i,j) ) > ( data.getAllocationObj1Cost(i,assignation[i]) - data.getAllocationObj2Cost(i,assignation[i]) ) )
					{
						double temp = ( data.getAllocationObj2Cost(i,j) - data.getAllocationObj2Cost(i,assignation[i]) ) / ( ( data.getAllocationObj2Cost(i,j) - data.getAllocationObj2Cost(i,assignation[i]) ) - ( data.getAllocationObj1Cost(i,j) - data.getAllocationObj1Cost(i,assignation[i]) ) ) ;

						if( assignedLambda[i] < temp && temp < 1 )
						{
							nextAssignation[i] = j ;
							assignedLambda[i] = temp ;
						}
					}
				}

				if( assignedLambda[i] > maxNextLambda )
					maxNextLambda = assignedLambda[i] ;

			}
			else if( !box->isAssigned(i) && assignedLambda[i] > maxNextLambda )
			{
				maxNextLambda = assignedLambda[i] ;
			}
		}


		if( maxNextLambda > 0 )
		{
			double temp1 = tempPoints[currentPoint] ;
			double temp2 = tempPoints[currentPoint+1] ;
			tempClient.push_back(vector< vector<double> >(data.getnbCustomer(),vector<double>(data.getnbFacility(),0))) ;

			for(unsigned int i = 0 ; i < data.getnbCustomer() ; ++i )
			{
				if( !box->isAssigned(i) && maxNextLambda == assignedLambda[i] )
				{
					temp1 += data.getAllocationObj1Cost(i,nextAssignation[i]) - data.getAllocationObj1Cost(i,assignation[i]) ;
					temp2 += data.getAllocationObj2Cost(i,nextAssignation[i]) - data.getAllocationObj2Cost(i,assignation[i]) ;

					assignation[i] = nextAssignation[i] ;
					tempClient[counter][i][ nextAssignation[i] ] = 1 ;
					assignedLambda[i] = 0 ;
					nextAssignation[i] = -1 ;
				}
				else
				{
					for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
					{
						tempClient[counter][i][j] = tempClient[counter-1][i][j] ;
					}
				}
			}

			tempPoints.push_back(temp1);
			tempPoints.push_back(temp2);
			counter++ ;
			currentPoint = currentPoint + 2 ;
		}
	}

	if( tempPoints[currentPoint] != end1 && tempPoints[currentPoint+1] != end2)
	{
		tempPoints.push_back(end1);
		tempPoints.push_back(end2);
		tempClient.push_back(endAlloc);
	}

	for( unsigned int it = 0 ; it < box->points.size() ; it = it+2)
	{
		for( unsigned int it2 = 0 ; it2 < tempPoints.size() ; it2 = it2+2)
		{
			
			if( box->points[it] == tempPoints[it2] && box->points[it+1] == tempPoints[it2+1] )
			{
				box->clientAllocation.push_back(tempClient[it2/2]) ;
				break ;
			}
			else if( box->points[it] < tempPoints[it2+2] && box->points[it+1] > tempPoints[it2+3] )
			{

				double percent = ( box->points[it]-tempPoints[it2] ) / ( tempPoints[it2+2]-tempPoints[it2] ) ;
				vector< vector<double> > matrix = vector< vector<double> >(data.getnbCustomer(),vector<double>(data.getnbFacility(),0));

				
				for( unsigned int i = 0 ; i < data.getnbCustomer() ; ++i )
				{
					if( box->isAssigned(i) )
					{
						for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
						{
							matrix[i][j] = tempClient[it2/2][i][j] ;
						}
					}
					else
					{
						for( unsigned int j = 0 ; j < data.getnbFacility() ; ++j )
						{
							if( tempClient[it2/2][i][j] && tempClient[it2/2+1][i][j])
							{
								matrix[i][j] = 1 ;
							}
							else if( tempClient[it2/2][i][j])
							{
								matrix[i][j] = (1.0-percent) ;
							}
							else if( tempClient[it2/2 + 1][i][j] )
							{
								matrix[i][j] = percent ;
							}
							else
							{
								matrix[i][j] = 0;
							}
						}
					}//endelse
				}//endfor i
				box->clientAllocation.push_back(matrix) ;
				break ;
			}//endelseif
			
		}//endfor it2
	}//endfor it
}

bool isPointDominated(Box *box1, Box *box2)
{
	return ( box1->getMinZ1() >= box2->getMinZ1() && box1->getMinZ2() >= box2->getMinZ2() );
}

int dominancePointEdge(Box *box1, Box *box2, Data &data)
{
	if( ( box1->getMinZ1() >= box2->getMaxZ1() && box1->getMaxZ2() <= box2->getMinZ2() ) 
	 || ( box1->getMaxZ1() <= box2->getMinZ1() && box1->getMinZ2() >= box2->getMaxZ2() ) )
	{
		/*  Dominance Impossible as stated by T.Vincent 
		    Nothing to do */
		
		return 1 ;
	}

	double a = (box2->getMaxZ2()-box2->getMinZ2())/(box2->getMinZ1()-box2->getMaxZ1()) ;
	double b = box2->getMaxZ2() - a * box2->getMinZ1() ;
  
	double Yproj = a * box1->getMinZ1() + b ;
	double Xproj = (box1->getMinZ2()-b)/a ;
	
	bool below = Yproj > box1->getMinZ2() ; 

	if( !below && ( ( Yproj <= box2->getMaxZ2() && Yproj >= box2->getMinZ2() ) || ( Xproj <= box2->getMaxZ1() && Xproj >= box2->getMinZ1() )|| ( Yproj <= box2->getMinZ2() && Xproj <= box2->getMinZ1() ) ) ) 
	{
		return -1 ;
	}
	else if ( below && Yproj >= box2->getMaxZ2() && Xproj >= box2->getMaxZ1() )
	{
		return 0 ;
	}

	/* Starting on the edges */
	for( unsigned int it = 0 ; it < box2->points.size()-2 ;)
	{
		if( box2->edges[it/2] )
		{
			double a = (box2->points[it+1]-box2->points[it+3])/(box2->points[it]-box2->points[it+2]) ;
			double b = box2->points[it+1] - a * box2->points[it] ;
		  
			double Yproj = a * box1->getMinZ1() + b ;
			double Xproj = (box1->getMinZ2()-b)/a ;
			
			bool below = Yproj > box1->getMinZ2() ; 
			  
			if( !below )
			{
				if( ( Yproj <= box2->points[it+1] && Yproj >= box2->points[it+3] ) || ( Xproj <= box2->points[it+2] && Xproj >= box2->points[it] ) || ( Yproj <= box2->points[it+3] && Xproj <= box2->points[it] ) )
				{
					return -1 ;
				}
				else
				{
					it =it + 2 ;
				}
			}
			else 
			{
				if( ( Yproj >= box2->points[it+1] && Xproj >= box2->points[it+2] ) )
				{
					box2->edges[it/2] = false ;
					it = it + 2 ;
				}
				else if( Yproj < box2->points[it+1] && Yproj > box2->points[it+3] && Xproj < box2->points[it+2] && Xproj > box2->points[it] )
				{				
					box2->points.insert( box2->points.begin() += (it+2) , box1->getMinZ2() ) ;
					box2->points.insert( box2->points.begin() += (it+2) , Xproj ) ;
					box2->edges.insert( box2->edges.begin() += (it/2 + 1 ), true ) ;

					box2->points.insert( box2->points.begin() += (it+2) , Yproj ) ;
					box2->points.insert( box2->points.begin() += (it+2) , box1->getMinZ1() ) ;
					box2->edges.insert( box2->edges.begin() += (it/2 + 1 ), false ) ;

					it = it + 6 ;
				}
				else if( Yproj < box2->points[it+1] && Yproj > box2->points[it+3] )
				{
					box2->points.insert( box2->points.begin() += (it+2) , Yproj ) ;
					box2->points.insert( box2->points.begin() += (it+2) , box1->getMinZ1() ) ;
					box2->edges.insert( box2->edges.begin() += (it/2 + 1 ), false ) ;
					it = it + 4 ;
				}
				else if( Xproj < box2->points[it+2] && Xproj > box2->points[it] )
				{
					box2->points.insert( box2->points.begin() += (it+2) , box1->getMinZ2() ) ;
					box2->points.insert( box2->points.begin() += (it+2) , Xproj ) ;
					box2->edges.insert( box2->edges.begin() += (it/2 + 1 ), true ) ;
					box2->edges[it/2] = false ;
					it = it + 4 ;
				}
				else
				{
					it = it + 2 ;
				}
			}
		} // endif
		else
		{
			it = it + 2 ;
		}
	} // endfor

	int toReturn = 1 ;
	
	prefiltering(box2,data);

	if( box2->points.size() <= 2 || box2->edges.size() == 0 || !box2->getHasEdge() )
	{
		toReturn = 0 ;
	}


	return toReturn ;
}

int dominanceEdgeEdge(Box *box1, Box *box2, Data &data)
{
	if( ( box1->getMinZ1() >= box2->getMaxZ1() && box1->getMaxZ2() <= box2->getMinZ2() ) 
	 || ( box1->getMaxZ1() <= box2->getMinZ1() && box1->getMinZ2() >= box2->getMaxZ2() ) )
	{
		/*  Dominance Impossible as stated by T.Vincent 
		    Nothing to do */
		
		return 0 ;
	}

	for( unsigned int it = 0 ; it < box1->points.size()-2 ; it=it+2 )
	{ 
		if( box1->edges[it/2])
		{
			double a1 = (box1->points[it+1] - box1->points[it+3])/(box1->points[it] - box1->points[it+2]) ;
			double b1 = box1->points[it+1] - a1 * box1->points[it] ;

			for( unsigned int it2 = 0 ; it2 < box2->points.size()-2 ; )
			{

				if( box2->edges[it2/2] )
				{
				  	double a2 = (box2->points[it2+1]-box2->points[it2+3])/(box2->points[it2]-box2->points[it2+2]) ;
					double b2 = box2->points[it2+1] - a2 * box2->points[it2] ;

					if( ( box1->points[it+2] <= box2->points[it2] && box1->points[it+3] >= box2->points[it2+1] ) )
					{
						/*  Dominance Impossible as stated by T.Vincent. As the edges are lexicographically sorted, further comparison are pointless we can stop */
						break ;
					}
					else if( ( box1->points[it] >= box2->points[it2+2] && box1->points[it+1] <= box2->points[it2+3] ) )
					{
						/*  Dominance Impossible as stated by T.Vincent. As the edges are lexicographically sorted, further comparison are needed to assert it is or not dominated. */
						it2 = it2 + 2 ;
					}
					else if( fabs(b2-b1) < data.epsilon && fabs(a1-a2) < data.epsilon )
			       	{
			       		// The two edges are on the same line if last point of edge from box1 finish before last point of edge from box2, further comparison are pointless as the edges are lexicographically sorted.
			       		if(  box1->points[it+2] <= box2->points[it2+2] )
			       			break ;
			       		else
			       			it2=it2+2 ;
			       	}
			       	else if( fabs(a1-a2) < data.epsilon )
			       	{
			       		// The two edges are parallele. Two comparison are needed and similar, if edge from box1 is below or if edge from box2 is below.
			       		if( b2 < b1 )
						{
							double Yproj1 = a1 * box2->points[it2] + b1 ;
							double Xproj1 = box2->points[it2] ;
							 
							double Xproj2 = (box2->points[it2+3]-b1)/a1 ;
							double Yproj2 = box2->points[it2+3] ;
						
							bool proj1exist = ( Yproj1 < box1->points[it+1] && Yproj1 > box1->points[it+3] ); 
							bool proj2exist = ( Xproj2 < box1->points[it+2] && Xproj2 > box1->points[it] );
							
							if( proj1exist && proj2exist )
							{	
								// Edge from box 2 is below and there is two projection on edge from box1 then the part between the projection is dominated.
								box1->points.insert( box1->points.begin() += (it+2) , Yproj2 ) ;
								box1->points.insert( box1->points.begin() += (it+2) , Xproj2 ) ;
								box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true) ;

								box1->points.insert( box1->points.begin() += (it+2) , Yproj1 ) ;
								box1->points.insert( box1->points.begin() += (it+2) , Xproj1 ) ;
								box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

								it = it + 4 ;
								it2 = it2 + 2 ;
							}
							else if( proj1exist )
							{
								// Edge from box 2 is below and there is one projection on edge from box1, then the part below the projection is dominated. As the edges are sorted lexicographically, further comparison with edge from box1 are pointless.
								box1->points.insert( box1->points.begin() += (it+2) , Yproj1 ) ;
								box1->points.insert( box1->points.begin() += (it+2) , Xproj1 ) ;
								box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

								break ;
							}
							else if( proj2exist )
							{
								// Edge from box2 is below and there is one projection on edge from box1, then the part above the projection is dominated. As the edges are sorted lexicographically, further comparison with edge from box1 are needed.
								box1->points.insert( box1->points.begin() += (it+2) , Yproj2 ) ;
								box1->points.insert( box1->points.begin() += (it+2) , Xproj2 ) ;
								box1->edges[it/2] = false ;
								box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true) ;

								it = it + 2 ;
								it2 = it2 + 2 ;
							}
							else
							{
								// Edge from box2 is below and there is no projection on edge from box1, then the edge from box1 is totally dominated and further comparison are pointless
								box1->edges[it/2] = false ;
								break ;
							}
						}// End edge from box2 below edge from Box1
						else
						{
							// Similar comparisons but considering that edge from box1 is below edge from box2
							double Yproj1 = a2 * box1->points[it] + b2 ;
							double Xproj1 = box1->points[it] ;
							 
							double Xproj2 = (box1->points[it+3]-b2)/a2 ;
							double Yproj2 = box1->points[it+3] ;
						
							bool proj1exist = ( Yproj1 < box2->points[it2+1] && Yproj1 > box2->points[it2+3] ); 
							bool proj2exist = ( Xproj2 < box2->points[it2+2] && Xproj2 > box2->points[it2] );
							
							if( proj1exist && proj2exist )
							{	
								box2->points.insert( box2->points.begin() += (it2+2) , Yproj2 ) ;
								box2->points.insert( box2->points.begin() += (it2+2) , Xproj2 ) ;
								box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true) ;

								box2->points.insert( box2->points.begin() += (it2+2) , Yproj1 ) ;
								box2->points.insert( box2->points.begin() += (it2+2) , Xproj1 ) ;
								box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;

								break ;
							}
							else if( proj1exist )
							{
								box2->points.insert( box2->points.begin() += (it2+2) , Yproj1 ) ;
								box2->points.insert( box2->points.begin() += (it2+2) , Xproj1 ) ;
								box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;
								it2 = it2 + 2 ;
							}
							else if( proj2exist )
							{
								box2->points.insert( box2->points.begin() += (it2+2) , Yproj2 ) ;
								box2->points.insert( box2->points.begin() += (it2+2) , Xproj2 ) ;
								box2->edges[it2/2] = false ;
								box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true) ;

								break ;
							}
							else
							{
								box2->edges[it2/2] = false ;
								it2 = it2 + 2 ;
							}
						}// End edge from box1 below edge from box2
			       	}
					else
					{
						// Edge are not parallele, will need to check if they have a relative interior or not.
						bool interiorRelatif ;
						double Xintersec ;
						double Yintersec ;
						
						Xintersec = (b2-b1)/(a1-a2) ;
						Yintersec = a1*Xintersec + b1 ;
					  
						interiorRelatif = ( Xintersec < box1->points[it+2] && Xintersec < box2->points[it2+2] && Xintersec > box1->points[it] && Xintersec > box2->points[it2] );

						if( interiorRelatif )
						{
							// The two edges have a relative interior, we need to verify wich edge is first below then above and do the correct comparison, the comparison on each part are equivalent.
							if( a1 > a2 )
							{
								// a1 and a2 are both negative, if a1 > a2 then the first part of edge from box1 is below the first part of edge from box2 and converse for second part.
								double testYproj = a2 * box1->points[it] + b2 ;
								double correspondingX = box1->points[it] ;

								double testXproj = (box2->points[it2+3]-b1)/a1 ;
								double correspondingY = box2->points[it2+3] ;

								if( testYproj >= box2->points[it2+1] )
								{
									// First part of edge from box1 is below first part of edge from box2 and totally dominate first part of edge from box2. We add the intersection point and flag first part of edge from box2 as dominated.
									box2->points.insert( box2->points.begin() += (it2+2) , Yintersec ) ;
									box2->points.insert( box2->points.begin() += (it2+2) , Xintersec ) ;
									box2->edges[it2/2] = false ;
									box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true ) ;
									it2 = it2 + 4 ;
								}
								else
								{
									// First part of edge from box1 is below first part of edge from box2 and there is a projection on edge from box2, then the part below the projection and above the intersection point is dominated. We add corresponding point and flag the corresponding part as dominated.
									box2->points.insert( box2->points.begin() += (it2+2) , Yintersec ) ;
									box2->points.insert( box2->points.begin() += (it2+2) , Xintersec ) ;
									box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true ) ;

									box2->points.insert( box2->points.begin() += (it2+2) , testYproj ) ;
									box2->points.insert( box2->points.begin() += (it2+2) , correspondingX ) ;
									box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;

									it2 = it2 + 6 ;

								}

								if( testXproj >= box1->points[it+2] )
								{
									// Second part of edge from box1 is above second part of edge from box2 and is totally dominated by second part of edge from box2. We add the intersection point and flag second part of edge from box1 as dominated. As the edges are sorted lexicographically, further comparisons are pointless.
									box1->points.insert( box1->points.begin() += (it+2) , Yintersec ) ;
									box1->points.insert( box1->points.begin() += (it+2) , Xintersec ) ;
									box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

									break ;
								}
								else
								{
									// Second part of edge from box1 is above second part of edge from box2 and there is a projection on edge from box1, then the part above the projection and below the intersection point is dominated. We add corresponding point and flag the corresponding part as dominated. As the edges are sorted lexicographically, further comparisons are needed.
									box1->points.insert( box1->points.begin() += (it+2) , correspondingY ) ;
									box1->points.insert( box1->points.begin() += (it+2) , testXproj ) ;
									box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true ) ;

									box1->points.insert( box1->points.begin() += (it+2) , Yintersec ) ;
									box1->points.insert( box1->points.begin() += (it+2) , Xintersec ) ;
									box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

									it = it + 4 ;
								}
							}// End comparison if a1 > a2
							else
							{
								// a1 and a2 are both negative, if a1 < a2 then the first part of edge from box1 is above the first part of edge from box2 and converse for second part. The comparison are equivalent to the previous comparisons.
								double testYproj = a1 * box2->points[it2] + b1 ;
								double correspondingX = box2->points[it2] ;

								double testXproj = (box1->points[it+3]-b2)/a2 ;
								double correspondingY = box1->points[it+3] ;

								if( testYproj >= box1->points[it+1] )
								{
									box1->points.insert( box1->points.begin() += (it+2) , Yintersec ) ;
									box1->points.insert( box1->points.begin() += (it+2) , Xintersec ) ;
									box1->edges[it/2] = false ;
									box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true ) ;
									it = it + 2 ;
								}
								else
								{
									box1->points.insert( box1->points.begin() += (it+2) , Yintersec ) ;
									box1->points.insert( box1->points.begin() += (it+2) , Xintersec ) ;
									box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true ) ;

									box1->points.insert( box1->points.begin() += (it+2) , testYproj ) ;
									box1->points.insert( box1->points.begin() += (it+2) , correspondingX ) ;
									box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

									it = it + 4 ;
								}

								if( testXproj >= box2->points[it2+2] )
								{
									box2->points.insert( box2->points.begin() += (it2+2) , Yintersec ) ;
									box2->points.insert( box2->points.begin() += (it2+2) , Xintersec ) ;
									box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;

									it2 = it2 + 4 ;
								}
								else
								{
									box2->points.insert( box2->points.begin() += (it2+2) , correspondingY ) ;
									box2->points.insert( box2->points.begin() += (it2+2) , testXproj ) ;
									box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true ) ;

									box2->points.insert( box2->points.begin() += (it2+2) , Yintersec ) ;
									box2->points.insert( box2->points.begin() += (it2+2) , Xintersec ) ;
									box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;

									break ;

								}
							}// End comparison if a1 < a2 
						}
						else
						{
							// No relative interior, we need to do all other possible comparisons.
				  			if( ( Xintersec <= box1->points[it] && Xintersec <= box2->points[it2] ) )
				  			{
				  				// The intersection of the line ( constructed from the edges ) is at the left of the two edges. Simple comparison can detect which one is below and which one is above.
				  				if( a1 < a2 )
				  				{
				  					// a1 and a2 are both negative. As a1 < a2 the line from edge from box1 is below the line from edge from box2. Edge from box1 potentially dominate edge from box2. Comparisons are similar to the parallele case.
				  					double Yproj1 = a2 * box1->points[it] + b2 ;
									double Xproj1 = box1->points[it] ;
									 
									double Xproj2 = (box1->points[it+3]-b2)/a2 ;
									double Yproj2 = box1->points[it+3] ;
								
									bool proj1exist = ( Yproj1 < box2->points[it2+1] && Yproj1 > box2->points[it2+3] ); 
									bool proj2exist = ( Xproj2 < box2->points[it2+2] && Xproj2 > box2->points[it2] );
									
									if( proj1exist && proj2exist )
									{	
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj2 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj2 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true) ;

										box2->points.insert( box2->points.begin() += (it2+2) , Yproj1 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj1 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;

										break ;
									}
									else if( proj1exist )
									{
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj1 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj1 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;
										it2 = it2 + 4 ;
									}
									else if( proj2exist )
									{
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj2 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj2 ) ;
										box2->edges[it2/2] = false ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true) ;

										break ;
									}
									else
									{
										box2->edges[it2/2] = false ;
										it2 = it2 + 2 ;
									}
				  				}// End a1 < a2
				  				else
				  				{
				  					// a1 and a2 are both negative. As a1 > a2 the line from edge from box1 is above the line from edge from box2. Edge from box1 is potentially dominated by edge from box2. Comparisons are similar to the parallele case.
				  					double Yproj1 = a1 * box2->points[it2] + b1 ;
									double Xproj1 = box2->points[it2] ;
									 
									double Xproj2 = (box2->points[it2+3]-b1)/a1 ;
									double Yproj2 = box2->points[it2+3] ;
								
									bool proj1exist = ( Yproj1 < box1->points[it+1] && Yproj1 > box1->points[it+3] ); 
									bool proj2exist = ( Xproj2 < box1->points[it+2] && Xproj2 > box1->points[it] );
									
									if( proj1exist && proj2exist )
									{	
										box1->points.insert( box1->points.begin() += (it+2) , Yproj2 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj2 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true) ;

										box1->points.insert( box1->points.begin() += (it+2) , Yproj1 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj1 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

										it = it + 4 ;
										it2 = it2 + 2 ;
									}
									else if( proj1exist )
									{
										box1->points.insert( box1->points.begin() += (it+2) , Yproj1 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj1 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

										break ;
									}
									else if( proj2exist )
									{
										box1->points.insert( box1->points.begin() += (it+2) , Yproj2 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj2 ) ;
										box1->edges[it/2] = false ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true) ;

										it = it + 2 ;
										it2 = it2 + 2 ;
									}
									else
									{
										box1->edges[it/2] = false ;
										break ;
									}

				  				}
				  			}// End intersection is at left from both edges
				  			else if( ( Xintersec >= box1->points[it+2] && Xintersec >= box2->points[it2+2] ))
				  			{
				  				// The intersection of the line ( constructed from the edges ) is at the right of the two edges. Simple comparison can detect which one is below and which one is above.
								if( a1 > a2 )
				  				{
				  					// a1 and a2 are both negative. As a1 > a2 the line from edge from box1 is below the line from edge from box2. Edge from box1 potentially dominate edge from box2. Comparisons are similar to the parallele case.
				  					double Yproj1 = a2 * box1->points[it] + b2 ;
									double Xproj1 = box1->points[it] ;
									 
									double Xproj2 = (box1->points[it+3]-b2)/a2 ;
									double Yproj2 = box1->points[it+3] ;
								
									bool proj1exist = ( Yproj1 < box2->points[it2+1] && Yproj1 > box2->points[it2+3] ); 
									bool proj2exist = ( Xproj2 < box2->points[it2+2] && Xproj2 > box2->points[it2] );
									
									if( proj1exist && proj2exist )
									{	
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj2 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj2 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true) ;

										box2->points.insert( box2->points.begin() += (it2+2) , Yproj1 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj1 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;

										break ;
									}
									else if( proj1exist )
									{
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj1 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj1 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;
										it2 = it2 + 4 ;
									}
									else if( proj2exist )
									{
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj2 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj2 ) ;
										box2->edges[it2/2] = false ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true) ;

										break ;
									}
									else
									{
										box2->edges[it2/2] = false ;
										it2 = it2 + 2 ;
									}
				  				}// End a1 > a2
				  				else
				  				{
				  					// a1 and a2 are both negative. As a1 < a2 the line from edge from box1 is above the line from edge from box2. Edge from box1 is potentially dominated by edge from box2. Comparisons are similar to the parallele case.
				  					double Yproj1 = a1 * box2->points[it2] + b1 ;
									double Xproj1 = box2->points[it2] ;
									 
									double Xproj2 = (box2->points[it2+3]-b1)/a1 ;
									double Yproj2 = box2->points[it2+3] ;
								
									bool proj1exist = ( Yproj1 < box1->points[it+1] && Yproj1 > box1->points[it+3] ); 
									bool proj2exist = ( Xproj2 < box1->points[it+2] && Xproj2 > box1->points[it] );
									
									if( proj1exist && proj2exist )
									{	
										box1->points.insert( box1->points.begin() += (it+2) , Yproj2 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj2 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true) ;

										box1->points.insert( box1->points.begin() += (it+2) , Yproj1 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj1 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

										it = it + 4 ;
										it2 = it2 + 2 ;
									}
									else if( proj1exist )
									{
										box1->points.insert( box1->points.begin() += (it+2) , Yproj1 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj1 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

										break ;
									}
									else if( proj2exist )
									{
										box1->points.insert( box1->points.begin() += (it+2) , Yproj2 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj2 ) ;
										box1->edges[it/2] = false ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true) ;

										it = it + 2 ;
										it2 = it2 + 2 ;
									}
									else
									{
										box1->edges[it/2] = false ;
										break ;
									}

				  				}// End a1 < a2

				  			}// End intersection point is at the right of both edges
				  			else if( Xintersec > box1->points[it] && Xintersec < box1->points[it+2] )
				  			{
				  				// Intersection point is inside the edge from box1
				  				if( ( Xintersec < box2->points[it2] && a1 < a2 ) || ( Xintersec > box2->points[it2+2] && a1 > a2 ))
				  				{
				  					// This condition verifies that edge from box1 is below edge from box2. Edge from box1 potentially dominates edge from box2. Comparisons are then similar to the parallel case.
				  					double Yproj1 = a2 * box1->points[it] + b2 ;
									double Xproj1 = box1->points[it] ;
									 
									double Xproj2 = (box1->points[it+3]-b2)/a2 ;
									double Yproj2 = box1->points[it+3] ;
								
									bool proj1exist = ( Yproj1 < box2->points[it2+1] && Yproj1 > box2->points[it2+3] ); 
									bool proj2exist = ( Xproj2 < box2->points[it2+2] && Xproj2 > box2->points[it2] );
									
									if( proj1exist && proj2exist )
									{	
										// NOT SUPPOSED TO HAPPEN 
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj2 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj2 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true) ;

										box2->points.insert( box2->points.begin() += (it2+2) , Yproj1 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj1 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;

										break ;
									}
									else if( proj1exist )
									{
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj1 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj1 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;
										it2 = it2 + 4 ;
									}
									else if( proj2exist )
									{
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj2 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj2 ) ;
										box2->edges[it2/2] = false ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true) ;

										break ;
									}
									else
									{
										box2->edges[it2/2] = false ;
										it2 = it2 + 2 ;
									}
				  				}// End edge from box1 below edge from box2
				  				else
				  				{
				  					// This false condition verifies that edge from box1 is above edge from box2. Edge from box1 is then potentially dominated by edge from box2. Comparisons are then similar to the parallel case.
				  					double Yproj1 = a1 * box2->points[it2] + b1 ;
									double Xproj1 = box2->points[it2] ;
									 
									double Xproj2 = (box2->points[it2+3]-b1)/a1 ;
									double Yproj2 = box2->points[it2+3] ;
								
									bool proj1exist = ( Yproj1 < box1->points[it+1] && Yproj1 > box1->points[it+3] ); 
									bool proj2exist = ( Xproj2 < box1->points[it+2] && Xproj2 > box1->points[it] );
									
									if( proj1exist && proj2exist )
									{	
										// NOT SUPPOSED TO HAPPEN
										box1->points.insert( box1->points.begin() += (it+2) , Yproj2 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj2 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true) ;

										box1->points.insert( box1->points.begin() += (it+2) , Yproj1 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj1 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

										it = it + 4 ;
										it2 = it2 + 2 ;
									}
									else if( proj1exist )
									{
										box1->points.insert( box1->points.begin() += (it+2) , Yproj1 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj1 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

										break ;
									}
									else if( proj2exist )
									{
										box1->points.insert( box1->points.begin() += (it+2) , Yproj2 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj2 ) ;
										box1->edges[it/2] = false ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true) ;

										it = it + 2 ;
										it2 = it2 + 2 ;
									}
									else
									{
										box1->edges[it/2] = false ;
										break ;
									}
				  				}// End edge from box1 above edge from box2
				  			}
				  			else if( Xintersec > box2->points[it2] && Xintersec < box2->points[it2+2] )
				  			{
				  				// Intersection point is inside the edge from box2, all subsequent comparison are similar to previous ones.
				  				if(( Xintersec < box1->points[it] && a1 < a2 ) || ( Xintersec > box1->points[it+2] && a1 > a2 ))
				  				{
				  					// This condition verifies that edge from box1 is below edge from box2. Edge from box1 potentially dominates edge from box2. Comparisons are then similar to the parallel case.
				  					double Yproj1 = a2 * box1->points[it] + b2 ;
									double Xproj1 = box1->points[it] ;
									 
									double Xproj2 = (box1->points[it+3]-b2)/a2 ;
									double Yproj2 = box1->points[it+3] ;
								
									bool proj1exist = ( Yproj1 < box2->points[it2+1] && Yproj1 > box2->points[it2+3] ); 
									bool proj2exist = ( Xproj2 < box2->points[it2+2] && Xproj2 > box2->points[it2] );
									
									if( proj1exist && proj2exist )
									{	
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj2 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj2 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true) ;

										box2->points.insert( box2->points.begin() += (it2+2) , Yproj1 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj1 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;

										break ;
									}
									else if( proj1exist )
									{
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj1 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj1 ) ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), false ) ;
										it2 = it2 + 2 ;
									}
									else if( proj2exist )
									{
										box2->points.insert( box2->points.begin() += (it2+2) , Yproj2 ) ;
										box2->points.insert( box2->points.begin() += (it2+2) , Xproj2 ) ;
										box2->edges[it2/2] = false ;
										box2->edges.insert( box2->edges.begin() += (it2/2 + 1 ), true) ;

										break ;
									}
									else
									{
										box2->edges[it2/2] = false ;
										it2 = it2 + 2 ;
									}
				  				}// End edge from box1 below edge from box2 
				  				else
				  				{
				  					// This false condition verifies that edge from box1 is above edge from box2. Edge from box1 is then potentially dominated by edge from box2. Comparisons are then similar to the parallel case.
				  					double Yproj1 = a1 * box2->points[it2] + b1 ;
									double Xproj1 = box2->points[it2] ;
									 
									double Xproj2 = (box2->points[it2+3]-b1)/a1 ;
									double Yproj2 = box2->points[it2+3] ;
								
									bool proj1exist = ( Yproj1 < box1->points[it+1] && Yproj1 > box1->points[it+3] ); 
									bool proj2exist = ( Xproj2 < box1->points[it+2] && Xproj2 > box1->points[it] );
									
									if( proj1exist && proj2exist )
									{	
										box1->points.insert( box1->points.begin() += (it+2) , Yproj2 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj2 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true) ;

										box1->points.insert( box1->points.begin() += (it+2) , Yproj1 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj1 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

										it = it + 4 ;
										it2 = it2 + 2 ;
									}
									else if( proj1exist )
									{
										box1->points.insert( box1->points.begin() += (it+2) , Yproj1 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj1 ) ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), false ) ;

										break ;
									}
									else if( proj2exist )
									{
										box1->points.insert( box1->points.begin() += (it+2) , Yproj2 ) ;
										box1->points.insert( box1->points.begin() += (it+2) , Xproj2 ) ;
										box1->edges[it/2] = false ;
										box1->edges.insert( box1->edges.begin() += (it/2 + 1 ), true) ;

										it = it + 2 ;
										it2 = it2 + 2 ;
									}
									else
									{
										box1->edges[it/2] = false ;
										break ;
									}
				  				}// End edge from box1 above edge from box2 
				  			}
						} // End of no Relative Interior
					} // End of Comparisons
				} // End of if2 (this is an edge from box2)
				else
				{
					it2 = it2 + 2 ;
				}
			} // end of for2
		} // end of if1 (this is an edge from box1)
	} // end of for1
	
	int toReturn = 0  ;

	prefiltering(box1,data);
	prefiltering(box2,data);

	if( box1->points.size() <= 2 || box1->edges.size() == 0 || !box1->getHasEdge() )
	{
		toReturn = 1 ;
	}
	else if( box2->points.size() <= 2 || box2->edges.size() == 0 || !box2->getHasEdge() )
	{
		toReturn = -1 ;
	}

	return toReturn ;
}

void prefiltering(Box* box, Data &data)
{
	bool erase = !box->edges[0];

	while( erase )
	{
		box->points.erase(box->points.begin());
		box->points.erase(box->points.begin());
		box->edges.erase(box->edges.begin());

		if( box->edges.size() > 0)
		{
			erase = !box->edges[0] ;
		}
		else
		{
			erase = false ;
		}
	}

	if( box->edges.size() > 0 )
	{
		erase = !box->edges[box->edges.size()-1];

		while( erase )
		{
			box->points.erase(box->points.begin() += (box->points.size()-1) );
			box->points.erase(box->points.begin() += (box->points.size()-1) );
			box->edges.erase(box->edges.begin() += (box->edges.size()-1) );

			if( box->edges.size() > 0)
			{
				erase = !box->edges[box->edges.size()-1] ;
			}
			else
			{
				erase = false ;
			}
		}
	}

	for(unsigned int i = 2 ; i < box->points.size()-2 ;)
	{
		if( (!box->edges[i/2] && !box->edges[i/2+1]) || fabs(box->points[i] - box->points[i+2]) < data.epsilon || fabs(box->points[i+1] - box->points[i+3]) < data.epsilon )
		{
			box->points.erase(box->points.begin() += (i + 2));
			box->points.erase(box->points.begin() += (i + 2));
			box->edges.erase(box->edges.begin() += (i/2 + 1));
		}
		else
		{
			i=i+2 ;
		}
	}

	if( fabs(box->getMinZ1() - box->getMaxZ1() ) < data.epsilon || fabs(box->getMinZ2() - box->getMaxZ2() ) < data.epsilon )
		box->setHasEdge(false) ;
}

void edgefiltering(vector<Box*> &vectorBox, Data &data)
{
	for( unsigned int it = 0; it < vectorBox.size() ; ++it )
	{
		if( vectorBox[it]->getHasEdge() )
			prefiltering(vectorBox[it],data);
	}
  
	for(unsigned int it = 0; it < vectorBox.size();)
	{	 
		unsigned int size = vectorBox.size() ;
		
		for(unsigned int it2 = it + 1 ; it2 < size ;)
		{
			if( !vectorBox[it]->getHasEdge() && !vectorBox[it2]->getHasEdge() )
			{
				// Both Box are points. We verify using point dominance test
				if( isPointDominated(vectorBox[it], vectorBox[it2]) )
				{
					delete vectorBox[it];
					vectorBox.erase(vectorBox.begin() += it);
					it2 = it + 1 ;
					--size ;
				}
				else if( isPointDominated(vectorBox[it2], vectorBox[it]) )
				{
					delete vectorBox[it2];
					vectorBox.erase(vectorBox.begin() += it2);
					--size ;
				}
				else
				{
					++it2 ;
				}

				// ++it2;
			}
			else if( !vectorBox[it]->getHasEdge() )
			{
				// One box is a point the other has edge. We verify using point edge dominance test
				int result = dominancePointEdge(vectorBox[it],vectorBox[it2],data);

				if( result == 1 )
				{
					++it2 ;
				}
				else if( result == -1 )
				{
					delete vectorBox[it];
					vectorBox.erase(vectorBox.begin() += it);
					it2 = it + 1 ;
					--size ;
				}
				else
				{
					delete vectorBox[it2];
					vectorBox.erase(vectorBox.begin() += it2);
					--size ;
				}
			}
			else if( !vectorBox[it2]->getHasEdge() )
			{
				// One box is a point the other has edge. We verify using point edge dominance test
				int result = dominancePointEdge(vectorBox[it2],vectorBox[it],data);
				
				if( result == 1 )
				{
					++it2 ;
				}
				else if( result == -1 )
				{
					delete vectorBox[it2];
					vectorBox.erase(vectorBox.begin() += it2);
					--size ;
				}
				else
				{
					delete vectorBox[it];
					vectorBox.erase(vectorBox.begin() += it);
					it2 = it + 1 ;
					--size ;
				}
			}
			else
			{	
				// Both box has edges. We verify using edge edge dominance test
				int result = dominanceEdgeEdge(vectorBox[it],vectorBox[it2],data) ;
				
				if( result == -1 )
				{
					delete vectorBox[it2];
					vectorBox.erase(vectorBox.begin() += it2);
					--size ;
				}
				else if( result == 1 )
				{
					delete vectorBox[it];
					vectorBox.erase(vectorBox.begin() += it);
					it2 = it + 1 ;
					--size ;
				}
				else
				{
					++it2 ;
				}
			}
		}
		it++;
	}
}

double computeCorrelation(Data &data)
{
	double correl(0);
	double meanX(0), meanY(0), num(0), den1(0), den2(0);
    
	for(unsigned int i = 0; i < data.getnbCustomer(); i++)
	{
		for(unsigned int j = 0; j < data.getnbFacility(); j++)
		{
			meanX += data.getAllocationObj1Cost(i,j);
			meanY += data.getAllocationObj2Cost(i,j);
		}
	}
	meanX /= ( data.getnbCustomer() * data.getnbFacility() );
	meanY /= ( data.getnbCustomer() * data.getnbFacility() );
    
	for(unsigned int i = 0; i < data.getnbCustomer(); i++)
	{
		for(unsigned int j = 0; j < data.getnbFacility(); j++)
		{
			num += (data.getAllocationObj1Cost(i,j) - meanX) * (data.getAllocationObj2Cost(i,j) - meanY) / ( data.getnbCustomer() * data.getnbFacility() );
			den1 += pow((data.getAllocationObj1Cost(i,j) - meanX),2) / ( data.getnbCustomer() * data.getnbFacility() );
			den2 += pow((data.getAllocationObj2Cost(i,j) - meanY),2) / ( data.getnbCustomer() * data.getnbFacility() );
		}
	}
    
	correl = num / (sqrt(den1)*sqrt(den2));
	
	return correl;	
}

void quicksortedge(vector<Box*> &toSort, int begin, int end)
{
      int i = begin, j = end;

      Box* tmp;

      double pivot = toSort[(begin + end) / 2]->getMinZ1();

      /* partition */

      while (i <= j) 
      {

            while (toSort[i]->getMinZ1() < pivot)
                  i++;

            while (toSort[j]->getMinZ1() > pivot)
                  j--;

            if (i <= j) 
            {
                  tmp = toSort[i];
                  toSort[i] = toSort[j];
                  toSort[j] = tmp;

                  i++;
                  j--;
            }
      };

      /* recursion */

      if (begin < j)
      {
            quicksortedge(toSort, begin, j);
      }
      if (i < end)
      {
            quicksortedge(toSort, i, end);
      }
}

void quicksortCusto(vector<double> &toHelp, vector<double> &lexHelp, vector<int> &toSort, int begin, int end)
{
      int i = begin, j = end;
      double tmpcost;
      double tmplex;
      int tmpfacility;

      double pivot = toHelp[(begin + end) / 2];
      double lexpivot = lexHelp[(begin + end) / 2];

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
              	else if( lexHelp[i] < lexpivot )
              	{
              		// Verification to be sure all customer preferences are sorted by lexicographical order
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
              	else if( lexHelp[j] > lexpivot )
              	{
              		// Verification to be sure all customer preferences are sorted by lexicographical order
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
                  tmplex = lexHelp[i];

                  toSort[i] = toSort[j];
                  toHelp[i] = toHelp[j];
                  lexHelp[i] = lexHelp[j];

                  toSort[j] = tmpfacility;
                  toHelp[j] = tmpcost;
                  lexHelp[j] = tmplex;

                  i++;
                  j--;
            }
      };

      /* recursion */

      if (begin < j)
      {
            quicksortCusto(toHelp, lexHelp, toSort, begin, j);
      }
      if (i < end)
      {
            quicksortCusto(toHelp, lexHelp, toSort, i, end);
      }
}

void quicksortFacility(vector<double> &toSort, int begin, int end, Data &data)
{
      int i = begin, j = end;

      int tmp;
      int tmp2;

      int pivot = toSort[(begin + end) / 2];

      /* partition */

      while (i <= j) 
      {

            while (toSort[i] > pivot)
                  i++;

            while (toSort[j] < pivot)
                  j--;

            if (i <= j) 
            {
                  tmp = toSort[i];
                  tmp2 = data.facilitySort[i];
                  toSort[i] = toSort[j];
                  data.facilitySort[i] = data.facilitySort[j];
                  toSort[j] = tmp;
                  data.facilitySort[j] = tmp2 ;

                  i++;
                  j--;
            }
      };

      /* recursion */

      if (begin < j)
      {
            quicksortFacility(toSort, begin, j, data);
      }
      if (i < end)
      {
            quicksortFacility(toSort, i, end, data);
      }
}

bool isAlreadyIn(vector<string> openedFacility, Box* box)
{
	for(unsigned int it = 0 ; it < openedFacility.size() ; ++it )
	{
		if( openedFacility[it] == box->getId() )
			return true ;
	}

	return false ;
}

void sortFacility(Data &data, vector<double> clientfacilitycost1,vector<double> clientfacilitycost2)
{	
	vector<double> sortFacility = vector<double>(data.getnbFacility(),0);

	for( unsigned int i = 0 ; i < data.getnbFacility() ; ++i )
		sortFacility[i] = clientfacilitycost1[i] + data.getLocationObj1Cost(i) + clientfacilitycost2[i] + data.getLocationObj2Cost(i) ;


	quicksortFacility(sortFacility,0,data.getnbFacility()-1,data);
}

void crono_start(clock_t &start_utime)
{
	start_utime = clock() ;
}

void crono_stop(clock_t &stop_utime)
{
	stop_utime = clock() ;
}

double crono_ms(clock_t start_utime, clock_t stop_utime)
{
	return ( (double) stop_utime - (double) start_utime ) / CLOCKS_PER_SEC * 1000.0 ;
}







void quicksortFacilityOBJ1(vector<double> &toSort, int begin, int end)
{
      int i = begin, j = end;

      double tmp;

      int pivot = toSort[(begin + end) / 2];

      /* partition */

      while (i <= j) 
      {

            while (toSort[i] < pivot)
                  i++;

            while (toSort[j] > pivot)
                  j--;

            if (i <= j) 
            {
                  tmp = toSort[i];
                  toSort[i] = toSort[j];
                  toSort[j] = tmp;

                  i++;
                  j--;
            }
      };

      /* recursion */

      if (begin < j)
      {
            quicksortFacilityOBJ1(toSort, begin, j);
      }
      if (i < end)
      {
            quicksortFacilityOBJ1(toSort, i, end);
      }
}

void quicksortFacilityOBJ2(vector<double> &toSort, int begin, int end)
{
      int i = begin, j = end;

      double tmp;

      int pivot = toSort[(begin + end) / 2];

      /* partition */

      while (i <= j) 
      {

            while (toSort[i] < pivot)
                  i++;

            while (toSort[j] > pivot)
                  j--;

            if (i <= j) 
            {
                  tmp = toSort[i];
                  toSort[i] = toSort[j];
                  toSort[j] = tmp;

                  i++;
                  j--;
            }
      };

      /* recursion */

      if (begin < j)
      {
            quicksortFacilityOBJ2(toSort, begin, j);
      }
      if (i < end)
      {
            quicksortFacilityOBJ2(toSort, i, end);
      }
}
