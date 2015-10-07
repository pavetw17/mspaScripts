**********************************************************************;
*       SAS_EDA_Sandbox;
*       Last updated: 2015-10-07 by MJG;
**********************************************************************;
 
*       Generic macros to help conduct EDA on any data set;
*       This section must be modified by the user;
 
*       Connect to data;
libname mydata '/sscc/home/m/mga293/411-DL/SAS_Data/' access = readonly;
 
*       Shorten data name, save to work library;
data MB;
        set mydata.moneyball;
run; quit;
 
**********************************************************************;
*       SAS Macros;
**********************************************************************;
 
*       Locals;
%let data_og = MB;
%let data_rev = &data_og._rev;
%let contents = &data_og._contents;
%let data_imp = &data_og._imp;
%let varname = name;
%let key = INDEX;                       *Primary, foreign, or other key;
%let response = TARGET_WINS;            *Response Variable;
 
*       Macro for scatterplots;
%macro scatter(varname);
        ods graphics on;
        proc sgscatter data = &data_og.;
                compare x = &varname. y = &response. / loess reg;
                title "Scatter Plot of &response. by &varname.";
                title2 "with LOESS smoother";
        run; quit;
        ods graphics off;
%mend;
 
*       Macro for histograms;
%macro histogram(varname);
        proc sgplot data = &data_og.;
                histogram &varname. / transparency = 0.5;
                density &varname. / type = normal;
                density &varname. / type = kernel;
                title "Histogram of &varname.";
                title2 "with normal and kernel density estimates";
        run; quit;
%mend;
 
*       Macro for boxplots;
%macro boxplot(varname);
        proc sgplot data = &data_og.;
                vbox &varname.;
                title "Boxplot of &varname.";
        run; quit;
%mend;
 
*       Macro for missing flags;
%macro missing(varname);
        data &data_rev.;
                set &data_rev.;
                        &varname._MF = missing(&varname.);
        run; quit;
%mend;
 
*       Macro to output summary stats from PROC MEANS across all variables;
*       As designed, must be used in conjunction with PROC TRANSPOSE;
%macro means(varname);
        proc means data = &data_og. noprint;
        output out = &varname. (drop = _freq_ _type_)
                nmiss(&varname.)        = &varname._nmiss
                n(&varname.)            = &varname._n
                mean(&varname.)         = &varname._mean
                median(&varname.)       = &varname._median
                mode(&varname.)         = &varname._mode
                std(&varname.)          = &varname._std
                skew(&varname.)         = &varname._skew
                P1(&varname.)           = &varname._P1
                P5(&varname.)           = &varname._P5
                P10(&varname.)          = &varname._P10
                P25(&varname.)          = &varname._P25
                P50(&varname.)          = &varname._P50
                P75(&varname.)          = &varname._P75
                P90(&varname.)          = &varname._P90
                P95(&varname.)          = &varname._P95
                P99 (&varname.)         = &varname._P99
                min(&varname.)          = &varname._min
                max(&varname.)          = &varname._max
                qrange(&varname.)       = &varname._qrange
                ;
run; quit;
%mend;
 
*       Macro to transpose summary stats from %macro means(varname);
%macro transpose(varname);
        proc transpose data = &varname. out = &varname._t;
                var _numeric_;
                by _character_;
        run; quit;
%mend;
 
*       Macro to store summary stats from PROC MEANS as macro variables;
*       Useful for automated truncates, transforms, and imputes;
%macro symput(varname);
        data _null_;
                set &varname._t;
                        call symput(_name_, col1);
        run; quit;
%mend;
 
**********************************************************************;
*       PROC CONTENTS;
**********************************************************************;
 
*       List out the column names and data types for the data set;
*       This is necessary as almost all macros depend on this output
        to extract variable names in data set for looping;
proc contents data = &data_og. out = &contents.;
run; quit;
 
*       Drop unnecessary variables gained from PROC CONTENTS output;
data &contents.;
        set &contents.(keep = name type length varnum format formatl
                informat informl just npos nobs);
run; quit;
 
*       View contents of data set, more info than og PROC CONTENTS output;
proc print data = &contents.;
run; quit;
 
**********************************************************************;
*       Scatter, Histogram, Boxplot;
**********************************************************************;
 
*       Conduct EDA on all _NUMERIC_ variables;
*       Excludes response variable and any primary, foreign, or other key;
data _null_;
        do i = 1 to num;
                set &contents. nobs = num;
                        if name = "&response." then delete;
                                else if name = "&key." then delete;
                                else where type = 1;
                                        call execute('%scatter('||name||')');
                                        call execute('%histogram('||name||')');
                                        call execute('%boxplot('||name||')');
        end;
run; quit;
 
**********************************************************************;
*       PROC MEANS;
**********************************************************************;
 
*       For each variable in the data set, extract summary stats from
        proc means and store as varname, then transpose as varname_t;
data _null_;
        do i = 1 to num;
                set &contents. nobs = num;
                        call execute('%means('||name||')');
                        call execute('%transpose('||name||')');
                        call execute('%symput('||name||')');
        end;
run; quit;
 
*       View all macro variables;
%put _user_;

*       Verify data with PROC MEANS output;
proc means data = &data_og. NOLABELS
        NMISS N MEAN MEDIAN MODE STD SKEW
        P1 P5 P10 P25 P50 P75 P90 P95 P99 MIN MAX QRANGE;
run; quit;

**********************************************************************;
*       Missing;
**********************************************************************;
*       Create flag variables for missing datum in data set;

*       XXX

**********************************************************************;
*       Truncate, Transform, and Impute;
**********************************************************************;
*       Important to follow TTI in this order;
*       For example, MEAN is extremely sensitive to outliers, so should
        truncate to P1 & P99 before imputing based on data;
*       Similarly, want to transform and add new variables to data set so
        when imputing occurs it will impute on all versions of variabbles;

***********************************;
*       Truncate;
***********************************;

* XXX

***********************************;
*       Transform;
***********************************;

* XXX

***********************************;
*       Impute;
***********************************;
*       Here actually do imputing on two data sets, cloned from &data_og.;
*       First creates new variables with MEAN, MEDIAN, MODE for missings;
*       Second uses PROC MI to replace missing values in current variables;
*       Benefit of keeping these separate is to see how well model does with
        manual imputing of MMM vs. programmatic imputing;

* XXX

**********************************************************************;
*       Models;
**********************************************************************;
*       Create multiple OLS models for data set;

* XXX

**********************************************************************;
*       Scoring;
**********************************************************************;
*       Score multiple models based on Y-hat & error (residual);
*       Model with the smallest %change between MSE and MAE in training
        and test is selected;
*       Model may NOT have highest adjusted R-squared, but here we care
        about predictive accuracy and not statistical inference;
*       The model with the highest adjusted R-squared may be overfit;

* XXX

**********************************************************************;
*       Output Accuracy;
**********************************************************************;
*       Create specific format, freq, and tables for model validation;
*       How many of the predicted values from response variable were
        within 5%, 10%, and 15% of acutals on training and test?;

* XXX
