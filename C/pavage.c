#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <limits.h>
#define DEBUG_LOAD 1
#define MAX_COLORS 275
/** Format des fichiers :
 * 
 * 
 * 
*/


/* Structures */
// RGB: stocker une couleur
typedef struct {
    int R; int G; int B;
} RGB;
// Image: 
//  - dimensions 
//  - rgb =  tableau de W*H couleurs 
//    coordonnées (x,y) dans l'image -> case y*W + x du tableau
typedef struct {
    int W;
    int H;
    RGB* rgb;
} Image; 
// Liste de brique disponibles
// - nShape, W, H, T : tableaux de formes possibles (1x1, 1x2, etc), T = trous
// - nCol, bCol : tableau de couleurs possibles (RGB)
// - nBrique, bCol, bShape, bStock : liste de briques)
//    (indice de la couleur, indice de la forme, quantité en stock)
typedef struct {
    int nShape;
    int nCol; 
    int nBrique;
    int* W;
    int* H;
    int* T;
    RGB* col;
    int* bCol;
    int* bShape;
    int* bPrix;
    int* bStock;
} BriqueList;
// Une brique placée dans la solution (référence de brique, coordonnées, rotation)
typedef struct {
    int iBrique;
    int x;
    int y;
    int rot;
} SolItem;
// Solution complète (liste de briques placées + statistiques)
typedef struct {
    int length;
    int totalError;
    int cost;
    int stock;
    SolItem* array;
} Solution;



/*** Gestion des fichiers ***/
FILE* open_with_dir(char* dir, char* name, char* mode) {
    char filename[256];
    snprintf(filename, sizeof(filename), "%s/%s", dir,name);
    printf("open file %s (%s)\n", filename, mode);
    FILE* fptr = fopen(filename, mode);
    assert(fptr!=NULL);
    return fptr;
}

/*** Image & couleur ***/

RGB* get(Image* I, int x, int y) {
    return &(I->rgb[y*I->W + x]);
}
void reset(RGB* col) {
    col->R=0;
    col->G=0;
    col->B=0;
}

int colError(RGB c1, RGB c2) {
    return (c1.R-c2.R)*(c1.R-c2.R) + (c1.G-c2.G)*(c1.G-c2.G) + (c1.B-c2.B)*(c1.B-c2.B);
}


/*** Tableau Solution ***/
//initialisation
void init_sol(Solution* sol, Image* I) {
    sol->length=0;
    sol->totalError=0;
    sol->cost=0;
    sol->stock=0;
    //on alloue suffisament pour le pire cas (= une brique par pixel)
    sol->array =malloc(I->W*I->H*sizeof(SolItem));
}
//ajout d'une brique au pavage
void push_sol(Solution* sol, int iBrique, int x, int y, int rot, Image* I, BriqueList* B) {
    assert(sol->length < I->W*I->H);
    sol->array[sol->length].iBrique = iBrique;
    sol->array[sol->length].x = x;
    sol->array[sol->length].y = y;
    sol->array[sol->length].rot = rot;    
    sol->length++;
    sol->cost+=B->bPrix[iBrique];
}
//calcul des stocks
void fill_sol_stock(Solution* sol, BriqueList* B){
    int* used = calloc(B->nBrique, sizeof(int));
    for (int i=0; i<sol->length; i++){
        used[sol->array[i].iBrique]++;
    }
    for (int i=0;i<B->nBrique; i++) {
        int diff= used[i] - B->bStock[i];
        if (diff>0)
            sol->stock+=diff;
    }
    free(used);
}
/** Trous **/

int charToMask(char c) {
    assert(c>='0' && c<='9');
    return 1<<(c-'0');
}
int coordToMask(int dx, int dy, int W) {
    return 1<<(dx + W*dy);
}

