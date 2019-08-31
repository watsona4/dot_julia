#include "corbits.h"
#include <cstdio>
#include <cassert>
#include <cstring>
#include <getopt.h>

bool report_error = false;
bool compute_all = false;
const char* DEFAULT_FORMAT = "nPeioOu";
const char* short_options = "ef:ho:A";

static struct option long_options[] = {
  {"help", no_argument, 0, 0}
};

void set_input_orbit_default (input_orbit &io) {
  io.a = 1;
  io.e = 0;
  io.i = 0;
  io.omega = 0;
  io.Omega = 0;
  io.P = 1;
  io.r = 0;
  io.r_star = 1;
  io.use = 1;
}

void fix_input_orbit (input_orbit &io) {
  io.P *= DAYS_IN_YEAR;
  io.i *= DEG_TO_RAD;
  io.omega *= DEG_TO_RAD;
  io.Omega *= DEG_TO_RAD;
  io.r_star *= SR_TO_AU;
}

bool read(FILE* fin, int &len, char* format, input_orbit io[]) {
  /* for (int i = 0; i < 20; i++) {
    char line[1000];
    int max_len_line = 1000;
    char* c = fgets (line, max_len_line, fin);
    fprintf (stderr, "LINE: %s\n", line);
  }
  return false; */
  int format_len = strlen (format);
  for (len = 0; ; len++) { 
    char line[1000];
    int max_len_line = 1000;
    char* c = fgets (line, max_len_line, fin);
    if (c == NULL) {
      return true;
    }
    else if (len >= MAX) {
	fprintf (stderr, "Error: Exceeded limit of %d planets\n", MAX);
	return false;
    }
    else {
      char *token[1000];
      token[0] = line;
      int cur = 1;
      int line_len = strlen(line);
      bool did_a = false;
      bool did_P = false;
      for (int i = 0; i < line_len; i++) {
	if (line[i] == '\t') {
	  token[cur++] = line + i + 1;
	  line[i] = '\0';
	}
      }
      if (cur != format_len) {
	fprintf (stderr, "Error: Incorrect number of tokens in row %d\n", len + 1);
	return false;
      }
      set_input_orbit_default(io[len]);
      for (int i = 0; i < format_len; i++) {
	int a;
	// fprintf (stderr, "CUR: %c\n", format[i]);
	switch (format[i]) {
	case 'a':
	  did_a = true;
	  a = sscanf (token[i], "%lf", &io[len].a);
	  break;
	case 'e':
	  a = sscanf (token[i], "%lf", &io[len].e);
	  break;
	case 'i':
	  a = sscanf (token[i], "%lf", &io[len].i);
	  break;
	case 'n':
	  char name[1000];
	  a = sscanf (token[i], "%s", name);
	  break;
	case 'o':
	  a = sscanf (token[i], "%lf", &io[len].omega);
	  break;
	case 'O':
	  a = sscanf (token[i], "%lf", &io[len].Omega);
	  break;
	case 'P':
	  did_P = true;
	  a = sscanf (token[i], "%lf", &io[len].P);
	  break;
	case 'r':
	  a = sscanf (token[i], "%lf", &io[len].r);
	  break;
	case 'R':
	  a = sscanf (token[i], "%lf", &io[len].r_star);
	  break;
	case 'u':
	  a = sscanf (token[i], "%d", &io[len].use);
	  break;
	default:
	  fprintf (stderr, "Error: Invalid format character\n");
	  return false;
	}
	if (a == EOF) {
	  fprintf (stderr, "Error: Unable to parse row %d\n", len + 1);
	  return false;
	}
      }
      fix_input_orbit(io[len]);
      if (did_a && !did_P) {
	io[len].P = sqrt (pow(io[len].a, 3) / mass_from_radius(io[len].r_star / SR_TO_AU)) * DAYS_IN_YEAR;
      }
      else if (!did_a && did_P) {
	io[len].a = radius(mass_from_radius(io[len].r_star / SR_TO_AU), io[len].P);
      }
    }
  }
}

void print_usage(char *prog) {
  printf ("Usage: %s [-h|--help] [-f FORMAT] [-e] [-A] < FILENAME\n\n", prog);
}

