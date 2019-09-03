QDates.jl release notes
=======================

Version 0.3.0 (2019/02/11 / 旧2019年01月07日)
---------------------------------------------

### Significant change in internal implementation

+ Removed the dependency on `qref.c`, and Reimplemented with **Pure Julia**
+ Performance improvement
+ Add support for 32-bit Windows and other platforms

### Specification change

+ Expand available dates (`旧445年1月1日` to `旧2200年12月29日`) (previously the max date is `旧2100年12月1日`)


Version 0.2.0 (2019/01/04 / 旧2018年11月29日)
---------------------------------------------

### Adjust for Julia v1.0.0 or later(ready for v"1.1")

+ Drop Julia v0.6 support
+ Remove dependency on `Compat.jl`
+ Add/Fix tests


Version 0.1.0 (2018/08/04 / 旧2018年06月23日)
---------------------------------------------

+ Add Support Julia v0.7.x/v1.0.x
+ Drop Support Julia v0.5.x


Version 0.0.2 (2017/05/23 / 旧2017年04月28日)
---------------------------------------------

* Bug fix


Version 0.0.1 (2017/05/10 / 旧2017年04月15日)
---------------------------------------------

* 1st release