int trou_str_to_int(char* buffer) {
    int T=0;
    for (int ibuffer=0; buffer[ibuffer]; ibuffer++) {
        T+=charToMask(buffer[ibuffer]);
    }
    return T;
}
void trou_int_to_str(int T,  char* buffer) {
    int ibuffer=0;
    char current = '0';
    while (T>0) {
        assert(current<='9'); //trous max = 3x3
        if (T%2 == 1) {
            buffer[ibuffer]= current;
            ibuffer++;
            T--;
        }
        current+=1;
        T/=2;
    }
    buffer[ibuffer] = 0;
}
//Teste si une brique (avec trous et rotation) couvre les coordonnées rotx et roty (avec coin haut gauche =0,0)
int BriqueCovers(BriqueList* B, int ishape, int rot, int rotx, int roty) {
    int W=B->W[ishape];
    int H=B->H[ishape];
    int T=B->T[ishape];
    //on calcule les coordonnées par rapport à la forme de base de la pièce (hors rotation)
    int dx=rotx;
    int dy=roty;
    if (rot==1) {
        dx=roty;
        dy=H-rotx-1;    
    } else if (rot==2) {
        dx=W-rotx-1;
        dy=H-roty-1;    
    } else if (rot==3) {
        dx=W-roty-1;
        dy=rotx;    
    }
    //on vérifie les bornes (W, H)
    if (dx<0 || dy<0 || dx>=W || dy>=H)
        return 0;
    //on vérifie que dx,dy ne tombe pas dans un trou
    if (T!= 0  && (T & coordToMask(dx, dy, W))) 
        return 0;
    return 1;
}

/** Export de solution **/
void print_sol(Solution* sol, char* dir, char* name, BriqueList* B) {
    printf("%s/%s %d %d %d\n",dir, name, sol->cost, sol->totalError, sol->stock);
    FILE* fptr=open_with_dir(dir, name, "w");
    fprintf(fptr, "%d %d %d %d\n",sol->length, sol->cost, sol->totalError, sol->stock);
    for (int i=0; i<sol->length; i++) {
        int ibrique = sol->array[i].iBrique;
        int ishape=B->bShape[ibrique];
        int icol=B->bCol[ibrique];
        if (B->T[ishape]==0) {
            fprintf(fptr, "%dx%d/%02x%02x%02x %d %d %d\n", 
                B->W[ishape], B->H[ishape], B->col[icol].R, B->col[icol].G, B->col[icol].B, sol->array[i].x, sol->array[i].y, sol->array[i].rot);
        } else {
            char buffer[20];

            trou_int_to_str(B->T[ishape], buffer);
            fprintf(fptr, "%dx%d-%s/%02x%02x%02x %d %d %d\n", 
                B->W[ishape], B->H[ishape],buffer,  B->col[icol].R, B->col[icol].G, B->col[icol].B, sol->array[i].x, sol->array[i].y, sol->array[i].rot);
        }
    }
}
/*** Chargement ***/
//lecture du fichier image 
void load_image(char* dir, Image* I) {
    FILE* fptr = open_with_dir(dir, "image.txt", "r");
    fscanf(fptr, "%d %d", &I->W, &I->H);
    I->rgb=malloc(I->W*I->H*sizeof(RGB));
    for (int j=0;j<I->H;j++) {
        for (int i=0;i<I->W;i++) {
            RGB col;
            reset(&col);
            int count= fscanf(fptr, "%02x%02x%02x", &col.R, &col.G, &col.B);
            assert(count==3); //otherwise: file incomplete
            *get(I, i, j) = col;          
            if (DEBUG_LOAD)
                printf(" %02x%02x%02x", col.R, col.G, col.B);  
        }
        if (DEBUG_LOAD)
            printf("\n");
    }
    fclose(fptr);
    if (DEBUG_LOAD)
        printf("Image loaded, %dx%d\n", I->W, I->H);
}
void load_brique(char* dir, BriqueList* B) {
    FILE* fptr = open_with_dir(dir, "briques.txt", "r");
    fscanf(fptr, "%d %d %d", &B->nShape, &B->nCol, &B->nBrique);
    assert(B->nCol<=MAX_COLORS);

    B->W = malloc(B->nShape * sizeof(int));
    B->H = malloc(B->nShape * sizeof(int));
    B->T = malloc(B->nShape * sizeof(int));
    B->col = malloc(B->nCol * sizeof(RGB));
    B->bCol = malloc(B->nBrique * sizeof(int));
    B->bShape = malloc(B->nBrique * sizeof(int));
    B->bPrix = malloc(B->nBrique * sizeof(int));
    B->bStock = malloc(B->nBrique * sizeof(int));
    if (DEBUG_LOAD)
        printf("%d shapes, %d colors, %d bricks\nShapes: ", B->nShape, B->nCol, B->nBrique);
    char buffer[80];
    for (int i=0; i<B->nShape; i++) {
        int count =fscanf(fptr, "%d-%d-%s", &B->W[i],  &B->H[i], buffer);
        assert(count>=2 && count<=3);
        if (DEBUG_LOAD)
            printf("[%d]%d-%d ",i,  B->W[i],  B->H[i]);
        if (count==3) {
            int T=0;
            for (int ibuffer=0; buffer[ibuffer]; ibuffer++) {
                T+=charToMask(buffer[ibuffer]);
            }
            B->T[i]=T;
            if (DEBUG_LOAD)
                printf("(%s -> %d) ",buffer, T );
        } else 
            B->T[i]=0;
    }
    if (DEBUG_LOAD)
        printf("\nColors: ");        
    for (int i=0; i<B->nCol; i++) { 
        RGB col;
        int count= fscanf(fptr, "%02x%02x%02x", &col.R, &col.G, &col.B);
        assert(count==3);
        B->col[i]=col;
        if (DEBUG_LOAD)
         printf("[%d]%02x%02x%02x",i, col.R, col.G, col.B);              
    }

    if (DEBUG_LOAD)
        printf("\nBriques: ");        
    for (int i=0; i<B->nBrique; i++) { 
        int count= fscanf(fptr, "%d/%d %d %d", &B->bShape[i], &B->bCol[i], &B->bPrix[i], &B->bStock[i]);
        assert(count==4);
        if (DEBUG_LOAD)
         printf("[%d]%d/%d %d€x%d ",i, B->bShape[i], B->bCol[i], B->bPrix[i], B->bStock[i]); 
    }
    if (DEBUG_LOAD)
        printf("\nLoading complete\n");        
       
}

