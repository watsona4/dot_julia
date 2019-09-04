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
 
#include "Box.hpp"

Box::Box(Data &data)
{
	//Set opening of depots to FALSE
	facility_ = new bool[data.getnbFacility()];
	for(unsigned int i = 0; i < data.getnbFacility(); ++i)
	{
		facility_[i] = false;
	}
	
	//Set allocation of customer to FALSE
	isAssigned_ = new bool[data.getnbCustomer()];
	for(unsigned int i = 0; i < data.getnbCustomer(); ++i)
	{
		isAssigned_[i] = false;
	}
    
	//All cost are 0 (nothing is allocated)
	nbCustomerNotAffected_ = data.getnbCustomer();
	nbFacilityOpen_ = 0 ;

	clientAllocation = vector< vector< vector<double> > >() ;
	points = vector<double>(4,0);
	edges = vector<bool>(1,true) ;
	dicho = vector<bool>(1,true) ;

	LB_origin_Z1 = data.optimalAllocationObj1 ;
	LB_origin_Z2 = data.optimalAllocationObj2 ;

	originZ1_ = 0;
	originZ2_ = 0;
	id_ = "";
}

Box::Box(Data &data, bool *toOpen)
{
	possiblyOpenFacility = vector<int>() ;

	nbCustomerNotAffected_ = data.getnbCustomer();
	nbFacilityOpen_ = 0 ;

	// Initialisation of the different vectors. A Priori we will obtain two points with feasible edge between them.
	clientAllocation = vector< vector< vector<double> > >() ;

	points = vector<double>(4,0);
	pointsLB = vector<double>(4,0);

	edges = vector<bool>(1,true) ;
	edgesLB = vector<bool>(1,true) ;

	dicho = vector<bool>(1,true) ;
	dichoLB = vector<bool>(1,true);

	originZ1_ = 0;
	originZ2_ = 0;
	LB_origin_Z1 = data.optimalAllocationObj1 ;
	LB_origin_Z2 = data.optimalAllocationObj2 ;
	id_ = "";
	hasEdge_ = true ; // A priori there is edges
	hasMoreStepWS_ = true ; // A priori, some supported points exist
	hasMoreStepLB_ = true ; // A priori, lowerbound has some supported points
	
	//Set opening of depots to FALSE
	facility_ = new bool[data.getnbFacility()];
	for(unsigned int i = 0; i < data.getnbFacility(); ++i)
	{
		facility_[i] = false;
		if (toOpen[i])
		{
			openFacility(data,i);
			id_ += "1";
			possiblyOpenFacility.push_back(i);
		}
		else
		{
			id_ += "0";
		}
	}

	if( data.modeLowerBound )
	{
		for(unsigned int i = possiblyOpenFacility[possiblyOpenFacility.size()-1]+1 ; i < data.getnbFacility(); ++i)
		{
			possiblyOpenFacility.push_back(i);
		}
	}

	//Set allocation of customer to FALSE
	isAssigned_ = new bool[data.getnbCustomer()];
	for(unsigned int i = 0; i < data.getnbCustomer(); ++i)
	{
		isAssigned_[i] = false;
	}
}

