<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%
	String path = request.getContextPath();
	String basePath = request.getScheme() + "://"+ request.getServerName() + ":" + request.getServerPort()+ path + "/";
%>
<!DOCTYPE html>
<html>
<head>
<script type="text/javascript" src="<%=path%>/resources/js/jquery.min.js"></script>
<script type="text/javascript" src="<%=path%>/resources/js/hikvideo/jsencrypt.min.js"></script>
<script type="text/javascript" src="<%=path%>/resources/js/hikvideo/jsWebControl-1.0.0.min.js"></script>
<script type="text/javascript" src="<%=path%>/resources/js/hikvideo/kik_video.js"></script>
 
</head>
<style>
.playWnd {
	/* margin-left:30px; */
    margin: 30px 0 0 60px;
    width: 800px;
    height: 400px;
    border: 1px solid red;
}
.cbInfoDiv {
    float: left;
    width: 360px;
    margin-left: 16px;
    border:1px solid #7F9DB9;
}
.cbInfo {
    height: 200px;
    padding: 5px;
    border: 1px solid #7F9DB9;
    word-break: break-all;
	overflow: scroll／auto;
}
.operate {
    margin-top: 24px;
}
.operate::after {
    content: '';
    display: block;
    clear: both;
}
.operate .btns {
    height: 32px;
}
.module {
    float: left;
    width: 120px;
    min-height: 290px;
    margin-left: 10px;
    padding: 16px 8px;
    box-sizing: border-box;
    border: 1px solid #e5e5e5;
}
.module .item {
    margin-bottom: 4px;
}
.module .label {
    width: 150px;
    display: inline-block;
    vertical-align: middle;
    margin-right: 8px;
    text-align: right;
}
.module input[type="text"],
.module select {
    box-sizing: border-box;
    display: inline-block;
    vertical-align: middle;
    margin-left: 0;
    width: 150px;
    min-height: 20px;
}
.module .btn {
    min-width: 80px;
    min-height: 24px;
    margin-top: 16px;
    margin-left: 158px;
}
</style>
<body>
<div id="playWnd" class="playWnd"></div>

<script>
//插件对象实例，初始化为null，需要创建多个插件窗口时，需要定义多个插件对象实例变量，各个变量唯一标志对应的插件实例
var dev_id = "${requestScope.dev_id}";//视频编号
var oWebControl = null;
var bIE = (!!window.ActiveXObject || 'ActiveXObject' in window);// 是否为IE浏览器
var pubKey = '';                  // demo中未使用加密，可根据需求参照开发指南自行使用加密功能
var initCount = 0;                // 异常重启计数
var iframePos = {};               // iframe相对文档的位置
var parentTitle = '';	          // 父页面标题
var iframeClientPos = null;       // iframe相对视窗的位置
var iframeParentShowSize = null;  // 视窗大小 width height