void freeData(Image I, BriqueList B) {
    free(I.rgb);
    free(B.W);
    free(B.H);
    free(B.T);
    free(B.col);
    free(B.bShape);
    free(B.bCol);
    free(B.bPrix);
    free(B.bStock);
}
void freeSolution(Solution S) {

    free(S.array);
}

/*** Outil de recherche de brique ***/

int lookupShape(BriqueList* B, int W, int H) {
    for (int i=0; i<B->nShape; i++) {
        if (B->W[i]==W && B->H[i]==H) 
            return i;
    }
    return -1;
}
/*** Question TP Noté ***/

//Q1 
int getIndex(int x, int y, Image* I) {
    assert(I != NULL);
    assert(x >= 0 && x < I->W);
    assert(y >= 0 && y < I->H);
    return x + I->W * y;
}

//Q2
int neighborIndex(int u, int dir, Image* I) {
    int x = u % I->W;
    int y = u / I->W;
    if (dir == 0) y--;
    else if (dir == 1) x++;
    else if (dir == 2) y++;
    else if (dir == 3) x--;
    if (x < 0 || x >= I->W || y < 0 || y >= I->H) return -1;
    return getIndex(x, y, I);
}

//Q3
typedef struct {
    int* match; 
    int size;
} Matching;

//Q4
#define UNMATCHED (-1)

//Q5
void init(Matching* M, Image* I) {
    M->size = I->W * I->H;
    M->match = malloc(M->size * sizeof(int));
    assert(M->match != NULL);
    for (int i = 0; i < M->size; i++) M->match[i] = UNMATCHED;
}

//Q6
int getMatch(Matching* M, int u) {
    assert (M != NULL);
    assert(u >= 0 && u < M-> size);
    return M->match[u];
}

//Q7

//Fonction auxiliaire pour comparer les couleurs 
int sameColor(RGB a, RGB b) {
    return (a.R == b.R && a.G == b.G && a.B == b.B);
}

void greedyInsert(Matching* M, int u, Image* I) {
     for (int dir = 0; dir < 4; dir++) {
        int v = neighborIndex(u, dir, I);
        if (v == -1) continue;
        if (sameColor(I->rgb[v], I->rgb[u]) && M->match[v] == UNMATCHED) {
            M->match[u] = v;
            M->match[v] = u;
            break;
        }
     }
}

//Q8
void greedyInsertSuccessive(Matching* M, Image* I) {
    for (int u = 0; u < M->size; u++) {
        if (M->match[u] == UNMATCHED)
            greedyInsert(M, u, I);
    }
}

//Q9

