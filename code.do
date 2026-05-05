cd D:\desktop\zhuomian\经济研究（绿色）-202101-202407\绿色信贷数据
//自己的数据放在哪个位置就改成那个位置,不知道数据存放在哪个路径可以百度（百度怎么查找文件存储路径），百度写的很清楚

use data1,clear
//data1需要替换成你自己的数据，你把数据命名成什么就改成什么。如果不知道怎么把excel数据导入stata，百度怎么把excel数据导入stata

xtset province_id year

***变量的描述性统计
sum new_acei  gf   new_a  mech_power   level  urban 
//y x1 x2 x3 x4 x5 x6 x7为自己的被解释变量和解释变量

***空间权重矩阵制作
spatwmat using WW.dta, n(WW) standardize
matrix list WW

***空间相关性检验
**Moran’ s I指数
*（1）计算全局莫兰指数
//从preserve到restore务必视为一个整体，选中一起执行！！
preserve 
keep if year==2005      
spatgsa acei,weights(W) moran  twotail 
restore
//上面这个代码只能一次求一个年份的莫兰指数，改变年份2009即可

//下面这个循环语句代码可以一次性求出每一年的莫兰指数，但是没有把所有年份整理到一个表格
forvalue i  = 2005/2022{
	preserve  
	keep if year==`i'
	spatgsa acei,weights(W) moran  twotail  
	restore 
}

//下面的代码可以一次性求出每一年的莫兰指数且把所有年份整理到了一起，但是有些人stata有问题装不了xtmoran命令，这时候可以用上面的循环语句代码
logout, save(全局莫兰指数) word dec(4) replace :xtmoran ln_gf,w(WW.dta)
//此处只要把解释变量y和矩阵w2替换成你自己的，当然若命名跟我的一样则不用改。

*（2）计算局部莫兰指数
use data2,clear
xtset province_id year
spatwmat using W.dta, n(W) standardize
preserve 
keep if year==2005     
spatlsa acei_std,weights(W) moran twotail    
restore
//改变年份2009，可计算不同年份

**moran散点图
//方法一，为显示地名的莫兰散点图
preserve 
keep if year==2020   //改变年份2019，可画不同年份的散点图
spatlsa ln_gf_std,weights(W)moran graph(moran) symbol(id) id(province)  //显示地名
restore
//方法二，为不显示地名的莫兰散点图
preserve 
keep if year==2020     //改变年份2020，可画不同年份的散点图
splagvar ln_gf_std, wname(W) wfrom(Stata) moran(ln_gf_std) plot(ln_gf_std)
restore

**1LM检验
//此处最容易犯的错，就是将数据复制到stata时会莫名其妙多出一些小短横，所以需要将data、w2都拉到最后看看有没有小短横或者缺失值。还有就是数值比较大的变量需要进行取对数处理,不然很可能运行不出来
clear all
use data1, clear
use WW
spcs2xt W_result1-W_result30,matrix(aaa)time(18)  
spatwmat using aaaxt,name(WW)
clear
use data1                                           
xtset province_id year   
reg  ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban
spatdiag,weights(WW)

**wald检验和LR检验实际只要满足一个即可。但如果两个检验都能满足，建议都写。
**2Wald检验
clear all
use data1
spatwmat using WW.dta,name(WW) standardize 
xtset province_id year
xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban , fe model(sdm) wmat(WW) type(both) nolog noeffects
//Wald Test for SAR
test [Wx]ln_gf = [Wx]ln_new_a = [Wx]ln_mech_power = [Wx]ln_level = [Wx]ln_urban = 0
//Wald Test for SEM
testnl ([Wx]ln_gf = -[Spatial]rho*[Main]ln_gf) ///
       ([Wx]ln_new_a = -[Spatial]rho*[Main]ln_new_a) ///
       ([Wx]ln_mech_power = -[Spatial]rho*[Main]ln_mech_power) ///
       ([Wx]ln_level = -[Spatial]rho*[Main]ln_level) ///
       ([Wx]ln_urban = -[Spatial]rho*[Main]ln_urban)
**3LR检验
clear all
use data1
spatwmat using WW.dta,name(WW) standardize 
xtset province_id year
xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban , fe model(sdm) wmat(WW) type(both) nolog noeffects
est store sdm
xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban , fe model(sar) wmat(WW) type(both) nolog noeffects
est store sar
xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban  , fe model(sem) emat(WW) type(both) nolog noeffects
est store sem
lrtest sdm sar  //H0：空间杜宾模型可以简化为空间滞后模型（SAR）
lrtest sdm sem  //H0：空间杜宾模型可以简化为空间误差模型（SEM）

* 诊断异方差：
reg cei_std gf_std mech_power_std urban_std level_std structure_std money_std
rvfplot  // 残差vs拟合值图
estat hettest  // Breusch-Pagan检验

* 如果残差散点呈漏斗形，p<0.05
* 取对数可能缓解异方差
**4Hausman检验
//若是空间误差模型需要将下面代码中的model(sdm) wmat(W2)改成model(sem) emat(W2)，若是空间滞后模型，需要将下面的代码其中model(sdm)改成model(sar)

//方法一
clear all
use data1


spatwmat using WW.dta,name(WW) standardize 
xtset province_id year
xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban  , fe model(sdm) wmat(WW)  nolog noeffects type(both)
est store fe
xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban   , re model(sdm) wmat(WW)  nolog noeffects type(both)
est store re
hausman fe re,sigmamore

ssc install xtoverid, replace

estimates clear
xtset province_id year

capture drop __touse
gen byte __touse = !missing(ln_new_acei  ,ln_gf  , ln_new_a , ln_mech_power ,  ln_level , ln_urban )

xtreg ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban  if __touse, re vce(cluster province_id)
xtoverid
**5固定效应类型检验
use data1,clear
xtset province_id year
spatwmat using WW.dta, n(WW) standardize
xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban   , fe  model(sdm) wmat(WW) nolog noeffects type(ind)
est store ind
xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban   , fe  model(sdm) wmat(WW) nolog noeffects type(time)
est store time
xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban   , fe  model(sdm) wmat(WW) nolog noeffects type(both)
est store both
lrtest both ind,df(29)  //比较“双向”和“个体”效应  LR检验 
lrtest both time,df(17)  //比较“时间”和“双向”效应  LR检验
//df（）括号里面的数字不知道填啥，就都空着运行一遍，运行结果会提示你填多少。不过也可以调节这个数字去调显著性

*将以上固定效应类型检验结果输出到word
use data1,clear
xtset id year
spatwmat using W2.dta, n(W2) standardize
xsmle y x1 x2 x3 x4 x5 x6 x7 , fe  model(sdm) wmat(W2) nolog noeffects type(ind)
est store ind
xsmle y x1 x2 x3 x4 x5 x6 x7  , fe  model(sdm) wmat(W2) nolog noeffects type(time)
est store time
xsmle y x1 x2 x3 x4 x5 x6 x7 , fe  model(sdm) wmat(W2) nolog noeffects type(both)
est store both
drop _est_ind _est_time _est_both
local m " ind time both"
esttab `m', mtitle(`m') nogap s(r2 N )
logout, save(Descriptive) word replace: esttab `m', mtitle(`m') nogap s(r2 N ) //将这部分代码一起运行输出到word，输出的word第一行的列名错位了一列，手动调一下。


