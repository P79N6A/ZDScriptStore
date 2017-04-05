#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os

# system(command) -> exit_status
# Execute the command (a string) in a subshell.

def PodFileContents(podfilePath, isOverride, **libInfo):
    info = ''
    for libName in libInfo.keys():
        if libInfo[libName] == '0':  # 用户输入时，0代表缺省属性，即不指定库的版本号
            podInfo = "pod '%s'\n" % (libName)
        elif libInfo[libName] == 'no':  # 用户输入q时，表示什么都不用
            podInfo = ' '
        else:
            podInfo = "pod '%s', '~> %s'\n" % (libName, libInfo[libName])

        info += podInfo

    # 如果是覆盖重写Podfile，必须要加上platform，否则只要在末尾继续添加库信息即可
    # 根据给定的路径创建一个podFile
    if isOverride == 'o':
        # 获取iOS版本信息
        iosVersion = raw_input('Please enter iOS version: \n')
        iosVersion.strip()
        # 将传入的iOS版本，库名，库版本添加为字符串，作为podfile内容
        content = "platform:ios, '%s'\n" % iosVersion
        content += info
        filehandle = open(podfilePath, "w")
        filehandle.write(content)
        filehandle.close()
    else:
        filehandle = open(podfilePath, "a")
        filehandle.write(info)
        filehandle.close()


def getUserInputLibInfo():
    # 获取第三方库名称，版本信息，若输入为q，则结束输入
    # print ('----Please enter lib name and version, using "," for seperatation.\nIf no version specified, enter "0" instead. '
    #         'Enter "q" to finish your input: ')
    print ('----输入库名和版本号，如"AFNetworking,2.1.0"\n若不指定版本号，则用0代替。如"AFNetworking,0"'
           '如果输入结束，按"q"然后回车以继续')
    libInfo = dict()
    userInputLibInfo = "start"  # 随便给一个非q的值作为初始值
    while userInputLibInfo != 'q':
        userInputLibInfo = raw_input()
        # 一进入就输入q，表示不做任何事
        if userInputLibInfo == 'q' and len(libInfo) == 0:
            libInfo = {'no': 'no'}
            return libInfo
        elif userInputLibInfo == 'q' and len(libInfo) > 0:
            continue

        try:  # 如果找不到分隔符,就抛出异常处理
            userInputLibInfo.index(',')
        except:
            print ('错误的输入, 请重试.若输入结束, 请输入"q"按回车: ')
            continue

        index = userInputLibInfo.index(',')
        libName = userInputLibInfo[0:index].strip()
        libVersion = userInputLibInfo[index + 1:].strip()
        libInfo[libName] = libVersion
        print ('库信息:{"%s,%s}",请继续添加，结束请按"q"并回车' % (libName, libVersion))

    print ('----完成输入, 库信息为 %s' % libInfo)
    return libInfo


def generatePodfile(filepath, projectpath, isoverride):
    # 获取用户输入的第三方库信息：库名+库版本号
    libInfo = getUserInputLibInfo()
    # 生成Podfile
    PodFileContents(filepath, isoverride, **libInfo)
    os.chdir(projectpath)
    print  ('====== podfile 日志 ======')
    os.system('pod install --verbose --no-repo-update')


# 判断给定路径的文件夹下是否包含某后缀名的文件，返回BOOL类型
def isAvailablePath(path, extension, isOpen):
    # 先判断给定路径的合法性
    path = path.strip()
    if os.path.exists(path):
        pathList = os.listdir(path)
        for fileName in pathList:
            if fileName.endswith(extension):
                filepath = path + '/%s' % fileName
                if isOpen == True:
                    os.system('open %s' % filepath)
                return True
        # 出循环，表示没有搜到这个文件
        return False
    else:
        return False


def main():
    # 获取工程文件夹路径
    projectPath = raw_input("请输入(或者拖曳进路径): ")  # Please drag in your project path:
    result = isAvailablePath(projectPath, 'xcodeproj', False)

    while result != True:
        projectPath = raw_input("无效路径，不包含Xcode工程，请重试 :")  # Please drag in your project path:
        result = isAvailablePath(projectPath, 'xcodeproj', False)

    projectPath = projectPath.strip()
    filePath = projectPath + '/Podfile'
    print (projectPath)
    # 增加需求，判断podfile是否存在，若存在，询问是 override 还是 append lib
    if os.path.exists(filePath):
        print ("----Podfile已存在, 重写还是添加一个新的库?\n"
               "输入 'o'(override) 来重写\n"
               "输入 'a'(append) 来添加")
        isOverride = raw_input()

        while (isOverride != 'o' and isOverride != 'a'):
            print("您输入的是 %s" % isOverride)
            isOverride = raw_input("无效的输入, 请重试: \n")

        generatePodfile(filePath, projectPath, isOverride)
    else:
        generatePodfile(filePath, projectPath, 'o')

    # 完成cocoapods，提醒用户是否打开当前目录下的
    isOpenXcodeWorkplace = raw_input("\n----Cocoapods 加载完毕, 你要打开 .xcworkspace 工程吗\n"
                                     "-Y\n"
                                     "-N\n")
    while (isOpenXcodeWorkplace != 'Y' and isOpenXcodeWorkplace != 'N'):
        print("您输入的是 = %s" % isOpenXcodeWorkplace)
        isOpenXcodeWorkplace = raw_input("无效的输入，请重试: \n")

    if isOpenXcodeWorkplace == 'Y':
        if isAvailablePath(projectPath, 'xcworkspace', True) == False:
            print ('打开失败，该文件不存在')
    elif isOpenXcodeWorkplace == 'N':
        print ('-end')


if __name__ == '__main__':
    main()