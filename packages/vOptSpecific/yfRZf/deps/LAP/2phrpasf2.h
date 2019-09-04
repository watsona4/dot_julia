/*!
* \file 2phrpasf2.h
* \brief Solver bi-objective LAP
*
*/

#ifndef PHRPAS2_H
#define PHRPAS2_H

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <time.h>
#include <sys/time.h>
#include <sys/resource.h>

#define ncrit 2 /* nombre de criteres */
#define SizeMax 100  /* taille maximum d' une instance */
#define MAXINT 10000000 /* cout tres eleve */
#define BIGNUMBER 9000000 /* grand nombre */
#define INFINI 10000000 /* infini */
#define LGLISTE 10000 /* taille maximum d'une liste de solutions */
#define PLISTE 1000 /* taille max d'une pliste de solutions */
#define instanceSolved    0 /* constante utilise pour lire une instance */
#define VERBOSE 0 /* baratin */

/* -----------------------   definition des structures ------------------------------------------------ */


/* Le chrono INTEL (diffrent du PowerPC) */

struct timeval start_utime, stop_utime;

/** \typedef structure indiquant les affectations d'une solution et les valeurs des fonctions objectif */

typedef struct
{
short int X[SizeMax];
short int z[ncrit];
} solution;

/** \typedef tableau de solutions + taille du tableau */

typedef struct
{
solution liste[LGLISTE];
long int lgListe;
} listeSol;

typedef struct
{
solution liste[PLISTE];
long int lgListe;
} pliste;

/** \typedef structure indiquant un arc de depart u et d'arrivee v */

typedef struct
{
short int u;
short int v;
} arc;

typedef struct node
{
arc val;
struct node *suivant;
} listarc;

/*typedef struct
{
listarc *I;
listarc *O;
solution M;
solution N;
int value;
} tas;*/

typedef struct
{
solution *s; //pointeur sur une solution 
int value; //valeur pour la ponderation des objectifs
short int DNI; // dernier noeud impose a gauche pour obtenir cette solution
listarc *I; // liste des arcs interdits pour obtenir cette solution
} tas;

typedef struct
{
short int num; // "vrai" numero du noeud dans le graphe
int nbsuiv; // nb de noeuds suivants
short int suiv[SizeMax]; //"vrai" bumero des noeuds suivants
int cout[SizeMax]; //couts de ces suivants
} noeud;

// void crono_start();

// void crono_stop();

// double crono_ms();

listarc * ajouterliste(arc, listarc *);

listarc * supprimerliste(listarc *);

listarc * copyliste(listarc *,listarc *);

int applistarc(arc A,listarc *);

int apptabarc(arc ,arc *,int);

/** \brief ajoute un element dans un tableau
  *
  * \fn void ajouter(int *t,int *taille,int n)
  * \param int *t
  * \param int *taille
  * \param int n
  * \retval void
*/
void ajouter(int *,int *,int );

/** \brief supprime un element dans un tableau
  *
  * \fn void supprimer(int *t,int *taille,int n)
  * \param int *t
  * \param int *taille
  * \param int n
  * \retval void
*/
void supprimer(int *,int *,int );

void supprimersuiv(noeud *,int);

/** \brief supprime un element dans un tableau en preservant l'ordre des elements
  *
  * \fn void supprimerordre(int *t,int *taille,int n)
  * \param int *t
  * \param int *taille
  * \param int n
  * \retval void
*/

void supprimerordre(int *,int *,int );

/** \brief supprime un element n d'une ligne k d'un tableau
  *
  * \fn void supprimer2(short int t[SizeMax][SizeMax],short int *taille,short int k,short int n)
  * \param short int t[SizeMax][SizeMax]
  * \param short int *taille
  * \param short int k
  * \param short int n
  * \retval void
*/
void supprimer2(short int t[SizeMax][SizeMax],short int *,short int ,short int );

/** \brief verifie l'appartenance d'un element dans un tableau d'entiers, si oui retourne 1, sinon 0
  *
  * \fn int app(int *t,int taille,int n)
  * \param int *t
  * \param int taille
  * \param int n
  * \retval int
*/
int app(int *,int ,int );

