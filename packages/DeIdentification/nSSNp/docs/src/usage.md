# Usage Guide

## DeIdentification Methods

Data can be processed in several different ways depending on the desired output
* **Dropped**: drop the column as it is not needed for analysis or as identifier
* **Hashed**: obfuscate the data in the column, but maintain referential integrity for joining data
* **Hashed and Salted**: obfuscate the data in the column, but do not maintain referential integrity for joining data (useful for columns that would only be needed in re-identifying data)
* **Date Shifted**: Shift date or datetime columns by a random value (all date/times related to the primary identifier will be shifted by the same random number), optionally add a static year value to all dates

Data can also be transformed before or after deidentification
* Preprocess: before deidentification (e.g. hash), transform the data (e.g. make sure zip codes are 5 digit)
* Postprocess: after deidentficiation (e.g. dateshift) transform the data (e.g. only include the year of the date)

## Config YAML
To indicate how to de-identify the data, where the data lives, and other variables a
configuration YAML file must be created by the user. There is a `build_config` utility function
which can walk a user through file creation for the basic deidentification methods.  Pre- and post-
processing must be manually added to the .yml file.  
It's possible to combine different `datasets` in the same config file, each `dataset`
will follow the set of rules defined in the dataset block. In addition, multiple
files of the same dataset can be processed at the same time by using Glob patterns
in the `filename` field instead of the full file path.

```
# config.yml
project:                <project name> # required
project_seed:           <int>          # optional, but required for reproducibility
log_path:               <dir path>     # required, must already be created
max_dateshift_days:     <int>          # optional, default is 30
dateshift_years:        <int>          # optional, default is 0
output_path:            <dir path>     # required, must already be created

# The primary ID must be present in all data sets, so that date shifting and salting work appropriately
primary_id: <column name>       # required

# Default date format is "y-m-dTH:M:S.s" (e.g. 1999-05-21T11:23:56.0123) - see Dates.DateFormat for options
date_format: <Dates.DateFormat>

# 1 to n datasets must be present to de-identify
datasets:
  - name: <dataset name 1>          # required, used to name output file
    filename: <file path / glob pattern>         # required, path for input CSV, or Glob pattern for input files in folder.
    rename_cols:                  # optional, useful if columns used in joining have different names, renaming occurs before any other processing
      - in: <col name 1a>                # required, current column name
        out: <col name 1b>               # required, future column name
    # NOTE: VAL must be used to indicate the field value being transformed - no matter the field's type, VAL will be processed as a string
    preprocess_cols:
      - col: <col name>
        transform: <expression>
    hash_cols:                    # optional, columns to be hashed
      - <col name 1>
      - <col name 2>
    dateshift_cols:               # optional, columns to be dateshifted
      - <col name 1>
      - <col name 2>
    salt_cols:                    # optional, columns to be hashed and salted
      - <col name 1>
      - <col name 2>
    drop_cols:                    # optional, columns to be excluded from the de-identified data set
      - <col name 1>
      - <col name 2>
    # NOTE: VAL must be used to indicate the field value being transformed - no matter the field's type, VAL will be processed as a string
    postprocess_cols:
      - col: <col name>
        transform: <expression>
  - name: <dataset name 2>          # required, used to name output file
    filename: <file path / glob pattern>         # required, path for input CSV, or Glob pattern for input files in folder.
    rename_cols:                  # optional, useful if columns used in joining have different names, renaming occurs before any other processing
      - in: <col name 1a>                # required, current column name
        out: <col name 1b>               # required, future column name
    hash_cols:                    # optional, columns to be hashed
      - <col name 1>
      - <col name 2>
    dateshift_cols:               # optional, columns to be dateshifted
      - <col name 1>
      - <col name 2>
    salt_cols:                    # optional, columns to be hashed and salted
      - <col name 1>
      - <col name 2>
    drop_cols:                    # optional, columns to be excluded from the de-identified data set
      - <col name 1>
      - <col name 2>
```

### Example Config

