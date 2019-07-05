#!/bin/bash

C_PWD=`dirname $0`

if [ ${C_PWD} == "." ]
then
    C_PWD=`pwd`
fi

cd ${C_PWD}
echo ""
echo ">>>脚本执行目录: "${C_PWD}

###################################
###### 工程信息
###################################
#
workspaceBasePath="/Users/momo/Desktop/MOMO/MOMO_iOS"
#工程名字
workspaceName="MomoChat.xcworkspace"
#scheme名字
schemeName="MomoChat CI"
#打包模式 Debug Release Distribution InHouse
configuration="InHouse"
# id
InHouse_PRODUCT_BUNDLE_IDENTIFIER="com.wemomo.momotest"
# profile
InHouse_ProvisioningProfile="Inhouse_momotest_only"
# 证书
InHouse_SigningCertificate="iPhone Distribution"

# iOS工程名称 MomoChat
iOSProjectName=${workspaceName/%.xcworkspace/""}
# 需要删除的target昵称
deleteTargetName1="MDNotificationService"
deleteTargetName2="MomoChatScreenRecord"
deleteTargetName3="MomoChatScreenRecordUI"

#控制进程开关
needcopycode=0
needupdatepbxproj=1

###############################
## 用户输入：：
###############################
inputRewritePackageInfo(){
    echo "😊请输入打包的版本号（eg:8.11.3 不填不改）："
    read -p "版本号: " version
    if [ -z "${version}" ];
    then
        version=0
    fi

    echo "😊请输入打包的build号（eg:1 不填不改）："
    read -p "build号：" build
    if [ -z "${build}" ];
    then
        build=0
    fi

    echo "😊请输入打包的内部版本号（eg:1332 不填不改）"
    read -p "内部版本号：" innerVersion
    if [ -z "${innerVersion}" ];
    then
        innerVersion=-1
    fi

    echo "😊请输入需要打包的工程文件夹名（默认:MOMO_IOS）"
    read -p "工程文件夹名：" projectFileName
    if [ -z "${projectFileName}" ];
    then
        projectFileName="MOMO_iOS"
    else
        projectFileName="${projectFileName}"
    fi
}

echo "##############################"
echo "是否修改打包信息--(版本号等...)："
echo "##############################"

read -p "(y/n):" rewrite
if [[ "${rewrite}" = "y" || "${rewrite}" = "yes" || "${rewrite}" = "Y" ]]
then
    inputRewritePackageInfo
else
    version=0
    build=0
    innerVersion=-1
    projectFileName="MOMO_iOS"
fi

oldtime=$(date +%s)

###############################
## 当前缓存目录
###############################
TEMP_CACHE_NAME=${projectFileName}"_cache_temp"
TEMP_CACHE_DIR=${C_PWD}"/"${TEMP_CACHE_NAME}
mkdir ${TEMP_CACHE_DIR}
echo ${TEMP_CACHE_DIR}

###############################
## 目标目录
###############################
DEST_DIR_NAME=${projectFileName}

##-目标
destinationDir=${workspaceBasePath}

#拷贝代码
backCodeFunction(){
    echo ">>>备份代码中..."
    rm -f -r "${TEMP_CACHE_DIR}/${DEST_DIR_NAME}"
    #rm -f -r "${TEMP_CACHE_DIR}"

    mkdir "${TEMP_CACHE_DIR}/${DEST_DIR_NAME}"

    sleep 0.5

    cp -r -f ${destinationDir} ${TEMP_CACHE_DIR}
    ###cp -r -f ${destinationDir} ${TEMP_CACHE_DIR}"/"${DEST_DIR_NAME}

    # -rv 会显示拷贝进度
    # --排查文件拷贝
    #rsync --exclude='.git/*' ${destinationDir} ${TEMP_CACHE_DIR} -r -quiet

    #shell中使用符号“$?”来显示上一条命令执行的返回值，如果为0则代表执行成功，其他表示失败。
    if [ $? != 0 ]
    then
        echo ">>>备份文件出错..."
    exit
    fi
    echo ">>>备份代码完成..."
}

#iOS工程目录
iOS_PROJECT_DIR=${destinationDir}
if [ ${needcopycode} == 1 ];
then
    backCodeFunction
    iOS_PROJECT_DIR=${TEMP_CACHE_DIR}"/"${DEST_DIR_NAME}
fi

oldtime1=$(date +%s)

#获取git分支名称
cd ${destinationDir}
BRANCH_NAME=`sh -c 'git branch --no-color 2> /dev/null' | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/' -e 's/\//\_/g'`
echo "分支名称：${BRANCH_NAME}"
cd ${C_PWD}


