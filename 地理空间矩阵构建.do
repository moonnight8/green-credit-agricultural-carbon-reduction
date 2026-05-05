* ======================
* 第一步：准备数据
* ======================

* 假设您的数据已经加载，包含以下变量：
* province: 省份名称
* year: 年份
* longitude: 经度
* latitude: 纬度
* green_patent1: 绿色低碳专利数量（低碳技术变量）



* ======================
* 第二步：计算地理距离矩阵 w_d
* ======================

* 首先，我们需要省份的经纬度（每个省份只有一个经纬度）
* 假设每个省份的经纬度是固定的，取第一年的数据
preserve
keep province longitude latitude
duplicates drop province, force
save "province_coordinates.dta", replace
restore

* 加载省份坐标数据
use "province_coordinates.dta", clear

* 生成省份ID
egen province_id = group(province)
order province_id province

* 计算球面距离（使用haversine公式）
* 创建空矩阵存储距离
local n = _N
matrix D = J(`n', `n', 0)
matrix rownames D = province
matrix colnames D = province

* 使用循环计算每对省份之间的距离
forvalues i = 1/`n' {
    local lat1 = latitude[`i']
    local lon1 = longitude[`i']
    local prov1 = province[`i']
    
    forvalues j = 1/`n' {
        if `i' == `j' {
            matrix D[`i', `j'] = 0  // 对角线为0
        }
        else {
            local lat2 = latitude[`j']
            local lon2 = longitude[`j']
            
            * 计算球面距离（单位：千米）
            * haversine公式
            local dlat = (`lat2' - `lat1') * _pi / 180
            local dlon = (`lon2' - `lon1') * _pi / 180
            
            local a = sin(`dlat'/2)^2 + cos(`lat1'*_pi/180) * cos(`lat2'*_pi/180) * sin(`dlon'/2)^2
            local c = 2 * asin(min(1, sqrt(`a')))
            local distance = 6371 * `c'  // 地球半径6371km
            
            matrix D[`i', `j'] = `distance'
        }
    }
}

* 转换为权重矩阵 w_d = 1/d^2 (i ≠ j)
matrix w_d = J(`n', `n', 0)
forvalues i = 1/`n' {
    forvalues j = 1/`n' {
        if `i' != `j' {
            local d = D[`i', `j']
            if `d' > 0 {
                matrix w_d[`i', `j'] = 1/(`d'^2)
            }
        }
    }
}

* 保存地理距离权重矩阵
matrix list w_d
svmat w_d, names(w_d_)
save "geographic_weight_matrix.dta", replace
* 计算每行的权重和
gen rowsum = 0
local n = _N  // 省份数量
forvalues i = 1/`n' {
    replace rowsum = 0 in `i'
    forvalues j = 1/`n' {
        replace rowsum = rowsum + w_d_`j'[`i'] in `i'
    }
}

* 创建标准化矩阵
forvalues j = 1/`n' {
    gen w_std_`j' = w_d_`j' / rowsum
}

* 检查标准化后每行的和
gen rowsum_std = 0
forvalues i = 1/`n' {
    replace rowsum_std = 0 in `i'
    forvalues j = 1/`n' {
        replace rowsum_std = rowsum_std + w_std_`j'[`i'] in `i'
    }
}

* 查看标准化后的行和（应该都是1）
summarize rowsum_std

* 查看标准化后的矩阵
list province w_std_1 w_std_2 w_std_3 in 1/5

* 保存标准化矩阵
save "geographic_weight_matrix_std.dta", replace