**空间杜宾效应分解
clear all
use data1
spatwmat using WW.dta,name(WW) standardize 
xtset province_id year 
xsmle   ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban , fe model(sdm) wmat(WW)  type(both) nolog effects 


xsmle ln_new_acei ln_gf ln_new_a ln_mech_power ln_level ln_urban i.year, ///
      fe model(sdm) wmat(WW) ///
      durbin(ln_gf ln_new_a ln_mech_power ln_level ln_urban) ///
      type(both) nolog effects
//type（）括号里面用双固定就写both，用个体固定就写ind，用时间固定就用time
//下面一行代码一起运行输出到命为abc的word,输出表格比较大可自行删掉第四列，即可看到完整结果
outreg2 using abc,word replace

**动态杜宾
xsmle y x1 x2 x3 x4 x5 x6 x7, fe model(sdm) wmat(W2) nolog effects type(both) dlag(2)
//dlag()里面可以填数字，比如填3表示y在时间上滞后3期

*若是空间误差模型则是以下代码，误差模型不能分解，x*表示x1 x2 x3 x4 x5 x6 x7
use data1,clear
xtset id year
spatwmat using W2.dta, n(W2) standardize
*随机效应模型
xsmle y x*, model(sem) emat(W2) type(both) nolog effects re
*时间固定效应
xsmle y x* , model(sem) emat(W2) type(time) nolog effects fe 
*个体固定效应
xsmle y x* , model(sem) emat(W2) type(ind) nolog effects fe 
*双固定效应
xsmle y x* , model(sem) emat(W2) type(both) nolog effects fe 


