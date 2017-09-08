#!/bin/bash

#使用此脚本的前提条件是安装了fastlane和gym以及shenzhen(安装shenzhen命令行：sudo gem install --bin /usr/local/bin/ shenzhen),
#前2者用来编译打包,后者用来上传到蒲公英
#参考：https://github.com/xilin/ios-build-script

#计时
SECONDS=0

#假设脚本放置在与项目相同的路径下
project_path=$(pwd)
#取当前时间字符串添加到文件结尾
nowTime=$(date +"%Y_%m_%d_%H_%M_%S")
#当前所在用户
current_user=$(logname)

#指定项目的scheme名称
scheme="xxxxxxx"
workspace_name="xxxxxxxxxxxxx"

#指定要打包的配置名
configuration="Release"
#指定打包所使用的输出方式，目前支持app-store, package, ad-hoc, enterprise, development, 和developer-id，即xcodebuild的method参数
export_method='enterprise'

#指定项目地址
workspace_path="$project_path/$workspace_name.xcworkspace"
#指定输出路径(此处是输出到桌面),如果不存在则创建一个
output_path="/Users/$current_user/Desktop/IPA"
if [[ ! -d $output_path ]]; then
	mkdir $output_path
fi
#自定义一个名字`scheme_time`
name="${scheme}_${nowTime}"
#指定输出归档文件地址
archive_path="$output_path/${name}.xcarchive"
#指定输出ipa地址
ipa_path="$output_path/${name}.ipa"
#指定输出ipa名称
ipa_name="${name}.ipa"
#获取执行命令时的commit message
commit_msg="$1"

#输出设定的变量值
echo "===workspace path: ${workspace_path}==="
echo "===archive path: ${archive_path}==="
echo "===ipa path: ${ipa_path}==="
echo "===export method: ${export_method}==="
echo "===commit msg: $1==="

#先清空前一次build
fastlane gym --workspace ${workspace_path} --scheme ${scheme} --clean --configuration ${configuration} --archive_path ${archive_path} --export_method ${export_method} --output_directory ${output_path} --output_name ${ipa_name}

#上传到fir
#fir publish ${ipa_path} -T ${fir_token} -c "${commit_msg}"

#上传到蒲公英
pgy_userKey="xxxxxxx"
pgy_apiKey="xxxxxxxxxxx"

#官方提供的一键上传到蒲公英的方法
# curl -F "file=@$ipa_path" \
# -F "uKey={$pgy_userKey}" 	\
# -F "_api_key={$pgy_apiKey}" \
# https://www.pgyer.com/apiv1/app/upload

#利用shenzhen上传到蒲公英
ipa distribute:pgyer -f ${ipa_path} -u ${pgy_userKey} -a ${pgy_apiKey}

#IPA包下载地址：
echo "IPA包下载地址：https://www.pgyer.com/xxxxxxxxxxx"

#输出总用时
echo "=== Finished. Total time: ${SECONDS}s  ==="
