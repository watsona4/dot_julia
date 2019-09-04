/**--------------------------------------------------

    \file Solver bi-objective LAP
    \brief Determination des solutions efficaces du probleme bicritere d'affectation

    \authors Anthony PRZYBYLSKI, Xavier GANDIBLEUX
    \date Juin 2005

 -------------------------------------------------*/

#include "2phrpasf2.h"

listarc * ajouterliste(arc A,listarc * premier)
{
listarc *p;
p = (listarc *) malloc (sizeof (listarc));
(p->val).u = A.u;
(p->val).v = A.v;
p->suivant = premier;
return p;
}

listarc * supprimerliste(listarc *premier)
{
listarc *precedent,*courant = premier;
while(courant != NULL)
    {
    precedent = courant;
    courant = courant->suivant;
    free(precedent);
    }
return courant;
}

listarc * copyliste(listarc *premier,listarc *nouveau)
{
listarc *courant = premier;
while(courant!= NULL)
    {
    nouveau = ajouterliste(courant->val,nouveau);
    courant = courant->suivant;
    }
return nouveau;
}

int applistarc(arc A,listarc *premier)
{
listarc *temp = premier;
while(temp != NULL)
    {
    if ( ((temp->val).u == A.u) && ((temp->val).v == A.v) ) return 1;
    temp = temp->suivant;
    }
return 0;
}



int appsh(short int *t,int taille,short int n)
{
int i = 0;
while((i < taille)&&(t[i] != n)) i++;
if ( i == taille) return 0;
	else      return 1;
}


void copy_Solution(short nSize, solution * S1, solution * S2)
{ int i;

  for(i=0;i<nSize;i++)
     S2->X[i] = S1->X[i];

  for(i=0;i<ncrit;i++)
     S2->z[i] = S1->z[i];
}

void addList(short nSize, solution * S, listeSol * L)
{
  if(  L->lgListe + 1 >=LGLISTE)
    {
	printf("ARRET FATAL : LGLISTE trop petite (routine addList)\n");
	exit(0);
    }
  copy_Solution(nSize, S, &(L->liste[L->lgListe]));
  L->lgListe++;

}

void marque(short int nSize,int Cb[SizeMax][SizeMax],short int *mark,short int *rmark,int *taillemark)
{//puts("marque");
int i,j;
int lignemark;
int mini;
short int col[SizeMax];

/* creation de zeros dans les colonnes de Cb */

for(i = 0;i < nSize;i++)
	{
	mini = Cb[i][0];
	for(j = 1;j < nSize;j++)
		if (Cb[i][j] < mini) mini = Cb[i][j];
	for(j = 0;j < nSize;j++) Cb[i][j] = Cb[i][j] - mini;
	}

/* creation de zeros dans les lignes de Cb */

for(j = 0;j < nSize;j++)
	{
	mini = Cb[0][j];
	for(i = 1;i < nSize;i++)
		if (Cb[i][j] < mini) mini = Cb[i][j];
	for(i = 0;i < nSize;i++) Cb[i][j] = Cb[i][j] - mini;
	}

/* marquage de zero initial */

//puts("Cinit = ");
//for(i = 0;i < nSize;i++)
//	{for(j = 0;j < nSize;j++) printf("%d ",Cb[i][j]);puts("");}

for(i = 0;i < nSize;i++)
	{
	j = 0;
	lignemark = 0;
	while( (lignemark == 0) && (j < nSize) )
		{
		if ( (Cb[i][j] == 0) && (appsh(col,*taillemark,j) == 0) )
			{
			mark[i] = j;
			rmark[j] = i;//printf("le zero (%d,%d) est marque\n",i,j);
			col[(*taillemark)++] = j;
			lignemark = 1;
			}
		else j++;
		}
	}
}

void casalpha(short int j0,int *taillemark,short int *reperlin,short int *repercol,short int *mark,short int *rmark)
{
/* on a un nouveau zero a marquer */
int i,j;//puts("cas alpha : changement de marquage");
rmark[j0] = repercol[j0];
mark[repercol[j0]] = j0;//printf("le zero (%d,%d) est marque\n",repercol[j0],j0);
i = repercol[j0];
j = reperlin[i];
while(j != - 1)
	{
	rmark[j] = repercol[j];
	mark[repercol[j]] = j;//printf("le zero (%d,%d) est marque\n",repercol[j],j);
	i = repercol[j];
	j = reperlin[i];
	}
(*taillemark)++;
}


void casbeta(int Cb[SizeMax][SizeMax],short int nSize,int *taillerlin,int *taillercol,int *taillemark,short int *reperlin,short int *repercol,
                     short int *etoilecol,short int *etoilelin,short int *vallin,short int *valcol,short int *mark,short int *rmark)
{//puts("cas beta");
int i,j;
short int nonrepcol[SizeMax];// indique les colonnes non reperees
int min = MAXINT;// delta a calculer pour construire des zeros
int taillenonrepcol = 0;// nombre de colonnes non reperees
for(i = 0;i < nSize;i++) if (etoilecol[i] == 0) nonrepcol[taillenonrepcol++] = i;
short int nonreplin[SizeMax];// indique les lignes non reperees
int taillenonreplin = 0;// nombre de lignes non reperees
for(i = 0;i < nSize;i++) if (etoilelin[i] == 0) nonreplin[taillenonreplin++] = i;

/* calcul du min pour i ligne reperee et j colonne non reperee */

for(i = 0;i < *taillerlin;i++)
	for(j = 0;j < taillenonrepcol;j++) if(Cb[vallin[i]][nonrepcol[j]] < min) min = Cb[vallin[i]][nonrepcol[j]];
//printf("min = %d\n",min);
/* modification de la matrice des couts reduits */

for(i = 0;i < *taillerlin;i++)
	for(j = 0;j < taillenonrepcol;j++) Cb[vallin[i]][nonrepcol[j]] = Cb[vallin[i]][nonrepcol[j]] - min;

for(i = 0;i < taillenonreplin;i++)
	for(j = 0;j < *taillercol;j++) Cb[nonreplin[i]][valcol[j]] = Cb[nonreplin[i]][valcol[j]] + min;
//puts("nouveau Cb");
//for(i = 0;i < nSize;i++)
//	{for(j = 0;j < nSize;j++) printf("%d ",Cb[i][j]);puts("");}
}

