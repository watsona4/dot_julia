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

#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <vector>
#include <map>
#include <list>
#include <iostream>
#include <cmath>
#include <time.h> 

#include "Data.hpp"
#include "Box.hpp"
#include "Dualoc.hpp"

/*! \namespace std
* 
* Using the standard namespace std of the IOstream library of C++.
*/
using namespace std;

/*!
*	\defgroup paving Methods of Paving
*/

/*!
*	\fn long int createBox(vector<Box*> &vectorBox, Data &data)
*	\ingroup paving
*	\brief This method computes all the initial \c Boxes of our algorithm.
*
*	This method computes all the \c Boxes in whichones the Label Setting algorithm will runs. This method uses a smart Branch&Bound (Breadth First Search, splitting on facility setup variables) to compute all the feasible and important \c Boxes. Useless \c Boxes are avoided by the Branch&Bound.
*	\param[in,out] vectorBox : A vector of \c Box, empty a the beginning, and containing all the \c Boxes at the end of this method.
*	\param[in] openedFacility : A vector of string representing the boxes calculated if ImprovedUB mode is on.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*	\return A long int which represents the number of \c Boxes computed by the method.
*/
long int createBox(vector<Box*> &vectorBox, vector<string> openedFacility, Data &data);


/*!
*	\fn addChildren(Box *boxMother, vector<Box*> &vBox)
*	\ingroup paving
*	\brief This method adds children of a \c Box into a vector of \c Boxes.
*
*	This method computes all the children \c Boxes of a \c Box into a vector of \c Boxes. A children is defined by a combination of facility in which indices have not yet been opened.
*	\param[in] boxMother : A \c Box for which ones wants to add children \c Boxes.
*	\param[in,out] vBox : A vector of \c Box in whichone ones add all the children \c Boxes at the end (enqueue at the end of the vector).
*/
void addChildren(Box *boxMother, vector<Box*> &vBox, Data &data);

/*!
*	\fn computeUpperBound(vector<Box*> &vectorBox, vector<bool> &dichoSearch, Data &data)
*	\ingroup paving
*	\brief Compute the weighted sum method to calculate supported point of the problem.
*
*	This method computes a weighted sum for all pair of point in the vector of \c Boxes. It updates the vector of boolean if the new points found are better w.r.t. the pair used. It correspond to one step of the dichotomich search.
*	\param[in,out] vectorBox : A vector of \c Box in which we can find all current supported point of the problem that we calculated and where we will add the new points.
*	\param[in,out] dichoSearch : A vector representing if it is interesting or not to apply a weighted sum between two points. When a new point is added to vectorBox, it is updated considering that a priori, the new pairs of points generated are interesting.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*/
void computeUpperBound(vector<Box*> &vectorBox, vector<bool> &dichoSearch, Data &data);

/*!
*	\fn computeLowerBound(vector<Box*> &vectorBox, Data &data)
*	\ingroup paving
*	\brief Compute the weighted sum method to calculate supported point of the problem.
*
*	This method computes a weighted sum for all pair of point in the vector of \c Boxes. It updates the vector of boolean if the new points found are better w.r.t. the pair used. It correspond to one step of the dichotomich search.
*	\param[in,out] vectorBox : A vector of \c Box in which we can find all current supported point of the problem that we calculated and where we will add the new points.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*/
void computeLowerBound(Box *box, Data &data);

/*!
*	\fn filter(vector<Box*> &vectorBox)
*	\ingroup paving
*	\brief This method filters all the \c Boxes of a vector of \c Box.
*
*	This method filters \c Boxes by eliminating all \c Box that are dominated by an other one.
*	\param[in,out] vectorBox : A vector of \c Boxes we need to filter.
*/
void filter(vector<Box*> &vectorBox);

/*!
*	\defgroup resolution Methods of Resolution
*/

/*!
*	\fn boxFiltering(vector<Box*> &vectorBox, Data &data)
*	\ingroup resolution
*	\brief This method filters all the \c Boxes of a vector of \c Box while computing their non-dominated points.
*
*	One step of this method is to compute a weighted sum on all pair of point on all \c Boxes then to filter all the boxes with those new points. This methods repeat those two step as long as we have not calculated the non-dominated points of each \c Boxes.
*	\param[in,out] vectorBox : A vector of \c Box in which we can find all current supported point of the problem that we calculated and where we will add the new points.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*/
void boxFiltering(vector<Box*> &vectorBox, Data &data);

