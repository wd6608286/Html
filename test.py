#!c:\pyhton
# -*- coding: utf-8 -*-
# 文件名：test.py

from Tkinter import *           # 导入 Tkinter 库
root = Tk()                     # 创建窗口对象的背景色
                                # 创建两个列表
li     = ['C','python','php','html','SQL','java']
movie  = ['CSS','jQuery','Bootstrap']
listb  = Listbox(root)          #  创建两个列表组件
listb2 = Listbox(root)
for item in li:                 # 第一个小部件插入数据
    listb.insert(0,item)

for item in movie:              # 第二个小部件插入数据
    listb2.insert(0,item)

listb.pack()                    # 将小部件放置到主窗口中
listb2.pack()
root.mainloop()                 # 进入消息循环

a=int(raw_input('Please input number a:'))
b=int(raw_input('Please input number b:'))

if a > 0 and b > 0:
    print "Answer"
    print "True"
else:
    print "Answer"
    # 没有严格缩进，在执行时保持
     print "False"

print 'The result for a - b is:' ,a-b
print 'The result for a + b is:' ,a+b
print 'The result for a * b is:' ,a*b
print 'The result for a / b is:' ,a/b

days = ['Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday']
word = 'word'
sentence = "这是一个句子。"
paragraph = """这是一个段落。
包含了多个语句"""

print days,word,sentence,paragraph

str = 'Hello World!'

print str # 输出完整字符串
print str[0] # 输出字符串中的第一个字符
print str[2:5] # 输出字符串中第三个至第五个之间的字符串
print str[2:] # 输出从第三个字符开始的字符串
print str * 2 # 输出字符串两次
print str + "TEST" # 输出连接的字符串