void reperagelin(int Cb[SizeMax][SizeMax],short int nSize,int *taillerlin,int *taillercol,int *taillemark,short int *reperlin,short int *repercol,
                          short int *etoilecol,short int *etoilelin,short int *vallin,short int *valcol,short int *mark,short int *rmark)
{//puts("reperagelin");
int i = 0,j,trouve = 0;
/* trouve indique si on a trouve une ligne a reperer,
   on peut reperer une ligne si elle n'est pas encore reperee,
   contient un zero marque dans une colonne reperee */

while(trouve == 0)
	{
	/* on cherche une ligne pas encore reperee a sonder */
	while((i < nSize) && (etoilelin[i] == 1)) i++;
	//printf("on regarde la ligne non reperee %d\n",i);
	/* on parcourt les colonnes reperees pour trouver des zeros marques */
	j = 0;
	while(j < *taillercol)
		{//printf("on regarde la colonne reperee %d\n",j);
		/* Si a l'intersection de la ligne et de la colonne, on a un zero marque, on repere */
		if((Cb[i][valcol[j]] == 0) && (mark[i] == valcol[j]))
			{//printf("on a trouve le zero marque (%d,%d)\n",i,valcol[j]);
			trouve = 1;
			etoilelin[i] = 1;
			reperlin[i] = valcol[j];//printf("on donne a la ligne %d le repere %d\n",i,valcol[j]);
			vallin[(*taillerlin)] = i;
			(*taillerlin)++;
			/* On continue en cherchant une colonne a reperer */
			//reperagecol(Cb,nSize,taillerlin,taillercol,taillemark,reperlin,repercol,etoilecol,etoilelin,vallin,valcol,mark,rmark);
			/* On a trouve notre ligne, inutile de continuer ==> sortie de boucle */
			j = *taillercol;
			}
		j++;
		}
	i++;
	}
}

int reperagecol(int Cb[SizeMax][SizeMax],short int nSize,int *taillerlin,int *taillercol,int *taillemark,short int *reperlin,short int *repercol,
                            short int *etoilecol,short int *etoilelin,short int *vallin,short int *valcol,short int *mark,
			    short int *rmark)
{//puts("reperagecol");
int i,j = 0,trouve = 0;

/* trouve indique si on a trouve une colonne a reperer ou pas
    on peut reperer une colonne si elle n'est pas encore reperee,
    contient un zero non marque dans une ligne reperee */

while(trouve == 0)
	{
	/* On cherche une colonne pas encore repere a sonder*/
	while((j < nSize) && (etoilecol[j] == 1)) j++;
	//printf("on regarde la colonne %d\n",j);
	/* Si on en trouve une pas encore sondee */
	if(j != nSize)
		{
		/* on parcours les lignes reperees pour trouver des zeros non marques */
		i = 0;
		while(i < *taillerlin)// && ((Cb[vallin[i]][j] != 0) || (mark[vallin[i]] == j)) )
			{//printf("on regarde la ligne %d\n",i);
			/* Si a l'intersection de la ligne et de la colonne, on a un zero non marque, on repere */
			if ((Cb[vallin[i]][j] == 0) && ( mark[vallin[i]] != j))
				{//printf("on a trouve le zero non marque (%d,%d)\n",vallin[i],j);
				trouve = 1;
				etoilecol[j] = 1;
				repercol[j] = vallin[i];//printf("on donne a la colonne %d le repere %d\n",j,vallin[i]);
				valcol[(*taillercol)] = j;
				(*taillercol)++;
				/* Si la colonne ne contient pas de zero marque, on peut marquer un zero supplementaire : cas alpha */
				if (rmark[j] == - 1) {casalpha(j,taillemark,reperlin,repercol,mark,rmark);return 0;}
				/* Sinon on continue en reperant des lignes */
				else return 1; //reperagelin(Cb,nSize,taillerlin,taillercol,taillemark,reperlin,repercol,etoilecol,etoilelin,vallin,valcol,mark,rmark);
				}
			i++;
			}
		/* la ligne reperee n'ayant pas permis de reperer une colonne, on passe a la suivante */
		j++;
		}
	/* on a plus de ligne reperee a sonder ==> pas possible de reperer une colonne ==> cas beta : on cree de nouveaux zeros dans la matrice */
	else
		{
		return 2;//casbeta(Cb,nSize,taillerlin,taillercol,taillemark,reperlin,repercol,etoilecol,etoilelin,vallin,valcol,mark,rmark);
		/* on recommence le reperage de colonne la ou on en etait */
		//reperagecol(Cb,nSize,taillerlin,taillercol,taillemark,reperlin,repercol,etoilecol,etoilelin,vallin,valcol,mark,rmark);
		/* on ne continue pas la boucle en cours */
		}
	}
	
	/* Ne doit pas arriver */
	return -1;
}

void hung(int C[SizeMax][SizeMax],short int nSize,solution *s,int Cb[SizeMax][SizeMax])
{//puts("hung");
int i,j,k;

/* copie de la matrice initiale sur laquelle on va appliquer l'algorithme ==> matrice des couts reduits */
for(i = 0;i < nSize;i++)
	for(j = 0;j < nSize;j++) Cb[i][j] = C[i][j];

//for(i = 0;i < nSize;i++)
//	{for(j = 0;j < nSize;j++) printf("%d ",Cb[i][j]);puts("");}

/* mark et rmark indiquent les zeros marques : mark[i] = j et rmark[j] = i signifie que le zero (i,j) est marque
   mark[i] = - 1 signifie qu'il n'y a pas de zero marque dans la ligne i
   rmark[j] = -1 signifie qu'il n'y a pas de zero marque dans la colonne j
   taillemark indique le nombre de zeros marques  */

short int mark[SizeMax],rmark[SizeMax];
int taillemark = 0;

/* initialement, aucun zero n'est marque */

for(i = 0;i < nSize;i++)
	{
	mark[i] = - 1;
	rmark[i] = - 1;
	}

/* marquage de zeros initial */

marque(nSize,Cb,mark,rmark,&taillemark);

/* reperlin et repercol indiquent respectivement les reperes des lignes et des colonnes
   reperlin[i] = j signifie qu'on attribue le repere j  a la ligne i
   reperlin[j] = i signifie qu'on attribue le repere i a la colonne j
   etoilelin et etoilecol indiquent les lignes et les colonnes qui ont ete reperees (1 repere,0 pas repere)
   vallin et vallcol sont des tableaux qui indiquent les lignes et les colonnes reperees (afin d'eviter des parcours pour les trouver)
   taillercol indique le nombre de colonnes reperes et taillerlin le nombre de lignes reperees */

short int reperlin[SizeMax],etoilelin[SizeMax],repercol[SizeMax],etoilecol[SizeMax],vallin[SizeMax],valcol[SizeMax];
int taillerlin,taillercol;

int compteur = nSize - taillemark;
int min;

while(compteur != 0)
	{//puts("nouvelle iteration");

	/* au debut de chaque iteration, aucune ligne ou colonne n'est reperee */

	taillerlin = 0;
	taillercol = 0;
	for(i = 0;i < nSize;i++)
		{
		etoilelin[i] = 0;
		etoilecol[i] = 0;
		}

	/* determination de la premiere ligne reperee, la premiere qui ne possede pas de zero marque */

	i = 0;
	while(mark[i] != -1) i++;
	min = Cb[i][0];
	for(j = 1;j < nSize;j++) if (Cb[i][j] < min) min = Cb[i][j];
	for(j = 0;j < nSize;j++) Cb[i][j] = Cb[i][j] - min;
	reperlin[i] = - 1;
	etoilelin[i] = 1;
	vallin[0] = i;
	taillerlin++;
	//for(i = 0;i < nSize;i++)
	//	{for(j = 0;j < nSize;j++) printf("%d ",Cb[i][j]);puts("");}
	//printf("la premiere ligne reperee est %d de repere %d\n",i,-1);
        
        /* lancement de la procedure de reperage */
        
        k = 1;
        while ( k != 0 )
            {//printf("k = %d avant repere\n",k);
            k = reperagecol(Cb,nSize,&taillerlin,&taillercol,&taillemark,reperlin,repercol,etoilecol,etoilelin,vallin,valcol,mark,rmark);
            //printf("k = %d apres repere\n",k);
            if (k != 0)
            switch(k)
                {
                case 1 : reperagelin(Cb,nSize,&taillerlin,&taillercol,&taillemark,reperlin,repercol,etoilecol,etoilelin,vallin,valcol,mark,rmark);break;
                case 2 : casbeta(Cb,nSize,&taillerlin,&taillercol,&taillemark,reperlin,repercol,etoilecol,etoilelin,vallin,valcol,mark,rmark);break;
                }
            }
        
	/* prochaine iteration */

	compteur--;
	}

/* remplissage de la solution a l'aide des zeros marques */

for(i = 0;i < nSize;i++) s->X[i] = mark[i];//for(i = 0;i < nSize;i++) printf("X[%d] = %d, ",i,s->X[i]);
}