###############################
## 修改iOS工程文件
###############################
echo ">>>修改工程文件信息..."

##备份文件
MomoChatInfoDir="${iOS_PROJECT_DIR}/OtherSources/MomoChat-Info.plist"
distributeStorePlistDir="${iOS_PROJECT_DIR}/OtherSources/distribute_store.plist"
innerVersionDir="${iOS_PROJECT_DIR}/OtherSources/MDInnerVersion.h"
projectFileDir="${iOS_PROJECT_DIR}/${iOSProjectName}.xcodeproj/project.pbxproj"

backupsavedir="${TEMP_CACHE_DIR}/.backup"
backupmodifyfiles(){
    mkdir ${backupsavedir}
    cp ${MomoChatInfoDir} ${backupsavedir}
    cp ${distributeStorePlistDir} ${backupsavedir}
    cp ${innerVersionDir} ${backupsavedir}
    cp ${projectFileDir} ${backupsavedir}
}
restorebackupfiles(){
    cp "${backupsavedir}/MomoChat-Info.plist" ${MomoChatInfoDir}
    cp "${backupsavedir}/distribute_store.plist" ${distributeStorePlistDir}
    cp "${backupsavedir}/MDInnerVersion.h" ${innerVersionDir}
    cp "${backupsavedir}/project.pbxproj" ${projectFileDir}
    rm -f -r ${backupsavedir}
}

backupmodifyfiles

export PATH=${PATH}:/usr/libexec

# 1、修改打包的版本号和build号
PLIST_ARRAY=(${MomoChatInfoDir})
for plistPath in ${PLIST_ARRAY[*]};
do
    # version
    if [ $version != 0 ]
    then
        PlistBuddy -c "Set :CFBundleShortVersionString ${version}" "${plistPath}"
    else
        version=$(PlistBuddy -c "print :CFBundleShortVersionString" "${plistPath}")
    fi
    # build
    if [ $build != 0 ]
    then
        PlistBuddy -c "Set :CFBundleVersion ${build}" "${plistPath}"
    else
        build=$(PlistBuddy -c "print :CFBundleVersion" "${plistPath}")
    fi
done

# 2、修改打包渠道plist
buildDate=$(date "+%m%d_%H:%M")
store="S2"

#echo 修改打包日期: buildDate = $buildDate
#echo 修改打包渠道: store = $store
PlistBuddy -c "Set :store ${store}" ${distributeStorePlistDir}
PlistBuddy -c "Set :buildDate ${buildDate}" ${distributeStorePlistDir}

# 3、修改内部版本号
if [ ${innerVersion} != -1 ]
then
    innerVersionStr="#define MomoApp_Version      ${innerVersion}"
    sed -i "" "s/.*MomoApp_Version.*/${innerVersionStr}/" ${innerVersionDir}
else
    innerVersionLine=`sed -n "/MomoApp_Version/p" ${innerVersionDir}`
    innerVersion=`echo ${innerVersionLine} | sed 's/.*MomoApp_Version *\([0-9]*\).*/\1/g'`
fi

# 4、修改配置文件
###################################################
## 删除多余target 只留主target extension 企业包
## .project就是plist
## 多余的tagret可以根据rootObject的值找到-》dict->targets数组中 只留第一个就好
###################################################
echo ">>>修改配置文件...project.pbxproj..."

## .project目录
iOSProjectPath=${projectFileDir}

