### 数据类型

>**原生数据类型**
>
>原生数据类型包括数字、字符串、布尔值以及两个特殊的类型：null和undefined。
>
>```javascript
>var num = 6;
>```
>
>null和undefined都代表了直接量的空缺，如果一个变量指向了其中任何一个都代表false的含义，也表示没有或空的概念。比如定义了一个变量a,但没有把任何直接量赋给它，那么a就默认指向了undefined；而null不同，有时候需要给某些变量赋值null达到清空的目的。
>
>**对象数据类型**
>
>对象数据类型是一种复合型数据类型，它可以把多个数据放到一起，就好像一个篮子，这个篮子里面的每一个数据都可以看作一个单元，它们都有自己的名字和值。
>
>```javascript
>var container = {};
>```
>
>这是创建对象的一种方式，也是最常用的方式。创建对象后，就相当于开辟了一块内存，对象包含若干数据，每个数据都有自己的名字和值。对象好比是一个容器。
>
>```javascript
>var container = {
>	caoyao:"草药",
>    feijian:"乌木剑"
>};
>```
>
>其实还有其他办法，那就是对象创建后，在外面对这个对象的变量进行操作。
>
>```javascript
>var container = {};
>container.caoyao = "解毒草";
>container.feijian = "乌木剑";
>```
>
>另外，还可以
>
>```solidity
>var container={
>	caoyao:"解毒草"，
>	feijian:"乌木剑"
>};
>var prop = "caoyao";
>console.log(container[prop]);
>console.log(container["caoyao"]);
>```
>
>对象不仅可以用点号（.）访问它的一个属性，也可以用中括号（[]）。如果用中括号，里面就允许写一个变量。当然写字符串也是可以的。
>
>如果事先属性的名称未知，或者调用的属性是动态变化的，就不能使用点号。使用中括号可以最大程度地提升对象调用属性的灵活度。

循环遍历

>for循环
>
>```solidity
>for(var i=0;i<10;i++){
>	console.log(i)
>}
>```
>
>while循环
>
>```solidity
>var i=0;
>while(i<10){
>	console.log(i);
>	i++;
>}
>```
>
>对象内容的遍历
>
>```solidity
>var yeXiaoFan = {
>	name : "叶小凡",
>	age : 16,
>	eat : function(){
>		console.log("KFC");
>	}
>}
>```
>
>然后使用for循环进行遍历对象中属性的名称
>
>```javascript
>for(var p in yeXiaoFan){
>	console.log(p);
>}
>```
>
>使用for循环进行遍历对象中属性的名称和值
>
>```solidity
>var yeXiaoFan = {
>	name : "叶小凡",
>	age : 16,
>	eat : function(){
>		console.log("KFC");
>	}
>}
>
>for(var p in yeXiaoFan){
>	console.log(p+"="+yeXiaoFan[p]);
>}
>```
>
>一旦遇到这种属性名称动态变化的，就只能用一个变量代替了——不能用点号，只能用中括号。

数组

>数组是一个容器可以存放一个或多个对象。数组有四种定义方式：
>
>```javascript
>var arr = ["first","second","third"];
>var a = new Array();
>var b = new Array(8);
>var c = new Array("first","second","third");
>```
>
>push方法：可以把元素添加到数组的尾部
>
>```solidity
>var b = new Array(8);
>b.push("苹果");
>b.push("香蕉");
>```
>
>如果直接用push方法，那么元素就会被添加到数组的尾部，而且原来的8个位置无法占用。
>
>同样也可以使用下标的方式添加元素
>
>```js
>b[0] = "梨";
>```
>
>有两种方法删除元素，第一种是`pop()`方法从数组尾部删除元素
>
>```js
>b.pop()
>```
>
>第二种方法是`splice()`方法
>
>```js
>var a = [1,2,3,4,5];
>a.splice(2,1);
>console.log(a);
>```
>
>