*若是空间滞后模型分解则是以下代码
**空间滞后模型（SLM）
*随机效应模型
xsmle y x* , model(sar) wmat(W2) type(both) nolog effects re
*时间固定效应
xsmle y x* , model(sar) wmat(W2) type(time) nolog effects fe 
*个体固定效应
xsmle y x* , model(sar) wmat(W2) type(ind) nolog effects fe 
*双固定效应
xsmle y x*, model(sar) wmat(W2) type(both) nolog effects fe 




**空间杜宾模型 - 添加AIC/BIC输出**
**比较不同模型并输出AIC/BIC**
xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban, ///
    fe model(sdm) wmat(WW) type(both) nolog noeffects
est store sdm
estat ic
matrix AIC_BIC_sdm = r(S)

xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban, ///
    fe model(sar) wmat(WW) type(both) nolog noeffects
est store sar
estat ic
matrix AIC_BIC_sar = r(S)

xsmle ln_new_acei  ln_gf   ln_new_a  ln_mech_power   ln_level  ln_urban, ///
    fe model(sem) emat(WW) type(both) nolog noeffects
est store sem
estat ic
matrix AIC_BIC_sem = r(S)

**将结果整理成表格**
clear
set obs 3
gen model = ""
gen AIC = .
gen BIC = .

replace model = "SDM" in 1
replace AIC = AIC_BIC_sdm[1,5] in 1
replace BIC = AIC_BIC_sdm[1,6] in 1

replace model = "SAR" in 2
replace AIC = AIC_BIC_sar[1,5] in 2
replace BIC = AIC_BIC_sar[1,6] in 2

replace model = "SEM" in 3
replace AIC = AIC_BIC_sem[1,5] in 3
replace BIC = AIC_BIC_sem[1,6] in 3

list, clean noobs






clear all
use data1, clear

// 1. 先设置面板（完整数据 2005-2022）
xtset province_id year 

// 2. 【关键步骤】趁着 2005 年数据还在，赶紧生成滞后项
// 此时：2005年的 L_ln_n_acei 是缺失的，但 2006年的 L_ln_n_acei 是有值的（等于2005原值）
gen L_ln_n_acei = L.ln_n_acei

// 3. 【关键步骤】现在可以安全地把 2005 年删掉了
// 这样保留下来的 2006-2022 数据中，所有变量（包括滞后项）都是完整的，没有缺失值
keep if year >= 2006

// 4. 再次检查，现在应该显示 Obs=. 为 0 了
misstable summarize ln_n_acei L_ln_n_acei

// 5. 加载权重矩阵
spatwmat using W.dta, name(W) standardize 

// 6. 运行模型（不需要 if 了，因为数据已经干净了）
xsmle ln_n_acei ln_gf ln_first_structure ln_mech_power ln_level ln_urban L_ln_n_acei, ///
    fe model(sdm) wmat(W) nolog effects type(both)
	
	