void computeValue(solution *s,int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax],short int nSize)
{
int i;
for(i = 0;i < ncrit;i++) s->z[i] = 0;

for(i = 0;i < nSize;i++)
    {
    s->z[0] += C1[i][s->X[i]];
    s->z[1] += C2[i][s->X[i]];
    }
}

void combiConvexe(int deltaZ1,int deltaZ2,short int nSize,int Cd[SizeMax][SizeMax],
                   int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax])
{
int i,j;
for (i = 0;i < nSize;i++)
	for (j = 0;j < nSize;j++)
		Cd[i][j] = deltaZ2 * C1[i][j] + deltaZ1 * C2[i][j];
}


int isMember(solution *s,listeSol *L)
{
int i;

for(i = 0;i < L->lgListe;i++)
    if (( s->z[0] == (L->liste[i]).z[0] ) && ( s->z[1] == (L->liste[i]).z[1] )) return 1;
return 0;
}
/*
int isMember2(short int nSize,solution *s,pliste *L)
{
int i;

for(i = 0;i < L->lgListe;i++)
	if (( s->z[0] == (L->liste[i]).z[0] ) && ( s->z[1] == (L->liste[i]).z[1] )) return 1;
return 0;
}
*/
int isMember2(short int nSize,solution *s,listeSol *listePE,int taillePEinit)
{
int i;

for(i = taillePEinit;i < listePE->lgListe;i++)
    if (( s->z[0] == (listePE->liste[i]).z[0] ) && ( s->z[1] == (listePE->liste[i]).z[1] )) return 1;
return 0;
}


void showSolution(int i, int nSize, solution * S)
{ int j;

  printf(" [%3d]  ( %3d | %3d ) :",i,S->z[0],S->z[1]);

  for(j=0;j<nSize;j++)
    printf(" %2d", S->X[j]) ;
  puts("");
}

void resolutionRecursive(int z11,int z12,int z21,int z22,short int nSize,int C1[SizeMax][SizeMax],
                         int C2[SizeMax][SizeMax],listeSol *listeS)
{
int Cd[SizeMax][SizeMax], Cb[SizeMax][SizeMax];
int deltaZ1,deltaZ2;
int a,b;
solution s;

/* calcule des coefficients de l'agregation */

printf("recherche entre (%d|%d) et (%d,%d)\n",z11,z12,z21,z22);
deltaZ1 = abs(z21 - z11);
deltaZ2 = abs(z22 - z12);//printf("a1 = %d et a2 = %d\n",deltaZ2,deltaZ1);

/* calcul de la matrice des couts du probleme unicritere */

combiConvexe(deltaZ1,deltaZ2,nSize,Cd,C1,C2);

/* resolution et retour des parametres */

hung(Cd,nSize,&s,Cb);
computeValue(&s,C1,C2,nSize);
if (isMember(&s,listeS) == 0) addList(nSize,&s,listeS);

/* verifie si les nouvelles solutions sont alignes avec les deux precedentes
   si ce n'est pas le cas, appel recursif */

a = deltaZ2 * s.z[0] + deltaZ1 * s.z[1];
b = deltaZ2 * z21 + deltaZ1 * z22;

if ( a != b )
	{
	resolutionRecursive(z11,z12,s.z[0],s.z[1],nSize,C1,C2,listeS);
	resolutionRecursive(s.z[0],s.z[1],z21,z22,nSize,C1,C2,listeS);
	}
}

int sortApproximation_fn1(const void *x , const void *y)
{
  solution  *xx = (solution *)x,
            *yy = (solution *)y ;

  if (xx->z[0] < yy->z[0])  return -1;
  if (xx->z[0] > yy->z[0])  return 1;
  return 0;
}


void sortApproximation1(solution * vectors, int numberOfVectors)
{  qsort( vectors, numberOfVectors, sizeof(solution), sortApproximation_fn1 );
}


int estdominee(solution *t,listeSol *listePE, int taillePEinit)
{
int i;

for(i = taillePEinit;i < listePE->lgListe;i++)
	if (    ((t->z[0] >= (listePE->liste[i]).z[0]) && (t->z[1] > (listePE->liste[i]).z[1]))
             || ((t->z[0] >  (listePE->liste[i]).z[0]) && (t->z[1] >= (listePE->liste[i]).z[1]))
	   )
	return 1;

return 0;
}


int intriangle(solution *r,solution *s,solution *t)
{
if ((t->z[0] < s->z[0]) && (t->z[1] < r->z[1])) return 1;
	else return 0;
}

void calculborne(listeSol *listePE,int *borne,solution *r, solution *s,int deltaZ1,int deltaZ2,int *valinitCd,int taillePEinit)
{
int i,maxinter,maxtemp;

sortApproximation1(&(listePE->liste[taillePEinit]),(listePE->lgListe) - taillePEinit);

//for(i = 0;i < listepos->lgListe;i++) printf("(%d,%d) ",(listepos->liste[i]).z[0],(listepos->liste[i]).z[1]);puts(" ");

maxinter = deltaZ2 * ((listePE->liste[taillePEinit]).z[0] - 1) + deltaZ1 * (r->z[1] - 1);//printf("(%d,%d), et bornepot = %d\n",(listepos->liste[0]).z[0] - 1,r.z[1] - 1,maxtemp);

#if SOL == 1
maxtemp = deltaZ2 * (listePE->liste[taillePEinit]).z[0] + deltaZ1 * (listePE->liste[taillePEinit]).z[1];
if (maxtemp > maxinter) maxinter = maxtemp;
#endif

for(i = taillePEinit + 1;i < listePE->lgListe;i++)
	{
	#if SOL == 1
	maxtemp = deltaZ2 * (listePE->liste[i]).z[0] + deltaZ1 * (listePE->liste[i]).z[1];//printf("(%d,%d) , et bornepot = %d\n",(listepos->liste[i]).z[0],(listepos->liste[i]).z[1],maxtemp);
	if (maxtemp > maxinter) maxinter = maxtemp;
	#endif
	maxtemp = deltaZ2 * ( (listePE->liste[i]).z[0] - 1) + deltaZ1 * ( (listePE->liste[i - 1]).z[1] - 1);//printf("(%d,%d) , et bornepot = %d\n",(listepos->liste[i]).z[0] - 1,(listepos->liste[i - 1]).z[1] - 1,maxtemp);
	if (maxtemp > maxinter)  maxinter = maxtemp;
	}

maxtemp = deltaZ2 * (s->z[0] - 1) + deltaZ1 * ( (listePE->liste[listePE->lgListe - 1]).z[1] - 1);//printf("(%d,%d) , et bornepot = %d\n",s.z[0] - 1,(listepos->liste[listepos->lgListe - 1]).z[1] - 1,maxtemp);
if (maxtemp > maxinter) maxinter = maxtemp;

maxinter = maxinter - *valinitCd;
if (maxinter < *borne) *borne = maxinter;
}

void TasEchange(tas *tab,short int nSize,int i, int j)
{
listarc *temp;
temp = tab[i].I;
tab[i].I = tab[j].I;
tab[j].I = temp;

solution *tem;
tem = tab[i].s;
tab[i].s = tab[j].s;
tab[j].s = tem;

short int stemp;
stemp = tab[i].DNI;
tab[i].DNI = tab[j].DNI;
tab[j].DNI = stemp;

int tamp;
tamp = tab[i].value;
tab[i].value = tab[j].value;
tab[j].value = tamp;
}

void TasDescend(tas *tab,short int nSize,int i, int tailletas)
{
int min;
if ( (2 * i + 1 < tailletas) && (tab[2 * i + 1].value < tab[i].value) ) min = 2 * i + 1;
else min = i;
if ( (2 * i + 2 < tailletas) && (tab[2 * i + 2].value < tab[min].value) ) min = 2 * i + 2;

if (min != i)
    {
    TasEchange(tab,nSize,i,min);
    TasDescend(tab,nSize,min,tailletas);
    }
}

/*---------- label correcting, on travaille avec les numeros de la structure graphe -----------------*/

void label_correcting (noeud *graphe, // represente le graphe
                       short int findnoeud[2 * SizeMax], // correspondance entre les "vrai" numeros des noeuds et ceux de la structure graphe 
                       int taillegraphe, // taille du graphe
                       int s, // source pour les pcc donne avec le numero de la structure graphe
                       int *pcc, // les pcc (allocation desallocation dehors) des "faux" numero de noeuds (ceux de la structure graphe)
                       int *from // les origines (allocation desallocation dehors) des "faux" numero de noeuds (ceux de la structure graphe) 
                       )
{
    int *file, *in_file;
    int j, q, head, size, n = taillegraphe, label;
    /* alloc. memoire */
    file = (int *) malloc (n * sizeof(int));
    in_file = (int *) malloc (n * sizeof(int));
    
    /* init. des labels sur chaque sommet */
    // pour tous les numeros de la structure graphe, on a from = -1 et dit = INFINI
    for (j = 0; j < n; j++)
    {
	from[j] = -1;
	pcc[j] = INFINI;
	in_file[j] = 0;
    }
    
    /* on met s dans la file */
    pcc[s] = 0;
    file[0] = s;
    head = 0;
    size = 1;
    in_file[s] = 1;
    
    //puts("initialement");
    
    /* boucle principale */
    while (size > 0)
    {
	/* depiler sommet en tete de la file */
        //for(i = 0;i < taillegraphe;i++) printf("%d (%3d), ",graphe[i].num,pcc[i]);getchar();
        q = file[head];//printf("on utilise %d\n",graphe[q].num);
	head = (head + 1) % n;
	size--;
	in_file[q] = 0;
	
	/* pour tous les successeurs de ce sommet */
	for (j = 0; j < graphe[q].nbsuiv; j++)
	{
	    /* relaxation eventuelle du successeur */
	    label = pcc[q] + graphe[q].cout[j];
	    if (label < pcc[findnoeud[graphe[q].suiv[j]]]) //calcul du label en comparaison a celui du numero de la structure graphe
	    {
		pcc[findnoeud[graphe[q].suiv[j]]] = label; 
		from[findnoeud[graphe[q].suiv[j]]] = q; //plus coherent avec q ou graphe[q].num? plutot q pour ne pas depareiller avec pcc
		
		/* insertion de findnoeud[graphe[q].suiv[j]] dans la file */
		if (in_file[findnoeud[graphe[q].suiv[j]]] == 0)
		{
		    file[(head+size)%n] = findnoeud[graphe[q].suiv[j]];
		    size++;
		    in_file[findnoeud[graphe[q].suiv[j]]] = 1;
		}
	    }
	}
    }
    free(file);
    free(in_file);
}

void ComputeValrank(short int nSize, tas *tab, int C1[SizeMax][SizeMax], int C2[SizeMax][SizeMax], int Cb[SizeMax][SizeMax])
{
int i;
(tab->s)->z[0] = 0;
(tab->s)->z[1] = 0;
tab->value = 0;
for(i = 0;i < nSize;i++) 
    {
    (tab->s)->z[0] += C1[i][(tab->s)->X[i]];
    (tab->s)->z[1] += C2[i][(tab->s)->X[i]];
    tab->value += Cb[i][(tab->s)->X[i]];
    }
}

tas *ComputeNextSolution(tas *tab,int *tailletab,int *taille, int C[SizeMax][SizeMax],int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax], short int nSize,int *borne)
{
int i,j,k;//variable de boucles
short int apr[SizeMax];// partie imposee de la solution, sert egalement de copie de tab[0].s
int tailleapr;// taille de la partie imposee 
short int b[SizeMax];// partie non imposee trouvee avec le plus court chemin (donnee a l'envers)
int tailleb;// taille de cette partie
short int DNIloc,DNIinit = tab[0].DNI;// derniere variable imposee dans la solution locale et dans la solution initiale
listarc *Ilocinit = NULL;// arcs interdits localement (initialement copie de tab[0].I)
listarc *Iloc = NULL;
arc temp;//arc utilise temporairement pour des ajouts
noeud *graphe;// graphe utilise 
int taillegraphe;// nbre de noeuds dans ce graphe
short int findnoeud[2 * SizeMax];// tableau de correspondance du "vrai numero" du noeud vers celui de la structure graphe (ne nous prenons pas la tete avec des operations compliques)
int *pcc;// pointeur pour le label correcting
int value = tab[0].value;
int *from;// pointeur pour le label correcting
solution *sloc; //pointeur sur une solution utilisee localement
// initialisation de l'etape du ranking
Ilocinit = copyliste(tab[0].I,Ilocinit); //copie de l'ensemble des arcs interdits
for(i = 0;i < nSize;i++) apr[i] = (tab[0].s)->X[i]; // initialisation de apr
tailleapr = nSize;
// suppression de tab[0]
tab[0].I = supprimerliste(tab[0].I);
free(tab[0].s);
tab[0].s = tab[(*tailletab) - 1].s;
tab[0].value = tab[(*tailletab) - 1].value;
tab[0].DNI = tab[(*tailletab) - 1].DNI;
tab[0].I = tab[(*tailletab) - 1].I;
(*tailletab)--;
TasDescend(tab,nSize,0,(*tailletab));

//affichage de la matrice de cout
/*puts("matrice :");
for(i = 0;i < nSize;i++)
    {for(j = 0;j < nSize;j++) printf("%3d ",C[i][j]);puts("");}
*/

if (DNIinit < nSize - 3) // si on a moins de n - 2 variables fixees ==> on a qqch a faire
    {
    // allocation memoire pour le graphe
    graphe = (noeud *) malloc (2 * (nSize - DNIinit - 1) * sizeof(noeud));
    pcc = (int *) malloc (2 * (nSize - DNIinit - 1) * sizeof(int));
    from = (int *) malloc (2 * (nSize - DNIinit - 1) * sizeof(int));
    //au depart seulement deux noeuds dans le graphes et un seul arc possible (qu'on supprimera ensuite)
    graphe[0].num = nSize - 1;
    findnoeud[nSize - 1] = 0; 
    graphe[1].num = apr[nSize - 1] + nSize;
    findnoeud[graphe[1].num] = 1;
    taillegraphe = 2;
    tailleapr--;
    //initialisation de la solution reduite initiale et de l'arc inverse correspondant
    b[0] = apr[nSize - 1];    
    tailleb = 1;
    graphe[0].nbsuiv = 0;
    graphe[1].suiv[0] = nSize - 1;
    graphe[1].cout[0] = -C[nSize - 1][apr[nSize - 1]];
    graphe[1].nbsuiv = 1;
    
    // debut de la boucle principale de l'etape du ranking
    for(i = nSize - 2;i > DNIinit + 1;i--)
        {
        // ajout de deux nouveaux noeuds
        graphe[taillegraphe].num = i;
        findnoeud[i] = taillegraphe;
        graphe[taillegraphe].nbsuiv = 0;
        taillegraphe++;
        graphe[taillegraphe].num = apr[i] + nSize;
        findnoeud[graphe[taillegraphe].num] = taillegraphe;
        graphe[taillegraphe].nbsuiv = 0;
        taillegraphe++;
        tailleapr--;
        DNIloc = i - 1;
        // arc interdit pour cette iteration
        temp.u = i;
        temp.v = apr[i];
        Iloc = ajouterliste(temp,Iloc);
            
        // ajout des nouveaux arcs pour les anciens noeux (arcs reliant les anciens noeuds de gauche au nouveau noeud de droite)
        // dans la partie gauche seulement
        temp.v = apr[i];
        for(j = 0;j < taillegraphe - 2;j = j + 2)
            {
            temp.u = graphe[j].num;
            if (applistarc(temp,Iloc) == 0)
                {
                (graphe[j].suiv)[(graphe[j].nbsuiv)] = graphe[taillegraphe - 1].num;
                (graphe[j].cout)[(graphe[j].nbsuiv)] = C[temp.u][temp.v];
                (graphe[j].nbsuiv)++;
                }
            }
            
        // ajout des arcs pour le nouveau noeud de gauche sauf l'arc correspondant aux deux nouveaux noeuds (forcement interdit) (arcs reliant le nouveau noeud de gauche aux anciens noeuds de droite)
        temp.u = graphe[taillegraphe - 2].num;
        for(j = 1;j < taillegraphe - 1;j = j + 2)
            {
            temp.v = graphe[j].num - nSize;
            if (applistarc(temp,Iloc) == 0)
                {
                (graphe[taillegraphe - 2].suiv)[(graphe[taillegraphe - 2].nbsuiv)] = graphe[j].num;
                (graphe[taillegraphe - 2].cout)[(graphe[taillegraphe - 2].nbsuiv)] = C[temp.u][temp.v];
                (graphe[taillegraphe - 2].nbsuiv)++;
                }
            }
            
        /* affichage du graphe avant l'appel au label correcting */
        /*
        for(j = 0;j < taillegraphe;j++)
            {
            printf("graphe[%d].num = %d\n",j,graphe[j].num);
            printf("suivants(couts) :");for(k = 0;k < graphe[j].nbsuiv;k++) printf("%d (%d),",graphe[j].suiv[k],graphe[j].cout[k]);puts("");
            } 
        getchar();
        */
        // calcul du plus court chemin
        label_correcting(graphe,findnoeud,taillegraphe,taillegraphe - 2,pcc,from);
            
        // recuperation de ce chemin et traduction en solution reduite obtenue (Que se passe-t-il s'il n'y a pas de chemin a recuperer? Pour le moment, je laisse un trou)
        // + modification du graphe en fonction de b
        k = taillegraphe - 1;
        if ((pcc[k] != INFINI)  && (value + pcc[k] - C[graphe[taillegraphe - 2].num][graphe[taillegraphe - 1].num - nSize] <= (*borne))) //sinon rien a faire 
            {
            //printf("b avant iteration=");
            //for(j = 0;j < tailleb;j++) printf("%d ,",b[j]);puts("");
            tailleb++;
            while(from[from[k]] != -1)
                {
                /*
                if (b[nSize - 1 - graphe[from[k]].num] != graphe[k].num - nSize) // on modifie l'affectation correspondante donc le graphe correspondant
                    {
                    printf("b[%d] = %d != %d\n",nSize - 1 - graphe[from[k]].num,b[nSize - 1 - graphe[from[k]].num],graphe[k].num - nSize);
                    graphe[from[k]].suiv[graphe[from[k]].nbsuiv] = b[nSize - 1 - graphe[from[k]].num] + nSize;
                    graphe[from[k]].cout[graphe[from[k]].nbsuiv] = C[graphe[from[k]].num][b[nSize - 1 - graphe[from[k]].num]]; 
                    (graphe[from[k]].nbsuiv)++; // ajout de l'arc qui etait enleve
                    
                    printf("on ajoute pour le noeud %d le suivant %d (%d)\n",graphe[from[k]].num,b[nSize - 1 - graphe[from[k]].num] + nSize,C[graphe[from[k]].num][b[nSize - 1 - graphe[from[k]].num]]);
                    supprimersuiv(&(graphe[from[k]]),graphe[k].num);// suppression de l'arc qui correspond a la nouvelle affectation
                    graphe[k].suiv[0] = graphe[from[k]].num;
                    graphe[k].cout[0] = - C[graphe[from[k]].num][graphe[k].num - nSize];
                    graphe[k].nbsuiv = 1;// ajout de l'arc en sens inverse
                    printf("on ajoute pour le noeud %d le suivant %d (%d)\n",graphe[k].num,graphe[k].suiv[0],graphe[k].cout[0]);
                    }
                */
                b[nSize - 1 - graphe[from[k]].num] = graphe[k].num - nSize;// mise a jour de l'affectation
//                printf("b[%d] = %d\n",nSize - 1 - graphe[from[k]].num,b[nSize - 1 - graphe[from[k]].num]);  
                k = from[from[k]];  //passage a l'iteration suivante
                }
            //derniere iteration, pareil sauf qu'on n'avait pas d'arc enleve
            //printf("nouveau : b[%d] = %d\n",nSize - 1 - graphe[from[k]].num,graphe[k].num - nSize);
            b[nSize - 1 - graphe[from[k]].num] = graphe[k].num - nSize;
//            printf("b[%d] = %d\n",nSize - 1 - graphe[from[k]].num,b[nSize - 1 - graphe[from[k]].num]);
            /*
            supprimersuiv(&(graphe[from[k]]),graphe[k].num);// suppression de l'arc qui correspond a la nouvelle affectation
            graphe[k].suiv[0] = graphe[from[k]].num;
            graphe[k].cout[0] = - C[graphe[from[k]].num][graphe[k].num - nSize];
            graphe[k].nbsuiv = 1;// ajout de l'arc en sens inverse
            printf("on ajoute pour le noeud %d le suivant %d (%d)\n",graphe[k].num,graphe[k].suiv[0],graphe[k].cout[0]);*/
            // et finalement, ajout de l'arc interdit pour l'iteration en sens inverse
            graphe[findnoeud[apr[i] + nSize]].suiv[graphe[findnoeud[apr[i] + nSize]].nbsuiv] = i;
            graphe[findnoeud[apr[i] + nSize]].cout[graphe[findnoeud[apr[i] + nSize]].nbsuiv] = -C[i][apr[i]];
            //printf("on ajoute pour le noeud %d le suivant %d (%d)\n",graphe[findnoeud[apr[i] + nSize]].num,i,-C[i][apr[i]]);
            (graphe[findnoeud[apr[i] + nSize]].nbsuiv)++;
            
            // concatenation de la solution reduite et creation du nouvel element du tas
            sloc = (solution *) malloc (sizeof(solution));//printf("apr =");
            for(j = 0;j < tailleapr;j++) sloc->X[j] = apr[j];//printf("%d ",apr[j]);}
            //printf("b =");
            for(j = 0;j < tailleb;j++) sloc->X[nSize - 1 - j] = b[j];//printf("%d ",b[j]);}
            if ( ((*tailletab) + 1) % (*taille) == 0)
                {
                (*taille) += 1000;
                tab = realloc(tab,(*taille) * sizeof(tas));
                }
            tab[(*tailletab)].s = sloc;
            tab[(*tailletab)].DNI = DNIloc;
            tab[(*tailletab)].I = Iloc;
            ComputeValrank(nSize,&(tab[*tailletab]),C1,C2,C);
            //showSolution(0, nSize, tab[*tailletab].s);
            (*tailletab)++;
            k = (*tailletab) - 1;
            while( (k > 0) && (tab[(k - 1) / 2].value) > (tab[k].value) )
                {
                TasEchange(tab,nSize,k,(k - 1) / 2);
                k = (k - 1) / 2;
                }
            Iloc = NULL;
            //remise de b dans l'etat initial
            for(j = 0;j < tailleb;j++) b[j] = apr[nSize - 1 -j];
            }
        else 
            {
            Iloc = supprimerliste(Iloc);
            tailleb++;
            for(j = 0;j < tailleb;j++) b[j] = apr[nSize - 1 -j];
            graphe[findnoeud[apr[i] + nSize]].suiv[graphe[findnoeud[apr[i] + nSize]].nbsuiv] = i;
            graphe[findnoeud[apr[i] + nSize]].cout[graphe[findnoeud[apr[i] + nSize]].nbsuiv] = -C[i][apr[i]];
            //printf("on ajoute pour le noeud %d le suivant %d (%d)\n",graphe[findnoeud[apr[i] + nSize]].num,i,-C[i][apr[i]]);
            (graphe[findnoeud[apr[i] + nSize]].nbsuiv)++;
            }
        }
    //derniere iteration
    graphe[taillegraphe].num = i;
    findnoeud[i] = taillegraphe;
    graphe[taillegraphe].nbsuiv = 0;
    taillegraphe++;
    graphe[taillegraphe].num = apr[i] + nSize;
    findnoeud[graphe[taillegraphe].num] = taillegraphe;
    graphe[taillegraphe].nbsuiv = 0;
    taillegraphe++;
    tailleapr--;
    DNIloc = i - 1;
    // arc interdit pour cette iteration + DIFFERENCE (ceux de l'iteration precedente)
    temp.u = i;//printf("i = %d",i);
    temp.v = apr[i];//printf("apr[i] = %d",apr[i]);
    Ilocinit = ajouterliste(temp,Ilocinit);
            
    // ajout des nouveaux arcs pour les anciens noeux (arcs reliant les anciens noeuds de gauche au nouveau noeud de droite)
    // dans la partie gauche seulement
    temp.v = apr[i];
    for(j = 0;j < taillegraphe - 2;j = j + 2)
        {
        temp.u = graphe[j].num;
        if (applistarc(temp,Ilocinit) == 0)
            {
            (graphe[j].suiv)[(graphe[j].nbsuiv)] = graphe[taillegraphe - 1].num;
            (graphe[j].cout)[(graphe[j].nbsuiv)] = C[temp.u][temp.v];
            (graphe[j].nbsuiv)++;
            }
        }
            
    // ajout des arcs pour le nouveau noeud de gauche sauf l'arc correspondant aux deux nouveaux noeuds (forcement interdit) (arcs reliant le nouveau noeud de gauche aux anciens noeuds de droite)
    temp.u = graphe[taillegraphe - 2].num;
    for(j = 1;j < taillegraphe - 1;j = j + 2)
        {
        temp.v = graphe[j].num - nSize;
        if (applistarc(temp,Ilocinit) == 0)
            {
            (graphe[taillegraphe - 2].suiv)[(graphe[taillegraphe - 2].nbsuiv)] = graphe[j].num;
            (graphe[taillegraphe - 2].cout)[(graphe[taillegraphe - 2].nbsuiv)] = C[temp.u][temp.v];
            (graphe[taillegraphe - 2].nbsuiv)++;
            }
        }
                    
    // calcul du plus court chemin
    label_correcting(graphe,findnoeud,taillegraphe,taillegraphe - 2,pcc,from);
            
    // recuperation de ce chemin et traduction en solution reduite obtenue (Que se passe-t-il s'il n'y a pas de chemin a recuperer? Pour le moment, je laisse un trou)
    // + modification du graphe en fonction de b
    k = taillegraphe - 1;
    if ((pcc[k] != INFINI)  && (value + pcc[k] - C[graphe[taillegraphe - 2].num][graphe[taillegraphe - 1].num - nSize] <= (*borne))) //autrement rien a faire 
        {
        tailleb++;
        while(from[from[k]] != -1)// on se fiche ici de modifier le graphe, il y a plus d'iteration apres
            {
            b[nSize - 1 - graphe[from[k]].num] = graphe[k].num - nSize;// mise a jour de l'affectation  
            k = from[from[k]];  //passage a l'iteration suivante
            }
        b[nSize - 1 - graphe[from[k]].num] = graphe[k].num - nSize;
        // concatenation de la solution reduite et creation du nouvel element du tas
        sloc = (solution *) malloc (sizeof(solution));
        for(j = 0;j < tailleapr;j++) sloc->X[j] = apr[j];
        for(j = 0;j < tailleb;j++) sloc->X[nSize - 1 - j] = b[j];
        if ( ((*tailletab) + 1) % (*taille) == 0)
            {
            (*taille) += 10000;
            tab = realloc(tab,(*taille) * sizeof(tas));
            }
        tab[(*tailletab)].s = sloc;
        tab[(*tailletab)].DNI = DNIloc;
        tab[(*tailletab)].I = Ilocinit;
        ComputeValrank(nSize,&(tab[*tailletab]),C1,C2,C);
        (*tailletab)++;
        k = (*tailletab) - 1;
        while( (k > 0) && (tab[(k - 1) / 2].value) > (tab[k].value) )
            {
            TasEchange(tab,nSize,k,(k - 1) / 2);
            k = (k - 1) / 2;
            }
        }
    else Ilocinit = supprimerliste(Ilocinit);
    free(pcc);
    free(from);
    free(graphe);
    }
return tab;
}

