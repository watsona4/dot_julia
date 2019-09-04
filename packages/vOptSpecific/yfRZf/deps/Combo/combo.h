//
//  combo.h
//  
//
//  Created by Audrey on 17/04/13.
//
//

#ifndef _combo_h
#define _combo_h

typedef int           boolean; /* logical variable         */
typedef int           ntype;   /* number of states/items   */
typedef long long     itype;   /* item profits and weights */
typedef long long     stype;   /* sum of profit or weight  */
typedef unsigned long btype;   /* binary solution vector   */
typedef double        prod;    /* product of state, item   */

typedef int (*funcptr) (const void *, const void *);

/* item record */
typedef struct {
   itype   p;              /* profit                     */
   itype   w;              /* weight                  	  */
   boolean x;              /* solution variable      	  */
   ntype 	 i;				  /* initial index in the table */
} item;

stype combo(item *f, item *l, stype c, stype lb, stype ub,
            boolean def, boolean relx);

stype solve(item *f, ntype sz, stype c, stype lb, stype ub);


#endif


/* Utilisation :
 
  item *prob // Déclaration d'un problème
  int index
 
  prob = (item *) malloc ((d->nbItem) * sizeof(item)); // allocation pour le problème (ici, d contient les données)
  
  for(i = 0;i < d->nbItem;i++)
  {
  prob[i].w = ???; // poids de l'item i
  prob[i].p = ???; // profit de l'item i
  prob[i].i = i; // indice de l'item i
  }
 
 capa = ???; // omega
 maxZ = ???; // borne sup sur z (on peut prendre simplement la somme des profits de tous les items)

 // Appel à combo
  s->z = combo(&prob[0], &prob[d->nbItem - 1], capa, 0, maxZ, 1, 1);

 // récupération des résultats
   
 for (i = 0; i < d->nbItem; i++)
 {
 index = prob[i].i; // on retrouve l'indice original de l'objet
 s->tab[index] = prob[i].x; // s->tab correspond à mon tableau pour les valeurs des variables
 }

 free(prob);

*/