int liberer(Matching* M, int u, Image* I, int* visited) {
    assert(M != NULL);
    assert(I != NULL);
    assert(visited != NULL);
    assert(u >= 0 && u < M->size);
    if (visited[u]) return 0;
    visited[u] = 1;
    if (M->match[u] == UNMATCHED)
        return 1;
    int v = M->match[u];
    for (int dir = 0; dir < 4; dir++) {
        int w = neighborIndex(v, dir, I);
        if (w == -1) continue;
        if (sameColor(I->rgb[v], I->rgb[w])) {
            if (liberer(M, w, I, visited)) {
                M->match[v] = w;
                M->match[w] = v;
                return 1;
            }
        }
    }
    return 0;
}

//Q10
void optimalInsert(Matching* M, int u, Image* I) {
    int N = I->W * I->H;
    int visited[N];
    
    for (int i = 0; i < N; i++) {
        visited[i] = 0;
    }

    for (int dir = 0; dir < 4; dir++) {
        int v = neighborIndex(u, dir, I);
        if (v == -1) continue;
        if (sameColor(I->rgb[u], I->rgb[v])) {
            if (M->match[v] == UNMATCHED || liberer(M, v, I, visited)) {
                M->match[u] = v;
                M->match[v] = u;
                return;
            }
        }
    }
}

//Q11

void optimalInsertwithMatching(Matching* M, Image* I) {
    for (int u = 0; u < M->size; u++) {
        if (M->match[u] == UNMATCHED)
            optimalInsert(M, u, I);
    }
}
 

/*** algorithmes de pavage ***/

/*** pavage 1x1 + matching ***/
Solution run_algo1(Image* I, BriqueList* B) {
    Solution S;
    init_sol(&S, I);
    int shape11 = lookupShape(B, 1, 1);
    int brique11WithColor[MAX_COLORS];
    for (int i=0; i<MAX_COLORS; i++){
        brique11WithColor[i]=-1;
    }
    for (int i=0; i<B->nBrique; i++ ) {
        if (B->bShape[i]==shape11) {
            int col=B->bCol[i];
            assert(brique11WithColor[col]==-1);
            brique11WithColor[col]=i;
        }

    }
    int* closestColor = malloc(I->W*I->H *sizeof(int));
    int totalError = 0;
    for (int y=0; y<I->H; y++) {
        for (int x=0; x<I->W; x++) {
            int bestCol=-1;
            int bestColError=INT_MAX;
            for (int i=0; i<B->nCol; i++) {
                if (brique11WithColor[i]==-1)
                    continue;
                int error = colError(B->col[i], *get(I, x, y));
                if (error < bestColError ) {
                    bestColError = error;
                    bestCol=i;
                }    
            }
            assert(bestCol>=0);
            closestColor[getIndex(x,y, I)] = bestCol;
            totalError+=bestColError;
        }
    }

    S.totalError=totalError;
    for (int y=0; y<I->H; y++) {
        for (int x=0; x<I->W; x++) {
            int u= getIndex(x,y, I);
            push_sol(&S, brique11WithColor[closestColor[u]], x, y, 0, I, B);
        }
    }
    fill_sol_stock(&S, B);
    free(closestColor);

    assert(S.length == I->W*I->H);
    return S;
}

