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
* \file Box.hpp
* \brief Class of the \c Box.
* \author Quentin DELMEE & Xavier GANDIBLEUX & Anthony PRZYBYLSKI
* \date 01 January 2017
* \version 1.3
* \copyright GNU General Public License
*
* This class represents an object \c Box. A \c Box is a sub-space of dimension 2 defined in the objective space and characterized by at most two feasible solutions. These solutions correspond to the two lexicographic optimal solutions for the two objective functions when a set of facility opened is considered.
*
*/


#ifndef BOX_H
#define BOX_H

#include <iostream>
#include <cfloat>
#include <math.h>

#include "Data.hpp"

/*! \namespace std
* 
* Using the standard namespace std of the IOstream library of C++.
*/
using namespace std;

/*! \class Box
* \brief Class to represent a \c Box.
*
*  This class represents a \c Box with all its attributes and methods.
*/
class Box
{
public:

    // BOX VARIABLE 
	vector<double> points;/*!< A vector of double which represents the consecutive feasible point currently calculated */
	vector<bool> edges ;/*!< A vector of boolean which defines if there is an non-dominated edge between two consecutive points or not */
	vector<bool> dicho ;/*!< A vector of boolean which defines if there is more dichotomic step to do between two consecutive points or not */
	vector< vector< vector<double> > >clientAllocation ;/*!< A vector of integer which defines the client allocation for a solution */

	// LOWER BOUND VARIABLE 
	vector<int> possiblyOpenFacility ;/*!< A vector of integer which defines non-defined facilities and which will potentially be used in the subsequent children */
	vector<double> pointsLB ;/*!< A vector of double which represents the consecutive feasible point currently calculated for the lower bound set of current \c Box */
	vector<bool> edgesLB ;/*!< A vector of boolean which defines if there is an non-dominated edge between two consecutive points or not for the lower bound set of current \c Box */
	vector<bool> dichoLB ;/*!< A vector of boolean which defines if there is more dichotomic step to do between two consecutive points or not for the lower bound set of current \c Box */

	// UPPER BOUND VARIABLES
	double upperBoundObj1 ; /*!< When modeImprovedUB is active, a double which represents the value w.r.t. the first objective of the upperbound calculated */
	double upperBoundObj2 ; /*!< When modeImprovedUB is active, a double which represents the value w.r.t. the second objective of the upperbound calculated */

    /*!
	*	\brief Default Constructor of the class \c Box.
	*
	*	The default construtor gives a \c Box which anyone facility opened.
	*	\param[in] data : A \c Data object which contains all the values of the instance.
	*/
    Box(Data &data);

    /*!
	*	\brief Constructor of the class \c Box.
	*
	*	This construtor gives a \c Box which a set of facilities opened.
	*	\param[in] data : A \c Data object which contains all the values of the instance.
	*	\param[in] toOpen : A pointer of boolean representing the vector of facility to open in order to construct an object \c Box.
	*/
    Box(Data &data, bool* toOpen);

    /*!
	*	\brief Constructor of the class \c Box.
	*
	*	This construtor gives a \c Box which a set of facilities opened w.r.t the current order of facilities.
	*	\param[in] data : A \c Data object which contains all the values of the instance.
	*	\param[in] toOpen : A pointer of boolean representing the vector of facility to open in order to construct an object \c Box.
	*	\param[in] facilitySort : A vector of integer representing the order of facilities.
	*	\param[in] last : An integer representing the last facility opened in facilitySort.
	*/
    Box(Data &data, bool* toOpen, vector<int> facilitySort,int last);

    /*!
	*	\brief Destructor of the class \c Box.
	*/
    ~Box();

    /*!
	*	\brief Getter for the minimum value w.r.t. objective 1.
	*	\return A double as the minimum value w.r.t. objective 1 of this \c Box.
	*/
    double getMinZ1() const;

    /*!
	*	\brief Getter for the minimum value w.r.t. objective 2.
	*	\return A double as the minimum value w.r.t. objective 2 of this \c Box.
	*/
    double getMinZ2() const;