```YAML
project:                "ehr"
project_seed:           42          # for reproducibility
log_path:               "./logs"
max_dateshift_days:     30
dateshift_years:        100
output_path:            "./output"

# The primary ID must be present in all data sets, so that dateshifting and salting works appropriately
primary_id: "CSN"

# Default date format is "y-m-dTH:M:S.s" (e.g. 1999-05-21T11:23:56.0000) - see Dates.DateFormat for options
date_format: "y-m-dTH:M:S.s"

datasets:
  - name: dx
    filename: "./data/dx_files/*" # Glob pattern option
    rename_cols:
      - in: "EncounterBrownCSN"
        out: "CSN"
    hash_cols:
      - "CSN"
      - "PatientPrimaryMRN"
    dateshift_cols:
      - "ArrivalDateandTime"
    drop_cols:
      - "DiagnosisTerminologyType"
  - name: pat
    filename: "./data/pat.csv"
    # NOTE: renaming happens before any other operations (pre-processing, hashing, salting, dropping, dateshifting, post-processing)
    rename_cols:
      - in: "EncounterBrownCSN"
        out: "CSN"
      - in: "PatientLastName"
        out: "last_name"
    # NOTE: VAL must be used to indicate the field value being transformed - no matter the field's type, VAL will be processed as a string
    preprocess_cols:
      - col: "PatientPostalCode"
        transform: "getindex(VAL, 1:5)"
    hash_cols:
      - "CSN"
      - "PatientPostalCode"
    salt_cols:
      - "last_name"
    dateshift_cols:
      - "ArrivalDateandTime"
      - "DepartureDateandTime"
      - "PatientBirthDate"
    # NOTE: VAL must be used to indicate the field value being transformed - no matter the field's type, VAL will be processed as a string
    postprocess_cols:
      - col: "PatientBirthDate"
        transform: "max(2000+100, parse(Int, getindex(VAL, 1:4)))"
  - name: med
    filename: "./data/med.csv"
    rename_cols:
      - in: "EncounterBrownCSN"
        out: "CSN"
    hash_cols:
      - "CSN"
    dateshift_cols:
      - "ArrivalDateandTime"
    drop_cols:
      - "MedicationTherapeuticClass"
```

### Generating the Configuration

Although the configuration YAML file can be put together by hand, there are also tools to help assist in the generation of a configuration file under different circumstances. Note, however, that in any circumstance, it is likely necessary to hand-edit the generated YAML file after processing to ensure everything is correct and to setup any pre- and post-processing necessary.

#### Build Configuration Interactively

If you have all the necessary data already in CSV format, you can use the `build_config` function to generate the configuration. This will prompt you for the necessary configuration actions for each column found in the CSV files. An interactive session might look like the below:

##### Example Interactive Session