void ranking(int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax],int Cd[SizeMax][SizeMax],int *borne,short int nSize,solution *r,solution *s,
             listeSol *listePE)
{
/* Cb est une matrice de couts reduits recuperee apres l'appel a la methode hongroise
   deltaZ1 et deltaZ2 sont les largeurs et hauteurs du triangle
   */
   
int Cb[SizeMax][SizeMax]; //matrice de couts reduits utilise pour le ranking
int i; //variables de boucles
int taillePEinit = listePE->lgListe;
int min,valinitCd = 0;
int deltaZ1 = s->z[0] - r->z[0],deltaZ2 = r->z[1] - s->z[1];// taille des cotes du triangle

/* calcul de valinitCd */

for(i = 0;i < nSize;i++) valinitCd += Cd[i][r->X[i]];

/* interdiction des affectations supprimes lors de tests */

tas *tab;
int tailletab = 1;
int taille = 10000;
tab = (tas *) malloc ( taille * sizeof (tas) );

tab[0].I = NULL;
tab[0].DNI = -1;

tab[0].s = (solution *) malloc (sizeof(solution));

hung(Cd,nSize,tab[0].s,Cb);

//puts("matrice initiale");
//for(i = 0;i < nSize;i++)
//    {for(j = 0;j < nSize;j++) printf("%8d ",Cb[i][j]);puts("");}

ComputeValrank(nSize,&(tab[0]),C1,C2,Cb);

/* 
if (intriangle(r,s,&(tab[0].s)) == 1) 
    {
    addList(nSize,&(tab[0].s),listePE);
    calculborne(listePE,borne,r,s,deltaZ1,deltaZ2,&valinitCd,taillePEinit);//printf("actu : borne = %d\n",*borne);
    }
*/

min = tab[0].value;
while(min <= *borne)
    {
    //avec le nouvel element du ranking, mise a jour eventuelle de la liste de solutions et 
    if ( (intriangle(r,s,tab[0].s) == 1) && ( (estdominee(tab[0].s,listePE,taillePEinit) == 0) ) )
        {            
        if(isMember2(nSize,tab[0].s,listePE,taillePEinit) == 0)
            {
            addList(nSize,tab[0].s,listePE);
            calculborne(listePE,borne,r,s,deltaZ1,deltaZ2,&valinitCd,taillePEinit);//printf("actu : borne = %d\n",*borne);
            }
        //else addList(nSize,tab[0].s,listePE);
        }
    tab = ComputeNextSolution(tab,&tailletab,&taille,Cb,C1,C2,nSize,borne);
    if (tailletab != 0) min = tab[0].value;//printf("min = %d et borne = %d\n",min,(*borne));
    else min = (*borne) + 1;
    //showSolution(0, nSize, tab[0].s);
    }    

//liberation de la memoire
for(i = 0;i < tailletab;i++)
    {
    tab[i].I = supprimerliste(tab[i].I);
    free(tab[i].s);
    }
free(tab);
//printf("tailletab = %d\n",tailletab);
}