/*!
*	\fn weightedSumOneStep(Box* box, Data &data)
*	\ingroup resolution
*	\brief Compute the weighted sum on all pair of points of a \c Box.
*
*	This method computes a weighted sum on all pair of point of a \c Box if the edge is not dominated.
*	\param[in,out] box : A box in which we compute the weighted sum method on all pair of points.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*/
void weightedSumOneStep(Box* box, Data &data);

/*!
*	\fn weightedSumOneStepLB(Box* box, Data &data)
*	\ingroup resolution paving
*	\brief Compute the weighted sum on all pair of points in the lower bound set of a \c Box.
*
*	This method computes a weighted sum on all pair of point in the lower bound set of a \c Box if the corresponding lower bound edge is not dominated.
*	\param[in,out] box : A box in which we compute the weighted sum method on all pair of points of the lower bound.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*/
void weightedSumOneStepLB(Box* box, Data &data);

/*!
*	\fn weightedSumOneStepAll(vector<Box*> &vectorBox, Data &data)
*	\ingroup resolution paving
*	\brief Compute the weighted sum on all pair of points of all \c Boxes of a vector of \c Box.
*
*	This method compute a weighted sum on all pair of point of all \c Boxes of a vector of \c Box if the corresponding edge is not already dominated.
*	\param[in,out] vectorBox : A vector of \c Box in which, for all \c Boxes, we compute the weighted sum method on all pair of points.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*	\param[in,out] MoreStep : A boolean which value is true that we will update to false if there is no more weighted sum to do on any \c Box in the vector.
*/
void weightedSumOneStepAll(vector<Box*> &vectorBox, Data &data, bool &MoreStep);

/*!
*	\fn parametricSearch(Box* box, Data &data)
*	\ingroup resolution
*	\brief Compute the supported solution of the allocation subproblem defined by the \c Box
*
*	This method computes the supported solution of the allocation subproblem defined by the set of facilities of this \c Box. This method uses a specific algorithm as proposed by Fernandez.
*	\param[in,out] box : A box in which we compute the supported solutions.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*/
void parametricSearch(Box* box, Data &data);

/*!
*	\fn parametricSearchUB(Box* box, Data &data)
*	\ingroup resolution paving
*	\brief Compute the supported solution of the allocation subproblem defined by the \c Box calculated in the Upper Bound Set.
*
*	This method computes the supported solution of the allocation subproblem defined by the set of facilities of this \c Box. This method uses a specific algorithm as proposed by Fernandez. It is specifically defined for the \c Box obtained with the upper bound set.
*	\param[in,out] box : A box in which we compute the supported solutions.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*/
void parametricSearchUB(Box* box, Data &data);

/*!
*	\fn parametricSearchLB(Box* box, Data &data)
*	\ingroup resolution paving
*	\brief Computes the supported solution of the allocation subproblem defined by the \c Box and its potentially opened facilities
*
*	This method computes the supported solution of the allocation subproblem defined by the set of facilities of this \c Box and the set of potentially opened facilities. This method uses a specific algorithm as proposed by Fernandez. The solutions obtained this way are a lower bound set for the current \c Box and all its children.
*	\param[in,out] box : A box in which we compute the supported solutions of the lower bound set.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*/
void parametricSearchLB(Box* box, Data &data);

/*!
*	\fn postProcessing(Box* box, Data &data)
*	\ingroup resolution
*	\brief Compute the allocation matrices of all client for \c Box box.
*
*	This method computes the allocation matrices of all client for \c Box box for every point in the box.
*	\param[in,out] box : A box in which we compute the allocation matrices solutions.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*/
void postProcessing(Box* box, Data &data);