initPlugin();
//标签关闭
$(window).bind('beforeunload',function(){
    if (oWebControl != null){
			oWebControl.JS_HideWnd();  // 先让窗口隐藏，规避可能的插件窗口滞后于浏览器消失问题
            oWebControl.JS_Disconnect().then(function(){}, function() {});
        }
});
//步骤1：监听父页面的消息
window.addEventListener('message', function(e){
	if(e && e.data){
		switch (e.data.action){
			case 'sendTitle':              // 父页面将其标题发送过来，子页面保存该标题，以便创建插件窗口成功后将标题设置回给父页面
			    console.log("===parentTitle=="+e.data.info)
				parentTitle = e.data.info;
				break;
			case 'updatePos':              // 更新插件位置：JS_CreateWnd时需要父页面计算滚动条偏移量，初始偏移量叠加该偏移量作为iframe的偏移量，防止插件窗口与DIV窗口初始不贴合情况
				var scrollValue = e.data.scrollValue;     // 滚动条滚动偏移量
				oWebControl.JS_SetDocOffset({
					left: iframePos.left + scrollValue.left,
					top: iframePos.top + scrollValue.top
				});  // 更新插件窗口位置
				
				oWebControl.JS_Resize(800, 400);
				setWndCover();	
				break;
			case 'updateInitParam':
				console.log(e.data.iframeClientPos)
				iframePos = e.data.iframeOffset;             // iframe与文档的偏移量
				console.log("===iframePos==="+JSON.stringify(JSON.stringify(iframePos)))
				iframeClientPos = e.data.iframeClientPos;    // iframe相对视窗的位置
				iframeParentShowSize = e.data.showSize;      // 视窗大小
				break;
			case 'resize':
				iframeParentShowSize = e.data.showSize;    // 视窗大小
				iframePos = e.data.iframeOffset;           // iframe与文档的偏移量
				iframeClientPos = e.data.iframeClientPos;  // iframe相对视窗的位置
        		console.log("===offsetLeft==="+iframePos.left)
        		var scrollValue = e.data.scrollValue;     // 滚动条滚动偏移量
				
				if(oWebControl){
					oWebControl.JS_SetDocOffset({
						left: iframePos.left + scrollValue.left,
						top: iframePos.top + scrollValue.top
					});
					oWebControl.JS_Resize(800, 400);
					setWndCover();
				}
				break;
			case 'scroll':
				iframeParentShowSize = e.data.showSize;   // 视窗大小
				iframePos = e.data.iframeOffset;          // iframe与文档的偏移量
				iframeClientPos = e.data.iframeClientPos; // iframe相对视窗的位置				
				var scrollValue = e.data.scrollValue;     // 滚动条滚动偏移量
				if(oWebControl){
					oWebControl.JS_SetDocOffset({
						left: iframePos.left + scrollValue.left,
						top: iframePos.top + scrollValue.top
					});    // 更新插件窗口位置
					oWebControl.JS_Resize(800, 400);
					setWndCover();					
				}
				break;
			default:
				break;
		}
	}
});
//顶部：iframe.getBoundingClientRect().top小于0并且其绝对值超过DIV.get(0).getBoundingClientRect().top部分需要剪切
// 底部：(iframe.getBoundingClientRect().bottom - iframe父窗口可视域高度，为H1)为不可见部分
//       ($(window).height() - DIV.get(0).getBoundingClientRect().bottom)
//        为DIV底部与其所在iframe底部之间的距离H2，H1-H2的值大于0则表示DIV有部分在不可见区域
// 左边：iframe.getBoundingClientRect().left小于0并且其绝对值超过DIV.get(0).getBoundingClientRect().left部分需要剪切
// 右边：(iframe宽度 - DIV.get(0).getBoundingClientRect().right表示DIV右边与其父iframe右边之间的距离，为W1)
//       (iframe父窗口可视域宽度-iframe.getBoundingClientRect().left表示iframe左边与iframe父窗口可视域右边之间的距离，为W2)
//       (iframe宽度 - W2 - W1)如果大于0，则表示DIV右边超出了iframe父窗口可视域，需要剪切超过的部分
function setWndCover() {
	if (oWebControl){
		// 准备要用到的一些数据
		var iframeWndHeight = $(window).height();  // iframe窗口高度
		var iframeWndWidth = $(window).width();    // iframe窗口宽度
		var divLeft = $("#playWnd").get(0).getBoundingClientRect().left;      
		var divTop = $("#playWnd").get(0).getBoundingClientRect().top;
		var divRight = $("#playWnd").get(0).getBoundingClientRect().right;
		var divBottom = $("#playWnd").get(0).getBoundingClientRect().bottom;
		var divWidth = $("#playWnd").width();
		var divHeight = $("#playWnd").height();		
		
		oWebControl.JS_RepairPartWindow(0, 0, 801, 401);  // 多1个像素点防止还原后边界缺失一个像素条
		// 判断剪切矩形的上边距        
		if (iframeClientPos.top < 0 && Math.abs(iframeClientPos.top) > divTop){
			var deltaTop = Math.abs(iframeClientPos.top) - divTop;
			oWebControl.JS_CuttingPartWindow(0, 0, 801, deltaTop + 1);
			//console.log({deltaTop: deltaTop});
		}
		
		// 判断剪切矩形的左边距
		if (iframeClientPos.left < 0 && Math.abs(iframeClientPos.left) > divLeft){
			var deltaLeft = Math.abs(iframeClientPos.left) - divLeft;
			//console.log({deltaLeft: deltaLeft});
			oWebControl.JS_CuttingPartWindow(0, 0, deltaLeft, 401);  // 多剪掉一个像素条，防止出现剪掉一部分窗口后出现一个像素条
		}
		
		// 判断剪切矩形的右边距
		var W1 = iframeWndWidth - divRight;
		var W2 = iframeParentShowSize.width - iframeClientPos.left;	
		if (W2 < divWidth){
			var deltaRight = iframeWndWidth - W2 - W1;				
			if (deltaRight > 0) {			
				oWebControl.JS_CuttingPartWindow(800 - deltaRight, 0, deltaRight + 1, 401);
			}
		}		
		
		// 判断剪切矩形的下边距
		var H1 = iframeClientPos.bottom - iframeParentShowSize.height;
		var H2 = iframeWndHeight - divBottom;
		var deltaBottom = H1 - H2;  
		//console.log({deltaBottom: deltaBottom});		
		if (deltaBottom > 0) {
			oWebControl.JS_CuttingPartWindow(0, 400 - deltaBottom, 801, deltaBottom + 1);
		}
	}		
}