void lancerLesTest(short int nSize,int C1[SizeMax][SizeMax],int C2[SizeMax][SizeMax],
                    solution *r,solution *s,listeSol *listePE,int premier,int dernier)
{
printf("recherche dans le triangle defini par (%d,%d) et (%d,%d)\n",r->z[0],r->z[1],s->z[0],s->z[1]);

/* deltaZ1 est le la largeur du triangle, deltaZ2 est la hauteur, borne est la limite qu'il est inutile de depasser */

int deltaZ1 = s->z[0] - r->z[0],deltaZ2 = r->z[1] - s->z[1];
int borne = deltaZ1 * deltaZ2 - deltaZ1 - deltaZ2;

/* S'il y a quelque chose a explorer... */

if (borne >=0)
    {
    int Cd[SizeMax][SizeMax];
    combiConvexe(deltaZ1,deltaZ2,nSize,Cd,C1,C2);
    ranking(C1,C2,Cd,&borne,nSize,r,s,listePE);
    }
}

void solve_bilap_exact(int *c1, int *c2, int nSize, int **z1, int **z2, int **solutions, int* nbsolutions)
{
int i,j,k,lg;
int C1[SizeMax][SizeMax],C2[SizeMax][SizeMax],Cd[SizeMax][SizeMax];
solution s;
int Ctemp[SizeMax][SizeMax];
listeSol listePE;


/* Initialisation ------------------------------------------------- */

  for(i = 0;i < nSize;i++)
  	for(j = 0;j < nSize;j++) C1[i][j] = c1[i*nSize + j];
  for(i = 0;i < nSize;i++)
  	for(j = 0;j < nSize;j++) C2[i][j] = c2[i*nSize + j];
  listePE.lgListe    = 0;

/* ---- CALCUL DES SE --------------------------------------------- */

  /* ---- Recherche efficace sur z1 --------------------------------- */
  printf("\n OK \n");
  hung(C1,nSize,&s,Ctemp);
  
  s.z[1] = 0;
  for(i = 0;i < nSize;i++) s.z[1] += C2[i][s.X[i]];
    
  combiConvexe(1,s.z[1] + 1,nSize,Cd,C1,C2);

  hung(Cd,nSize,&s,Ctemp);
    
  addList(nSize,&s,&listePE);
  
  /* ---- Recherche efficace sur z2 --------------------------------- */

  hung(C2,nSize,&s,Ctemp);
  
  s.z[0] = 0;
  for(i = 0;i < nSize;i++) s.z[0] += C1[i][s.X[i]];
  
  combiConvexe(s.z[0] + 1,1,nSize,Cd,C1,C2);
  
  hung(Cd,nSize,&s,Ctemp);
  
  addList(nSize,&s,&listePE);

  for(i = 0;i < 2;i++)
  	{
	listePE.liste[i].z[0] = 0;
	listePE.liste[i].z[1] = 0;
	}

  for(i = 0;i < 2;i++)
  	for(j = 0;j < nSize;j++)
		{
		listePE.liste[i].z[0] += C1[j][listePE.liste[i].X[j]];
		listePE.liste[i].z[1] += C2[j][listePE.liste[i].X[j]];
		}

  if (listePE.liste[0].z[0] == listePE.liste[1].z[0]) 
	{
		puts("solution ideale");
		*z1 = calloc(1, sizeof(int));
	   	*z2 = calloc(1, sizeof(int));
	   	*solutions = calloc(nSize, sizeof(int));
	   	*nbsolutions = 1;

	   	(*z1)[0] = (listePE.liste[0]).z[0];
	   	(*z2)[0] = (listePE.liste[0]).z[1];
	   	for(j = 0; j < nSize; j++){
	     	(*solutions)[j] = (listePE.liste[0]).X[j];
	   	}

	   	return;
		
	}


  /* ---- Resolution dichotomique ----------------------------------- */
     
     printf(" \n Calculs en cours... \n");
     puts("phase 1");

     resolutionRecursive(listePE.liste[0].z[0],listePE.liste[0].z[1],listePE.liste[listePE.lgListe - 1].z[0],
                         listePE.liste[listePE.lgListe - 1].z[1],nSize,C1,C2,
                         &listePE);

  /* nombre de solutions supportees */

     lg = listePE.lgListe;

  /* tri de ces solutions suivant Z[0] */

     sortApproximation1(&(listePE.liste[0]),lg);

  /* lancement de la phase 2 */

     puts("phase 2");

     j = 0;
     while(listePE.liste[j].z[0] == listePE.liste[j + 1].z[0]) j++;

     i = lg - 2;
     while(listePE.liste[i].z[0] == listePE.liste[i + 1].z[0]) i--;

     if (i == j) lancerLesTest(nSize,C1,C2,&(listePE.liste[j]),&(listePE.liste[j + 1]),
                               &listePE,1,1);
          else
	  {
          lancerLesTest(nSize,C1,C2,&(listePE.liste[j]),&(listePE.liste[j + 1]),&listePE,1,0);
          lancerLesTest(nSize,C1,C2,&(listePE.liste[i]),&(listePE.liste[i + 1]),&listePE,0,1);
	  for(k = j + 1;k < i;k++) if (listePE.liste[k].z[0] != listePE.liste[k + 1].z[0]) lancerLesTest(nSize,C1,C2,&(listePE.liste[k]),&(listePE.liste[k + 1]),&listePE,0,0);
           }

  /* fin : affichage des resultats */
	 
     sortApproximation1(&(listePE.liste[lg]),listePE.lgListe - lg);
     printf("\n\n Compte-rendu\n");
     printf(" ============\n\n");

     for(i = 0; i < listePE.lgListe; i++)
       showSolution(i, nSize, &(listePE.liste[i]));
     printf(" -- \n");
     // printf("time : %lf (sec) \n",temps);

     printf(" Nbre Points non-domines Phase 1 (Supportes extremes + qques non-extremes) : %d\n",      lg);
     printf(" Nbre Points non-domines Phase 2 : %ld\n",  listePE.lgListe - lg);
	 printf(" Nbre Total : %ld\n", listePE.lgListe);
   
   *z1 = calloc(listePE.lgListe, sizeof(int));
   *z2 = calloc(listePE.lgListe, sizeof(int));
   *solutions = calloc(listePE.lgListe * nSize, sizeof(int));
   *nbsolutions = listePE.lgListe;


   for (i = 0; i < listePE.lgListe ; i++){
	   (*z1)[i] = (listePE.liste[i]).z[0];
	   (*z2)[i] = (listePE.liste[i]).z[1];
	   for(j = 0; j < nSize; j++){
	     (*solutions)[i*nSize + j] = (listePE.liste[i]).X[j];
	   }
	}
	//FILE * fOut1;
	//fOut1 = fopen("res2ph.txt","wt");
	//fprintf(fOut1,"%ld\n",listePE.lgListe);
	//fprintf(fOut1,"%d %d\n",(listePE.liste[0]).z[0],(listePE.liste[0]).z[1]); 
	//for(i = 1;i < listePE.lgListe;i++) 
		//if ( (listePE.liste[i]).z[0] != (listePE.liste[i - 1]).z[0] )  
			//fprintf(fOut1,"%d %d\n",(listePE.liste[i]).z[0],(listePE.liste[i]).z[1]);
	//fclose(fOut1);
}

/* EOF */
