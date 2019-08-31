# Characteristic Attribute Organization System (CAOS)

This package provides an interface to use the CAOS algorithm for sequence classification.

In an ideal world, a full phylogenetic analysis would be done on every new sequence found. However, this is often a time-consuming and computer-intensive task. The Characteristic Attribute Organization System (CAOS) is an algorithm to discover descriptive information about *a priori* organized discretized data (*e.g.*, from a phylogenetic analysis). Derived from some of the fundamental tenets from evolutionary biology, rule sets can be generated from data sets that can be used for effecicient and effective classification of novel data elements. It's important to emphasize that CAOS is NOT a tree analysis, instead it is a classification scheme based on a phylogenetic analysis. Based on information (rules) discovered from the phylogenetic analysis that unambiguously distinguish between each node on a tree, CAOS is able to classify novel sequences. Studies have indicated that CAOS-based classification has over a 95% accuracy rate of classification, as determined by where sequences would be classified if a full phylogenetic analysis were to be done using the novel and known sequences.

CAOS.jl is an implementation of the CAOS approach designed to approximate a parsimony-based tree analysis. This tool computes diagnostic character states from phylogenetic trees and uses them for classification of new molecular sequences.

> ##### CAOS Publications  
> Sarkar IN, Thornton JW, Planet PJ, Figurski DH, Schierwater B, and DeSalle R. *An Autotmated Phylogenetic Key for Classifying Homoboxes.* Molecular Genetics and Evolution (2002) 24: 388-399.   
> [![DOI](https://img.shields.io/badge/DOI-10.1016%2FS1055--7903%2802%2900259--2-purple.svg?style=flat-square)](https://doi.org/10.1016/S1055-7903%2802%2900259-2)  
>
> Sarkar IN, Planet PJ, and DeSalle R. *caos software for use in character‐based DNA barcoding*. Molecular Ecology Resources (2008) 8, 1256-1259.   
> [![DOI](https://img.shields.io/badge/DOI-10.1111%2Fj.1755--0998.2008.02235.x-purple.svg?style=flat-square)](https://doi.org/10.1111/j.1755-0998.2008.02235.x)  