```
julia --project=@. -e 'using DeIdentification; build_config("./test/data", "test.yaml")'

DeIdentification Config Builder
===============================
Follow the prompts to build a draft of your config file using the datasets.
The prompts are all written as 'Prompt [default]: '. If there is no default
the field is required.
NOTE: this builder will not ask about pre- or post-processing, add after if needed
Ready to get started? [y]
Great! Here we go...

Let's start with the project level info
---------------------------------------
Project name [data]:
Project seed [2809867404]: (used for reproducibility)
Maximum Date Shift Days [30]:
Years to add to all dates [0]:
Path for logs [./logs]:
Path for output files [./output]:
Input date format [y-m-dTH:M:S.s]:
Primary ID Column Name: (REQUIRED - must be present in all datasets) CSN

Now let's look at the data sets
-------------------------------
Dataset Name [dx]:

[  ArrivalDateandTime - Dates.DateTime  ]
Column Name [ArrivalDateandTime]:
Deidentification Method:
   Nothing
   Hash
   Hash & Salt
 > Date Shift
   Drop

[  EncounterBrownCSN - Int64  ]
Column Name [EncounterBrownCSN]: CSN
Deidentification Method:
   Nothing
 > Hash
   Hash & Salt
   Date Shift
   Drop

[  DiagnosisTerminologyType - CSV.PooledString  ]
Column Name [DiagnosisTerminologyType]:
Deidentification Method:
 > Nothing
   Hash
   Hash & Salt
   Date Shift
   Drop

[  DiagnosisTerminologyValue - CSV.PooledString  ]
Column Name [DiagnosisTerminologyValue]:
Deidentification Method:
 > Nothing
   Hash
   Hash & Salt
   Date Shift
   Drop

[  PatientPrimaryMRN - Int64  ]
Column Name [PatientPrimaryMRN]:
Deidentification Method:
   Nothing
 > Hash
   Hash & Salt
   Date Shift
   Drop

[  ArrivalDepartmentName - CSV.PooledString  ]
Column Name [ArrivalDepartmentName]:
Deidentification Method:
 > Nothing
   Hash
   Hash & Salt
   Date Shift
   Drop

Dataset Name [med]:

[  EncounterBrownCSN - Int64  ]
Column Name [EncounterBrownCSN]: CSN
Deidentification Method:
   Nothing
 > Hash
   Hash & Salt
   Date Shift
   Drop

[  ArrivalDateandTime - Dates.DateTime  ]
Column Name [ArrivalDateandTime]:
Deidentification Method:
   Nothing
   Hash
   Hash & Salt
 > Date Shift
   Drop

[  MedicationName - CSV.PooledString  ]
Column Name [MedicationName]:
Deidentification Method:
 > Nothing
   Hash
   Hash & Salt
   Date Shift
   Drop

[  MedicationTherapeuticClass - Int64  ]
Column Name [MedicationTherapeuticClass]:
Deidentification Method:
 > Nothing
   Hash
   Hash & Salt
   Date Shift
   Drop

Dataset Name [pat]:

[  ArrivalDateandTime - Dates.DateTime  ]
Column Name [ArrivalDateandTime]:
Deidentification Method:
   Nothing
   Hash
   Hash & Salt
 > Date Shift
   Drop

[  ArrivalDepartmentName - CSV.PooledString  ]
Column Name [ArrivalDepartmentName]:
Deidentification Method:
 > Nothing
   Hash
   Hash & Salt
   Date Shift
   Drop

[  DepartureDateandTime - Dates.DateTime  ]
Column Name [DepartureDateandTime]:
Deidentification Method:
   Nothing
   Hash
   Hash & Salt
 > Date Shift
   Drop

[  EncounterBrownCSN - Int64  ]
Column Name [EncounterBrownCSN]: CSN
Deidentification Method:
   Nothing
 > Hash
   Hash & Salt
   Date Shift
   Drop

[  PatientBirthDate - Dates.DateTime  ]
Column Name [PatientBirthDate]:
Deidentification Method:
   Nothing
   Hash
   Hash & Salt
 > Date Shift
   Drop

[  PatientLastName - String  ]
Column Name [PatientLastName]:
Deidentification Method:
   Nothing
   Hash
   Hash & Salt
   Date Shift
 > Drop

[  PatientPostalCode - String  ]
Column Name [PatientPostalCode]:
Deidentification Method:
   Nothing
   Hash
   Hash & Salt
   Date Shift
 > Drop

[  PatientPrimaryMRN - Int64  ]
Column Name [PatientPrimaryMRN]:
Deidentification Method:
   Nothing
 > Hash
   Hash & Salt
   Date Shift
   Drop

[  PatientSex - CSV.PooledString  ]
Column Name [PatientSex]:
Deidentification Method:
 > Nothing
   Hash
   Hash & Salt
   Date Shift
   Drop

[  PatientSSN - String  ]
Column Name [PatientSSN]:
Deidentification Method:
 > Nothing
   Hash
   Hash & Salt
   Date Shift
   Drop


All set! Writing your config file to test.yaml
Your file is ready - please review it and add any pre- or post-processing steps as needed.
```

#### Build Configuration from a CSV