Box::Box(Data &data, bool *toOpen, vector<int> facilitySort, int last)
{
	possiblyOpenFacility = vector<int>() ;

	nbCustomerNotAffected_ = data.getnbCustomer();
	nbFacilityOpen_ = 0 ;

	// Initialisation of the different vectors. A Priori we will obtain two points with feasible edge between them.
	clientAllocation = vector< vector< vector<double> > >() ;

	points = vector<double>(4,0);
	pointsLB = vector<double>(4,0);

	edges = vector<bool>(1,true) ;
	edgesLB = vector<bool>(1,true) ;

	dicho = vector<bool>(1,true) ;
	dichoLB = vector<bool>(1,true);

	originZ1_ = 0;
	originZ2_ = 0;
	LB_origin_Z1 = data.optimalAllocationObj1 ;
	LB_origin_Z2 = data.optimalAllocationObj2 ;
	id_ = "";
	hasEdge_ = true ; // A priori there is edges
	hasMoreStepWS_ = true; // A priori, some supported points exist
	hasMoreStepLB_ = true ; // A priori, lowerbound has some supported points
	
	//Set opening of depots to FALSE
	facility_ = new bool[data.getnbFacility()];
	for(unsigned int i = 0; i < data.getnbFacility(); ++i)
	{
		facility_[i] = false;
		if (toOpen[i])
		{
			openFacility(data,i);
			id_ += "1";
			possiblyOpenFacility.push_back(i);
		}
		else
		{
			id_ += "0";
		}
	}

	if( data.modeLowerBound )
	{
		for(unsigned int i = last+1 ; i < facilitySort.size() ; ++i)
		{
			possiblyOpenFacility.push_back(facilitySort[i]);
		}
	}

	//Set allocation of customer to FALSE
	isAssigned_ = new bool[data.getnbCustomer()];
	for(unsigned int i = 0; i < data.getnbCustomer(); ++i)
	{
		isAssigned_[i] = false;
	}
}

Box::~Box()
{
	delete[] facility_;
	delete[] isAssigned_;
	// clientAllocation.clear();
	points.clear();
	edges.clear();
	dicho.clear();
	possiblyOpenFacility.clear() ;
	pointsLB.clear() ;
	edgesLB.clear() ;
	dichoLB.clear() ;
}

double Box::getMinZ1() const
{
	return points[0];
}

double Box::getMinZ2() const
{
	return points[points.size()-1];
}

double Box::getMaxZ1() const
{
	return points[points.size()-2];
}

double Box::getMaxZ2() const
{
	return points[1];
}

double Box::getOriginZ1() const
{
	// return LB_origin_Z1;
	return originZ1_;

}

double Box::getOriginZ2() const
{
	// return LB_origin_Z2;
	return originZ2_;	
}

double Box::getLBOriginZ1() const
{
	return LB_origin_Z1;
	// return originZ1_;

}

double Box::getLBOriginZ2() const
{
	return LB_origin_Z2;
	// return originZ2_;	
}

string Box::getId() const
{
	return id_;
}

bool Box::isAssigned(int cust) const
{
	return isAssigned_[cust];
}

bool Box::isOpened(int fac) const
{
	return facility_[fac];
}

int Box::getnbCustomerNotAffected() const
{
	return nbCustomerNotAffected_;
}

int Box::getNbFacilityOpen() const
{
	return nbFacilityOpen_;;
}

bool Box::getHasMoreStepWS() const
{
	return hasMoreStepWS_;
}

bool Box::getHasMoreStepLB() const
{
	return hasMoreStepLB_;
}

bool Box::getHasEdge() const
{
	return hasEdge_;
}

void Box::setId(string s)
{
	id_ += s;
}

void Box::setHasMoreStepWS(bool b)
{
	hasMoreStepWS_ = b;
}

void Box::setHasMoreStepLB(bool b)
{
	hasMoreStepLB_ = b ;
}

void Box::setHasEdge(bool b)
{
	hasEdge_ = b ;
}

void Box::computeBox(Data &data)
{
	//Calcul of the box
	for(unsigned int i = 0; i < data.getnbCustomer(); ++i)
	{
		double vMinZ1 = DBL_MAX;
		double vMaxZ1 = -1;
		double vMinZ2 = DBL_MAX;
		double vMaxZ2 = -1;
		int iMinZ1 = -1, iMinZ2 = -1;

		for(unsigned int j = 0; j < data.getnbFacility(); ++j)
		{
			//Search for local min and max
			if(facility_[j])
			{
				if( data.getAllocationObj1Cost(i,j) <  vMinZ1 || (data.getAllocationObj1Cost(i,j) == vMinZ1 && data.getAllocationObj2Cost(i,j) < vMaxZ2) )
				{
					// <Z1 || =Z1 et <Z2
					vMinZ1 = data.getAllocationObj1Cost(i,j);
					vMaxZ2 = data.getAllocationObj2Cost(i,j);
					iMinZ1 = j;
				}
				if(data.getAllocationObj2Cost(i,j) <  vMinZ2 || (data.getAllocationObj2Cost(i,j) == vMinZ2 && data.getAllocationObj1Cost(i,j) < vMaxZ1) )
				{
					// <Z2 || =Z2 et <Z1
					vMinZ2 = data.getAllocationObj2Cost(i,j);
					vMaxZ1 = data.getAllocationObj1Cost(i,j);
					iMinZ2 = j;
				}
			}
		}

		//If they are equals, this allocation is data.optimal <=> "trivial"
		if(iMinZ1 == iMinZ2)
		{
			points[0] += data.getAllocationObj1Cost(i,iMinZ1);
			points[1] += data.getAllocationObj2Cost(i,iMinZ1);

			points[points.size()-1] += data.getAllocationObj2Cost(i,iMinZ1);
			points[points.size()-2] += data.getAllocationObj1Cost(i,iMinZ1);

			originZ1_ += data.getAllocationObj1Cost(i,iMinZ1);
			originZ2_ += data.getAllocationObj2Cost(i,iMinZ1);

			nbCustomerNotAffected_--;
			isAssigned_[i] = true;
		}
		else
        //We add the lexicographically data.optimal cost
		{
			points[0] += vMinZ1;
			points[1] += vMaxZ2;

			points[points.size()-2] += vMaxZ1;
			points[points.size()-1] += vMinZ2;
		}

		// clientAllocation[0][i][iMinZ1] = 1 ;
		// clientAllocation[clientAllocation.size()-1][i][iMinZ2] = 1 ;
	}

	if(nbCustomerNotAffected_ == 0)
	{
		//If all customers are affected, the box is a point, so there is no more WS step possible
		hasEdge_ = false;
		hasMoreStepWS_= false;
	}
}

void Box::openFacility(Data &data, int fac)
{
	facility_[fac] = true;
	nbFacilityOpen_ ++ ;
	//We add costs to the box
	points[0]	+= data.getLocationObj1Cost(fac);
	points[1]	+= data.getLocationObj2Cost(fac);

	points[points.size()-2]	+= data.getLocationObj1Cost(fac);
	points[points.size()-1]	+= data.getLocationObj2Cost(fac);

	LB_origin_Z1 += data.getLocationObj1Cost(fac);
	LB_origin_Z2 += data.getLocationObj2Cost(fac);

	originZ1_	+= data.getLocationObj1Cost(fac);
	originZ2_	+= data.getLocationObj2Cost(fac);

	pointsLB[0]	+= data.getLocationObj1Cost(fac);
	pointsLB[1]	+= data.getLocationObj2Cost(fac);
	pointsLB[pointsLB.size()-2]	+= data.getLocationObj1Cost(fac);
	pointsLB[pointsLB.size()-1]	+= data.getLocationObj2Cost(fac);
}



//***** PUBLIC FONCTIONS *****

bool isDominatedBetweenTwoBoxes(Box *box1, Box *box2)
{
	bool dominated(false);

	if( ( box1->getMinZ1() >= box2->getMaxZ1() && box1->getMaxZ2() <= box2->getMinZ2() ) 
	|| ( box1->getMaxZ1() <= box2->getMinZ1() && box1->getMinZ2() >= box2->getMaxZ2() ) )
	{
		/*  Dominance Impossible as stated by T.Vincent 
		    Nothing to do */
		return false ;
	}
	else if( box1->getHasEdge() )
	{
		// If Box1 is not a point we will need to consider all edge to edge or edge to point comparison

		for(unsigned int it = 0 ; it < box1->points.size()-2 ; it=it+2 )
		{
			dominated = false ;

			if( box1->edges[it/2] )
			{
				// If current edge is non-dominated we do all subsequent comparison
				for(unsigned int it2 = 0 ; it2 < box2->points.size()-2 && !dominated ; it2 = it2 + 2)
				{
					if( ( box1->points[it+3] >= box2->points[it2+1] && box1->points[it] <= box2->points[it2] ) )
					{
						// Dominance is Impossible furthermore as all edges and points are sorted lexicographically all subsequent comparisons with this edge are useless.
						dominated = false ;
						break ;
					}
					else if( box1->points[it] >= box2->points[it2+2] && box1->points[it+3] <= box2->points[it2+3] )
					{
						// Dominance is Impossible but the placement of the edges does not allow us to stop the comparisons for this edge.
						dominated = false ;
					} 
					else if( ( box1->points[it] >= box2->points[it2+2] && box1->points[it+3] >= box2->points[it2+3] ) || ( box1->points[it+3] >= box2->points[it2+1] && box1->points[it] >= box2->points[it2] ) )
					{
						// This edge is totally dominated.
						dominated = true;
					}
					else if( box2->points[it2] != box2->points[it2+2] )
					{
						// If current point of Box2 are different we can calculate the corresponding edge


						// Calculation of the line going through the two successive points of Box2
						double a = (box2->points[it2+1]-box2->points[it2+3])/(box2->points[it2]-box2->points[it2+2]) ;
						double b = box2->points[it2+1] - a * box2->points[it2] ;
					  
					  	// Simple projection of the edge of Box1 on the previous calculated line.
						double Yproj = a * box1->points[it] + b ;
						double Xproj = ( box1->points[it+3] - b )/ a ;

						if( Yproj > box2->points[it2+1] || Xproj > box2->points[it2+2] || Yproj < box2->points[it2+3] || Xproj < box2->points[it2])
						{
							// If the projection is outside the boundaries of the edge from box2 then the edge from box1 is not dominated, indeed in the only case that it is dominated, previous comparisons would have found that it is dominated beforehand.
							dominated = false ;
						}
						else if( !box1->getHasMoreStepWS() )
						{
							// If the dichotomic search is finished on Box1 we can improve comparison with the projection instead of taking only ideal point.
							dominated = ( Xproj <= box1->points[it+2] ) && ( Yproj <= box1->points[it+1] ) ;
						}
						else
						{
							// We verify if edge from Box1 is below or above edge from Box2.
							dominated = ( Xproj <= box1->points[it] ) && ( Yproj <= box1->points[it+3] );
						}
					}
					if( dominated )
					{
						// If edge from Box1 is dominated, we flag it has dominated and precise that it is not useful to continue the dichotomic search on it.
						box1->edges[it/2] = false ;

						if( box1->getHasMoreStepWS() )
							box1->dicho[it/2] = false ;
					}
				}
			}
		}

		bool erase = !box1->edges[0];
		while( erase )
		{
			// If there is dominated edges on the beggining of the box, we can reduce Box1 by deleting the first point of those dominated edges. We can do it until no edges are dominated on the beggining of the box.
			box1->points.erase(box1->points.begin());
			box1->points.erase(box1->points.begin());

			box1->edges.erase(box1->edges.begin());

			box1->dicho.erase(box1->dicho.begin());

			if( box1->edges.size() > 0)
			{
				erase = !box1->edges[0] ;
			}
			else
			{
				erase = false ;
			}
		}

		if( box1->edges.size() > 0 )
		{
			erase = !box1->edges[box1->edges.size()-1];

			while( erase )
			{
				// If there is dominated edges at the ed of the box, we can reduce Box1 by deleting the last point of those dominated edges. We can do it until no edges are dominated at the end of the box.
				box1->points.erase(box1->points.begin() += (box1->points.size()-1) );
				box1->points.erase(box1->points.begin() += (box1->points.size()-1) );

				box1->edges.erase(box1->edges.begin() += (box1->edges.size()-1));

				box1->dicho.erase(box1->dicho.begin() += (box1->dicho.size()-1));

				if( box1->edges.size() > 0)
				{
					erase = !box1->edges[box1->edges.size()-1] ;
				}
				else
				{
					erase = false ;
				}
			}
		}

		for(unsigned int i = 2 ; i < box1->points.size()-2 ;)
		{
			if( !box1->edges[i/2] && !box1->edges[i/2+1])
			{
				// If continuous edges are dominated, we can delete those edges and only keep the first and last points.
				box1->points.erase(box1->points.begin() += (i + 2));
				box1->points.erase(box1->points.begin() += (i + 2));

				box1->edges.erase(box1->edges.begin() += (i/2 + 1));

				box1->dicho.erase(box1->dicho.begin() += (i/2 + 1));
			}
			else
			{
				i=i+2 ;
			}

		}

		// If box is empty, that means that all its edges and point where dominated and the box is dominated.
		return ( box1->edges.size() <= 0 || box1->points.size() <= 2 );
	}
	else
	{
		// Box1 is a point, we can apply the comparison to this point.
		for(unsigned int it2 = 0 ; it2 < box2->points.size()-2 && !dominated ; it2 = it2 + 2)
		{
			if( ( box1->points[3] > box2->points[it2+1] && box1->points[0] < box2->points[it2] ) )
			{
				// Dominance is Impossible furthermore as all edges and points are sorted lexicographically all subsequent comparisons with this point are useless.
				return false ;
			}
			else if( box1->points[0] > box2->points[it2+2] && box1->points[3] < box2->points[it2+3] )
			{
				// Dominance is Impossible but the placement of the edges does not allow us to stop the comparisons for this point.
				dominated = false ;
			} 
			else if( ( box1->points[0] >= box2->points[it2+2] && box1->points[3] >= box2->points[it2+3] ) || ( box1->points[3] >= box2->points[it2+1] && box1->points[0] >= box2->points[it2] ) )
			{
				// This point is dominated
				return true;
			}
			else if( box2->points[it2] != box2->points[it2+2] )
			{
				// If current point of Box2 are different we can calculate the corresponding edge


				// Calculation of the line going through the two successive points of Box2
				double a = (box2->points[it2+1]-box2->points[it2+3])/(box2->points[it2]-box2->points[it2+2]) ;
				double b = box2->points[it2+1] - a * box2->points[it2] ;
			  	
			  	// Simple projection of the point of Box1 on the previous calculated line.
				double Yproj = a * box1->points[0] + b ;

				// We verify if point is below or above the line which will define if it is dominated or not as all previous test exclude the non-dominance possibility.
				dominated =  Yproj <= box1->points[1]  ;

			}

			if( dominated )
			{
				return true ;
			}
		}

		return dominated ;
	}
}

bool isDominatedBetweenOrigins(Box *box1, Box *box2)
{
	bool dominated(false);

		// cout << "BOX1 " << box1->getLBOriginZ1() << " " << box1->getLBOriginZ2() << " " ;
		// cout << "BOX2 " << box2->getMinZ1() << " " << box2->getMaxZ2() << " " ;
		// cout << "BOX2 " << box2->getMaxZ1() << " " << box2->getMinZ2() << endl ;

	if( ( box1->getLBOriginZ1() > box2->getMaxZ1() && box1->getLBOriginZ2() < box2->getMinZ2() ) || ( box1->getLBOriginZ2() > box2->getMaxZ2() && box1->getLBOriginZ1() < box2->getMinZ1() ) )
	{
		/*  Dominance Impossible as stated by T.Vincent 
		    Nothing to do */

		// cout << "BOX1 " << box1->getLBOriginZ1() << " " << box1->getLBOriginZ2() << " " ;
		// cout << "BOX1 " << box1->getOriginZ1() << " " << box1->getOriginZ2() << " " ;
		// cout << "BOX2 " << box2->getMinZ1() << " " << box2->getMaxZ2() << " " ;
		// cout << "BOX2 " << box2->getMaxZ1() << " " << box2->getMinZ2() << endl ;
		return false ;
	}

	for(unsigned int it = 0 ; it < box2->points.size()-2 && !dominated ; it=it+2 )
	{
		// cout << "BOX1 " << box1->getLBOriginZ1() << " " << box1->getLBOriginZ2() << " " ;
		// cout << "BOX2 " << box2->points[it] << " " << box2->points[it+1] << " " ;
		// cout << "BOX2 " << box2->points[it+2] << " " << box2->points[it+3] << " it " << it << endl ;
		// Comparison of the origin of Box1 and the edges and points of Box2
		if( ( box1->getLBOriginZ1() >= box2->points[it+2] && box1->getLBOriginZ2() >= box2->points[it+3] ) || ( box1->getLBOriginZ2() >= box2->points[it+1] && box1->getLBOriginZ1() >= box2->points[it] ) )
		{
			// The origin is dominated by one of the two points and so Box1 is also dominated.
			return true;
		}
		else if( box1->getLBOriginZ2() > box2->points[it+1] && box1->getLBOriginZ1() < box2->points[it] )
		{
			// Dominance is Impossible furthermore as all edges and points are sorted lexicographically all subsequent comparisons with this origin are useless.
			// cout << "BOX1 " << box1->getLBOriginZ1() << " " << box1->getLBOriginZ2() << " " ;
			// cout << "BOX1 " << box1->getOriginZ1() << " " << box1->getOriginZ2() << " " ;
			// cout << "BOX2 " << box2->points[it] << " " << box2->points[it+1] << " " ;
			// cout << "BOX2 " << box2->points[it+2] << " " << box2->points[it+3] << " it " << it << endl ;

			return false ;
		}
		else if( box1->getLBOriginZ1() > box2->points[it+2] && box1->getLBOriginZ2() < box2->points[it+3] )
		{
			// Dominance is Impossible but the placement of the edges does not allow us to stop the comparisons for this origin.

			dominated = false ;
		}
		else if( box2->points[it] != box2->points[it+2] )
		{
			// If current point of Box2 are different we can calculate the corresponding edge

		    // Calculation of the line going through the two successive points of Box2
			double a = (box2->points[it+1]-box2->points[it+3])/(box2->points[it]-box2->points[it+2]) ;
			double b = box2->points[it+1] - a * box2->points[it] ;
			
			// Simple projection of the origin of Box1 on the previous calculated line.
			double Yproj = a * box1->getLBOriginZ1() + b ;

			// We verify if the origin is below or above the line which will define if it is dominated or not as all previous test exclude the non-dominance possibility.
			dominated = ( box1->getLBOriginZ2() >= Yproj ) ;

		}

		if( dominated )
		{
			return true ;
		}
	}

	// cout << "BOX1 " << box1->getLBOriginZ1() << " " << box1->getLBOriginZ2() << " " ;
	// cout << "BOX1 " << box1->getOriginZ1() << " " << box1->getOriginZ2() << " " ;

	return dominated;
}

bool isDominatedBetweenLowerBound(Box *box1, Box *box2, Data &data)
{
	bool dominated(false);

	if( ( box1->pointsLB[0] >= box2->getMaxZ1() && box1->pointsLB[box1->pointsLB.size()-1] <= box2->getMinZ2() ) || ( box1->pointsLB[box1->pointsLB.size()-1] >= box2->getMaxZ2() && box1->pointsLB[0] <= box2->getMinZ1() ) )
	{
		/*  Dominance Impossible as stated by T.Vincent 
		    Nothing to do */
		return false ;
	}

	/* Verification with IDEAL POINT of the lbs */ 
	for(unsigned int it = 0 ; it < box2->points.size()-2 ; it=it+2 )
	{
		if( box1->pointsLB[box1->pointsLB.size()-1] > box2->points[it+1] && box1->pointsLB[0] < box2->points[it] )
		{
			// Dominance is Impossible furthermore as all edges and points are sorted lexicographically all subsequent comparisons with this IDEAL POINT are useless.
			return false;
		}
		else if( box1->pointsLB[0] > box2->points[it+2] && box1->pointsLB[box1->pointsLB.size()-1] < box2->points[it+3] )
		{
			// Dominance is Impossible but the placement of the edges does not allow us to stop the comparisons for this IDEAL POINT.
			dominated = false ;
		}
		else if( ( box1->pointsLB[0] >= box2->points[it+2] && box1->pointsLB[box1->pointsLB.size()-1] >= box2->points[it+3] ) 
			  || ( box1->pointsLB[box1->pointsLB.size()-1] >= box2->points[it+1] && box1->pointsLB[0] >= box2->points[it] ) )
		{
			// The IDEAL POINT is dominated by one of the two points of Box2 and so the LBS of Box1 is also dominated.
			return true;
		}
		else if( box2->points[it] != box2->points[it+2] )
		{
			// If current point of Box2 are different we can calculate the corresponding edge

			// Calculation of the line going through the two successive points of Box2
			double a = (box2->points[it+1]-box2->points[it+3])/(box2->points[it]-box2->points[it+2]) ;
			double b = box2->points[it+1] - a * box2->points[it] ;
			
			// Simple projection of the IDEAL POINT of the lbs of Box1 on the previous calculated line.
			double Yproj = a * box1->pointsLB[0]+ b ;

			// We verify if the IDEAL POINT is below or above the line which will define if it is dominated or not as all previous test exclude the non-dominance possibility.
			dominated = ( box1->pointsLB[box1->pointsLB.size()-1] > Yproj ) ;

			if( dominated )
			{
				return true ;
			}

		}
	}

	if( data.modeImprovedLB )
	{
		// if we have calculated the complete set of supported point of the lbs we can improve the dominance tests :
		for(unsigned int it = 0 ; it < box1->pointsLB.size()-2 ; it=it+2 )
		{
			dominated = false ;

			if( box1->edgesLB[it/2] )
			{
				for(unsigned int it2 = 0 ; it2 < box2->points.size()-2 && !dominated ; it2 = it2 + 2)
				{
					/* VERIFICATION OF POSSIBLE EDGES */
					if( ( box1->pointsLB[it+3] > box2->points[it2+1] && box1->pointsLB[it] < box2->points[it2] ) )
					{
						// Dominance is Impossible furthermore as all edges and points are sorted lexicographically all subsequent comparisons with this lb edge are useless.
						dominated = false ;
						break ;
					}
					else if( box1->pointsLB[it] > box2->points[it2+2] && box1->pointsLB[it+3] < box2->points[it2+3] )
					{
						// Dominance is Impossible but the placement of the edges does not allow us to stop the comparisons for this lb edge.
						dominated = false ;
					} 
					else if( ( box1->pointsLB[it] >= box2->points[it2+2] && box1->pointsLB[it+3] >= box2->points[it2+3] ) || ( box1->pointsLB[it+3] >= box2->points[it2+1] && box1->pointsLB[it] >= box2->points[it2] ) )
					{
						// This lb edge is totally dominated.
						dominated = true;
					}
					else if( box2->points[it2] != box2->points[it2+2] && box2->points[it2+1] != box2->points[it2+3] )
					{
						// If current point of Box2 are different we can calculate the corresponding edge

						// Calculation of the line going through the two successive points of Box2
						double a = (box2->points[it2+1]-box2->points[it2+3])/(box2->points[it2]-box2->points[it2+2]) ;
						double b = box2->points[it2+1] - a * box2->points[it2] ;
					  	
					  	// Simple projection of the lb edge of Box1 on the previous calculated line.
						double Yproj = a * box1->pointsLB[it] + b ;
						double Xproj = ( box1->pointsLB[it+3] - b )/ a ;

						if( Yproj > box2->points[it2+1] || Xproj > box2->points[it2+2] || Yproj < box2->points[it2+3] || Xproj < box2->points[it2])
						{
							// If the projection is outside the boundaries of the edge from box2 then the lb edge from box1 is not dominated, indeed in the only case that it is dominated, previous comparisons would have found that it is dominated beforehand.
							dominated = false ;
						}
						else
						{
							// We verify if the lb edge is below or above the line which will define if it is dominated or not as all previous test exclude the non-dominance possibility.
							dominated = ( Xproj <= box1->pointsLB[it+2] ) && ( Yproj <= box1->pointsLB[it+1] ) ;
						}
					}

					if( dominated )
					{
						// If lb edge from Box1 is dominated, we flag it has dominated and precise that it is not useful to continue the dichotomic search on it.
						box1->edgesLB[it/2] = false ;

						if( box1->getHasMoreStepLB() )
							box1->dichoLB[it/2] = false ;
					}
				}
			}
		}

		dominated = true ;

		for(unsigned int i = 0 ; i < box1->edgesLB.size() && dominated ; ++i )
		{
			// if all lb edges are dominated then necessarily box1 is dominated
			dominated = dominated && !box1->edgesLB[i] ;
		}
	}

	return dominated ;
}

void filterDominatedBoxes(vector<Box*> &vectBox)
{
	for(unsigned int it = 0; it < vectBox.size(); it++)
	{
		for(unsigned int it2 = it + 1; it2 < vectBox.size(); it2++)
		{
			if( isDominatedBetweenTwoBoxes( vectBox[it2] , vectBox[it] ) )
			{
				//it2 is dominated
				delete (vectBox[it2]);
				vectBox.erase((vectBox.begin())+=it2);
				it2--;//We delete it2, so we shift by one
			}
			else
			{
				if( isDominatedBetweenTwoBoxes( vectBox[it] , vectBox[it2] ) )
				{
					//it is dominated
					delete (vectBox[it]);
					vectBox.erase((vectBox.begin())+=it);
					//Delete it, pass to the next loop. Initialize it2 to it+1
					it2 = it;
				}
			}
		}
	}
}

bool isDominatedByItsOrigin(vector<Box*> &vectBox, Box *box)
{
	bool isDominated(false);
	vector<Box*>::iterator it;
	/*Stop Criterion
     - all the vector is travelled (but condition 3 may occur before)
     - we are dominated
     - we compare with itself
     */
	for( it = vectBox.begin(); it != vectBox.end() && !isDominated && (*it != box); it++)
	{
		if( isDominatedBetweenOrigins( box , (*it) ) )
		{
			isDominated = true;
		}
  	}
	return isDominated;
}

bool isDominatedByItsLowerBound(vector<Box*> &vectBox, Box *box, Data &data)
{
	bool isDominated(false);
	vector<Box*>::iterator it;
	/*Stop Criterion
     - all the vector is travelled (but condition 3 may occur before)
     - we are dominated
     - we compare with itself
     */
	for( it = vectBox.begin(); it != vectBox.end() && !isDominated && (*it != box); it++)
	{
		if( isDominatedBetweenLowerBound( box , (*it) , data ) )
		{
			isDominated = true;
		}
  	}
	return isDominated;
}

bool isDominatedByItsBox(vector<Box*> &vectBox, Box *box)
{
	bool isDominated(false);
	vector<Box*>::iterator it;
	/*Stop Criterion
     - all the vector is travelled (but condition 3 may occur before)
     - we are dominated
     - we compare with itself
     */
	for(it = vectBox.begin(); it != vectBox.end() && !isDominated && (*it != box); it++)
	{
		if( isDominatedBetweenTwoBoxes( box , (*it) ) )
		{
			isDominated = true;
		}
	}	
	return isDominated;
}