     /*!
	*	\brief Getter for the maximum value w.r.t. objective 1.
	*	\return A double as the maximum value w.r.t. objective 1 of this \c Box.
	*/
    double getMaxZ1() const;

     /*!
	*	\brief Getter for the maximum value w.r.t. objective 2.
	*	\return A double as the maximum value w.r.t. objective 2 of this \c Box.
	*/
    double getMaxZ2() const;

    /*!
	*	\brief Getter for the value of the origin w.r.t. objective 1.
	*	\return A double as the value of the point of origin w.r.t. objective 1 of this \c Box.
	*/
    double getOriginZ1() const;

     /*!
	*	\brief Getter for the value of the origin w.r.t. objective 2.
	*	\return A double as the value of the point of origin w.r.t. objective 2 of this \c Box.
	*/
    double getOriginZ2() const;
    /*!
	*	\brief Getter for the value of the origin w.r.t. objective 1.
	*	\return A double as the value of the point of origin w.r.t. objective 1 of this \c Box.
	*/
    double getLBOriginZ1() const;

     /*!
	*	\brief Getter for the value of the origin w.r.t. objective 2.
	*	\return A double as the value of the point of origin w.r.t. objective 2 of this \c Box.
	*/
    double getLBOriginZ2() const;

    /*!
	*	\brief Getter for the id.
	*	\return A string as the sequence of 1 and 0 representing the combination of facility of this \c Box.
	*/
    string getId() const;

    /*!
	*	\brief method to know if a customer is assigned or not.
	*	\param[in] cust : A customer.
	*	\return A boolean which value is TRUE if the customer is assigned to any facility.
	*/
    bool isAssigned(int cust) const;

    /*!
	*	\brief method to know if a facility is opened or not.
	*	\param[in] cust : A facility.
	*	\return A boolean which value is TRUE if the facility is opened.
	*/
    bool isOpened(int fac) const;

    /*!
	*	\brief Getter for the number of customers nonaffected.
	*	\return An int as the number of customers which are not affected to a facility.
	*/
    int getnbCustomerNotAffected() const;

    /*!
	*	\brief Getter for the number of facilities opened.
	*	\return An int as the number of facilities which are opened (set to 1).
	*/
    int getNbFacilityOpen() const;

    /*!
	*	\brief Getter for the number of Weighted Sum.
	*	\return A boolean if this \c Box gets a remaining iteration of weigthed sum method.
	*/
    bool getHasMoreStepWS() const;

    /*!
	*	\brief Getter for the number of Weighted Sum.
	*	\return A boolean if this \c Box gets a remaining iteration of weigthed sum method.
	*/
    bool getHasMoreStepLB() const;
    /*!
	*	\brief Getter for the existance of edges.
	*	\return A boolean if this \c Box gets edges.
	*/
    bool getHasEdge() const ;

    /*!
	*	\brief Setter for the id of this \c Box.
	*	\param[in] s : A string which represents the id (combination of facility) of this \c Box.
	*/
    void setId(string s);

    /*!
	*	\brief Setter for the remaining weighted sum method.
	*	\param[in] b : A boolean which value is TRUE if this \c Box has a remaining iteration of weighted sum method.
	*/
    void setHasMoreStepWS(bool b);

    /*!
	*	\brief Setter for the remaining weighted sum method.
	*	\param[in] b : A boolean which value is TRUE if this \c Box has a remaining iteration of weighted sum method.
	*/
    void setHasMoreStepLB(bool b);

    /*!
	*	\brief Setter for the existance of edges in this \c Box.
	*	\param[in] b : A boolean which value is TRUE if this \c Box has edges.
	*/
    void setHasEdge(bool b);
    
    /*!
	*	\brief A method to expand a box, which means attempting to allocate all customers to facilities.
	*/
    void computeBox(Data &data);
    /*!
	*	\brief A method that opens a facility in this \c Box, by adding all the location cost of the two objectives.
	*	\param[in] fac : A facility to open.
	*/
    void openFacility(Data &data, int fac);

private:
    string id_;/*!< A string which represents the id of this \c Box */
	int nbFacilityOpen_;/*!< An int which represents the number of facility opened*/