The configuration from a CSV file is designed to work with BCBI's data request worksheet. However, it simply requires a CSV file that contains at least three fields:

 1. **Source Table**: The name of the CSV file that will contain the data
 1. **Field**: The name of the field to map
 1. **Method**: The DeIdentification method which can be any of **Hash**, **Hash & Salt**, **Hash - Research ID**, **Date Shift**, or **Drop**. Methods not matching these names will be ignored. Note that a field marked **Hash - Research ID** will be treated as the primary id for the dataset and needs to have the same name in all data sources.

 Other fields or method values will be ignored by the tool. It can be run by using the `build_config_from_csv` function.

 A valid CSV file designed to be consumed by this tool might look like this:

 ```
 Source Universe,Source Table,Field,PHI,Method
BCBI Clinic Visits,BCBI Clinic Detail,Patient Id,Y,Hash - Research ID
BCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Arrival Method,N,
BCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Discharge Disposition,N,
BCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Acuity Level,N,
BCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Level Of Care,N,
BCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Financial Class,N,
BCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Facility Level Of Service,N,
BCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Professional Level Of Service,N,
BCBI Clinic Visits,BCBI Clinic Detail,Clinic Visit Encounter Csn,Y,Hash
BCBI Clinic Visits,BCBI Clinic Detail,Clinic Department Name,N,
BCBI Clinic Visits,BCBI Clinic Detail,Clinic Department Id,N,
BCBI Clinic Visits,BCBI Clinic Detail,Primary Clinic Diagnosis Name,N,
BCBI Clinic Visits,BCBI Clinic Detail,Primary Clinic Diagnosis Id,N,
BCBI Clinic Visits,BCBI Clinic Detail,Primary Chief Complaint Name,N,
BCBI Clinic Visits,BCBI Clinic Detail,Primary Chief Complaint Id,N,
BCBI Clinic Visits,BCBI Clinic Detail,Encounter Type,N,
BCBI Clinic Visits,BCBI Clinic Detail,Encounter Admission Type,N,
BCBI Clinic Visits,BCBI Clinic Detail,Encounter Admission Source,N,
BCBI Clinic Visits,BCBI Clinic Detail,Encounter Date,Y,Date Shift
BCBI Clinic Visits,BCBI Clinic Detail,Encounter End Instant,Y,Date Shift
BCBI Clinic Visits,BCBI Clinic Detail,Encounter Admission Instant,Y,Date Shift
BCBI Clinic Visits,BCBI Clinic Detail,Encounter Discharge Instant,Y,Date Shift
BCBI Clinic Visits,BCBI Clinic Detail,First Trauma Start Instant,Y,Date Shift
BCBI Clinic Visits,BCBI Clinic Detail,First Trauma End Instant,Y,Date Shift
BCBI Clinic Visits,BCBI Clinic Detail,Arrival Instant,Y,Date Shift
BCBI Clinic Visits,BCBI Clinic Detail,Departure Instant,Y,Date Shift
,,,,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Id,Y,Hash - Research ID
BCBI Clinic Visits,BCBI Clinic Demographics,Clinic Visit Encounter Csn,Y,Hash
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Name,Y,Hash & Salt
BCBI Clinic Visits,BCBI Clinic Demographics,Patient First Name,Y,Hash & Salt
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Middle Name,Y,Hash & Salt
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Last Name,Y,Hash & Salt
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Sex,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Preferred Language,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Ethnicity,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient First Race,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Second Race,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Third Race,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Fourth Race,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Fifth Race,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Multi Racial?,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Birth Date,Y,Date Shift
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Death Instant,Y,Date Shift
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Death Location,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Status,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Address,Y,Drop
BCBI Clinic Visits,BCBI Clinic Demographics,Patient City,Y,Drop
BCBI Clinic Visits,BCBI Clinic Demographics,Patient County,Y,Drop
BCBI Clinic Visits,BCBI Clinic Demographics,Patient State Or Province,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Country,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Postal Code,Y,Hash
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Sexual Orientation,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Marital Status,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Religion,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Smoking Status,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Highest Level Of Education,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Is Cancer Patient?,N,
BCBI Clinic Visits,BCBI Clinic Demographics,Patient Restricted?,N,
,,,,
BCBI Clinic Visits,BCBI Clinic Providers,Patient Id,Y,Hash - Research ID
BCBI Clinic Visits,BCBI Clinic Providers,Clinic Visit Encounter Csn,Y,Hash
BCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Third Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Case Manager Id,N,
BCBI Clinic Visits,BCBI Clinic Providers,Case Manager Npi,N,
BCBI Clinic Visits,BCBI Clinic Providers,Case Manager Dea Number,N,
BCBI Clinic Visits,BCBI Clinic Providers,Case Manager Primary Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Case Manager Second Specialty,N,
BCBI Clinic Visits,BCBI Clinic Providers,Case Manager Third Specialty,N,
 ```

## Running the Pipeline

To de-identify a data set, pass the config YAML to the `deidentify` function.

```julia
deidentify("./config.yml")
```
This will read in the data, de-identify the data, write a log to file, and write the resulting data set to file.

The pipeline consists of three main steps:
* Read the configuration file and process the settings
* De-identify and write the data set
* Write the dictionaries with salts, dateshift values, and research IDs to files

The `deidentify` function runs the three steps:

```julia
proj_config = DeIdConfig(cfg_file)
deid = DeIdentified(proj_config)
```
