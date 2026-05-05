cd D:\desktop\zhuomian\数据
//自己的数据放在哪个位置就改成那个位置,不知道数据存放在哪个路径可以百度（百度怎么查找文件存储路径），百度写的很清楚

use data2,clear

xtset province_id year

***变量的描述性统计
sum LNaca  ln_mech_power_std	ln_gf_std	ln_urban_std	ln_level_std	ln_structure_std	ln_money_std	LNaca


***空间权重矩阵制作
spatwmat using W2.dta, n(W2) standardize
matrix list W2

***空间相关性检验
**Moran' s I指数
*（1）计算全局莫兰指数
//从preserve到restore务必视为一个整体，选中一起执行！！
preserve 
keep if year==2005      
spatgsa LNaca,weights(W2) moran  twotail 
restore
//上面这个代码只能一次求一个年份的莫兰指数，改变年份2009即可

//下面这个循环语句代码可以一次性求出每一年的莫兰指数，但是没有把所有年份整理到一个表格
forvalue i  = 2005/2022{
	preserve  
	keep if year==`i'
	spatgsa LNaca,weights(W2) moran  twotail  
	restore 
}

//下面的代码可以一次性求出每一年的莫兰指数且把所有年份整理到了一起，但是有些人stata有问题装不了xtmoran命令，这时候可以用上面的循环语句代码
logout, save(全局莫兰指数) word dec(4) replace :xtmoran ln_gf_std,wname(W2)


*（2）计算局部莫兰指数
use data2,clear
xtset province_id year
spatwmat using W2.dta, n(W2) standardize
preserve 
keep if year==2005     
spatlsa LNaca,weights(W2) moran twotail    
restore
//改变年份2009，可计算不同年份

**moran散点图
//方法一，为显示地名的莫兰散点图
preserve 
keep if year==2005   //改变年份2019，可画不同年份的散点图
spatlsa LNaca,weights(W2)moran graph(moran) symbol(id) id(province)  //显示地名
restore
//方法二，为不显示地名的莫兰散点图
preserve 
keep if year==2005     //改变年份2020，可画不同年份的散点图
splagvar LNaca, wname(W2) wfrom(Stata) moran(acei_std) plot(acei_std)
restore