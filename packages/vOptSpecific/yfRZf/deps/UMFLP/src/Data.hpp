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
* \file Data.hpp
* \brief Class of the \c Data.
* \author Quentin DELMEE & Xavier GANDIBLEUX & Anthony PRZYBYLSKI
* \date 01 January 2017
* \version 1.3
* \copyright GNU General Public License
*
* This class will contains all the values, parameters of the instance. Especially, it contains the allocation cost between customers and facilities.
*
*/

#ifndef DATA_H
#define DATA_H

#include <iostream>
#include <vector>
#include <cfloat>

/*! \namespace std
* 
* Using the standard namespace std of the IOstream library of C++.
*/
using namespace std;

/*! \class Data
* \brief Class to represent a \c Data.
*
*  This class represents a \c Data with all its attributes, parameters.
*/
class Data
{
public:

	/*!
	*	\defgroup global Global Variables
	*/

    /*!
	*	\var modeVerbose
	*	\ingroup global
	*	\brief Variable representing the Verbose mode.
	*
	*	This boolean gets the value TRUE if the verbose mode is on, and FALSE otherwise. If the verbose mode is on, the software prints detailled information while running.
	*/
	bool modeVerbose ;

	/*!
	*	\var modeLowerBound
	*	\ingroup global
	*	\brief Variable representing the Lower Bound mode.
	*
	*	This boolean gets the value TRUE if the lower bound mode is on, and FALSE otherwise. If the lower bound mode is on, the paving method will calculate lower bound during the branch and bound.
	*/
	bool modeLowerBound ;

	/*!
	*	\var modeFullDicho
	*	\ingroup global
	*	\brief Variable representing the FullDicho mode.
	*
	*	This boolean gets the value TRUE if the fulldicho mode is on, and FALSE otherwise. If the fulldicho mode is on, we will perform complete dichotomic search during the upper bound phase.
	*/
	bool modeFullDicho ;

	/*!
	*	\var modeDichoBnB
	*	\ingroup global
	*	\brief Variable representing the DichoBnB mode.
	*
	*	This boolean gets the value TRUE if the dichobnb mode is on, and FALSE otherwise. If the dichobnb mode is on, we will perform partial dichotomic search during the branch and bound to improve the data of the paving.
	*/
	bool modeDichoBnB ;

	/*!
	*	\var modeImprovedLB
	*	\ingroup global
	*	\brief Variable representing the ImprovedLB mode.
	*
	*	This boolean gets the value TRUE if the ImprovedLB mode is on, and FALSE otherwise. If the ImprovedLB mode is on, the paving method will calculate an improved lower bound during the branch and bound.
	*/
	bool modeImprovedLB ;

	/*!
	*	\var modeImprovedUB
	*	\ingroup global
	*	\brief Variable representing the ImprovedUB mode.
	*
	*	This boolean gets the value TRUE if the ImprovedUB mode is on, and FALSE otherwise. If the ImprovedUB mode is on, the paving method will calculate an upper bound before launching the branch and bound.
	*/
	bool modeImprovedUB ;

	/*!
	*	\var modeParam
	*	\ingroup global
	*	\brief Variable representing the Param mode.
	*
	*	This boolean gets the value TRUE if the Param mode is on, and FALSE otherwise. If the Param mode is on, the paving method will calculate the local non-dominated point of each triangle using a parametric search otherwise it will use a dichotomic search.
	*/
	bool modeParam ;

	/*!
	*	\var modeSortFacility
	*	\ingroup global
	*	\brief Variable representing the SortFacility mode.
	*
	*	This boolean gets the value TRUE if the SortFacility mode is on, and FALSE otherwise. If the SortFacility mode is on, the paving method will sort the facility considering an interest function of each facility.
	*/
	bool modeSortFacility ;

	/*!
	*	\var MaxDeepNess
	*	\ingroup global
	*	\brief Variable representing the Maximum Deepness.
	*
	*	This int represents the maximum deepness we obtain during the branch and bound. It is at most the bound we obtained.
	*/
	int MaxDeepNess ;

	/*!
	*	\var BoundDeepNess
	*	\ingroup global
	*	\brief Variable representing the Bound on Deepness.
	*
	*	This int represents the maximum deepness we could obtain during the branch and bound, computed with bound on the data.
	*/
	int BoundDeepNess ;

	/*!
	*	\var optimalAllocationObj1
	*	\ingroup global
	*	\brief Variable representing the optimal allocation w.r.t. Obj1.
	*
	*	This double variable is computed at the beggining and represend the best allocation we can obtain w.r.t. objective 1. It allows us to compute efficiently and quickly lower bound.
	*/
	double optimalAllocationObj1 ;

	/*!
	*	\var optimalAllocationObj2
	*	\ingroup global
	*	\brief Variable representing the optimal allocation w.r.t. Obj2.
	*
	*	This double variable is computed at the beggining and represend the best allocation we can obtain w.r.t. objective 2. It allows us to compute efficiently and quickly lower bound.
	*/

	double optimalAllocationObj2 ;