/** \brief verifie l'appartenance d'un element dans un tableau de short
  *
  * \fn int appsh(short int *t,int taille,short int n)
  * \param short int *t
  * \param int taille
  * \short int n
  * \retval int 
*/
int appsh(short int *,int ,short int );

/** \brief copie une solution S1 dans une solution S2
  *
  * \fn void copySolution(short nSize, solution * S1, solution * S2)
  * \param short nSize
  * \param solution * S1
  * \param solution * S2
  * \retval void
  */
  void copy_Solution(short , solution * , solution *);
  
  /** \brief ajoute une solution S dans une listeSol L
  *
  * \fn void addList(short nSize, solution * S, listeSol * L)
  * \param short nSize
  * \param solution * S
  * \param listeSol * L
  * \retval void
  */
  void addList(short , solution * , listeSol * );
  
  void addplist(short , solution * ,pliste * );
  
int reperagecol(int Cb[SizeMax][SizeMax],short int ,int *,int *,int *,short int *,short int *, short int *,short int *,short int *,short int *,short int *,short int *);
                            
void reperagelin(int Cb[SizeMax][SizeMax],short int ,int *,int *,int *,short int *,short int *,short int *,short int *,short int *,short int *,short int *,short int *);
                          
/** \brief realise le marquage de zeros pour la methode hongroise'
  *
  * \fn void marque(short int nSize,int Cb[SizeMax][SizeMax],short int *mark,short int *rmark,int *taillemark)
  * \param short int nSize
  * \param int Cb[SizeMax][SizeMax]
  * \param short int *mark
  * \param short int *rmark
  * \param int *taillemark
  * \retval void
  */
  void marque(short int ,int Cb[SizeMax][SizeMax],short int *,short int *,int *);

/** \brief correspond au cas alpha lors du reperage de colonnes : le nombre de zeros marque augmente de 1
  *
  * \fn void casalpha(short int j0,int *taillemark,short int *reperlin,short int *repercol,short int *mark,short int *rmark)
  * \param short int j0
  * \param int *taillemark
  * \param short int *reperlin
  * \param short int *repercol
  * \param short int *mark
  * \param short int *rmark
  * \retval void
  */
  void casalpha(short int ,int *,short int *,short int *,short int *,short int *);
  
  /** \brief correspond au cas beta lors du reperage de colonnes : il est impossible de reperer une colonne ==> on modifie la solution duale
  *
  * \fn void casbeta(int Cb[SizeMax][SizeMax],short int nSize,int *taillerlin,int *taillercol,int *taillemark,short int *reperlin,short int *repercol,
                              short int *etoilecol,short int *etoilelin,short int *vallin,short int *valcol,short int *mark,short int *rmark)
  * \param int Cb[SizeMax][SizeMax]
  * \param short int nSize
  * \param int *taillerlin
  * \param int *taillercol
  * \param int *taillermark
  * \param short int *reperlin
  * \param short int *repercol
  * \param short int *etoilecol
  * \param short int *etoilelin
  * \param short int *vallin
  * \param short int *valcol
  * \param short int *mark
  * \param short int *rmark
  * \retval void
  */
void casbeta(int Cb[SizeMax][SizeMax],short int ,int *,int *,int *,short int *,short int *,
                     short int *,short int *,short int *,short int *,short int *,short int *);


/** \brief correspond au reperage de ligne
  *
  * \fn void reperagelin(int Cb[SizeMax][SizeMax],short int nSize,int *taillerlin,int *taillercol,int *taillemark,short int *reperlin,short int *repercol,
                                    short int *etoilecol,short int *etoilelin,short int *vallin,short int *valcol,short int *mark,short int *rmark)
  * \param int Cb[SizeMax][SizeMax]
  * \param short int nSize
  * \param int *taillerlin
  * \param int *taillercol
  * \param int *taillemark
  * \param short int *reperlin
  * \param short int *repercol
  * \param short int *etoilecol
  * \param short int *etoilelin
  * \param short int *vallin
  * \param short int *valcol
  * \param short int *mark
  * \param short int *rmark
  * \retval void
  */