//Je crée des fonctions pour tester outOptMatching et outGreedyMatching  
Solution run_greedy_matching(Image* I, BriqueList* B) {
    Matching M;
    init(&M, I);
    greedyInsertSuccessive(&M, I);

    Solution S;
    init_sol(&S, I);

    int shape21 = lookupShape(B, 2, 1);
    int shape12 = lookupShape(B, 1, 2); 
    int shape11 = lookupShape(B, 1, 1);

    for (int u = 0; u < M.size; u++) {
        int v = getMatch(&M, u);
        
        if (v != UNMATCHED) {
            if (u < v) {
                int x1 = u % I->W, y1 = u / I->W;
                int x2 = v % I->W, y2 = v / I->W;
                int iBrique = -1, rot = 0;

                if (y1 == y2) { 
                    for (int b = 0; b < B->nBrique; b++) {
                        if (B->bShape[b] == shape21 && sameColor(B->col[B->bCol[b]], I->rgb[u])) {
                            iBrique = b; break;
                        }
                    }
                    rot = 0;
                } else if (x1 == x2) { 
                    for (int b = 0; b < B->nBrique; b++) {
                        if (B->bShape[b] == shape12 && sameColor(B->col[B->bCol[b]], I->rgb[u])) {
                            iBrique = b; break;
                        }
                    }
                    rot = 0;
                }

                if (iBrique >= 0) {
                    push_sol(&S, iBrique, x1, y1, rot, I, B);
                } 
                else { 
                    int b1 = -1, bestErr1 = INT_MAX;
                    for (int b = 0; b < B->nBrique; b++) {
                        if (B->bShape[b] == shape11) {
                            int err = colError(B->col[B->bCol[b]], I->rgb[u]);
                            if (err < bestErr1) { bestErr1 = err; b1 = b; }
                        }
                    }
                    if (b1 != -1) push_sol(&S, b1, x1, y1, 0, I, B);

                    int b2 = -1, bestErr2 = INT_MAX;
                    for (int b = 0; b < B->nBrique; b++) {
                        if (B->bShape[b] == shape11) {
                            int err = colError(B->col[B->bCol[b]], I->rgb[v]);
                            if (err < bestErr2) { bestErr2 = err; b2 = b; }
                        }
                    }
                    if (b2 != -1) push_sol(&S, b2, x2, y2, 0, I, B);
                }
            }
        } 
        else {
            int x = u % I->W;
            int y = u / I->W;
            int bestBrique = -1, bestErr = INT_MAX;
            
            for (int b = 0; b < B->nBrique; b++) {
                if (B->bShape[b] == shape11) {
                    int err = colError(B->col[B->bCol[b]], I->rgb[u]);
                    if (err < bestErr) {
                        bestErr = err;
                        bestBrique = b;
                    }
                }
            }
            if (bestBrique != -1)
                push_sol(&S, bestBrique, x, y, 0, I, B);
        }
    }

    fill_sol_stock(&S, B);
    free(M.match);
    return S;
}

Solution run_optimal_matching(Image* I, BriqueList* B) {
    Matching M;
    init(&M, I);
    optimalInsertwithMatching(&M, I);

    Solution S;
    init_sol(&S, I);

    int shape21 = lookupShape(B, 2, 1);
    int shape12 = lookupShape(B, 1, 2);
    int shape11 = lookupShape(B, 1, 1);

    for (int u = 0; u < M.size; u++) {
        int v = getMatch(&M, u);
        
        if (v != UNMATCHED) {
            if (u < v) {
                int x1 = u % I->W, y1 = u / I->W;
                int x2 = v % I->W, y2 = v / I->W;
                int iBrique = -1, rot = 0;

                if (y1 == y2) { 
                    for (int b = 0; b < B->nBrique; b++) {
                        if (B->bShape[b] == shape21 && sameColor(B->col[B->bCol[b]], I->rgb[u])) {
                            iBrique = b; break;
                        }
                    }
                    rot = 0;
                } else if (x1 == x2) { 
                    for (int b = 0; b < B->nBrique; b++) {
                        if (B->bShape[b] == shape12 && sameColor(B->col[B->bCol[b]], I->rgb[u])) {
                            iBrique = b; break;
                        }
                    }
                    rot = 0;
                }

                if (iBrique >= 0) {
                    push_sol(&S, iBrique, x1, y1, rot, I, B);
                } else {
                    int b1 = -1, bestErr1 = INT_MAX;
                    for (int b = 0; b < B->nBrique; b++) {
                        if (B->bShape[b] == shape11) {
                            int err = colError(B->col[B->bCol[b]], I->rgb[u]);
                            if (err < bestErr1) { bestErr1 = err; b1 = b; }
                        }
                    }
                    push_sol(&S, b1, x1, y1, 0, I, B);

                    int b2 = -1, bestErr2 = INT_MAX;
                    for (int b = 0; b < B->nBrique; b++) {
                        if (B->bShape[b] == shape11) {
                            int err = colError(B->col[B->bCol[b]], I->rgb[v]);
                            if (err < bestErr2) { bestErr2 = err; b2 = b; }
                        }
                    }
                    push_sol(&S, b2, x2, y2, 0, I, B);
                }
            }
        } 
        else {
            int x = u % I->W;
            int y = u / I->W;
            int bestBrique = -1, bestErr = INT_MAX;
            
            for (int b = 0; b < B->nBrique; b++) {
                if (B->bShape[b] == shape11) {
                    int err = colError(B->col[B->bCol[b]], I->rgb[u]);
                    if (err < bestErr) {
                        bestErr = err;
                        bestBrique = b;
                    }
                }
            }
            if (bestBrique != -1)
                push_sol(&S, bestBrique, x, y, 0, I, B);
        }
    }

    fill_sol_stock(&S, B);
    free(M.match);
    return S;
}