	/*!
	*	\var customerSort
	*	\ingroup global
	*	\brief Variable representing preferred facilities for each customer.
	*
	*	This three dimensional vector of integet represents that each customer has two vector corresponding to its preferences w.r.t. objective 1 and objective 2. The facilities are sorted by decreasing preference.
	*/
	vector< vector< vector<int> > > customerSort ;

	/*!
	*	\var facilitySort
	*	\ingroup global
	*	\brief Variable representing the sort of the facilities.
	*
	*	This vector of integer represents the preference of facilities based on SortFacility mode. If SortFacility mode is on, the facility will be sort by increasing interest value otherwise it will sort considering the \c Parser.
	*/
	vector<int> facilitySort ;




	double epsilon ;

	
	Data();

	/*!
	*	\brief Destructor of the class \c Data.
	*/
    ~Data();


    /*!
	*	\brief Constructor of the class \c Data.
	*
	*	\param[in] nbFacility : The number of facility of the instance.
	*	\param[in] nbCustomer : The number of customer of the instance.
	*	\param[in] name : The name of the instance.
	*/
    void Init(unsigned int nbFacility, unsigned int nbCustomer, string name);
    /*!
	*	\brief Getter for the number of facilities.
	*	\return An unsigned int as the number of facilities of the instance.
	*/
    unsigned int getnbFacility() const;
	/*!
	*	\brief Getter for the number of customers.
	*	\return An unsigned int as the number of customers of the instance.
	*/
    unsigned int getnbCustomer() const;
	/*!
	*	\brief Getter for the allocation cost w.r.t. objective 1 between a Customer and a Facility.
	*	\param[in] cust : The index of the Customer.
	*	\param[in] fac : The index of the Facility.
	*	\return A double as the value of the allocation cost w.r.t. objective 1 for the Customer cust to the Facility fac.
	*/
    double getAllocationObj1Cost(int cust, int fac) const;
    /*!
	*	\brief Getter for the allocation cost w.r.t. objective 2 between a Customer and a Facility.
	*	\param[in] cust : The index of the Customer.
	*	\param[in] fac : The index of the Facility.
	*	\return A double as the value of the allocation cost w.r.t. objective 2 for the customer cust to the facility fac.
	*/
    double getAllocationObj2Cost(int cust, int fac) const;
    /*!
	*	\brief Getter for the location cost w.r.t. objective 1.
	*	\return A double as the location cost w.r.t. objective 1 of this Facility.
	*/
    double getLocationObj1Cost(int fac) const;
    /*!
	*	\brief Getter for the location cost w.r.t. objective 2.
	*	\return A double as the location cost w.r.t. objective 2 of this Facility.
	*/
    double getLocationObj2Cost(int fac) const;
    


    /*!
	*	\brief Getter for the name of the instance.
	*	\return A string which represents the name of the instance.
	*/
    string getFileName() const;
    
    /*!
	*	\brief Setter for the allocation cost w.r.t. objective 1 between a Customer and a Facility.
	*	\param[in] cust : The index of the Customer.
	*	\param[in] fac : The index of the Facility.
	*	\param[in] val : The value of the allocation cost of the customer cust to the facility fac w.r.t. objective 1.
	*/
    void setAllocationObj1Cost(int cust,int fac, double val);
    /*!
	*	\brief Setter for the allocation cost w.r.t. objective 2 between a Customer and a Facility.
	*	\param[in] cust : The index of the Customer.
	*	\param[in] fac : The index of the Facility.
	*	\param[in] val : The value of the allocation cost of the customer cust to the facility fac w.r.t. objective 2.
	*/
    void setAllocationObj2Cost(int cust, int fac, double val);
        /*!
	*	\brief Setter for the location cost w.r.t. objective 1.
	*	\param[in] val : A double which represents the value of the location cost of this Facility w.r.t. objective 1.
	*/
    void setLocationObj1Cost(int fac, double val);
    /*!
	*	\brief Setter for the location cost w.r.t. objective 2.
	*	\param[in] val : A double which represents the value of the location cost of this Facility w.r.t. objective 2.
	*/
    void setLocationObj2Cost(int fac, double val);

    /*!
	*	\brief Setter for the name of the instance.
	*	\param[in] name : A string which represents the name of the instance.
	*/
    void setFileName(string name);
    
private:
    
    string fileName_;/*!< A string which represents the name of the instance */

    int nbFacility_ ;/*!< An int which represent the number of facility of the instance */
    int nbCustomer_ ;/*!< An int which represent the number of customer of the instance */

    vector< vector<double> > allocationObj1Cost_;/*!< A vector of double (2 dimensions) which represents the matrix of allocation cost w.r.t. objective 1 */
    vector< vector<double> > allocationObj2Cost_;/*!< A vector of double (2 dimensions) which represents the matrix of allocation cost w.r.t. objective 2 */

    vector<double> locationObj1Cost_;/*!< A vector of double which represents the values of the location costs of the facilities w.r.t. objective 1 */
    vector<double> locationObj2Cost_;/*!< A vector of double which represents the values of the location costs of the facilities w.r.t. objective 2 */
};

#endif
