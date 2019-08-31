#define NDATA 20000
#define COLUMNS 14

// not all fields are necessarily used by an implementation of input_data()
typedef struct {
    double KOI;
    int KIC;
    double Kp;
    double t0;
    double e_t0;
    double Per;
    double e_Per;
    double Rad;
    double a;
    double Teq;
    double Dur;
    int Depth;
    double d_R;
    double e_d_R;
    double r_R;
    double e_r_R;
    double b;
    double i;
    double e_b;
    double SNR;
    double chi;
    int Teff;
    double log_g;
    double solRad;
    double f_Teff;
} kepler_input;

// read KOI data into array
// returns number of KOIs in FILENAME
int input_data(const char* FILENAME, kepler_input kepler_data[NDATA]);