/*!
*	\fn isPointDominated(Box *box1, Box *box2)
*	\ingroup resolution
*	\brief Verifies if a point is dominated or not an other point.
*
*	This methods compares the relative position of the two point and return if box1 is dominated by box2.
*	\param[in] box1 : A \c Box which is a point.
*	\param[in] box2 : A \c Box which is a point.
*	\return A boolean which represents if box1 is dominated by box2.
*/
bool isPointDominated(Box *box1, Box *box2);

/*!
*	\fn dominancePointEdge(Box *box1, Box *box2)
*	\ingroup resolution
*	\brief Verifies if a point is dominated or not an other point.
*
*	This methods compares the relative position of the two point and return if box1 is dominated by box2.
*	\param[in] box1 : A \c Box which is a point.
*	\param[in] box2 : A \c Box composed of points and edges.
*	\return An integer which represents if box1 is dominated by box2 or box2 is partially dominated by box1 or box2 is totally dominated by box1.
*/
int dominancePointEdge(Box *box1, Box *box2, Data &data);

/*!
*	\fn dominanceEdgeEdge(Box *box1, Box *box2)
*	\ingroup resolution
*	\brief Verifies and Compares the dominance between all the edges of two \c Boxes.
*
*	This methods compares all the edges of the two boxes to eliminates all dominated parts.
*	\param[in] box1 : A \c Box composed of points and edges.
*	\param[in] box2 : A \c Box composed of points and edges.
*	\return An integer which represents if box1 is totally dominated by box2 or box2 is totally dominated by box1 or no box are totally dominated.
*/
int dominanceEdgeEdge(Box *box1, Box *box2, Data &data);

/*!
*	\fn prefiltering(Box* box);
*	\ingroup resolution
*	\brief Filters the consecutive dominated edges of a \c Box.
*
*	This method filters all consecutive edges of a \c Box by removing corresponding edges and points. It also verifies that no edges at the beggining or end of the box are dominated and if so, it eliminates them.
*	\param[in,out] box : A \c Box in which we filter consecutive dominated edges.
*/
void prefiltering(Box* box, Data &data);

/*!
*	\fn edgefiltering(vector<Box*> &vectorBox);
*	\ingroup resolution
*	\brief Filters the edges and points of all \c Boxes in the vector of \c Box.
*
*	This method compares all boxes to each other and filter all dominated points and edges from those boxes. The resulting edges and points are all non-dominated thus we obtain the exact solution of the problem.
*	\param[in,out] vectorBox : A vector of \c Boxes which will be filtered.
*/
void edgefiltering(vector<Box*> &vectorBox, Data &data);

/*!
*	\defgroup others Others Methods
*/

/*!
*	\fn computeCorrelation(Data &data)
*	\ingroup others
*	\brief This method computes the correlation.
*
*	This method computes the correlation between the two objectives w.r.t. to the \c Data.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*	\return A double representing the correlation between the two objectives.
*/
double computeCorrelation(Data &data);

/*!
*	\fn quicksortedge(vector<Box*> &toSort, int begin, int end)
*	\ingroup others
*	\brief Sorts all the box considering their first point.
*
*	This method lexicographically sorts all the box considering their first point. It allows us some assumption we use in the filtering of boxes and edges.
*	\param[in,out] vectorBox : A vector of \c Box that will be sorted.
*	\param[in] begin : An integer which represent where we begin the sort.
*	\param[in] end : An integer which represent where we end the sort.
*/
void quicksortedge(vector<Box*> &toSort, int begin, int end);

/*!
*	\fn quicksortCusto(vector<Box*> &toSort, int begin, int end)
*	\ingroup others
*	\brief Sorts all the facilities considering the preference of a customer.
*
*	This method lexicographically sorts all the facilities considering the preference of a customer. It allows the algorithm to speed up the research of prefered facilities from customer.
*	\param[in,out] toHelp : A vector of double with the affilition cost of one objective to help sort the facilities.
*	\param[in,out] lexHelp : A vector of double with the affiliation cost of the other objective to help sort the facilities.
*	\param[in,out] toSort : A vector of int corresponding to the order of facilities.
*	\param[in] begin : An integer which represent where we begin the sort.
*	\param[in] end : An integer which represent where we end the sort.
*/
void quicksortCusto(vector<double> &toHelp, vector<double> &lexHelp, vector<int> &toSort, int begin, int end);