void reperagelin(int Cb[SizeMax][SizeMax],short int ,int *,int *,int *,short int *,short int *,
                          short int *,short int *,short int *,short int *,short int *,short int *);


/** \brief correspond au reperage de colonnes
  *
  * \fn void reperagecol(int Cb[SizeMax][SizeMax],short int nSize,int *taillerlin,int *taillercol,int *taillemark,short int *reperlin,short int *repercol,
                                     short int *etoilecol,short int *etoilelin,short int *vallin,short int *valcol,short int *mark,short int *rmark)
  * \param int Cb[SizeMax][SizeMax]
  * \param short int nSize
  * \param int *taillerlin
  * \param int *taillercol
  * \param int *taillermark
  * \param short int *reperlin
  * \param short int *repercol
  * \param short int *etoilecol
  * \param short int *etoilelin
  * \param short int *vallin
  * \param short int *valcol
  * \param short int *mark
  * \param short int *rmark
  * \retval void
  */

int reperagecol(int Cb[SizeMax][SizeMax],short int ,int *,int *,int *,short int *,short int *,
                            short int *,short int *,short int *,short int *,short int *,
			    short int *);                  


/** \brief corresopnd a la methode hongroise
  *
  * \fn void hung(int C[SizeMax][SizeMax],short int nSize,solution *s,int Cb[SizeMax][SizeMax])
  * \param int C[SizeMax][SizeMax]
  * \param short int nSize
  * \param solution *s
  * \param int Cb[SizeMax][SizeMax]
  * \retval void
  */
void hung(int C[SizeMax][SizeMax],short int ,solution *,int Cb[SizeMax][SizeMax]);

void hung2(int Cb[SizeMax][SizeMax],short int );

void computeValue(solution *,int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax],short int );


/** \brief calcule la matrice d'un probleme agrege
  *
  * \fn void combiConvexe(int deltaZ1,int deltaZ2,short int nSize,int Cd[SizeMax][SizeMax],
                   int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax])
  * \param int deltaZ1
  * \param int deltaZ2
  * \param short int nSize
  * \param int Cd[SizeMax][SizeMax]
  * \param int C1[SizeMax][SizeMax]
  * \param int C2[SizeMax](SizeMax]
  * \retval void
  */
  
void combiConvexe(int ,int ,short int ,int Cd[SizeMax][SizeMax],
                   int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax]);
                   

/** \brief verifie si une solution est dans une listeSol, si oui retourne 1,sinon 0
  *
  * \fn int isMember(int nSize,solution s,listeSol *L)
  * \param int nSize
  * \param solution s
  * \param listeSol *L
  * \retval int
  */
  
int isMember(solution *,listeSol *);

int isMember2(short int ,solution *,listeSol *,int );

/** \brief affiche une solution
  *
  * \fn void showSolution(int i, int nSize, solution * S)
  * \param int i
  * \param int nSize
  * \param solution *S
  * \retval void
  */

void showSolution(int , int , solution *);

/** \brief fonction qui recherche l'ensemble des solutions supportees a partir de 2 solutions initiales
  *
  * \fn void resolutionRecursive(int z11,int z12,int z21,int z22,short int nSize,int C1[SizeMax][SizeMax],
                         int C2[SizeMax][SizeMax],listeSol *listeS,int z1init,int z2init)
  * \param int z11
  * \param int z12
  * \param int z21
  * \param int z22
  * \param short int nSize
  * \param int C1[SizeMax][SizeMax]
  * \param int C2[SizeMax][SizeMax]
  * \param listeSol *listeS
  * \param int z1init
  * \param int z2init
  * \retval void
  */

void resolutionRecursive(int ,int ,int ,int ,short int ,int C1[SizeMax][SizeMax], int C2[SizeMax][SizeMax],listeSol *);