    bool *isAssigned_;/*!< A boolean which represents the vector of customer assigned or not */
    bool *facility_;/*!< A boolean which represents the vector of facility opened or not */
    bool hasMoreStepWS_;/*!< A boolean which represents if this \c Box has a remaining iteration of weighted sum method or not */
	bool hasMoreStepLB_ ;/*!< A boolean which represents if this \c Box has a remaining iteration of weighted sum method for its lower bound set or not */
	bool hasEdge_ ;/*!< A boolean which represents if this \c Box has edges or not */
    
    int nbCustomerNotAffected_; /*!< An integer which represents the number of customer not affected of this \c Box*/

    double LB_origin_Z1 ;
    double LB_origin_Z2 ;

    double originZ1_;/*!< A double which represents the value of the origin of this \c Box w.r.t. objective 1 */
    double originZ2_;/*!< A double which represents the value of the origin of this \c Box w.r.t. objective 2 */

};

/*!
* 	\relates Box
*	\brief Method of comparison between two boxes.
*
*	A method to compare two \c Boxes using the bounds minZ1_, minZ2_, maxZ1_, maxZ2_ of each \c Boxes.
*	\param[in] box1 : A \c Box to compare.
*	\param[in] box2 : A \c Box to compare.
*	\return A boolean which value is TRUE if the box1 is dominated by the box2. 
*/
bool isDominatedBetweenTwoBoxes(Box *box1, Box *box2);

/*!
* 	\relates Box
*	\brief Method of comparison between two boxes.
*
*	A method to compare two \c Boxes using the bounds minZ1_, minZ2_, maxZ1_, maxZ2_, originZ1_ and originZ2_.
*	\param[in] box1 : A \c Box to compare.
*	\param[in] box2 : A \c Box to compare.
*	\return A boolean which value is TRUE if the origin of the box1 is dominated by the box2. 
*/
bool isDominatedBetweenOrigins(Box *box1, Box *box2);

/*!
* 	\relates Box
*	\brief Method of comparison between the lower bound set of a \c Box and an other \c Box.
*
*	A method to compare two \c Boxes using the bounds minZ1_, minZ2_, maxZ1_, maxZ2_, originZ1_ and originZ2_.
*	\param[in] box1 : A \c Box to compare.
*	\param[in] box2 : A \c Box to compare.
*	\return A boolean which value is TRUE if the origin of the box1 is dominated by the box2. 
*/
bool isDominatedBetweenLowerBound(Box *box1, Box *box2, Data &data);

/*!
* 	\relates Box
*	\brief Method to filter a vector of \c Boxes
*
*	A method to filter and delete \c Box in a vector of \c Boxes by comparing each other. 
*	\param[in] vectBox : A vector of \c Boxes.
*/
void filterDominatedBoxes(vector<Box*> &vectBox);

/*!
* 	\relates Box
*	\brief Method of comparison between a \c Box and a vector of \c Boxes.
*
*	\param[in] vectBox : A vector of \c Boxes to compare.
*	\param[in] box : A \c Box to compare.
*	\return A boolean which value is TRUE if \c Box box is dominated by one of the \c Box of the vector vectBox. 
*/
bool isDominatedByItsOrigin(vector<Box*> &vectBox, Box *box);

/*!
* 	\relates Box
*	\brief Method of comparison between the lower bound set of a \c Box and a vector of \c Boxes.
*
*	\param[in] vectBox : A vector of \c Boxes to compare.
*	\param[in] box : A \c Box with its lower bound set to compare.
*	\return A boolean which value is TRUE if the lower bound set of \c Box is dominated by one of the \c Box of the vector vectBox. 
*/
bool isDominatedByItsLowerBound(vector<Box*> &vectBox, Box *box, Data &data);

/*!
* 	\relates Box
*	\brief Method of comparison between a \c Box and a vector of \c Boxes.
*
*	\param[in] vectBox : A vector of \c Boxes to compare.
*	\param[in] box : A \c Box to compare.
*	\return A boolean which value is TRUE if one of the \c Box of the vector vectBox is dominated by the \c Box box. 
*/
bool isDominatedByItsBox(vector<Box*> &vectBox, Box *box);

#endif