/*!
*	\fn quicksortFacility(vector<Box*> &toSort, int begin, int end)
*	\ingroup others
*	\brief Sorts all the facilities considering their interest value.
*
*	This method sorts all the facilities considering an interest value we heuristically choosed. It could be further improved with better and cleverer interest value.
*	\param[in,out] toSort: A vector of int representing the order of the facilities.
*	\param[in] begin : An integer which represent where we begin the sort.
*	\param[in] end : An integer which represent where we end the sort.
*/
void quicksortFacility(vector<double> &toSort, int begin, int end);

/*!
*	\fn isAlreadyIn(vector<string> openedFacility, Box* box)
*	\ingroup others
*	\brief Verifies if a \c Box has already been opened with the upper bound set.
*
*	This method verifies in the vector of string if a \c Box has already been computed while computing the upper bound set. If it has been computed, its ID will be found in the vector of string.
*	\param[in] openedFacility : A vector of string which represent all the IDs of box already opened during the computation of the upper bound set.
*	\param[in] box : A \c Box we verify the presence in the vector of string.
*/
bool isAlreadyIn(vector<string> openedFacility, Box* box);

/*!
*	\fn sortFacility(Data &data, vector<double> clientfacilitycost1,vector<double> clientfacilitycost2)
*	\ingroup others
*	\brief Computes the interest value of each facility.
*
*	This method computes the interest value of all facility so we can sort them later by increasing value.
*	\param[in] data : A \c Data object which contains all the values of the instance.
*	\param[in] clientfacilitycost1 : A vector of double which represent the total cost of assigning all client to one facility w.r.t. first objective.
*	\param[in] clientfacilitycost2 : A vector of double which represent the total cost of assigning all client to one facility w.r.t. second objective.
*/
void sortFacility(Data &data, vector<double> clientfacilitycost1,vector<double> clientfacilitycost2);

/*!
*	\fn crono_start(timeval &start_utime)
*	\ingroup others
*	\brief Initialize the timeval at current starting time.
*
*	This method update the timeval with current time.
*	\param[in] start_utime : A timeval we want to initialize at starting time.
*/
void crono_start(clock_t &start_utime);

/*!
*	\fn crono_stop(timeval &stop_utime)
*	\ingroup others
*	\brief Initialize the timeval at current stoping time.
*
*	This method update the timeval with current time.
*	\param[in] stop_utime : A timeval we want to initialize at stoping time.
*/
void crono_stop(clock_t &stop_utime);

/*!
*	\fn crono_ms(timeval start_utime, timeval stop_utime)
*	\ingroup others
*	\brief Computes the difference in milliseconds between starting and stoping time.
*
*	This method computes the differences in milliseconds between the starting time and stoping time and return the result.
*	\param[in] start_utime : A timeval with the value of starting time.
*	\param[in] stop_utime : A timeval with the value of stoping time.
*	\return a double which represent the difference between starting and stoping time in milliseconds.
*/
double crono_ms(clock_t start_utime, clock_t stop_utime);

/*!
*	\fn quicksortFacilityOBJ1(vector<Box*> &toSort, int begin, int end)
*	\ingroup others
*	\brief Sorts all the facilities considering the objective 1.
*
*	This method sorts all the facilities considering their objective 1 value.
*	\param[in,out] toSort: A vector of double representing the cost of the facilities.
*	\param[in] begin : An integer which represent where we begin the sort.
*	\param[in] end : An integer which represent where we end the sort.
*/
void quicksortFacilityOBJ1(vector<double> &toSort, int begin, int end);

/*!
*	\fn quicksortFacilityOBJ2(vector<Box*> &toSort, int begin, int end)
*	\ingroup others
*	\brief Sorts all the facilities considering the objective 2.
*
*	This method sorts all the facilities considering their objective 2 value.
*	\param[in,out] toSort: A vector of double representing the cost of the facilities.
*	\param[in] begin : An integer which represent where we begin the sort.
*	\param[in] end : An integer which represent where we end the sort.
*/
void quicksortFacilityOBJ2(vector<double> &toSort, int begin, int end);

#endif
