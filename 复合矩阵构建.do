* ===========================================================
* 0. 设置环境与参数
* ===========================================================
clear all
set more off
cd "D:\desktop\zhuomian\数据"

* 定义权重 (根据你的计算结果)
global alpha_dist  = 0.495176  // 反距离矩阵权重
global beta_green  = 0.504824  // 绿色技术矩阵权重

di "正在计算复合矩阵..."
di "公式: W_composite = $alpha_dist * W_dist + $beta_green * W_green"

* ===========================================================
* 1. 读取并准备 反距离矩阵 (W_d)
* ===========================================================
* 假设文件名为 geographic_weight_matrix_raw.dta (之前生成的原始矩阵)
use "geo_std.dta", clear

mkmat _all, matrix(W_d)

* ===========================================================
* 2. 读取并准备 绿色技术矩阵 (W_e)
* ===========================================================
* 假设文件名为 green_tech_matrix.dta (请修改为你真实的文件名)
use "eco_std.dta", clear


mkmat _all, matrix(W_e)

* --- 检查维度一致性 ---
local r_d = rowsof(W_d)
local r_e = rowsof(W_e)
if `r_d' != `r_e' {
    di as error "错误：两个矩阵的维度不一致！"
    di "反距离矩阵: `r_d' 行, 绿色矩阵: `r_e' 行"
    exit
}

* ===========================================================
* 3. 利用 Mata 执行公式计算与标准化
* ===========================================================
mata:
    // 1. 导入矩阵到 Mata 环境
    Wd = st_matrix("W_d")
    We = st_matrix("W_e")
    
    // 2. 获取权重
    alpha = $alpha_dist
    beta  = $beta_green
    
    // 3. 执行线性组合公式 (Linear Combination)
    // W = alpha * Wd + beta * We
    W_comp = (alpha * Wd) + (beta * We)
    
    // 4. 确保对角线为 0 (公式要求 i != j)
    _diag(W_comp, 0)
    
    // 5. 【最后一步】行标准化 (Row Normalization)
    // 空间计量模型通常要求矩阵行和为 1
    rs = rowsum(W_comp)
    // 避免除以 0 (如果某行全是0，分母设为1，结果仍为0)
    W_final = W_comp :/ (rs + (rs:==0))
    
    // 6. 将结果传回 Stata
    st_matrix("W_result", W_final)
end

* ===========================================================
* 4. 导出结果
* ===========================================================
clear
svmat W_result

* 导出为 Excel (可视化查看)
export excel using "绿色_地理_复合矩阵.xlsx", replace firstrow(variables)

* 导出为 DTA (用于回归分析)
save "W_green_geo_composite.dta", replace

di _n
di "========================================================"
di "计算成功！"
di "反距离权重: $alpha_dist"
di "绿色权重:   $beta_green"
di "最终矩阵已保存为: W_green_geo_composite.dta"
di "========================================================"