// 创建插件实例，并启动本地服务建立websocket连接，创建插件窗口
function initPlugin () {
	oWebControl = new WebControl({
		szPluginContainer: "playWnd",
		iServicePortStart: 15900,
		iServicePortEnd: 15909,
		szClassId:"23BF3B0A-2C56-4D97-9C03-0CB103AA8F11",   // 用于IE10使用ActiveX的clsid
		cbConnectSuccess: function () {
			initCount = 0;
			setCallbacks();
			oWebControl.JS_StartService("window", {
				dllPath: "./VideoPluginConnect.dll"
			}).then(function () {
				// 步骤2：JS_CreateWnd时指定cbSetDocTitle回调，并在回调中向父页面发送更新标题消息，标题为回调出来的uuid
				oWebControl.JS_CreateWnd("playWnd", 800, 400, {
					cbSetDocTitle: function (uuid) {
					  oWebControl._pendBg = false;
					  window.parent.postMessage({
						  action:'updateTitle',
						  msg:'子页面通知父页面修改title',
						  info:uuid
						}, '\*');    // '\*'表示跨域参数，请结合自身业务合理设置
					}
				}).then(function () {
					// 步骤3：JS_CreateWnd成功后通知父页面将其标题修改回去
					console.log("JS_CreateWnd success");
					window.parent.postMessage({
						  action:'updateTitle',
						  msg:'子页面通知父页面更新title',
						  info: parentTitle
						}, '\*');
					
					// 步骤4：发消息更新插件窗口位置：这里不直接更新的原因是，父页面默认可能就存在滚动条，此时有滚动量
					window.parent.postMessage({
						  action:'updatePos',
						  msg:'更新Pos'
						}, '\*');
						
					initBtnClicked();						
				});
			}, function () {
				console.log("JS_CreateWnd fail");				
			});
		},
		cbConnectError: function () {
			console.log("cbConnectError");
			oWebControl = null;
			$("#playWnd").html("插件未启动，正在尝试启动，请稍候...");
			WebControl.JS_WakeUp("VideoWebPlugin://");
			initCount ++;
			if (initCount < 3) {
				setTimeout(function () {
					initPlugin();
				}, 3000)
			} else {
				$("#playWnd").html("插件启动失败，请检查插件是否安装！");
			}
		},
		cbConnectClose: function (bNormalClose) {
			// 异常断开：bNormalClose = false
			// JS_Disconnect正常断开：bNormalClose = true
			if (true == bNormalClose){
				console.log("cbConnectClose normal");
			}else{
				console.log("cbConnectClose exception");
			}
			
			oWebControl = null;
		}
	});
}


