// pdf and cdf structs and function(s)

struct cdf {
      double x;
      double F;
};

struct pdf {
      double x;
      double P;
};

// used for sorting pdf values
bool pdf_cmp (pdf p1, pdf p2);