void print_help(char *prog) {
  print_usage(prog);
  printf ("Compute the geometric probability of observing\n");
  printf ("the transit of all exoplanets specified in FILENAME\n");
  printf ("from the perspective of a random observer.\n\n");
  printf ("Options:\n");
  printf ("  -h --help    prints help information then exits\n");
  printf ("  -f FORMAT    specifies format of input (see below)\n");
  printf ("  -e           include worst-case error bounds in output\n");
  printf ("  -A           compute probabilities for all possible observations\n");
  printf ("\n");
  printf ("The input, read from stdin or FILENAME, should be a tab-delimited\n");
  printf("table, each row of which specific an individual planet.  The orbital\n");
  printf ("parameters represented by each column should be specific to each format.\n");
  printf ("If certain orbital parameters are omitted, their values will be set to\n");
  printf ("a given default value or be inferred from the other specific values.\n");
  printf ("The possible formats, specified by the string FORMAT, and their default\nvalues if not selected are:\n");
  printf ("  a            the semi-major axis in AU (default: 1)\n");
  printf ("  e            the eccentricity (default: 0)\n");
  printf ("  i            the inclination in degrees (default: 0)\n");
  printf ("  n            the name of the planet (default: NULL)\n");
  printf ("  o            the argument of periapsis in degrees (default: 0)\n");
  printf ("  O            the longitude of the ascending node in degrees (default: 0)\n");
  printf ("  P            the period of the orbit in years (default: 1)\n");
  printf ("  r            the radius of the planet in earth radii (default: 0)\n");
  printf ("  R            the radius of the star in stellar radii (default: 1)\n");
  printf ("  u            0 explicitly excludes the planet, 1 explicitly includes the  \n               planet from the observation (default: 1)\n");
  printf ("\n");
  printf ("CORBITS will have an exit status of  0 if successful. If there are\nerrors in the reading of the table, an exit status of 1 will be returned.\nAny other errors will return an exit status of 2.\n");
  printf ("\n");
  printf ("Copyright (c) 2014, Joshua Brakensiek and Darin Ragozzine\n");
  printf ("CORBITS is licensed under the MIT license.\n");
  printf ("If you find CORBITS useful for academic purposes, please cite Brakensiek & Ragozzine, 2014 (in prep).\n");
  printf ("For more information about CORBITS:\n");
  printf ("<https://www.github.com/jbrakensiek/CORBITS/>\n");
}

int main(int argc, char **argv) {
  FILE *fin = stdin, *fout = stdout;
  char format[30];
  strcpy (format, DEFAULT_FORMAT);
  // option code based on getopt man page example
  while (true) {
    int c, option_index = 0;
    c = getopt_long(argc, argv, short_options,
		    long_options, &option_index);

    if (c == -1)
      break;
    
    switch (c) {
    case 0:
      // fprintf (stderr, "Option: %s\n", long_options[option_index].name);
      if (option_index == 0) {
	print_help(argv[0]);
	return 0;
      }
      break;
    case 'e':
      // fprintf (stderr, "Option: Report Error\n");
      report_error = true;
      break;
    case 'f':
      // fprintf (stderr, "Option: Format: %s\n", optarg);
      if (strlen (optarg) > 20) {
	fprintf (stderr, "Error: format string exceeds maximum length of 20 characters\n");
	return 1;
      }
      strcpy (format, optarg);
      break;
    case 'h':
      print_help(argv[0]);
      return 0;
    case 'o':
      fout = fopen (optarg, "r");
      break;
    case 'A':
      compute_all = true;
      break;
    case '?':
      print_usage(argv[0]);
      return 2;
    default:
      fprintf (stderr, "Error: getopt\n");
      print_usage(argv[0]);
      return 2;
    }
  }
  // fprintf (stderr, "optind: %d\n", optind);
  int len = 0;
  input_orbit io[MAX];
  /* for (int i = 0; i < n; i++) {
    
     } */

  if (!read(fin, len, format, io)) {
    return 2;
  }
  
  if (!compute_all) {
    sci_value prob = prob_of_transits_input_orbit(len, io);
  
    fprintf (fout, "Probability: %e\n", prob.val);
    if (report_error) {
      fprintf (fout, "Positive Error: %e\n", prob.pos_err);
      fprintf (fout, "Negative Error: %e\n", prob.neg_err);
    }
  }
  else {
    double total = 0;
    for (int i = 0; i < (1 << len); i++) {
      for (int j = 0; j < len; j++) {
	io[j].use = ((1 << j) & i) > 0;
      }
      for (int k = 0; k < len; k++) {
	printf ("%d", io[k].use);
      }
      sci_value prob = prob_of_transits_input_orbit(len, io);
      fprintf (fout, " %e", prob.val);
      total += prob.val;
      if (report_error) {
	fprintf (fout, " %e", prob.pos_err);
	fprintf (fout, " %e", prob.neg_err);
      }
      fprintf (fout, "\n");
    }
    // printf ("Total: %e\n", total);
  }
  return 0;
}
