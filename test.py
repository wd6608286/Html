#!c:\pyhton
# -*- coding: utf-8 -*-
# �ļ�����test.py

from Tkinter import *           # ���� Tkinter ��
root = Tk()                     # �������ڶ���ı���ɫ
                                # ���������б�
li     = ['C','python','php','html','SQL','java']
movie  = ['CSS','jQuery','Bootstrap']
listb  = Listbox(root)          #  ���������б����
listb2 = Listbox(root)
for item in li:                 # ��һ��С������������
    listb.insert(0,item)

for item in movie:              # �ڶ���С������������
    listb2.insert(0,item)

listb.pack()                    # ��С�������õ���������
listb2.pack()
root.mainloop()                 # ������Ϣѭ��

a=int(raw_input('Please input number a:'))
b=int(raw_input('Please input number b:'))

if a > 0 and b > 0:
    print "Answer"
    print "True"
else:
    print "Answer"
    # û���ϸ���������ִ��ʱ����
     print "False"

print 'The result for a - b is:' ,a-b
print 'The result for a + b is:' ,a+b
print 'The result for a * b is:' ,a*b
print 'The result for a / b is:' ,a/b

days = ['Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday']
word = 'word'
sentence = "����һ�����ӡ�"
paragraph = """����һ�����䡣
�����˶�����"""

print days,word,sentence,paragraph

str = 'Hello World!'

print str # ��������ַ���
print str[0] # ����ַ����еĵ�һ���ַ�
print str[2:5] # ����ַ����е������������֮����ַ���
print str[2:] # ����ӵ������ַ���ʼ���ַ���
print str * 2 # ����ַ�������
print str + "TEST" # ������ӵ��ַ���
