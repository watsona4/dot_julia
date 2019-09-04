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
 
#include "Data.hpp"

Data::Data()
{
	modeVerbose = false;

	modeLowerBound = false;

	modeFullDicho = false;

	modeDichoBnB = false;

	modeImprovedLB = false ;

	modeImprovedUB = false ;

	modeParam = false ;

	modeSortFacility = false ;

	MaxDeepNess = 0 ;

	BoundDeepNess = 0 ;

	optimalAllocationObj1 = 0.0;

	optimalAllocationObj2 = 0.0;

	epsilon = 10E-9 ;

	customerSort = vector< vector< vector<int> > >() ;

	facilitySort = vector<int>() ;
}

Data::~Data()
{
	for(unsigned int i = 0; i < getnbCustomer(); ++i)
	{
		allocationObj1Cost_[i].clear() ;
		allocationObj2Cost_[i].clear() ;
	}
	allocationObj1Cost_.clear() ;
	allocationObj2Cost_.clear() ;

	locationObj1Cost_.clear() ;
	locationObj2Cost_.clear() ;

	customerSort.clear() ;
	facilitySort.clear() ;
}

void Data::Init(unsigned int nbFacility, unsigned int nbCustomer, string name)
{
	nbCustomer_ = nbCustomer ;
	nbFacility_ = nbFacility ;

	allocationObj1Cost_ = vector< vector<double> >(nbCustomer,vector<double>(nbFacility,0)) ;
	allocationObj2Cost_ = vector< vector<double> >(nbCustomer,vector<double>(nbFacility,0)) ;

	locationObj1Cost_ = vector<double>(nbFacility,0);
	locationObj2Cost_ = vector<double>(nbFacility,0);
	
	fileName_ = name;
}

unsigned int Data::getnbFacility() const
{
	return nbFacility_ ;
}

unsigned int Data::getnbCustomer() const
{
	return nbCustomer_ ;
}

double Data::getAllocationObj1Cost(int cust, int fac) const
{
	return allocationObj1Cost_[cust][fac];
}

double Data::getAllocationObj2Cost(int cust, int fac) const
{
	return allocationObj2Cost_[cust][fac];
}

double Data::getLocationObj1Cost(int fac) const
{
    return locationObj1Cost_[fac];
}

double Data::getLocationObj2Cost(int fac) const
{
    return locationObj2Cost_[fac];
}

string Data::getFileName() const
{
	return fileName_;
}

void Data::setAllocationObj1Cost(int cust,int fac, double val)
{
	allocationObj1Cost_[cust][fac] = val;
}

void Data::setAllocationObj2Cost(int cust,int fac, double val)
{
	allocationObj2Cost_[cust][fac] = val;
}

void Data::setLocationObj1Cost(int fac, double val)
{
    locationObj1Cost_[fac] = val;
}

void Data::setLocationObj2Cost(int fac, double val)
{
    locationObj2Cost_[fac] = val;
}

void Data::setFileName(string name)
{
	fileName_ = name;
}