// 获取公钥
function getPubKey (callback) {
    oWebControl.JS_RequestInterface({
        funcName: "getRSAPubKey",
        argument: JSON.stringify({
            keyLength: 1024
        })
    }).then(function (oData) {
        console.log(oData)
        if (oData.responseMsg.data) {
            pubKey = oData.responseMsg.data
            callback()
        }
    })
}

// 设置窗口控制回调
function setCallbacks() {
    oWebControl.JS_SetWindowControlCallback({
        cbIntegrationCallBack: cbIntegrationCallBack
    });
}

// 推送消息
function cbIntegrationCallBack(oData) {
    showCBInfo(JSON.stringify(oData.responseMsg));
}

// RSA加密
function setEncrypt (value) {
    var encrypt = new JSEncrypt();
    encrypt.setPublicKey(pubKey);
    return encrypt.encrypt(value);
}

function requestInterface(value)
{
	console.log("======视频初始化完成====")
	console.log(value)
    oWebControl.JS_RequestInterface(JSON.parse(value)).then(function (oData) {
        console.log(oData)
        showCBInfo(JSON.stringify(oData ? oData.responseMsg : ''));
    });
}

// 显示接口返回的消息及插件回调信息
function showCBInfo(szInfo, type) {
    if (type === 'error') {
        szInfo = "<div style='color: red;'>" + dateFormat(new Date(), "yyyy-MM-dd hh:mm:ss") + " " + szInfo + "</div>";
    } else {
        szInfo = "<div>" + dateFormat(new Date(), "yyyy-MM-dd hh:mm:ss") + " " + szInfo + "</div>";
    }
    $("#cbInfo").html(szInfo + $("#cbInfo").html());
}

function initBtnClicked(){
	console.log("===视频初始化==")
	var param = {
		    "argument": {
		        "appkey": hik_appkey,
		        "ip": hik_ip,
		        "port": 443,
		        "secret": hik_secret,
		        "enableHTTPS": 1,
		        "layout": "1x1",
		        "playMode": 0
		    },
		    "funcName": "init"
		}
	var paramStr = JSON.stringify(param);
    //删除字符串中的回车换行
	paramStr = paramStr.replace(/(\s*)/g, "");
    
	// 执行初始化
	requestInterface(paramStr);
	playBtn();
}

function playBtn(){
    var param = {
    	    "argument": {
    	        "cameraIndexCode": dev_id,
    	        "ezvizDirect": 0,
    	        "gpuMode": 0,
    	        "streamMode": 0,
    	        "transMode": 1,
    	        "wndId": -1
    	    },
    	    "funcName": "startPreview"
    	}
    var paramStr = JSON.stringify(param);
    //删除字符串中的回车换行
	paramStr = paramStr.replace(/(\s*)/g, "");

	// 执行预览
    requestInterface(paramStr);
}

// 清空
$("#clear").click(function() {
    $("#cbInfo").html('');
})

// 格式化时间
function dateFormat(oDate, fmt) {
    var o = {
        "M+": oDate.getMonth() + 1, //月份
        "d+": oDate.getDate(), //日
        "h+": oDate.getHours(), //小时
        "m+": oDate.getMinutes(), //分
        "s+": oDate.getSeconds(), //秒
        "q+": Math.floor((oDate.getMonth() + 3) / 3), //季度
        "S": oDate.getMilliseconds()//毫秒
    };
    if (/(y+)/.test(fmt)) {
        fmt = fmt.replace(RegExp.$1, (oDate.getFullYear() + "").substr(4 - RegExp.$1.length));
    }
    for (var k in o) {
        if (new RegExp("(" + k + ")").test(fmt)) {
            fmt = fmt.replace(RegExp.$1, (RegExp.$1.length == 1) ? (o[k]) : (("00" + o[k]).substr(("" + o[k]).length)));
        }
    }
    return fmt;
}
</script>


</body>
</html>