/** \brief lit une instance dans un fichier
  *
  * \fn void loadInstance(donnees * uneInstance)
  * \param donnees *uneInstance
  * \retval void
  */

//void loadInstance(vopt_prob *,donnees  *);

/** \brief affiche le titre
  *
  * \fn void showTitle()
  * \retval void
  */
void showTitle();


/** \brief compare deux solutions suivant le critere z[0], retourne -1 si la premiere solution est plus petite, 1 si elle est plus grande, 0 sinon
  *
  * \fn int sortApproximation_fn(const void *x , const void *y)
  * \param const void *x
  * \param const void *y
  * \retval int
  */

int sortApproximation_fn1(const void *, const void *);

/** \brief trie des solutions suivant le 1-er critere
  *
  * \fn void sortApproximation(solution * vectors, int numberOfVectors)
  * \param solution *vectors
  * \param int numbersOfVectors
  * \retval void
  */
void sortApproximation1(solution * , int );

/** \brief affiche une listeSol
  *
  * \fn void showList(int nSize, listeSol * L)
  * \param int nSize
  * \param listeSol * L
  * \retval void
  */

void showList(int , listeSol * );

/** \brief affiche une listeSol triee
  *
  * \fn void showListSorted(int nSize, solution * L, long int lg)
  * \param int nSize
  * \param solution *L
  * \param long int lg
  * \retval void
  */
void showListSorted(int, solution *, long int);

/** \brief imprime les resultats (une listeSol) dans un fichier
  *
  * \fn void printList(char * file, int nSize, listeSol * L)
  * \param char * file
  * \param int nSize
  * \param listeSol * L
  * \retval void
  */
void printList(char * , int , listeSol *);

/** \brief verifie si la solution t est dominee par des elements de listepos, retourne 1 si la solution est dominee, 0 sinon
  *
  * \fn int estdominee(solution t,listeSol *listepos)
  * \param solution t
  * \param listeSol *listepos
  * \retval int
  */
int estdominee(solution *,listeSol *, int );

/** \brief verifie si la solution t est bien dans le triangle delimite par r et s, retourne 1 si la solution est dans le triangle, 0 sinon
  *
  * \fn int intriangle(solution r,solution s,solution t)
  * \param solution r
  * \param solution s
  * \param solution t
  * \retval int
  */
int intriangle(solution *,solution *,solution *);

/** \brief calcule la borne d'augmentation autorisee dans l'exploration du triangle
  *
  * \fn void calculborne(listeSol *listepos,int *borne,solution r, solution s,int deltaZ1,int deltaZ2,int *valinitCd)
  * \param listeSol *listepos
  * \param int *borne
  * \param solution r
  * \param solution s
  * \param int deltaZ1
  * \param int deltaZ2
  * \param int *valinitCd
  */
void calculborne(listeSol *,int *,solution *, solution *,int ,int ,int *,int );

/** \brief permute 2 element dans un tableau
  *
  * \fn void permuter(short int *t,int i,int j)
  * \param short int *t
  * \param int i
  * \param int j
  * \retval void
  */
void permuter(int *,int ,int );

void TasEchange(tas *,short int ,int , int );

void TasDescend(tas *,short int,int, int );

void label_correcting (noeud *, short int findnoeud[2 * SizeMax], int , int , int *,int *);

void ComputeValrank(short int , tas *, int C1[SizeMax][SizeMax], int C2[SizeMax][SizeMax], int Cb[SizeMax][SizeMax]);

tas *ComputeNextSolution(tas *,int *,int *, int C[SizeMax][SizeMax],int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax], short int ,int *);

void ranking(int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax],int Cd[SizeMax][SizeMax],int *,short int ,solution *,solution *, listeSol *);
             
void lancerLesTest(short int ,int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax], solution *,solution *,listeSol *,int ,int );

/* \brief main
 * \fn solve_bilap_exact()
 */
void solve_bilap_exact(int *c1,int *c2, int nSize, int **z1, int **z2, int **solutions, int *nbsolutions); 
#endif