int in_bounds_2x2(int x, int y, Image* I) {
    return (x + 1 < I->W && y + 1 < I->H);
}

int find_brique_for_shape_and_color(BriqueList* B, int shape, RGB color) {
    for (int b = 0; b < B->nBrique; b++) {
        if (B->bShape[b] == shape && sameColor(B->col[B->bCol[b]], color))
            return b;
    }
    return -1;
}

int find_best_brique_for_shape_color(BriqueList* B, int shape, RGB target) {
    int best = -1, bestErr = INT_MAX;
    for (int b = 0; b < B->nBrique; b++) {
        if (B->bShape[b] != shape) continue;
        int err = colError(B->col[B->bCol[b]], target);
        if (err < bestErr) {
            bestErr = err;
            best = b;
        }
    }
    return best;
}


Solution run_place_2x2(Image* I, BriqueList* B, int* assigned) {
    Solution S;
    init_sol(&S, I);

    int shape22 = lookupShape(B, 2, 2);
    if (shape22 < 0) return S;

    int* closest = malloc(I->W * I->H * sizeof(int));

    for (int y = 0; y < I->H; y++) {
        for (int x = 0; x < I->W; x++) {
            int bestCol = -1, bestErr = INT_MAX;
            for (int c = 0; c < B->nCol; c++) {
                int err = colError(B->col[c], *get(I, x, y));
                if (err < bestErr) {
                    bestErr = err;
                    bestCol = c;
                }
            }
            closest[getIndex(x, y, I)] = bestCol;
        }
    }

    for (int y = 0; y < I->H - 1; y++) {
        for (int x = 0; x < I->W - 1; x++) {

            if (!in_bounds_2x2(x, y, I)) continue;

            int idx0 = getIndex(x, y, I);
            if (assigned[idx0]) continue;

            int c = closest[idx0];
            int coords[4] = {
                getIndex(x, y, I),
                getIndex(x+1, y, I),
                getIndex(x, y+1, I),
                getIndex(x+1, y+1, I)
            };

            int ok = 1;
            for (int k = 0; k < 4; k++) {
                if (assigned[coords[k]] || closest[coords[k]] != c) {
                    ok = 0;
                    break;
                }
            }
            if (!ok) continue;

            int br = find_brique_for_shape_and_color(B, shape22, B->col[c]);
            if (br < 0) {
                RGB avg = {0,0,0};
                for (int k = 0; k < 4; k++) {
                    RGB p = I->rgb[coords[k]];
                    avg.R += p.R; avg.G += p.G; avg.B += p.B;
                }
                avg.R/=4; avg.G/=4; avg.B/=4;
                br = find_best_brique_for_shape_color(B, shape22, avg);
                if (br < 0) continue;
            }

            push_sol(&S, br, x, y, 0, I, B);
            for (int k = 0; k < 4; k++) assigned[coords[k]] = 1;
        }
    }

    free(closest);
    return S;
}

Solution merge_2x2_to_4x2(Image* I, BriqueList* B, Solution* base) {
    Solution S;
    init_sol(&S, I);

    int shape22 = lookupShape(B, 2, 2);
    int shape42 = lookupShape(B, 4, 2);

    if (shape42 < 0) {
        for (int i = 0; i < base->length; i++)
            push_sol(&S, base->array[i].iBrique, base->array[i].x, base->array[i].y, 0, I, B);
        return S;
    }

    int* used = calloc(base->length, sizeof(int));

    for (int i = 0; i < base->length; i++) {
        if (used[i]) continue;

        SolItem A = base->array[i];
        if (B->bShape[A.iBrique] != shape22) continue;
        for (int j = 0; j < base->length; j++) {
            if (i == j || used[j]) continue;

            SolItem Bk = base->array[j];
            if (B->bShape[Bk.iBrique] != shape22) continue;

            if (A.y == Bk.y && A.x + 2 == Bk.x) {
                int colA = B->bCol[A.iBrique];
                int colB = B->bCol[Bk.iBrique];
                if (colA == colB) {
                    int br = -1;
                    for (int b = 0; b < B->nBrique; b++)
                        if (B->bShape[b] == shape42 && B->bCol[b] == colA)
                            br = b;

                    if (br >= 0) {
                        push_sol(&S, br, A.x, A.y, 0, I, B);
                        used[i] = used[j] = 1;
                    }
                }
            }
        }
    }

    for (int i = 0; i < base->length; i++)
        if (!used[i])
            push_sol(&S, base->array[i].iBrique, base->array[i].x, base->array[i].y, 0, I, B);

    free(used);
    return S;
}

void repair_stock(Solution* S, Image* I, BriqueList* B) {
    int* used = calloc(B->nBrique, sizeof(int));
    for (int i=0; i<S->length; i++)
        used[S->array[i].iBrique]++;

    for (int b = 0; b < B->nBrique; b++) {
        int excess = used[b] - B->bStock[b];
        if (excess <= 0) continue;

        for (int i = 0; i < S->length && excess > 0; i++) {
            if (S->array[i].iBrique != b) continue;
            int shape = B->bShape[b];
            int best = -1, bestErr = INT_MAX;
            for (int bb = 0; bb < B->nBrique; bb++) {
                if (B->bShape[bb] != shape || bb == b) continue;
                if (used[bb] >= B->bStock[bb]) continue;

                RGB pix = *get(I, S->array[i].x, S->array[i].y);
                int err = colError(B->col[B->bCol[bb]], pix);

                if (err < bestErr) {
                    bestErr = err;
                    best = bb;
                }
            }

            if (best >= 0) {
                used[b]--;
                used[best]++;
                S->array[i].iBrique = best;
                excess--;
            }
        }
    }

    free(used);
}

Solution run_version3(Image* I, BriqueList* B) {
    Solution base = run_algo1(I, B);

    int* assigned = calloc(I->W * I->H, sizeof(int));

    Solution S2 = run_place_2x2(I, B, assigned);
    Solution S4 = merge_2x2_to_4x2(I, B, &S2);

    Solution Final;
    init_sol(&Final, I);

    for (int i = 0; i < S4.length; i++)
        push_sol(&Final, S4.array[i].iBrique, S4.array[i].x, S4.array[i].y, 0, I, B);

    for (int y = 0; y < I->H; y++) {
        for (int x = 0; x < I->W; x++) {
            int u = getIndex(x, y, I);
            if (!assigned[u]) {
                int bidx = base.array[u].iBrique;
                push_sol(&Final, bidx, x, y, 0, I, B);
            }
        }
    }

    repair_stock(&Final, I, B);
    fill_sol_stock(&Final, B);

    free(assigned);
    freeSolution(base);
    freeSolution(S2);
    freeSolution(S4);

    return Final;
}

Solution run_low_cost(Image* I, BriqueList* B) {
    Solution S;
    init_sol(&S, I);
    
    int shape11 = lookupShape(B, 1, 1);
    
    int TOLERANCE = 5000; 

    for (int y = 0; y < I->H; y++) {
        for (int x = 0; x < I->W; x++) {
            
            int bestBrique = -1;
            int minPrice = INT_MAX;
            int minError = INT_MAX;
        
            for (int i = 0; i < B->nBrique; i++) {
                if (B->bShape[i] != shape11) continue;
                
                int icol = B->bCol[i];
                int prix = B->bPrix[i];
                int error = colError(B->col[icol], *get(I, x, y));
                
                if (error < TOLERANCE) {
                    if (prix < minPrice) {
                        minPrice = prix;
                        bestBrique = i;
                    }
                } 
                else if (minPrice == INT_MAX && error < minError) {
                    minError = error;
                    bestBrique = i;
                }
            }
        
            if (bestBrique == -1) { 
                 for(int i=0; i<B->nBrique; i++) 
                    if(B->bShape[i] == shape11) { bestBrique=i; break;}
            }

            push_sol(&S, bestBrique, x, y, 0, I, B);
        }
    }
    fill_sol_stock(&S, B);
    return S;
}