deleteExtTraget() {
#############################
#删除规则：删掉rootid:TargetAttributes/targets
#        rootid:productRefGroup中的数据
#        maintargetid:dependencies/依赖
#        Embed App Extensions -files
##############################
    if [ ! -n "$1" ];then
        echo ">>>需输入删除的target昵称..."
    exit
    fi

    #获取id
    rootid=`PlistBuddy -c "print :rootObject" ${iOSProjectPath}`

    ## 如有特殊情况可以遍历 每个id 找到需要的主target
    #找到roottargetid
    roottargets=`PlistBuddy -c "print :objects:${rootid}:targets" ${iOSProjectPath}`


    #查找maintargetid 和删除的targetid
    index=-1
    for targetid in ${roottargets}
    do
        if [ "${targetid}" == "Array" -o "${targetid}" == "{" -o "${targetid}" == "}" ];
        then
        continue
        fi

        index=`expr ${index} + 1`
        #根据productName判断获取id
        targetproductname=`PlistBuddy -c "print :objects:${targetid}:productName" ${iOSProjectPath}`

        #保存需要删除的targetid
        for arg in $@;
        do
            if [ ${targetproductname} == ${arg} ];
            then
                deltargetids[${#deltargetids[*]}]=${targetid}
                #删除
                deleindexarray[${#deleindexarray[*]}]=${index}
                PlistBuddy -c "Delete :objects:${rootid}:attributes:TargetAttributes:${targetid}" ${iOSProjectPath}
                continue
            fi
        done

        if [ ${targetproductname} == ${iOSProjectName} ];
        then
            maintargetid=${targetid}
        fi

    done

    #deleindexarray
    for((i=${#deleindexarray[*]}-1;i>=0;i--))
    do
        PlistBuddy -c "Delete :objects:${rootid}:targets:${deleindexarray[i]}" ${iOSProjectPath}
        echo "dele:target:${deleindexarray[i]}"
    done
    unset deleindexarray
    index=-1

    echo "main:"${maintargetid}
    echo "del:"${deltargetids}

    productsid=`PlistBuddy -c "print :objects:${rootid}:productRefGroup" ${iOSProjectPath}`
    maingroupid=`PlistBuddy -c "print :objects:${rootid}:mainGroup" ${iOSProjectPath}`

    ## 删除product
    products=`PlistBuddy -c "print :objects:${productsid}:children" ${iOSProjectPath}`
    for productid in ${products}
    do
        if [ "${productid}" == "Array" -o "${productid}" == "{" -o "${productid}" == "}" ];
        then
        continue
        fi

        index=`expr ${index} + 1`
        productpathname=`PlistBuddy -c "print :objects:${productid}:path" ${iOSProjectPath}`

        for arg in $@;
        do
            if [ `expr ${productpathname} : "${arg}\(.*\)"` ];
            then
                #删除
                echo "dele-:productname:"${productpathname}
                deleindexarray[${#deleindexarray[*]}]=${index}
                continue
            fi
        done
    done

    for((i=${#deleindexarray[*]}-1;i>=0;i--))
    do
        PlistBuddy -c "Delete :objects:${productsid}:children:${deleindexarray[i]}" ${iOSProjectPath}
        echo "dele:product:${deleindexarray[i]}"
    done

## 删除buildphaseid == Embed App Extensions的files
    buildphases=`PlistBuddy -c "print :objects:${maintargetid}:buildPhases" ${iOSProjectPath}`
    for buildphaseid in ${buildphases}
    do
        if [ "${buildphaseid}" == "Array" -o "${buildphaseid}" == "{" -o "${buildphaseid}" == "}" ];
        then
            continue
        fi

        buildphasename=`PlistBuddy -c "print :objects:${buildphaseid}:name" ${iOSProjectPath}`
        if [ "${buildphasename}" == "Embed App Extensions" ];
        then
            #删除
            echo "dele-:buildphasename:"${buildphasename}
            PlistBuddy -c "Delete :objects:${buildphaseid}:files" ${iOSProjectPath}
            PlistBuddy -c "Add :objects:${buildphaseid}:files array" ${iOSProjectPath}
            break
        fi
    done

    ##删除主target依赖
    PlistBuddy -c "Delete :objects:${maintargetid}:dependencies" ${iOSProjectPath}
    PlistBuddy -c "Add :objects:${maintargetid}:dependencies array" ${iOSProjectPath}


    ### 修改打包id
    updateArchiveMode() {
        ##productName
        productName=`PlistBuddy -c "print :objects:${maintargetid}:productName" ${iOSProjectPath}`

        ##--修改ident --模式下的ID Debug / Release / InHouse / Distribution
        buildConfigurationListID=`PlistBuddy -c "print :objects:${maintargetid}:buildConfigurationList" ${iOSProjectPath}`
        buildConfigurations=`PlistBuddy -c "print :objects:${buildConfigurationListID}:buildConfigurations" ${iOSProjectPath}`
        echo ">>>>${buildConfigurations}"

        for id in ${buildConfigurations}
        do
            if [ "${id}" == "Array" -o "${id}" == "{" -o "${id}" == "}" ];
            then
            continue
            fi

            #echo ">>>>>>> id ${id}"
            name=`PlistBuddy -c "print :objects:${id}:name" ${iOSProjectPath}`


            ### inhouse -企业包
            if [ "${name}" == "${configuration}" ];
            then
                if [ -n "${InHouse_PRODUCT_BUNDLE_IDENTIFIER}" ];
                then
                    PlistBuddy -c "set :objects:${id}:buildSettings:PRODUCT_BUNDLE_IDENTIFIER ${InHouse_PRODUCT_BUNDLE_IDENTIFIER}" ${iOSProjectPath}
                fi

                if [ "${name}" == "InHouse" ];
                then
                    # 设置ENTITLEMENTS 为nil
                    PlistBuddy -c "Set :objects:${id}:buildSettings:CODE_SIGN_ENTITLEMENTS string ''" ${iOSProjectPath}
                fi
            fi
        done
    }

    #updateArchiveMode

    sleep 1.0
}

if [ ${needupdatepbxproj} == 1 ];
then
    deleteExtTraget ${deleteTargetName1} ${deleteTargetName2} ${deleteTargetName3}
fi

oldtime2=$(date +%s)


echo ""
echo "##############😊😊😊########################"
echo "版本号   : ${version}"
echo "build号 : ${build}"
echo "内部版本号: ${innerVersion}"
echo "分支名称 : ${BRANCH_NAME}"
echo ">>>开始打包..."
echo "######################################"

############################################
## https://www.jianshu.com/p/4f4d16326152
############################################
echo "#####################################"
echo "###########开始打包..##################"
echo "#####################################"
# 打包目录
archiveTempName="${iOSProjectName}_$(date '+%Y-%m-%d_%H%M')"

mkdir ${TEMP_CACHE_DIR}"/${archiveTempName}"

archivePath=${TEMP_CACHE_DIR}"/${archiveTempName}/MomoChat.xcarchive"
#导出包路径
exportPath=${TEMP_CACHE_DIR}"/${archiveTempName}"
#export plist文件所在路径
exportOptionsPlistPath=${exportPath}"/exportOptionsPlist.plist"

### 生成export plist
exportPlist(){
cat>${exportOptionsPlistPath}<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>compileBitcode</key>
<false/>
<key>destination</key>
<string>export</string>
<key>method</key>
<string>enterprise</string>
<key>provisioningProfiles</key>
<dict>
<key>${InHouse_PRODUCT_BUNDLE_IDENTIFIER}</key>
<string>${InHouse_ProvisioningProfile}</string>
</dict>
<key>signingCertificate</key>
<string>${InHouse_SigningCertificate}</string>
<key>signingStyle</key>
<string>manual</string>
<key>stripSwiftSymbols</key>
<true/>
<key>teamID</key>
<string>72CZEEPG39</string>
<key>thinning</key>
<string>&lt;none&gt;</string>
</dict>
</plist>
EOF
}
exportPlist

#
cd ${iOS_PROJECT_DIR}

#echo ""
#echo ">>>>>清理中....."
#echo ""
## 5、清理工程
#xcodebuild clean \
#-workspace "${workspaceName}" \
#-scheme "${schemeName}" \
#-configuration "${configuration}" \
#-quiet
#
#if [ $? != 0 ]
#then
#    echo ""
#    echo ">>>>>clen出错......"
#    restorebackupfiles
#    exit
#fi
#
#echo ""
#echo ">>>>>清理完成....."

oldtime3=$(date +%s)

echo ""
echo ">>>>>archiving....."
echo ""
# 6 打包
xcodebuild archive \
-workspace "${workspaceName}" \
-scheme "${schemeName}" \
-configuration "${configuration}" \
-archivePath "${archivePath}" \
-quiet

if [ $? != 0 ]
then
    echo ""
    echo ">>>>>archive出错......"
    restorebackupfiles
    exit
fi

oldtime4=$(date +%s)
echo ""
echo ">>>>>archive 完成...."

# 7、导出包
echo ""
echo ">>>>>正在导出ipa包..."
xcodebuild -exportArchive \
-archivePath "${archivePath}" \
-exportOptionsPlist "${exportOptionsPlistPath}" \
-exportPath "${exportPath}"

if [ $? != 0 ]
then
    echo ""
    echo ">>>>>exportArchive出错......"
    restorebackupfiles
    exit
fi

oldtime5=$(date +%s)
echo ""
echo ">>>>>导出ipa包完成..."
echo ""

# 还原拷贝文件
restorebackupfiles

##rm -f -r ${exportPath}

archivetime=$((oldtime4 - oldtime3))
totaltime=$(($(date +%s) - oldtime))
echo "#################😊😸😄###################"
echo "版本号       : ${version}"
echo "build号     : ${build}"
echo "内部版本号    : ${innerVersion}"
echo "分支名称     : ${BRANCH_NAME}"
echo "耗时>>>>>"
echo "总耗时       :$((totaltime/60))分$((totaltime%60))秒 or ${totaltime}s"
echo "修改文件耗时  :$((oldtime2 - oldtime))s"
echo "archive耗时 :${archivetime}s or $((archivetime/60))分$((archivetime%60))秒 "
echo "导出耗时     :$((oldtime5 - oldtime4))s"
echo "#################😊😸😄###################"

## 上传
echo ""
echo ">>>>>开始上传..."
echo ""

echo ""
echo ">>>>>上传成功..."
echo ""

# 编译优化
# https://bestswifter.com/improve_compile_speed/