Solution run_any_shape(Image* I, BriqueList* B) {
    Solution S;
    init_sol(&S, I);
    
    int* assigned = calloc(I->W * I->H, sizeof(int));
    
    for (int y = 0; y < I->H; y++) {
        for (int x = 0; x < I->W; x++) {
            if (assigned[getIndex(x, y, I)]) continue;
            int bestBrique = -1;
            int bestRot = 0;
            int minError = INT_MAX;
            
            for (int i = 0; i < B->nBrique; i++) {
                int shapeIdx = B->bShape[i];
                if (B->W[shapeIdx] == 1 && B->H[shapeIdx] == 1) continue;
                
                for (int rot = 0; rot < 4; rot++) {
                    

                    int fits = 1;
                    int currentError = 0;
                    int pixelCount = 0;
                    
                    int W = B->W[shapeIdx];
                    int H = B->H[shapeIdx];
                    
                    int boxW = (rot%2==0) ? W : H;
                    int boxH = (rot%2==0) ? H : W;
                    
                    if (x + boxW > I->W || y + boxH > I->H) {
                         fits = 0; 
                    } else {
                         for (int dy = 0; dy < boxH; dy++) {
                            for (int dx = 0; dx < boxW; dx++) {

                                if (BriqueCovers(B, shapeIdx, rot, dx, dy)) {
                                    int idx = getIndex(x + dx, y + dy, I);
                                    if (assigned[idx]) {
                                        fits = 0; break;
                                    }
                                    RGB pixelColor = *get(I, x+dx, y+dy);
                                    RGB briqueColor = B->col[B->bCol[i]];
                                    currentError += colError(pixelColor, briqueColor);
                                    pixelCount++;
                                }
                            }
                            if (!fits) break;
                        }
                    }
                    
                    if (fits && pixelCount > 0) {
                        int avgError = currentError / pixelCount;
                        if (avgError < minError) {
                            minError = avgError;
                            bestBrique = i;
                            bestRot = rot;
                        }
                    }
                }
            }
            
            if (bestBrique != -1 && minError < 2000) {
                push_sol(&S, bestBrique, x, y, bestRot, I, B);
                int shapeIdx = B->bShape[bestBrique];
                int W = B->W[shapeIdx];
                int H = B->H[shapeIdx];
                int boxW = (bestRot%2==0) ? W : H;
                int boxH = (bestRot%2==0) ? H : W;
                
                for (int dy = 0; dy < boxH; dy++) {
                    for (int dx = 0; dx < boxW; dx++) {
                        if (BriqueCovers(B, shapeIdx, bestRot, dx, dy)) {
                            assigned[getIndex(x + dx, y + dy, I)] = 1;
                        }
                    }
                }
            }
        }
    }

    int shape11 = lookupShape(B, 1, 1);
    for (int y = 0; y < I->H; y++) {
        for (int x = 0; x < I->W; x++) {
            if (!assigned[getIndex(x, y, I)]) {
                int best11 = -1;
                int bestErr = INT_MAX;
                for (int i = 0; i < B->nBrique; i++) {
                     if (B->bShape[i] == shape11) {
                         int err = colError(B->col[B->bCol[i]], *get(I, x, y));
                         if (err < bestErr) { bestErr = err; best11 = i; }
                     }
                }
                if (best11 != -1) {
                    push_sol(&S, best11, x, y, 0, I, B);
                    assigned[getIndex(x, y, I)] = 1;
                }
            }
        }
    }
    
    fill_sol_stock(&S, B);
    free(assigned);
    return S;
}

int main(int argn, char** argv) {
    char* dir="fichier_test";
    if (argn>1)
        dir=argv[1];
    
    Image I;    
    BriqueList B;
    load_image(dir, &I);
    load_brique(dir , &B);

    printf("Différentes Sorties : \n");

    printf("Generation Algo 1 (Reference)\n");
    Solution S1 = run_algo1(&I, &B);
    print_sol(&S1, dir, "out11.txt", &B);
    freeSolution(S1);

    printf("Generation Matching Optimal\n");
    Solution SOpt = run_optimal_matching(&I, &B);
    print_sol(&SOpt, dir, "outOptMatching.txt", &B);
    freeSolution(SOpt);

    printf("Generation Any Shape (Toutes formes acceptées)\n");
    Solution SAny = run_any_shape(&I, &B);
    print_sol(&SAny, dir, "outAnyShape.txt", &B); 
    freeSolution(SAny);

    printf("Generation Low Cost (Priorité Prix sur Qualité)\n");
    Solution SCost = run_low_cost(&I, &B);
    print_sol(&SCost, dir, "outCheap.txt", &B);
    freeSolution(SCost);
    
    printf("Generation Version 3\n");
    Solution SV3 = run_version3(&I, &B);
    print_sol(&SV3, dir, "outV3.txt", &B);
    freeSolution(SV3);

    freeData(I,B);
    printf("Tous les fichiers ont été générés");
    return 0;
}
